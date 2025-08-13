import base64, json, os, shutil, subprocess, tempfile, zipfile, sys
from pathlib import Path

# Optional S3 IO if user wants it
try:
    import boto3
except Exception:
    boto3 = None

from .stage_inputs import stage_from_zip
from .run_dssat import run_single_or_batch
from .collect_outputs import collect_and_zip

RET_DEFAULT = [
    "Summary.OUT","PlantGro.OUT","Evaluate.OUT",
    "Warning.OUT","MODEL.ERR"
]

def _b64_to_file(s: str, out_path: Path):
    data = base64.b64decode(s)
    out_path.write_bytes(data)
    return out_path

def _download_s3(bucket, key, out_path: Path):
    if boto3 is None:
        raise RuntimeError("boto3 not available in runtime")
    s3 = boto3.client("s3")
    s3.download_file(bucket, key, str(out_path))
    return out_path

def _upload_s3(bucket, key, file_path: Path):
    s3 = boto3.client("s3")
    s3.upload_file(str(file_path), bucket, key)
    return f"s3://{bucket}/{key}"

def _upload_unzipped_to_s3(bucket, prefix, work_dir: Path, artifacts):
    """Upload individual output files to S3 (unzipped)"""
    if boto3 is None:
        raise RuntimeError("boto3 not available in runtime")
    
    s3 = boto3.client("s3")
    s3_files = []
    
    for artifact in artifacts:
        file_path = work_dir / artifact
        if file_path.exists():
            s3_key = f"{prefix}/{artifact}"
            s3.upload_file(str(file_path), bucket, s3_key)
            s3_files.append(f"s3://{bucket}/{s3_key}")
    
    return s3_files

def lambda_handler(event, context=None):
    """
    Enhanced Event schema:
      Input Options:
      - zip_b64: base64 ZIP with .MZX, .WTH, .SOL, .CUL, .ECO, .SPE, optional DSSBatch.v4*
      - OR s3_input_bucket + s3_input_key
      
      Output Options:
      - s3_output_bucket + s3_output_prefix: Store outputs in S3
      - unzip_outputs: true|false (unzip individual files to S3, default false)
      - return_zip_b64: true|false (return base64 ZIP in response, default true if no S3 output)
      
      Processing Options:
      - csv: true|false (optional hint; see docs)
      - return_outputs: [list of filenames to prioritize in JSON] (optional)
      - simulation_id: unique identifier for this run (optional, auto-generated if not provided)
    """
    import uuid
    from datetime import datetime
    
    # Generate simulation ID if not provided
    simulation_id = event.get("simulation_id", f"sim-{uuid.uuid4().hex[:8]}")
    timestamp = datetime.utcnow().isoformat()
    
    work = Path("/tmp/work");  inp = Path("/tmp/in/in.zip")
    out_zip = Path("/tmp/out/results.zip")
    for p in [work.parent, out_zip.parent, inp.parent]:
        p.mkdir(parents=True, exist_ok=True)

    # ---- Fetch input ZIP ----
    if "zip_b64" in event and event["zip_b64"]:
        _b64_to_file(event["zip_b64"], inp)
    elif "s3_input_bucket" in event and "s3_input_key" in event:
        _download_s3(event["s3_input_bucket"], event["s3_input_key"], inp)
    else:
        return {"status": "ERROR", "error": "Missing zip_b64 or s3_input_* or empty zip_b64"}

    # Optional explicit module code override from event (e.g., MZCER048)
    if event.get("module_code"):
        os.environ["DSSAT_MODULE"] = event["module_code"].strip()

    # ---- Stage inputs & core Data ----
    staged = stage_from_zip(inp, work_dir=work)
    # staged = {"mzx": [Path,...], "batch_file": Path|None, "driver": "A"|"B"|None}

    # ---- Run model ----
    run_info = run_single_or_batch(work, staged)
    # run_info = {"status": "...", "mode": "A|B|MULTI_A", "runs": int, "exit_code": 0|!=0}

    # ---- Collect outputs ----
    want = event.get("return_outputs", RET_DEFAULT)
    artifacts, zipped_path = collect_and_zip(work, out_zip, prioritize=want)

    # ---- Ship outputs ----
    resp = {
        "status": run_info["status"],
        "mode": run_info["mode"],
        "runs": run_info["runs"],
        "exit_code": run_info["exit_code"],
    "module": run_info.get("module"),
    "artifacts": artifacts,
    "precheck_warnings": staged.get("precheck", []),
    "last_stdout": run_info.get("last_stdout"),
    "last_stderr": run_info.get("last_stderr"),
        "simulation_id": simulation_id,
        "timestamp": timestamp
    }

    # S3 Output handling
    s3_uri = None
    s3_files = []
    
    if "s3_output_bucket" in event and "s3_output_prefix" in event:
        bucket = event["s3_output_bucket"]
        prefix = event["s3_output_prefix"].rstrip("/")
        
        # Upload main results ZIP
        zip_key = f"{prefix}/results.zip"
        s3_uri = _upload_s3(bucket, zip_key, zipped_path)
        resp["s3_results_zip"] = s3_uri
        
        # Optionally unzip individual files to S3
        if event.get("unzip_outputs", False):
            s3_files = _upload_unzipped_to_s3(bucket, prefix, work, artifacts)
            resp["s3_files"] = s3_files
            
        # Upload metadata
        metadata = {
            "simulation_id": simulation_id,
            "timestamp": timestamp,
            "status": run_info["status"],
            "mode": run_info["mode"],
            "runs": run_info["runs"],
            "exit_code": run_info["exit_code"],
            "artifacts": artifacts,
            "input_source": "s3" if "s3_input_bucket" in event else "base64"
        }
        if "s3_input_bucket" in event:
            metadata["input_s3"] = f"s3://{event['s3_input_bucket']}/{event['s3_input_key']}"
            
        metadata_key = f"{prefix}/metadata.json"
        metadata_path = Path("/tmp/metadata.json")
        metadata_path.write_text(json.dumps(metadata, indent=2))
        _upload_s3(bucket, metadata_key, metadata_path)
        resp["s3_metadata"] = f"s3://{bucket}/{metadata_key}"

    # Return base64 ZIP if requested or no S3 output configured
    if event.get("return_zip_b64", (s3_uri is None)):
        resp["results_zip_b64"] = base64.b64encode(zipped_path.read_bytes()).decode("ascii")

    return resp

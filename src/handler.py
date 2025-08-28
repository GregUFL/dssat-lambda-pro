import base64, json, os, shutil, subprocess, tempfile
import zipfile, sys
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

def stage_individual_files(input_files, work_dir: Path):
    """Stage individual files from S3 or base64 content"""
    from .stage_inputs import _copy_core_data, _place_by_ext
    
    work_dir.mkdir(parents=True, exist_ok=True)
    _copy_core_data(work_dir)
    
    experiment_files = []
    batch_file = None
    
    for filename, source in input_files.items():
        file_path = work_dir / "temp" / filename
        file_path.parent.mkdir(parents=True, exist_ok=True)
        
        if isinstance(source, dict):
            if "s3_bucket" in source and "s3_key" in source:
                # Download from S3
                _download_s3(source["s3_bucket"], source["s3_key"], file_path)
            elif "base64_content" in source:
                # Decode base64 content
                _b64_to_file(source["base64_content"], file_path)
            else:
                raise ValueError(f"Invalid source for file {filename}: {source}")
        else:
            # Assume it's base64 content directly
            _b64_to_file(source, file_path)
        
        # Organize file by extension
        _place_by_ext(file_path, work_dir)
        
        # Track experiment files by their final location
        ext = Path(filename).suffix.upper()
        if len(ext) == 4 and ext.endswith('X'):
            # Experiment files go to root directory
            experiment_files.append(work_dir / filename)
        elif ext == ".V48":
            # Batch files go to root directory
            batch_file = work_dir / filename
    
    # Determine driver mode
    driver = None
    if batch_file:
        driver = "B"
    elif len(experiment_files) == 1:
        driver = "A"
    
    staged = {
        "mzx": experiment_files,
        "batch_file": batch_file,
        "driver": driver,
        "precheck": []
    }
    
    return staged

def stage_direct_content(files_content, work_dir: Path):
    """Stage files directly from base64 content in JSON"""
    from .stage_inputs import _copy_core_data, _place_by_ext
    
    work_dir.mkdir(parents=True, exist_ok=True)
    _copy_core_data(work_dir)
    
    experiment_files = []
    batch_file = None
    
    for filename, base64_content in files_content.items():
        file_path = work_dir / "temp" / filename
        file_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Decode base64 content
        _b64_to_file(base64_content, file_path)
        
        # Organize file by extension
        _place_by_ext(file_path, work_dir)
        
        # Track experiment files
        ext = Path(filename).suffix.upper()
        if len(ext) == 4 and ext.endswith('X'):
            experiment_files.append(filename)
        elif ext == ".V48":
            batch_file = filename
    
    # Determine driver mode
    driver = None
    if batch_file:
        driver = "B"
    elif len(experiment_files) == 1:
        driver = "A"
    
    staged = {
        "mzx": [work_dir / name for name in experiment_files],
        "batch_file": (work_dir / batch_file) if batch_file else None,
        "driver": driver,
        "precheck": []
    }
    
    return staged

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

    # ---- Enhanced Input Processing ----
    if "input_files" in event:
        # NEW: Individual files with flexible sources
        staged = stage_individual_files(event["input_files"], work)
        
    elif "files_content" in event:
        # NEW: Direct file content as base64 in JSON
        staged = stage_direct_content(event["files_content"], work)
        
    elif "zip_b64" in event and event["zip_b64"]:
        # EXISTING: Base64 ZIP input
        _b64_to_file(event["zip_b64"], inp)
        staged = stage_from_zip(inp, work_dir=work)
        
    elif "s3_input_bucket" in event and "s3_input_key" in event:
        # EXISTING: S3 ZIP input
        _download_s3(event["s3_input_bucket"], event["s3_input_key"], inp)
        staged = stage_from_zip(inp, work_dir=work)
        
    else:
        return {"status": "ERROR", "error": "No valid input method provided"}

    # Optional explicit module code override from event (e.g., MZCER048)
    if event.get("module_code"):
        os.environ["DSSAT_MODULE"] = event["module_code"].strip()

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

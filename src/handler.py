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

def lambda_handler(event, context=None):
    """
    Event schema:
      - zip_b64: base64 ZIP with .MZX, .WTH, .SOL, .CUL, .ECO, .SPE, optional DSSBatch.v4*
      - OR s3_input_bucket + s3_input_key
      - csv: true|false (optional hint; see docs)
      - return_outputs: [list of filenames to prioritize in JSON] (optional)
      - s3_output_bucket, s3_output_prefix (optional)
      - return_zip_b64: true|false (default true if no S3 output)
    """
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
        "artifacts": artifacts,
    }

    s3_uri = None
    if "s3_output_bucket" in event and "s3_output_prefix" in event:
        key = event["s3_output_prefix"].rstrip("/") + "/results.zip"
        s3_uri = _upload_s3(event["s3_output_bucket"], key, zipped_path)
        resp["s3_results"] = s3_uri

    if event.get("return_zip_b64", (s3_uri is None)):
        resp["results_zip_b64"] = base64.b64encode(zipped_path.read_bytes()).decode("ascii")

    return resp

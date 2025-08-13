import subprocess, os
from pathlib import Path

def _run(cmd, cwd: Path):
    p = subprocess.run(cmd, cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return p.returncode, p.stdout, p.stderr

def run_single_or_batch(work_dir: Path, staged: dict):
    """
    Policy:
      - If a DSSBatch.v4* is present -> B mode (single invocation)
      - Else if exactly one .MZX -> A mode (all treatments)
      - Else (>=2 .MZX) -> loop A-mode per file (MULTI_A)
    """
    mode = "UNKNOWN"; runs = 0; last_rc = 0

    # Ensure model sees DSSATPRO.v48 and CDE in cwd
    os.chdir(str(work_dir))

    if staged.get("batch_file"):
        mode = "B"
        last_rc, _, _ = _run(["/var/task/bin/dscsm048", "B", staged["batch_file"].name], work_dir)
        runs = 1
    elif len(staged.get("mzx", [])) == 1:
        mode = "A"
        filex = staged["mzx"][0].name
        last_rc, _, _ = _run(["/var/task/bin/dscsm048", "A", filex], work_dir)
        runs = 1
    else:
        mode = "MULTI_A"
        last_rc = 0
        for p in staged.get("mzx", []):
            rc, _, _ = _run(["/var/task/bin/dscsm048", "A", p.name], work_dir)
            # record non-zero but continue to collect outputs
            if rc != 0:
                last_rc = rc
            runs += 1

    status = "OK" if last_rc == 0 else "NONZERO_EXIT"
    return {"status": status, "mode": mode, "runs": runs, "exit_code": last_rc}

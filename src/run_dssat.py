import subprocess, os, re
from pathlib import Path

def _run(cmd, cwd: Path):
    p = subprocess.run(cmd, cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return p.returncode, p.stdout, p.stderr

MODULE_MAP = {
    # DSSAT crop codes -> module executable code
    # From DSSATPRO.v48
    "AL": "PRFRM048",   # Alfalfa
    "BA": "CSCER048",   # Barley
    "BG": "CRGRO048",   # Bambara Groundnut
    "BH": "PRFRM048",   # Bahia Grass
    "BM": "PRFRM048",   # Bermuda Grass
    "BN": "CRGRO048",   # Dry Bean
    "BR": "PRFRM048",   # Brachiaria
    "BS": "BSCER048",   # Sugar Beet
    "CB": "CRGRO048",   # Cabbage
    "CH": "CRGRO048",   # Chickpea
    "CI": "CRGRO048",   # Chia
    "CN": "CRGRO048",   # Canola
    "CO": "CRGRO048",   # Cotton
    "CP": "CRGRO048",   # Cowpea
    "CS": "CSYCA048",   # Cassava
    "FB": "CRGRO048",   # Faba Bean
    "GB": "CRGRO048",   # Green Bean
    "GG": "PRFRM048",   # Guinea Grass
    "ML": "MLCER048",   # Millet
    "MZ": "MZCER048",   # Maize
    "PE": "CRGRO048",   # Pea
    "PI": "PIALO048",   # Pineapple
    "PN": "CRGRO048",   # Peanut
    "PO": "PRFRM048",   # Perennial Peanut
    "PP": "CRGRO048",   # Pigeon Pea
    "PT": "PTSUB048",   # Potato
    "QU": "CRGRO048",   # Quinoa
    "RI": "RICER048",   # Rice
    "SB": "CRGRO048",   # Soybean
    "SC": "SCCAN048",   # Sugarcane
    "SG": "SGCER048",   # Sorghum
    "SR": "CRGRO048",   # Strawberry
    "SU": "CRGRO048",   # Sunflower
    "SW": "SWCER048",   # Sweet Corn
    "TM": "CRGRO048",   # Tomato
    "TR": "TRARO048",   # Taro
    "WH": "CSCER048",   # Wheat (uses generic CERES)
}
GENERIC_MODULE = "CSCER048"

def _detect_module(filex: Path) -> str | None:
    """Infer module code from FileX.
    Order:
      1. Extension pattern .??X -> first two letters (e.g., .MZX -> MZ)
      2. *CULTIVARS section second token (legacy heuristic)
    Returns module executable code or None.
    """
    # 1. Extension-based crop code
    ext = filex.suffix.upper()  # e.g., .MZX
    if len(ext) == 4 and ext.endswith('X'):
        crop2 = ext[1:3]
        if crop2 in MODULE_MAP:
            return MODULE_MAP[crop2]
    try:
        text = filex.read_text(errors="ignore")
    except Exception:
        return None
    # Find *CULTIVARS section then first data line beginning with index number
    cult_idx = text.upper().find("*CULTIVARS")
    if cult_idx == -1:
        return None
    after = text[cult_idx:].splitlines()[1:50]  # look ahead some lines
    for line in after:
        if re.match(r"^\s*\d+\s+\w+\b", line):
            parts = line.strip().split()
            if len(parts) >= 2:
                crop_code = parts[1].upper()[:2]
                if crop_code in MODULE_MAP:
                    return MODULE_MAP[crop_code]
    return None

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

    launcher = "/var/task/bin/run_dssat_wrapper.sh"
    # Determine module code from first FileX (if available)
    module_code = None
    first_filex = None
    if staged.get("mzx"):
        first_filex = staged["mzx"][0]
        module_code = _detect_module(first_filex)
    # Fallback environment override
    if not module_code:
        module_code = os.environ.get("DSSAT_MODULE")
    if not module_code:
        module_code = GENERIC_MODULE  # final fallback
    if os.environ.get("DSSAT_DEBUG"):
        print(f"DSSAT_DEBUG module={module_code} staged_driver={staged.get('driver')} mzx_count={len(staged.get('mzx', []))}")
    if staged.get("batch_file") and module_code:
        mode = "B"
        last_rc, out, err = _run([launcher, module_code, "B", staged["batch_file"].name], work_dir)
        runs = 1
    elif len(staged.get("mzx", [])) == 1:
        mode = "A"
        filex = staged["mzx"][0].name
        if module_code:
            last_rc, out, err = _run([launcher, module_code, "A", filex], work_dir)
        else:  # legacy two-arg fallback
            last_rc, out, err = _run([launcher, "A", filex], work_dir)
        runs = 1
    else:
        mode = "MULTI_A"
        last_rc = 0
        for p in staged.get("mzx", []):
            if module_code:
                rc, out, err = _run([launcher, module_code, "A", p.name], work_dir)
            else:
                rc, out, err = _run([launcher, "A", p.name], work_dir)
            # record non-zero but continue to collect outputs
            if rc != 0:
                last_rc = rc
            runs += 1

    status = "OK" if last_rc == 0 else "NONZERO_EXIT"
    # Preserve last stdout/stderr for troubleshooting
    return {"status": status, "mode": mode, "runs": runs, "exit_code": last_rc, "last_stdout": out, "last_stderr": err, "module": module_code}

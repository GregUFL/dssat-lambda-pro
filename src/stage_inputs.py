import zipfile, shutil, os
from pathlib import Path
import re

ESSENTIAL = [
    "DSSATPRO.v48",
    "DATA.CDE",
    "DETAIL.CDE",
    "GCOEFF.CDE",
    "ECONOMIC.CDE",
    "DSCSM048.CTR",  # control file needed by model
]

def _copy_core_data(dst_root: Path):
    """Copy ALL core Data shipped in image into work dir.
    This is safer than cherry-picking and avoids PATH related runtime errors.
    User-provided inputs will overwrite as needed.
    """
    src_data = Path("/var/task/Data")
    for item in src_data.iterdir():
        dst_path = dst_root / item.name
        if item.is_dir():
            if dst_path.exists():
                shutil.rmtree(dst_path)
            shutil.copytree(item, dst_path)
        else:
            shutil.copy2(item, dst_path)
    # Ensure runtime subdirs exist for categorized placement
    for d in ["Weather", "Soil", "Genotype"]:
        (dst_root / d).mkdir(parents=True, exist_ok=True)

def _place_by_ext(f: Path, root: Path):
    ext = f.suffix.upper()
    # Handle ALL crop experiment files (.??X pattern)
    if len(ext) == 4 and ext.endswith('X'):
        # All experiment files: .MZX, .WHX, .RIX, .SBX, .COX, etc.
        shutil.move(str(f), str(root / f.name))
    elif ext == ".WTH":
        shutil.move(str(f), str(root / "Weather" / f.name))
    elif ext == ".SOL":
        shutil.move(str(f), str(root / "Soil" / f.name))
    elif ext in (".CUL", ".ECO", ".SPE"):
        shutil.move(str(f), str(root / "Genotype" / f.name))
    elif ext in (".V48",):
        # Accept user-supplied batch control as-is in root
        shutil.move(str(f), str(root / f.name))
    else:
        # keep in root for safety
        shutil.move(str(f), str(root / f.name))

def stage_from_zip(zip_path, work_dir: Path):
    work_dir.mkdir(parents=True, exist_ok=True)
    tmp_extract = work_dir.parent / "in_extract"
    if tmp_extract.exists():
        shutil.rmtree(tmp_extract)
    tmp_extract.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(tmp_extract)

    _copy_core_data(work_dir)

    mzx = []  # Experiment files (all crops: .MZX, .WHX, .RIX, .SBX, etc.)
    batch_file = None
    for p in tmp_extract.rglob("*"):
        if p.is_dir():
            continue
        ext = p.suffix.upper()
        # Detect ALL crop experiment files (.??X pattern)
        if len(ext) == 4 and ext.endswith('X'):
            mzx.append(p.name)
        if ext == ".V48" and p.name.upper().endswith(".V48"):
            batch_file = p.name
        _place_by_ext(p, work_dir)

    driver = None
    if batch_file:
        driver = "B"
    elif len(mzx) == 1:
        driver = "A"

    staged = {
        "mzx": [work_dir / name for name in mzx],
        "batch_file": (work_dir / batch_file) if batch_file else None,
        "driver": driver,
        "precheck": []
    }

    # Pre-validate references (Weather WSTA and first soil code) for quick feedback
    for fx in staged["mzx"]:
        try:
            txt = fx.read_text(errors="ignore")
        except Exception:
            continue
        # Weather station code often in *WEATHER or general header lines WSTA = XXXXX
        wsta_match = re.search(r"WSTA\s*=\s*([A-Z0-9]{5})", txt, re.IGNORECASE)
        if wsta_match:
            wsta = wsta_match.group(1).upper()
            # Expect matching file Weather/<WSTA>.WTH
            if not (work_dir / "Weather" / f"{wsta}.WTH").exists():
                staged["precheck"].append(f"Missing weather file Weather/{wsta}.WTH referenced by {fx.name}")
        # Soil file code (SLTX/SLNO lines vary; simplest: search for a .SOL token)
        soil_match = re.search(r"\b([A-Z0-9]{5})\.SOL\b", txt, re.IGNORECASE)
        if soil_match:
            soil = soil_match.group(1).upper()+".SOL"
            if not (work_dir / "Soil" / soil).exists():
                staged["precheck"].append(f"Missing soil file Soil/{soil} referenced by {fx.name}")

    # Check essentials presence
    for name in ESSENTIAL:
        if not (work_dir / name).exists():
            staged["precheck"].append(f"Missing essential file {name}")

    # Warn if no weather files but references exist
    if not any((work_dir/"Weather").glob("*.WTH")) and staged["mzx"]:
        staged["precheck"].append("No Weather/*.WTH files present")

    return staged

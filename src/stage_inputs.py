import zipfile, shutil, os
from pathlib import Path

ESSENTIAL = ["DSSATPRO.v48", "Data.CDE", "Detail.CDE"]

def _copy_core_data(dst_root: Path):
    # Copy core Data shipped in image into work dir
    src_data = Path("/var/task/Data")
    (dst_root / "Genotype").mkdir(parents=True, exist_ok=True)
    (dst_root / "StandardData").mkdir(parents=True, exist_ok=True)
    (dst_root / "Weather").mkdir(parents=True, exist_ok=True)
    (dst_root / "Soil").mkdir(parents=True, exist_ok=True)

    # Copy essentials (files)
    for fname in ESSENTIAL:
        shutil.copy2(src_data / fname, dst_root / fname)
    # Copy dirs (subset needed for run-time)
    for d in ["StandardData", "Genotype"]:
        src_d = src_data / d
        dst_d = dst_root / d
        if dst_d.exists():
            shutil.rmtree(dst_d)
        shutil.copytree(src_d, dst_d)

def _place_by_ext(f: Path, root: Path):
    ext = f.suffix.upper()
    if ext == ".MZX":  # FileX
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

    mzx = []
    batch_file = None
    for p in tmp_extract.rglob("*"):
        if p.is_dir():
            continue
        if p.suffix.upper() == ".MZX":
            mzx.append(p.name)
        if p.suffix.upper() == ".V48" and p.name.upper().endswith(".V48"):
            batch_file = p.name
        _place_by_ext(p, work_dir)

    driver = None
    if batch_file:
        driver = "B"
    elif len(mzx) == 1:
        driver = "A"

    return {
        "mzx": [work_dir / name for name in mzx],
        "batch_file": (work_dir / batch_file) if batch_file else None,
        "driver": driver
    }

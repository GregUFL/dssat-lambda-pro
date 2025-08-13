import io, zipfile
from pathlib import Path

DEFAULT_GLOBS = [
    "*.OUT", "*.CSV", "*.PLT", "*.DSS", "MODEL.ERR", "WARNING.OUT"
]

def _walk_files(root: Path):
    for p in root.rglob("*"):
        if p.is_file():
            yield p

def collect_and_zip(work_dir: Path, out_zip: Path, prioritize=None):
    # Gather outputs
    files = []
    pri_set = set([n.upper() for n in (prioritize or [])])

    # Prefer prioritize list order
    present = {p.name.upper(): p for p in _walk_files(work_dir)}
    ordered = []
    for name in (prioritize or []):
        p = present.get(name.upper())
        if p: ordered.append(p)

    # Add the rest matching defaults
    if not ordered:
        for p in _walk_files(work_dir):
            up = p.name.upper()
            if up in pri_set:
                ordered.append(p)
        # fallback: add common extensions
        for p in _walk_files(work_dir):
            if p.suffix.upper() in (".OUT", ".CSV", ".PLT", ".DSS") or p.name.upper() in ("MODEL.ERR","WARNING.OUT"):
                if p not in ordered:
                    ordered.append(p)

    # Write zip
    out_zip.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(out_zip, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        relroot = work_dir
        for p in ordered:
            arc = str(p.relative_to(relroot))
            zf.write(p, arcname=arc)

    return [str(p.relative_to(work_dir)) for p in ordered], out_zip

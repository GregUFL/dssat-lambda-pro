#!/bin/sh
# Ensure /DSSAT48 symlink points at the current working directory (model expects this root)
WORKDIR="$(pwd)"
if [ ! -e /DSSAT48 ]; then
  ln -s "$WORKDIR" /DSSAT48 2>/dev/null || true
fi
# Provide case-insensitive aliases for data files some routines expect
for base in DATA DETAIL ECONOMIC; do
  u="${base}.CDE"
  t="${base^}.CDE"  # Capitalize first letter only
  [ -f "$WORKDIR/$u" ] && [ ! -f "$WORKDIR/$t" ] && ln -s "$WORKDIR/$u" "$WORKDIR/$t" 2>/dev/null || true
done
if [ -f "$WORKDIR/DSSATPRO.v48" ] && [ ! -f "$WORKDIR/DssatPro.v48" ]; then
  ln -s "$WORKDIR/DSSATPRO.v48" "$WORKDIR/DssatPro.v48" 2>/dev/null || true
fi
if [ -f "$WORKDIR/DSCSM048.CTR" ] && [ ! -f "$WORKDIR/Dscsm048.CTR" ]; then
  ln -s "$WORKDIR/DSCSM048.CTR" "$WORKDIR/Dscsm048.CTR" 2>/dev/null || true
fi
if [ ! -e "$WORKDIR/DSCSM048.EXE" ]; then
  ln -s /var/task/bin/dscsm048 "$WORKDIR/DSCSM048.EXE" 2>/dev/null || cp /var/task/bin/dscsm048 "$WORKDIR/DSCSM048.EXE" 2>/dev/null || true
fi

# Some compiled-in references look for /usr/local/StandardData/*. Provide a symlink
# pointing at the staged StandardData inside the working directory (which already
# contains a copy from the image Data tree). Fallback to image Data if not present.
if [ ! -e /usr/local/StandardData ]; then
  if [ -d "$WORKDIR/StandardData" ]; then
    ln -s "$WORKDIR/StandardData" /usr/local/StandardData 2>/dev/null || true
  elif [ -d /var/task/Data/StandardData ]; then
    ln -s /var/task/Data/StandardData /usr/local/StandardData 2>/dev/null || true
  fi
fi

# AWS Lambda fallback: if symlink failed, copy all StandardData files to working directory
if [ ! -e /usr/local/StandardData ] && [ -d /var/task/Data/StandardData ]; then
  cp /var/task/Data/StandardData/* "$WORKDIR/" 2>/dev/null || true
fi

# Export environment variables some tooling expects
export DSSATDIR=/DSSAT48
export DSSATPATH=/DSSAT48

# Provide root-level symlinks for Weather and Soil files (some legacy inputs expect flat layout)
for w in "$WORKDIR"/Weather/*.WTH; do
  [ -f "$w" ] || continue
  base=$(basename "$w")
  [ -e "$WORKDIR/$base" ] || ln -s "$w" "$WORKDIR/$base" 2>/dev/null || true
done
for s in "$WORKDIR"/Soil/*.SOL; do
  [ -f "$s" ] || continue
  base=$(basename "$s")
  [ -e "$WORKDIR/$base" ] || ln -s "$s" "$WORKDIR/$base" 2>/dev/null || true
done

# Promote genotype definition files to root so legacy path expectations resolve
for g in "$WORKDIR"/Genotype/*.[cC][uU][lL] "$WORKDIR"/Genotype/*.[eE][cC][oO] "$WORKDIR"/Genotype/*.[sS][pP][eE]; do
  [ -f "$g" ] || continue
  base=$(basename "$g")
  # Overwrite Data copy if exists
  if [ ! -L "$WORKDIR/$base" ] && [ -f "$WORKDIR/$base" ]; then
    rm -f "$WORKDIR/$base" 2>/dev/null || true
  fi
  [ -e "$WORKDIR/$base" ] || ln -s "$g" "$WORKDIR/$base" 2>/dev/null || true
done

# If debug requested, snapshot directory tree
if [ -n "$DSSAT_DEBUG" ]; then
  (echo "--- WORK DIR TREE ---"; find "$WORKDIR" -maxdepth 3 -type f -printf '%P\n'; echo "--- ARGS ---"; printf '%s ' "$@"; echo) > "$WORKDIR/DIAG.TXT" 2>&1 || true
fi

exec ./DSCSM048.EXE "$@"

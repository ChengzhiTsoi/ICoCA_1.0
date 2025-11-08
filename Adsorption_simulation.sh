#!/bin/bash
# Environment: ADTL/LINUX/prepared_structures
set -euo pipefail

FrameworkName="$1"

# Safety check: ensure .mol file exists
if [[ -f "$FrameworkName.mol" ]]; then
    mol_src="$FrameworkName.mol"
elif [[ -f "$FrameworkName/$FrameworkName.mol" ]]; then
    mol_src="$FrameworkName/$FrameworkName.mol"
else
    echo "Skipping $FrameworkName: mol file not found (root or subdir)."
    exit 0
fi

# If the directory and simulation.input already exist, do not overwrite
if [[ -d "$FrameworkName" && -f "$FrameworkName/simulation.input" ]]; then
    cd "$FrameworkName"
else
    mkdir -p "$FrameworkName"
    cp "$mol_src" "$FrameworkName/"
    cp "simulation.input" "$FrameworkName/"
    cd "$FrameworkName"

    # Only replace placeholder INDEX if it still exists
    # Escape special characters in FrameworkName to avoid sed errors
    if grep -q 'INDEX' simulation.input; then
        safe_name=$(printf '%s' "$FrameworkName" | sed 's/[\/&]/\\&/g')
        sed -i "s/INDEX/$safe_name/" simulation.input
    fi
fi

if grep -Eiq '(^|[[:space:]])-?[Nn][Aa][Nn]([[:space:]]|$)' "$FrameworkName.mol"; then
  echo "Detected NaN charges in $FrameworkName.mol, skipping GCMC."
  {
    flock -x 9
    echo "$FrameworkName" >> ../../../error_list_gcmc.txt
  } 9>> ../.gcmc_progress.lock
  exit 1
fi

# Set RASPA environment variables. Environment: ADTL/LINUX/prepared_structures/$FrameworkName
export RASPA_DIR="${RASPA_PATH}"
export PATH="$RASPA_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$RASPA_DIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Run simulation and handle errors
if ! "$RASPA_DIR/bin/simulate" -i simulation.input > simulate.log 2>&1; then
    # Append to error list with file lock to avoid race conditions
    {
      flock -x 9
      echo "$FrameworkName" >> ../../../error_list_gcmc.txt
    } 9>> ../.gcmc_progress.lock
    exit 1
fi

# Update global progress with atomic read/write using file lock
{
  flock -x 9
  count=$(cat ../.gcmc_progress)
  count=$((count + 1))
  echo "$count" > ../.gcmc_progress
  total=$(cat ../.gcmc_total)
  printf "Progress: %d / %d GCMC completed\n" "$count" "$total"
} 9>> ../.gcmc_progress.lock

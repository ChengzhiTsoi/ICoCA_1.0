#!/bin/bash
# Env: ADTL/gcmc_selected_structures

FrameworkName=$1

mkdir -p "$FrameworkName"
cp "$FrameworkName.cif" "$FrameworkName/"
cp "lammps_input.in" "$FrameworkName/"
cp "DatatoCif.py" "$FrameworkName/"

cd "$FrameworkName"

# Step 1: Run lammps-interface
lammps-interface "$FrameworkName.cif" -ff UFF4MOF --cutoff 12.0

# Step 2: Check output of lammps-interface
if [ ! -s "data.${FrameworkName}" ]; then
    echo "$FrameworkName" >> ../../error_list_obtain_data.txt
    exit 0
fi

# Step 3: Run LAMMPS
sed -i 's/INDEX/'"${FrameworkName}"'/' lammps_input.in
if ! ${LAMMPS_PATH}/src/lmp_mpi -in lammps_input.in; then
    echo "$FrameworkName" >> ../error_list_energy_mini.txt
    exit 0
fi

# Step 4: Convert to optimized cif
python3 DatatoCif.py

# Step 5: Move result to LINUX folder
cd ../..
cp "gcmc_selected_structures/$FrameworkName/optimized_structure.cif" "LINUX/$FrameworkName.cif"

# Step 6: Progress tracking
(
    flock -n 9 || exit 1
    count=$(cat gcmc_selected_structures/.progress_counter)
    count=$((count + 1))
    echo $count > gcmc_selected_structures/.progress_counter
    echo -ne "Progress: $count minimized\r"
) 9> gcmc_selected_structures/.progress_counter.lock

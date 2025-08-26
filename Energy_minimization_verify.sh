#!/bin/bash
# Env: ADTL/LINUX/MOF_verify

FrameworkName=$1

mkdir -p "$FrameworkName"
mv "$FrameworkName.cif" "$FrameworkName/$FrameworkName.cif"
cp "lammps_input.in" "$FrameworkName/"
cp "DatatoCif.py" "$FrameworkName/"

cd "$FrameworkName"

# Run lammps-interface
lammps-interface "$FrameworkName.cif" -ff UFF4MOF --cutoff 12.0

# Check data file existence
if [ ! -s "data.${FrameworkName}" ]; then
    echo "$FrameworkName" >> ../../../error_list_obtain_data.txt
    exit 0
fi

# Run LAMMPS
sed -i 's/INDEX/'"$FrameworkName"'/' lammps_input.in
if ! ${LAMMPS_PATH}/src/lmp_mpi -in lammps_input.in; then
    echo "$FrameworkName" >> ../../../error_list_energy_mini.txt
    exit 0
fi

# Convert to optimized CIF
python3 DatatoCif.py

cd ../..
cp "LINUX/MOF_verify/$FrameworkName/optimized_mof.cif" "LINUX/$FrameworkName.cif"

# Update progress
(
    flock -n 9 || exit 1
    count=$(cat LINUX/MOF_verify/.verify_progress)
    count=$((count + 1))
    echo $count > LINUX/MOF_verify/.verify_progress
    echo -ne "Progress: $count verified\r"
) 9> LINUX/MOF_verify/.verify_progress.lock

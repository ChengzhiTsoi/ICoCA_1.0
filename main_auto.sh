#!/bin/bash
source /afs/crc.nd.edu/user/c/ccai/miniconda3/etc/profile.d/conda.sh
conda activate dl-env  
chmod 777 *.sh
chmod 777 *.py



# Beginning
print_banner() {
                echo "============================================="
                echo "                                             "
                echo "    #####   #####           #####     #      "
                echo "      #     #   #           #   #    # #     "
                echo "      #     #        ###    #       #   #    "
                echo "      #     #       #   #   #       #####    "
                echo "      #     #       #   #   #       #   #    "
                echo "      #     #   #   #   #   #   #   #   #    "
                echo "    #####   #####    ###    #####   #   #    "
                echo "                                             "
                echo " Iterative Construction of Crystal Adsorbent "
                echo "                                             "
                echo "============================================="
                }
print_banner
echo ">>> Starting AutoDesign..."



part1(){
# Automatically design of MOFs. Env: ADTL
python3 MOF_design_part1.py
}



part2(){
# Dividing MOFs into train set and test set. Env: ADTL
python3 MOF_design_part2.py


# Energy minimization. Env: ADTL
cd gcmc_selected_mofs

# Remove Windows-style carriage returns if any
sed -i 's/\r$//' MOFs_gcmc.csv
N_samp=$(wc -l < MOFs_gcmc.csv)
MAX_JOBS=$MAX_JOBS

# Clean up old folders and outputs (only once)
echo "Cleaning previous MOF directories..."
cat MOFs_gcmc.csv | tail -n +2 | awk '{print $1}' | while read FrameworkName; do
    rm -rf "$FrameworkName"
    rm -f "../LINUX/$FrameworkName.cif"
done

# Prepare progress tracking
progress_file=".progress_counter"
echo 0 > $progress_file
rm -f $progress_file.lock

# Run energy minimization with GNU parallel
cat MOFs_gcmc.csv | tail -n +2 | awk '{print $1}' | parallel -j "${MAX_JOBS:-1}" ../Energy_minimization.sh {}
echo -e "All minimizations completed!"

# Clean up progress file
rm -f $progress_file $progress_file.lock
cd ..


# EQeq charge assignment. Env: ADTL
cd LINUX

# Set trap to clean child processes if script is interrupted
trap 'pkill -P $$' EXIT

# Preprocessing
sed -i 's/\r$//' MOFs_gcmc.csv
N_samp=$(wc -l < MOFs_gcmc.csv)
MAX_JOBS=$MAX_JOBS
topdir=$PWD

# Step 1: Clean up old folders
echo "Cleaning EQeq temporary folders..."
cat MOFs_gcmc.csv | tail -n +2 | awk '{print $1}' | while read FrameworkName; do
    rm -rf "$FrameworkName"
done

# Step 2: Create progress tracker
progress_file=".charge_progress"
echo 0 > $progress_file
rm -f "$progress_file.lock"

# Step 3: Run EQeq in parallel
cat MOFs_gcmc.csv | tail -n +2 | awk '{print $1}' | parallel -j "${MAX_JOBS:-1}" ../EQeq_calculation.sh {}
echo -e "All EQeq charge calculations completed!"

# Step 4: Extract mol files
echo "Extracting EQeq mol files to prepared_mofs..."
mkdir -p prepared_mofs   # Create if it doesn't exist
cat MOFs_gcmc.csv | tail -n +2 | awk '{print $1}' | while read FrameworkName; do
    cp "$FrameworkName/$FrameworkName.cif_EQeq_ewald_1.20_-2.00.mol" "prepared_mofs/$FrameworkName.mol"
done

# Step 5: Copy CSV to prepared_mofs
cp MOFs_gcmc.csv prepared_mofs/
echo "All energy minimization and charge calculation are finished."

# Final cleanup
rm -f "$progress_file" "$progress_file.lock"


# Modifing the simulation.input. Env: ADTL/LINUX
topdir=$PWD
cd prepared_mofs
N_samp=$(wc -l < MOFs_gcmc.csv) 

sed -i 's/\r$//' MOFs_gcmc.csv
for ((i=1; i<N_samp; i++))
do
    Row=$((i + 1))
    read FrameworkName <<< $(awk 'FNR=='$Row' {print $1}' MOFs_gcmc.csv)
    
    if [ -d "$FrameworkName" ]; then
        rm -r $FrameworkName 2>/dev/null || true
    fi
    
    # Checking if the mol file exists
    if [[ ! -f "$FrameworkName.mol" ]]; then
        echo "Warning: File $FrameworkName.mol does not exist. Skipping..."
        continue
    fi
    
    mkdir -p $FrameworkName
    cp "$FrameworkName.mol" "$FrameworkName/"
    cp "${topdir}/simulation.input" "$FrameworkName/"
    
    cd $FrameworkName
    
    sed -i 's/INDEX/'${FrameworkName}'/' simulation.input
    
    echo "Updated simulation.input with framework name: $FrameworkName"

    # Initialize variables
    ia=0
    ib=0
    ic=0
    
    # Optimize the crystal size
    while IFS=' ' read -r line
    do
        if [[ $line == "Fundcell_Info: Listed" ]]; then
            read -r ia ib ic
            break
        fi
    done < "$FrameworkName.mol"

    if [ `echo $ia | awk -v bi=30 '{print($1>bi)?"1":"0"}'` -eq "1" ]
     then
     ja=1
    elif [ `echo $ia | awk -v bi=3 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=15
    elif [ `echo $ia | awk -v bi=4 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=12
    elif [ `echo $ia | awk -v bi=5 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=8
    elif [ `echo $ia | awk -v bi=8 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=6
    elif [ `echo $ia | awk -v bi=10 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=4
    elif [ `echo $ia | awk -v bi=15 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=3
    else
     ja=2
    fi

    if [ `echo $ib | awk -v bi=30 '{print($1>bi)?"1":"0"}'` -eq "1" ]
     then
     jb=1
    elif [ `echo $ib | awk -v bi=3 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=15
    elif [ `echo $ib | awk -v bi=4 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=12
    elif [ `echo $ib | awk -v bi=5 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=8
    elif [ `echo $ib | awk -v bi=8 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=6
    elif [ `echo $ib | awk -v bi=10 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=4
    elif [ `echo $ib | awk -v bi=15 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=3
    else
     jb=2
    fi

    if [ `echo $ic | awk -v bi=30 '{print($1>bi)?"1":"0"}'` -eq "1" ]
     then
     jc=1
    elif [ `echo $ic | awk -v bi=3 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=15
    elif [ `echo $ic | awk -v bi=4 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=12
    elif [ `echo $ic | awk -v bi=5 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=8
    elif [ `echo $ic | awk -v bi=8 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=6
    elif [ `echo $ic | awk -v bi=10 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=4
    elif [ `echo $ic | awk -v bi=15 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=3
    else
     jc=2
    fi

    sed -i -e 's/UnitCells\ 1\ 1\ 1/UnitCells\ '$ja'\ '$jb'\ '$jc'/g' simulation.input

    cd ..

done
echo "All simulation files are ready."


# Running GCMC. Env: ADTL/LINUX/prepared_mofs
csvfile="MOFs_gcmc.csv"

echo "Validating .mol files..."
mapfile -t all_mofs < <(tail -n +2 "$csvfile" | awk '{print $1}')

valid_mofs=()
for name in "${all_mofs[@]}"; do
    if [[ -f "$name/$name.mol" ]]; then
        valid_mofs+=("$name")
    else
        echo "Warning: File $name.mol does not exist. Skipping..."
    fi
done

# Initialize progress tracking
echo 0 > .gcmc_progress
rm -f .gcmc_progress.lock
echo "${#valid_mofs[@]}" > .gcmc_total

# concurrent execution
chmod 755 ../../Adsorption_simulation.sh   # grant execute permission

echo "Launching GCMC simulations..."

printf "%s\n" "${valid_mofs[@]}" \
  | parallel --line-buffer -j "${MAX_JOBS:-1}" ../../Adsorption_simulation.sh {}

# Final output
echo
echo "All GCMC simulations completed successfully."
echo "Final Progress: $(< .gcmc_progress) / $(< .gcmc_total)"


# Extracting adsorption data. Env: ADTL/LINUX/prepared_mofs
topdir=$PWD
N_samp=$(wc -l < MOFs_gcmc.csv) 

sed -i 's/\r$//' MOFs_gcmc.csv
for ((i=1; i<N_samp; i++))
do
    Row=$((i + 1))
    read FrameworkName <<< $(awk 'FNR=='$Row' {print $1}' MOFs_gcmc.csv)
    
    if [ ! -d $FrameworkName/Output/System_0/ ]; then
        echo " $FrameworkName have not been successfully calculated, skipping..."
        continue
    fi

    cd $FrameworkName/Output/System_0/
    echo $FrameworkName >> ${topdir}/$FrameworkName/N.txt
    cat *.data | grep "Average loading absolute" | grep "mol\/kg\ framework" >> ${topdir}/$FrameworkName/N.txt
    

    cd ../../../../.. # Env: ADTL
    cp "${topdir}/$FrameworkName/N.txt" "TL/"
    
    # Calculate TSN. Env: ADTL
    cd TL
    python3 TSN_cal.py
    rm N.txt
    cd ..
    cd LINUX/prepared_mofs
    
done
cd ../..

}



part3(){
# Running TL. Env: ADTL
topdir=$PWD
cd TL
python3 Transferlearning_finetune.py


# Getting the TSN top 20% MOFs. Env: ADTL/TL
if [[ -d "MOF_verify" ]]; then
    echo "Directory MOF_verify exists. Removing it..."
    rm -rf MOF_verify
fi

mkdir MOF_verify
cp "MOF_verify_model.csv" "MOF_verify/"

cd ..

cp "gcmc_selected_mofs/lammps_input.in" "TL/MOF_verify/"
cp "gcmc_selected_mofs/DatatoCif.py" "TL/MOF_verify/"

cd TL/MOF_verify
N_samp=$(wc -l < MOF_verify_model.csv) 

sed -i 's/\r$//' MOF_verify_model.csv
for ((i=1; i<N_samp; i++))
do
    Row=$((i + 1))
    read FrameworkName <<< $(awk 'FNR=='$Row' {print $1}' MOF_verify_model.csv)
    cp "${topdir}/gcmc_rest_mofs/$FrameworkName.cif" "${topdir}/TL/MOF_verify/"
done

cd ../..
scp -r TL/MOF_verify LINUX


# Energy minimization (verified MOFs). Env: ADTL
topdir=$PWD
cd LINUX/MOF_verify
MAX_JOBS=$MAX_JOBS
csv_file="MOF_verify_model.csv"

# Remove Windows-style carriage returns
sed -i 's/\r$//' "$csv_file"
N_samp=$(wc -l < "$csv_file")

# Clean previous run
echo "Cleaning previous verification folders..."
cat "$csv_file" | tail -n +2 | awk '{print $1}' | while read FrameworkName; do
    rm -rf "$FrameworkName"
    rm -f "../$FrameworkName.cif"
done

# Prepare progress tracker
progress_file=".verify_progress"
echo 0 > $progress_file
rm -f "$progress_file.lock"

# Run energy minimization in parallel
cat "$csv_file" | tail -n +2 | awk '{print $1}' | parallel -j "${MAX_JOBS:-1}" ../../Energy_minimization_verify.sh {}

# Final message
echo -e "All MOF verifications completed!"
rm -f "$progress_file" "$progress_file.lock"


# EQeq charge assignment for verified MOFs. Env: ADTL/LINUX/MOF_verify
MAX_JOBS=$MAX_JOBS
csv_file="MOF_verify_model.csv"

# Preprocess CSV
sed -i 's/\r$//' "$csv_file"
N_samp=$(wc -l < "$csv_file")

# Copy csv to LINUX (if needed)
cp "$csv_file" ../MOF_verify_model.csv
cd ../
cd LINUX

# Create progress tracker
progress_file=".verify_charge_progress"
echo 0 > "$progress_file"
rm -f "$progress_file.lock"

# Step 1: Clean up old folders
echo "Cleaning EQeq temporary folders..."
cat MOF_verify_model.csv | tail -n +2 | awk '{print $1}' | while read FrameworkName; do
    rm -rf "$FrameworkName"
done

# Run EQeq using parallel
cat MOF_verify_model.csv | tail -n +2 | awk '{print $1}' | parallel -j "${MAX_JOBS:-1}" ../EQeq_calculation.sh {}

echo -e "All verified MOF charges calculated!"
rm -f "$progress_file" "$progress_file.lock"

# Extract mol files
echo "Extracting EQeq .mol files..."
mkdir -p prepared_mofs   # Create if it doesn't exist
cat MOF_verify_model.csv | tail -n +2 | awk '{print $1}' | while read FrameworkName; do
    mv "$FrameworkName/$FrameworkName.cif_EQeq_ewald_1.20_-2.00.mol" "prepared_mofs/$FrameworkName.mol"
done

cp MOF_verify_model.csv prepared_mofs/
echo "All EQeq mol files extracted."


# Modifing the simulation.input. Env: ADTL/LINUX
topdir=$PWD
cd prepared_mofs
N_samp=$(wc -l < MOF_verify_model.csv) 

sed -i 's/\r$//' MOF_verify_model.csv
for ((i=1; i<N_samp; i++))
do
    Row=$((i + 1))
    read FrameworkName <<< $(awk 'FNR=='$Row' {print $1}' MOF_verify_model.csv)
    
    if [ -d "$FrameworkName" ]; then
        rm -r $FrameworkName 2>/dev/null || true
    fi
    
    # Checking if the mol file exists
    if [[ ! -f "$FrameworkName.mol" ]]; then
        echo "Warning: File $FrameworkName.mol does not exist. Skipping..."
        continue
    fi
    
    mkdir -p $FrameworkName
    cp "$FrameworkName.mol" "$FrameworkName/"
    cp "${topdir}/simulation.input" "$FrameworkName/"
    
    cd $FrameworkName
    
    sed -i 's/INDEX/'${FrameworkName}'/' simulation.input
    
    echo "Updated simulation.input with framework name: $FrameworkName"
    
    # Initialize variables
    ia=0
    ib=0
    ic=0
    
    # Optimizing the crystal size
    while IFS=' ' read -r line
    do
        if [[ $line == "Fundcell_Info: Listed" ]]; then
            read -r ia ib ic
            break
        fi
    done < "$FrameworkName.mol"

    if [ `echo $ia | awk -v bi=30 '{print($1>bi)?"1":"0"}'` -eq "1" ]
     then
     ja=1
    elif [ `echo $ia | awk -v bi=3 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=15
    elif [ `echo $ia | awk -v bi=4 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=12
    elif [ `echo $ia | awk -v bi=5 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=8
    elif [ `echo $ia | awk -v bi=8 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=6
    elif [ `echo $ia | awk -v bi=10 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=4
    elif [ `echo $ia | awk -v bi=15 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     ja=3
    else
     ja=2
    fi

    if [ `echo $ib | awk -v bi=30 '{print($1>bi)?"1":"0"}'` -eq "1" ]
     then
     jb=1
    elif [ `echo $ib | awk -v bi=3 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=15
    elif [ `echo $ib | awk -v bi=4 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=12
    elif [ `echo $ib | awk -v bi=5 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=8
    elif [ `echo $ib | awk -v bi=8 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=6
    elif [ `echo $ib | awk -v bi=10 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=4
    elif [ `echo $ib | awk -v bi=15 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jb=3
    else
     jb=2
    fi

    if [ `echo $ic | awk -v bi=30 '{print($1>bi)?"1":"0"}'` -eq "1" ]
     then
     jc=1
    elif [ `echo $ic | awk -v bi=3 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=15
    elif [ `echo $ic | awk -v bi=4 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=12
    elif [ `echo $ic | awk -v bi=5 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=8
    elif [ `echo $ic | awk -v bi=8 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=6
    elif [ `echo $ic | awk -v bi=10 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=4
    elif [ `echo $ic | awk -v bi=15 '{print($1<bi)?"1":"0"}'` -eq "1" ]
     then 
     jc=3
    else
     jc=2
    fi

    sed -i -e 's/UnitCells\ 1\ 1\ 1/UnitCells\ '$ja'\ '$jb'\ '$jc'/g' simulation.input
    
    cd ..

done
echo "All simulation files are ready."


# Running GCMC. Env: ADTL/LINUX/prepared_mofs
csvfile="MOFs_gcmc.csv"

echo "Validating .mol files..."
mapfile -t all_mofs < <(tail -n +2 "$csvfile" | awk '{print $1}')

valid_mofs=()
for name in "${all_mofs[@]}"; do
    if [[ -f "$name/$name.mol" ]]; then
        valid_mofs+=("$name")
    else
        echo "Warning: File $name.mol does not exist. Skipping..."
    fi
done

# Initialize progress tracking
echo 0 > .gcmc_progress
rm -f .gcmc_progress.lock
echo "${#valid_mofs[@]}" > .gcmc_total

# concurrent execution
chmod 755 ../../Adsorption_simulation.sh   # grant execute permission

echo "Launching GCMC simulations..."

printf "%s\n" "${valid_mofs[@]}" \
  | parallel --line-buffer -j "${MAX_JOBS:-1}" ../../Adsorption_simulation.sh {}

# Final output
echo
echo "All GCMC simulations completed successfully."
echo "Final Progress: $(< .gcmc_progress) / $(< .gcmc_total)"


# Extracting adsorption data. Env: ADTL/LINUX/prepared_mofs
topdir=$PWD
N_samp=$(wc -l < MOF_verify_model.csv) 

sed -i 's/\r$//' MOF_verify_model.csv
for ((i=1; i<N_samp; i++))
do
    Row=$((i + 1))
    read FrameworkName <<< $(awk 'FNR=='$Row' {print $1}' MOF_verify_model.csv)
    
    if [ ! -d $FrameworkName/Output/System_0/ ]; then
        echo " $FrameworkName have not successfully calculated, skipping..."
        continue
    fi
    
    cd $FrameworkName/Output/System_0/
    echo $FrameworkName >> ${topdir}/$FrameworkName/N.txt
    cat *.data | grep "Average loading absolute" | grep "mol\/kg\ framework" >> ${topdir}/$FrameworkName/N.txt
    
    cd ../../../../..
    cp -r ${topdir}/$FrameworkName/N.txt TL
    
    # calculate TSN. Env: ADTL
    cd TL
    python3 TSN_cal_verify.py
    rm N.txt
    cd ..
    cd LINUX/prepared_mofs
done
cd ../..
return 0
}



# Main script. Env: ADTL
# Function to modify the train-test split rate
current_dir=$(dirname "$(readlink -f "$0")")
source "$current_dir/required_path.sh"

modify_train_test_split() {
      local new_rate=$1
      sed -i "s|train_test=.*|train_test=$new_rate|" MOF_design_part2.py
}


# Move required files to RASPA. Env: ADTL
cd LINUX/gcmc_required/

scp -r COREMOF_eqeq ${RASPA_DIR}/share/raspa/forcefield/
scp -r C2.def ${RASPA_DIR}/share/raspa/molecules/TraPPE/
scp -r C3.def ${RASPA_DIR}/share/raspa/molecules/TraPPE/
scp -r CH4.def ${RASPA_DIR}/share/raspa/molecules/TraPPE/
scp -r CO2.def ${RASPA_DIR}/share/raspa/molecules/TraPPE/
scp -r H2S_qiao.def ${RASPA_DIR}/share/raspa/molecules/TraPPE/

cd ../..


# Initial train-test split rate
new_cycle_number_mof=2
new_cycle_number_linker=1

echo '{"counter": 1}' > TL/counter.json

sed -i 's/train_test=.*/train_test=0.1/' MOF_design_part2.py
sed -i 's/cycle_number=.*/cycle_number=1/' MOFs_summary.py
sed -i 's/cycle_number=.*/cycle_number=0/' Linkers_summary.py

rm -rf Linker_summary/*
rm -rf New_MOF_summary/*


while true; do
    start_time=$(date +%s.%N)
    
    # Running part1 to get some new MOFs. Env: ADTL
    part1
    python3 MOFs_summary.py
    python3 Linkers_summary.py

    # Modify the parameter to optimize the model
    sed -i "s|cycle_number=.*|cycle_number=$new_cycle_number_mof|" MOFs_summary.py
    sed -i "s|cycle_number=.*|cycle_number=$new_cycle_number_linker|" Linkers_summary.py
    
    new_cycle_number_mof=$(echo "$new_cycle_number_mof + 1" | bc)
    new_cycle_number_linker=$(echo "$new_cycle_number_linker + 1" | bc)
    
    # Running part2, getting the status code, and judging if the model is accuracy. Env: ADTL
    part2
    
    # Checking the R2 of the original DNN. Env: ADTL
    cd TL
    python3 calculate_R2_original_DNN.py
    status_0=$?
    cd ..

    if [ $status_0 -eq 0 ]; then # Env:ADTL
        echo "Original model accuracy meets the requirement, can be used directly."
        
        cd TL
        python3 Transferlearning_originaldnn.py
        
        # Judging if the max TSN will bigger than the maximum of last batch of MOFs
        python3 Data_summize.py
        status_2=$?
        cd ..
        
        # If so, choose the TSN top 20% MOFs, and take the name of their linkers from their name, and copy these linkers from best_edges_mol to optimal_linker
        if [ $status_2 -eq 0 ]; then
            echo "Performance has improved after retraining. Restarting the loop..."
            cd ..
            end_time=$(date +%s.%N)
            elapsed_time=$(echo "$end_time - $start_time" | bc)
            printf "Elapsed time for this round: %.2f seconds\n" "$elapsed_time"
            bash "$0"
            exit

     
        # If not, stop the loop
        elif [ $status_2 -eq 1 ]; then
            echo "Performance has not improved after retraining. Stopping the loop."
            end_time=$(date +%s.%N)
            elapsed_time=$(echo "$end_time - $start_time" | bc)
            printf "Elapsed time for this round: %.2f seconds\n" "$elapsed_time"
            break
        
        else
            echo "Program error."
            exit 1
        fi
          
    elif [ $status_0 -eq 1 ]; then # Env:ADTL
        echo "Original model accuracy doesn't meet the requirements, should be fine-tuned."
        part3
        
        # Calculating R2. Env: ADTL
        cd TL
        python3 calculate_R2.py
        status_1=$?
        cd ..
    
        if [ $status_1 -eq 0 ]; then
            echo "Model accuracy meets the requirement."
        
            # Judging if the max TSN will bigger than the maximum of last batch of MOFs
            cd TL
            python3 Data_summize.py
            status_2=$?
            cd ..
            
            # If so, choose the TSN top 20% MOFs, and take the name of their linkers from their name, and copy these linkers from best_edges_mol to optimal_linker
            if [ $status_2 -eq 0 ]; then
                echo "Performance has improved after retraining. Restarting the loop..."
                end_time=$(date +%s.%N)
                elapsed_time=$(echo "$end_time - $start_time" | bc)
                printf "Elapsed time for this round: %.2f seconds\n" "$elapsed_time"
                bash "$0"
                exit
        
            # If not, stop the loop
            elif [ $status_2 -eq 1 ]; then
                echo "Performance has not improved after retraining. Stopping the loop."
                end_time=$(date +%s.%N)
                elapsed_time=$(echo "$end_time - $start_time" | bc)
                printf "Elapsed time for this round: %.2f seconds\n" "$elapsed_time"
                break
                
            else:
                echo "Program error."
                exit 1 
            fi
        
        elif [ $status_1 -eq 1 ]; then
            echo "Model accuracy doesn't meet the requirements. Optimizing the model..."
            
            # Initial train-test split rate
            current_rate=0.1
            new_rate=0.2
    
            # Modify the parameter to optimize the model
            modify_train_test_split $new_rate
            
            # Running the loop again to make sure the accuracy of the model meets the requirement.
            while true; do
                
                # Running part2 again to make sure
                part2
                                
                # Checking the R2 of the original DNN. Env: ADTL
                cd TL
                python3 calculate_R2_original_DNN.py
                status_0=$?
                cd ..
            
                if [ $status_0 -eq 0 ]; then # Env:ADTL
                    echo "Original model accuracy meets the requirement, can be used directly."
                    
                    cd TL
                    python3 Transferlearning_originaldnn.py
                    
                    # Judging if the max TSN will bigger than the maximum of last batch of MOFs
                    python3 Data_summize.py
                    status_2=$?
                    cd ..
                    
                    # If so, choose the TSN top 20% MOFs, and take the name of their linkers from their name, and copy these linkers from best_edges_mol to optimal_linker
                    if [ $status_2 -eq 0 ]; then
                        echo "Performance has improved after retraining. Restarting the loop..."
                        end_time=$(date +%s.%N)
                        elapsed_time=$(echo "$end_time - $start_time" | bc)
                        printf "Elapsed time for this round: %.2f seconds\n" "$elapsed_time"
                        bash "$0"
                        exit
                 
                    # If not, stop the loop
                    elif [ $status_2 -eq 1 ]; then
                        echo "Performance has not improved after retraining. Stopping the loop."
                        end_time=$(date +%s.%N)
                        elapsed_time=$(echo "$end_time - $start_time" | bc)
                        printf "Elapsed time for this round: %.2f seconds\n" "$elapsed_time"
                        break
                    
                    else:
                        echo "Program error."
                        exit 1
                        
                    fi
                      
                elif [ $status_0 -eq 1 ]; then # Env:ADTL
                    echo "Original model accuracy doesn't meet the requirements, should be fine-tuned"
                    part3
                    
                    # Calculating R2. Env: ADTL
                    cd TL
                    python3 calculate_R2.py
                    status_1=$?
                    cd ..
                
                    if [ $status_1 -eq 0 ]; then
                        echo "Model accuracy meets the requirement."
                    
                        # Judging if the max TSN will bigger than the maximum of last batch of MOFs
                        cd TL
                        python3 Data_summize.py
                        status_2=$?
                        cd ..
                        
                        # If so, choose the TSN top 20% MOFs, and take the name of their linkers from their name, and copy these linkers from best_edges_mol to optimal_linker
                        if [ $status_2 -eq 0 ]; then
                            echo "Performance has improved after retraining. Restarting the loop..."
                            end_time=$(date +%s.%N)
                            elapsed_time=$(echo "$end_time - $start_time" | bc)
                            printf "Elapsed time for this round: %.2f seconds\n" "$elapsed_time"
                            bash "$0"
                            exit

                        # If not, stop the loop
                        elif [ $status_2 -eq 1 ]; then
                            echo "Performance has not improved after retraining. Stopping the loop."
                            end_time=$(date +%s.%N)
                            elapsed_time=$(echo "$end_time - $start_time" | bc)
                            printf "Elapsed time for this round: %.2f seconds\n" "$elapsed_time"
                            break
                            
                        else:
                            echo "Program error."
                            exit 1
                        
                        fi
                    
                    elif [ $status_1 -eq 1 ]; then
                        echo "Model accuracy doesn't meet the requirements. Optimizing the model..."
                                    
                        # Modify the train-test split rate further if needed
                        current_rate=$new_rate
                        new_rate=$(echo "$new_rate + 0.1" | bc)
                        
                        if (( $(echo "$new_rate > 0.4" | bc -l) )); then
                            echo "Train-test split rate has exceeded 0.4, and the accuracy of model predictions cannot be guaranteed. Stopping the loop."
                            end_time=$(date +%s.%N)
                            elapsed_time=$(echo "$end_time - $start_time" | bc)
                            printf "Elapsed time for this round: %.2f seconds\n" "$elapsed_time"
                            break
                        fi

                        modify_train_test_split $new_rate
                        
                    else:
                        echo "Program error."
                        exit 1
                    fi
                    
                else:
                    echo "Program error."
                    exit 1
                fi
                
            done
            
        else:
            echo "Program error."
            exit 1 
        fi
        
    else:
        echo "Program error."
        exit 1
    fi
    
done

echo "The script ends."

sed -i 's/cycle_number=.*/cycle_number="final"/g' Linkers_summary.py
sed -i 's/cycle_number=.*/cycle_number="final"/g' MOFs_summary.py
python3 MOFs_summary.py
python3 Linkers_summary.py

cd TL
python3 Data_output.py

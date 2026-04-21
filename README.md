# Iterative Construction of Crystal Adsorbent (ICoCA)
*Iterative Evolutionary Design of High-Performance Crystalline Porous Frameworks via Material Fingerprints and Transfer Learning*

<p align="center">
  <img src="ICoCA_Process.png" width="800" alt="ICoCA Process">
</p>


This repository contains the transfer learning model and the iterative evolutionary design submission script codes for hypothetical CPFs, along with the corresponding datasets described in our paper.

## Table of Contents
- [Project Description](#project-description)
- [Project Organization](#project-organization)
- [Requirements](#requirements)
- [Usage](#usage)
- [Expected Results](#expected-results)
- [References](#references)
- [Credits](#credits)
- [Citation](#citation)

## Project Description
This project focuses on the automated design of high-performance CPFs (Crystalline Porous Frameworks) through material fingerprints and transfer learning. The repository includes code for running transfer learning models, automating the CPF design process, and managing related datasets. This project aims to accelerate the discovery and optimization of hypothetical CPFs by predicting performance and facilitating efficient molecular simulation workflows.

## Project Organization

```plaintext
├── README.md                # Top-level README for developers using this project.
├── main_auto.sh                       # Main execution script
├── required_path.sh                       # Paths and concurrency settings
├── __pycache__/           # Python cache files
├── all_nodes/             # All nodes data
├── all_topologies/          # All topologies data
├── best_edges_cif/        # Selected substructure CIF files
├── best_edges_mol/        # Selected substructure MOL files
├── best_edges_png/        # Selected substructure PNG image files
├── gcmc_rest_structures/        # Structures not requiring GCMC simulations
├── gcmc_selected_structures/    # Folder of structures selected for GCMC simulations
│   ├── DatatoCif.py             # Convert LAMMPS output .DATA files to .CIF
│   ├── lammps_input.in          # Energy minimization of CPFs
│   └── Structures_gcmc.csv         # CPFs for GCMC simulations
├── Linker_summary/        # Linker summaries
├── LINUX/                # Linux environment files
│   ├── EQeq/          # Charged mol files required for RASPA calculations
│   ├── gcmc_required/             # Required files for running RASPA, including forcefield and molecular model files
│   ├── prepared_structures/                      # Structure files ready for RASPA MC simulation
│   ├── Structures_gcmc.csv         # CPFs for MC simulation
│   └── simulation.input         # Input script for running RASPA
├── new_designed_structures/     # All newly designed CPFs
│   └── All_designed_structures.xlsx           # All newly designed CPFs, including unit cell sizes, the one-hot encoding of their metal centers and topology structures, MACCS fingerprints  of organic linkers (255-bit encoding), and performance predictions from the pre-trained deep neural network model
├── New_structure_summary/       # Summaries of new CPFs
├── optimal_linker/        # Optimal linkers
├── TL/    # Containing files related to transfer learning data
│   ├── __pycache__/           # Python cache files
│   ├── Structure_verify/           # CPFs used for verifying DNN model performance
│   │   ├── DatatoCif.py             # Convert LAMMPS output .DATA files to .CIF files
│   │   ├── lammps_input.in          # LAMMPS script for energy minimization of CPFs
│   │   └── Structures_verify_model.csv         # CPFs for MC simulation to verify DNN model
│   ├── calculate_R2.py           # Calculate R2 of CPF performance predicted by fine-tuned pre-trained DNN model
│   ├── calculate_R2_original_DNN.py           # Calculate R2 of CPF performance predicted by the original pre-trained DNN model
│   ├── counter.json           # JSON file used to record the current loop count
│   ├── Data_output.py           # Generating the Output.png
│   ├── Data_summarize.py           # Summarizing the data into final_data.xlsx at the end of each loop
│   ├── final_data.xlsx           # Summary of structure encodings (255-bit) and performance of all batches of CPFs after program completion
│   ├── Pretrained_model.ckpt           # Pre-trained DNN model
│   ├── scaler_pretrained.pkl           # Pre-fitted feature scaler (StandardScaler) obtained from the training dataset; used to normalize new input features before inference
│   ├── Structure_verify_model.xlsx           # CPFs used for verifying the DNN model
│   ├── Output.png           # Summary graph of the program"s final results, including the average performance, highest performance, and total number of CPFs in each batch
│   ├── TL_data_target_task_test.xlsx           # CPFs used to validate the fine-tuned DNN model
│   ├── TL_data_target_task_train.xlsx           # CPFs used to fine-tune the pre-trained DNN model
│   ├── Transferlearning_finetune.py           # Fine-tuning the original pre-trained DNN model with some new CPFs, followed by transfer learning on the remaining CPFs
│   ├── Transferlearning_originaldnn.py           # Performing transfer learning using the original pre-trained DNN model to predict the performance of the remaining CPFs
│   ├── TSN_cal.py           # Calculating CPF performance based on MC simulation data, and output adsorption capacity, selectivity as well as TSN value
│   └── TSN_cal_verify.py           # Calculating CPF performance based on MC simulation data, used to verify the DNN model
├── tobacco_1.0/    # Tobacco files
├── 500000.sdf                  # Large substructure database
├── Adsorption_simulation.sh                       # GCMC simulation for gas adsorption
├── colourMol.py                # Coloring PNG image files
├── DefineXAtoms.py             # Defining X atoms
├── Encode_structures.py               # Encoding structures
├── Energy_minimization.sh                       # Geometry optimization for CPF structures
├── Energy_minimization_verify.sh                       # Optimization for verification CPFs only
├── EQeq_calculation.sh                       # EQeq-based partial charge assignment
├── error_list_energy_mini.txt           # CPFs that failed during energy minimization
├── error_list_eqeq.txt         # CPFs that failed during charge calculation (EQeq)
├── error_list_obtain_data.txt         # CPFs that failed to generate DATA file via lammps-interface
├── Linkers_summary.py          # Summarizing the selected linkers in each cycle
├── Structure_design_part1.py         # Part 1 of CPF design
├── Structure_design_part2.py         # Part 2 of CPF design
├── Structures_summary.py             # Summarizing synthesized CPFs in each cycle
├── mol_with_atom_index.py      # processing MOL files with atom index
├── MolFormatConversion.py      # Converting CPF file formats
├── MoltoCif.py                 # Converting MOL files to CIF files
├── netcode.py                  # Encoding nodes and topology structures
├── OptimalFingerprint.py       # Selecting the optimal molecular fingerprint
└── ScreenLinkers.py            # Screening linkers
```

## Requirements
1. Python 3.7+
2. Linux environment (Note: This program has only been tested on `Red Hat Enterprise Linux 9.6 (Plow)`.)
3. Packages: `RDKit`, `torch`, `scikit-learn`, `openpyxl`, `pytorch-ignite`, `ase` and `openmpi`, `pymatgen`, `paramiko`, `LAMMPS-interface`.
4. LAMMPS with `MOLECULE` and `EXTRA-MOLECULE` packages enabled. [https://www.lammps.org/#gsc.tab=0]
5. RASPA (Ensure that the required molecular definition files (.def) and force field files are located in `/LINUX/gcmc_required`, while the RASPA input files (`simulation.input`) are located in `/LINUX`.) [https://iraspa.org/raspa/]
6. GNU parallel. [http://ftpmirror.gnu.org/parallel/]
7. To ensure all dependencies (including ToBaCCo 1.0) are properly retrieved, the repository should be cloned with submodules:  
   `git clone --recurse-submodules https://github.com/ChengzhiTsoi/ICoCA_1.0.git`  
   If the repository has already been cloned, run:  
   `git submodule update --init --recursive`  
   Note:  
   The ToBaCCo 1.0 module is included as a submodule and will not be downloaded by default unless the commands above are used.  

## Usage
1. Set paths in `required_path.sh`:
   - `LAMMPS_DIR` → path to LAMMPS (`lmp` in `build/`)
   - `RASPA_DIR` → RASPA installation root
   - Number of concurrent tasks

2. Prepare input files:
   - Place linker (**.mol**) files in `/optimal_linker`
   - Copy node/topology files from `/all_nodes` (predefined node set) and `/all_topologies` to `/tobacco_1.0/nodes_bb` and `/tobacco_1.0/templates`
   - Add computed CPF performance data into `TL/final_data.xlsx` (sheet name: `Cycle 0`)  
     Format: **CPF name → MACCS fingerprint (167 bits) → node one-hot encoding (44 bits) → topology one-hot encoding (41 bits) → crystal size (3 bits) → CPF performance**
   - Place pre-trained model `Pretrained_model.ckpt` into `/TL`
   - Extract the `SDF.zip` file and place the `500000.sdf` file from the extracted folder in the same directory as `main_auto.sh`.

3. Run in terminal:
   ```bash
   conda activate ${YOUR_ENV_NAME}
   chmod +x main_auto.sh
   nohup sh main_auto.sh > output.log 2>&1 &

## Expected Results
1. Final performance summary: `TL/final_data.xlsx`
2. Performance graph: `TL/Output.png`
3. Generated CPFs: `New_structure_summary/`
4. Linker summaries: `Linker_summary/`

## References
[LAMMPS for energy minimization] A. P. Thompson, H. M. Aktulga, R. Berger, D. S. Bolintineanu, W. M. Brown, P. S. Crozier, P. J. in "t Veld, A. Kohlmeyer, S. G. Moore, T. D. Nguyen, R. Shan, M. J. Stevens, J. Tranchida, C. Trott, S. J. Plimpton, LAMMPS - a flexible simulation tool for particle-based materials modeling at the atomic, meso, and continuum scales, Comp. Phys. Comm., 271, 10817 (2022). [https://doi.org/10.1016/j.cpc.2021.108171]

[LAMMPS-interface for generating LAMMPS files] P. G. Boyd, S. M. Moosavi, M. Witman & B. Smit, Force-Field Prediction of Materials Properties in Metal-Organic Frameworks. J. Phys. Chem. Lett. 8, 357-363 (2017). [https://dx.doi.org/10.1021/acs.jpclett.6b02532]

[RASPA for calculating CPFs' adsorption performance] D. Dubbeldam, S. Calero, D.E. Ellis, and R.Q. Snurr, RASPA: Molecular Simulation Software for Adsorption and Diffusion in Flexible Nanoporous Materials, Mol. Simulat., 42(2), 81-101 (2015). [http://dx.doi.org/10.1080/08927022.2015.1010082]

[ToBaCCo_1.0 for CPFs synthesis] Y. J. Colón, D. A. Gómez-Gualdrón, R. Q. Snurr, Topologically guided, automated construction of metal–organic frameworks and their evaluation for energy-related applications, Cryst. Growth Des. 17, 5801-5810 (2017). [https://doi.org/10.1021/acs.cgd.7b00848]

[EQeq for charge equilibration] C. E. Wilmer, K. C. Kim, R. Q. Snurr, An Extended Charge Equilibration Method, J. Phys. Chem. Lett., 3(17), 2506-2511 (2012). [http://doi.org/10.1021/jz3008485]

[RDKit] RDKit: Open-source cheminformatics. (https://www.rdkit.org). [https://doi.org/10.5281/zenodo.591637]

## Credits
This work is supported by:
- Guangzhou University
- University of Notre Dame
- Center for Research Computing at the University of Notre Dame
- Guangzhou Key Laboratory New Energy and Green Catalysis
- Joint Institute of Guangzhou University & Institute of Corrosion Science and Technology

Special thanks to the project collaborators for their contributions and insights.

## Citation

If you use this code or dataset in your research, please cite the following publication:




















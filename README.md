# Iterative Construction of Crystal Adsorbent (ICoCA)
*Automated Circular Design of High-Performance MOFs*

<p align="center">
  <img src="ICoCA_Process.png" width="800" alt="ICoCA Process">
</p>


This repository contains the transfer learning model and the automated design submission script codes for hypothetical MOFs, along with the corresponding datasets described in our paper.

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
This project focuses on the automated design of high-performance MOFs (Metal-Organic Frameworks) through material fingerprints and transfer learning. The repository includes code for running transfer learning models, automating the MOF design process, and managing related datasets. This project aims to accelerate the discovery and optimization of hypothetical MOFs by predicting performance and facilitating efficient molecular simulation workflows.

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
├── gcmc_rest_mofs/        # MOFs not requiring GCMC simulations
├── gcmc_selected_mofs/    # Folder of MOFs selected for GCMC simulations
│   ├── DatatoCif.py             # Convert LAMMPS output .DATA files to .CIF
│   ├── lammps_input.in          # Energy minimization of MOFs
│   └── MOFs_gcmc.csv         # MOFs for GCMC simulations
├── Linker_summary/        # Linker summaries
├── LINUX/                # Linux environment files
│   ├── EQeq/          # Charged mol files required for RASPA calculations
│   ├── gcmc_required/             # Required files for running RASPA, including forcefield and molecular model files
│   ├── prepared_mofs/                      # MOF files ready for RASPA MC simulation
│   ├── MOFs_gcmc.csv         # MOFs for MC simulation
│   └── simulation.input         # Input script for running RASPA
├── new_designed_mofs/     # All newly designed MOFs
│   └── All_designed_mofs.xlsx           # All newly designed MOFs, including unit cell sizes, the one-hot encoding of their metal centers and topology structures, MACCS fingerprints  of organic linkers (255-bit encoding), and performance predictions from the pre-trained deep neural network model
├── New_MOF_summary/       # Summaries of new MOFs
├── optimal_linker/        # Optimal linkers
├── TL/    # Containing files related to transfer learning data
│   ├── __pycache__/           # Python cache files
│   ├── MOF_verify/           # MOFs used for verifying DNN model performance
│   │   ├── DatatoCif.py             # Convert LAMMPS output .DATA files to .CIF files
│   │   ├── lammps_input.in          # LAMMPS script for energy minimization of MOFs
│   │   └── MOFs_verify_model.csv         # MOFs for MC simulation to verify DNN model
│   ├── calculate_R2.py           # Calculate R2 of MOF performance predicted by fine-tuned pre-trained DNN model
│   ├── calculate_R2_original_DNN.py           # Calculate R2 of MOF performance predicted by the original pre-trained DNN model
│   ├── counter.json           # JSON file used to record the current loop count
│   ├── Data_output.py           # Generating the Output.png
│   ├── Data_summaize.py           # Summarizing the data into final_data.xlsx at the end of each loop
│   ├── final_data.xlsx           # Summary of structure encodings (255-bit) and performance of all batches of MOFs after program completion
│   ├── Pretrained_model.ckpt           # Pre-trained DNN model
│   ├── MOF_verify_model.xlsx           # MOFs used for verifying the DNN model
│   ├── Output.png           # Summary graph of the program"s final results, including the average performance, highest performance, and total number of MOFs in each batch
│   ├── TL_data_target_task_test.xlsx           # MOFs used to validate the fine-tuned DNN model
│   ├── TL_data_target_task_train.xlsx           # MOFs used to fine-tune the pre-trained DNN model
│   ├── Transferlearning_finetune.py           # Fine-tuning the original pre-trained DNN model with some new MOFs, followed by transfer learning on the remaining MOFs
│   ├── Transferlearning_originaldnn.py           # Performing transfer learning using the original pre-trained DNN model to predict the performance of the remaining MOFs
│   ├── TSN_cal.py           # Calculating MOF performance based on MC simulation data, and output adsorption capacity, selectivity as well as TSN value
│   └── TSN_cal_verify.py           # Calculating MOF performance based on MC simulation data, used to verify the DNN model
├── tobacco_1.0/    # Tobacco files
├── 500000.sdf                  # Large substructure database
├── Adsorption_simulation.sh                       # GCMC simulation for gas adsorption
├── colourMol.py                # Coloring PNG image files
├── DefineXAtoms.py             # Defining X atoms
├── EncodeMOFs.py               # Encoding MOFs
├── Energy_minimization.sh                       # Geometry optimization for MOF structures
├── Energy_minimization_verify.sh                       # Optimization for verification MOFs only
├── EQeq_calculation.sh                       # EQeq-based partial charge assignment
├── error_list_energy_mini.txt           # MOFs that failed during energy minimization
├── error_list_eqeq.txt         # MOFs that failed during charge calculation (EQeq)
├── error_list_obtain_data.txt         # MOFs that failed to generate DATA file via lammps-interface
├── Linkers_summary.py          # Summarizing the selected linkers in each cycle
├── MOF_design_part1.py         # Part 1 of MOF design
├── MOF_design_part2.py         # Part 2 of MOF design
├── MOFs_summary.py             # Summarizing synthesized MOFs in each cycle
├── mol_with_atom_index.py      # processing MOL files with atom index
├── MolFormatConversion.py      # Converting MOF file formats
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

## Usage
1. Set paths in `required_path.sh`:
   - `LAMMPS_DIR` → path to LAMMPS (`lmp_mpi` in `src/`)
   - `RASPA_DIR` → RASPA installation root
   - Number of concurrent tasks

2. Prepare input files:
   - Place linker (**.mol**) files in `/optimal_linker`
   - Place node (**.cif**) files in `/all_nodes` and topologies (**.template**) in `/all_topologies`
   - Copy node/topology files into `/tobacco_1.0/nodes_bb` and `/tobacco_1.0/templates`
   - Add computed MOF performance data into `TL/final_data.xlsx` (sheet name: `Cycle 1`)  
     Format: **MOF name → MACCS fingerprint → node one-hot encoding → topology one-hot encoding → crystal size → MOF performance**
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
3. Generated MOFs: `New_MOF_summary/`
4. Linker summaries: `Linker_summary/`

## References
[LAMMPS for energy minimization] A. P. Thompson, H. M. Aktulga, R. Berger, D. S. Bolintineanu, W. M. Brown, P. S. Crozier, P. J. in "t Veld, A. Kohlmeyer, S. G. Moore, T. D. Nguyen, R. Shan, M. J. Stevens, J. Tranchida, C. Trott, S. J. Plimpton, LAMMPS - a flexible simulation tool for particle-based materials modeling at the atomic, meso, and continuum scales, Comp. Phys. Comm., 271, 10817 (2022). [https://doi.org/10.1016/j.cpc.2021.108171]

[LAMMPS-interface for generating LAMMPS files] P. G. Boyd, S. M. Moosavi, M. Witman & B. Smit, Force-Field Prediction of Materials Properties in Metal-Organic Frameworks. J. Phys. Chem. Lett. 8, 357-363 (2017). [https://dx.doi.org/10.1021/acs.jpclett.6b02532]

[RASPA for calculating MOFs' adsorption performance] D. Dubbeldam, S. Calero, D.E. Ellis, and R.Q. Snurr, RASPA: Molecular Simulation Software for Adsorption and Diffusion in Flexible Nanoporous Materials, Mol. Simulat., 42(2), 81-101 (2015). [http://dx.doi.org/10.1080/08927022.2015.1010082]

[ToBaCCo_1.0 for MOFs synthesis] Y. J. Colón, D. A. Gómez-Gualdrón, R. Q. Snurr, Topologically guided, automated construction of metal–organic frameworks and their evaluation for energy-related applications, Cryst. Growth Des. 17, 5801-5810 (2017). [https://doi.org/10.1021/acs.cgd.7b00848]

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


















# -*- coding: utf-8 -*-

import shutil
import os
from MoltoCif import MoltoCif
from ScreenLinkers import SL
from DefineXAtoms import DXA
from OptimalFingerprint import OF
from rdkit import Chem
import openpyxl


# Empting the folders
path1 = 'best_edges_cif'
path2 = 'best_edges_mol'
path3 = 'best_edges_png'
path4 = 'new_designed_structures'
for i in os.listdir(path1):
    os.remove(path1 + '/' + i)
for j in os.listdir(path2):
    os.remove(path2 + '/' + j)
for k in os.listdir(path3):
    os.remove(path3 + '/' + k)
for l in os.listdir(path4):
    os.remove(path4 + '/' + l)
    
path5 = 'tobacco_1.0/edges_bb'
path6 = 'tobacco_1.0/output_structures'
for m in os.listdir(path5):
    os.remove(path5 + '/' + m)
for n in os.listdir(path6):
    os.remove(path6 + '/' + n)


# 1. Obtaining optimal fingerprint
ol_folder = 'optimal_linker'
dirs = os.listdir(ol_folder)
mols = []
for file in dirs:
    try:
        linkername = ol_folder + '/' + file
        optlinker = Chem.MolFromMolFile(linkername)
        if optlinker:
            mols.append(optlinker)
    except OSError:
        continue
optimal_linker = OF(ol_folder)
print('The optimal fingerprint sequence has been obtained.')


# 2. Importing the data, screening out the substructures, and outputing the diagram file as well as mol file
sdf_name = "500000.sdf"
optimal_linker1 = optimal_linker
best_edges_png = 'best_edges_png'
best_edges_mol = 'best_edges_mol'
SL(optimal_linker1, sdf_name, best_edges_png, best_edges_mol)
print('The data has been read, mol file have been exported')


# 3. Turning MOL file into CIF file
path_mol = 'best_edges_mol'
path_cif = 'best_edges_cif'
for molfile in os.listdir(path_mol):
    if ".mol" not in molfile:
        pass
    else:
        MoltoCif(path_mol + '/' + molfile, path_cif + '/' + molfile.split('.')[0] + '.cif')   
print('Cif file has been obtained.')  


# 4. Defining X atoms
path_mol = 'best_edges_mol'
best_edges_png = 'best_edges_png'
best_edges_cif = 'best_edges_cif'
DXA(path_mol, best_edges_png, best_edges_cif)
print('Cif file has been processed.')


# 5. Transferring CIF file and running ToBaCCo
path_new_cif = 'best_edges_cif'
pathname_new_cif = os.listdir(path_new_cif)
for single_new_cif in pathname_new_cif:
    if 'best_mol' not in single_new_cif:
        pass
    else:
        old_path = path_new_cif + '/' + single_new_cif
        new_path = 'tobacco_1.0/edges_bb/' + single_new_cif
        shutil.copy(old_path, new_path)
print('Cif file has been transferred.')
os.system('cd tobacco_1.0 && python main_auto.py')
print('ToBaCCo has finished running')


# 6. Transferring new structures and doing geometry optimization of structures 
path_new_structure = 'tobacco_1.0/output_structures'
path_new_structure_1 = 'new_designed_structures'
for o in os.listdir(path_new_structure):
    if 'best_mol_' not in o:
        pass
    else:
        shutil.copy(path_new_structure + '/' + o, path_new_structure_1 + '/' + o)
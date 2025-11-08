# -*- coding: utf-8 -*-

from ase.io import read, write
import ase
import os

# A dictionary that defines elements and their relative atomic mass
element_masses = {
    1.008: 'H', 4.0026: 'He', 6.94: 'Li', 9.0122: 'Be', 10.81: 'B', 12.011: 'C', 
    14.007: 'N', 15.999: 'O', 18.998: 'F', 20.180: 'Ne', 22.990: 'Na', 24.305: 'Mg', 
    26.982: 'Al', 28.085: 'Si', 30.974: 'P', 32.06: 'S', 35.45: 'Cl', 39.948: 'Ar',
    39.098: 'K', 40.078: 'Ca', 44.956: 'Sc', 47.867: 'Ti', 50.942: 'V', 51.996: 'Cr', 
    54.938: 'Mn', 55.845: 'Fe', 58.933: 'Co', 58.693: 'Ni', 63.546: 'Cu', 65.38: 'Zn',
    69.723: 'Ga', 72.63: 'Ge', 74.922: 'As', 78.96: 'Se', 79.904: 'Br', 83.798: 'Kr',
    85.468: 'Rb', 87.62: 'Sr', 88.906: 'Y', 91.224: 'Zr', 92.906: 'Nb', 95.95: 'Mo',
    98.0: 'Tc', 101.07: 'Ru', 102.91: 'Rh', 106.42: 'Pd', 107.87: 'Ag', 112.41: 'Cd',
    114.82: 'In', 118.71: 'Sn', 121.76: 'Sb', 127.60: 'Te', 126.90: 'I', 131.29: 'Xe',
    132.91: 'Cs', 137.33: 'Ba', 138.91: 'La', 140.12: 'Ce', 140.91: 'Pr', 144.24: 'Nd',
    145.0: 'Pm', 150.36: 'Sm', 151.96: 'Eu', 157.25: 'Gd', 158.93: 'Tb', 162.50: 'Dy',
    164.93: 'Ho', 167.26: 'Er', 168.93: 'Tm', 173.05: 'Yb', 174.97: 'Lu', 178.49: 'Hf',
    180.95: 'Ta', 183.84: 'W', 186.21: 'Re', 190.23: 'Os', 192.22: 'Ir', 195.08: 'Pt',
    196.97: 'Au', 200.59: 'Hg', 204.38: 'Tl', 207.2: 'Pb', 208.98: 'Bi', 209.0: 'Po',
    210.0: 'At', 222.0: 'Rn', 223.0: 'Fr', 226.0: 'Ra', 227.0: 'Ac', 232.04: 'Th',
    231.04: 'Pa', 238.03: 'U', 237.0: 'Np', 244.0: 'Pu', 243.0: 'Am', 247.0: 'Cm',
    247.0: 'Bk', 251.0: 'Cf', 252.0: 'Es', 257.0: 'Fm', 258.0: 'Md', 259.0: 'No',
    262.0: 'Lr', 267.0: 'Rf', 270.0: 'Db', 271.0: 'Sg', 270.0: 'Bh', 277.0: 'Hs',
    276.0: 'Mt', 281.0: 'Ds', 282.0: 'Rg', 285.0: 'Cn', 286.0: 'Nh', 289.0: 'Fl',
    290.0: 'Mc', 293.0: 'Lv', 294.0: 'Ts', 294.0: 'Og'
}

# Reading lammps data file
atoms = read('data.optimized_structure', format='lammps-data')

# Obtaining atomic coordinates and masses
positions = atoms.get_positions()
masses = atoms.get_masses()

# Judging the element symbol according to its quality
symbols = []
for mass in masses:
    # Finding the symbol of the element closest to the mass
    closest_mass = min(element_masses.keys(), key = lambda x: abs(x - mass))
    element_symbol = element_masses[closest_mass]
    symbols.append(element_symbol)

# Creating a new ASE Atoms object
new_atoms = ase.Atoms(
                      symbols = symbols, 
                      positions = positions, 
                      cell = atoms.get_cell(), 
                      pbc = True,
                      )

# Outputing cif file
write('optimized_structure_0.cif', new_atoms)

# Reading the generated CIF file contents and make adjustments
with open('optimized_structure_0.cif', 'r') as cif_file:
    cif_lines = cif_file.readlines()

# Finding the atomic coordinate section and swap the columns
new_cif_lines = []
for line in cif_lines:
    if line.startswith('_atom_site_label'):
        new_cif_lines.append(line)
        continue
    if line.startswith('loop_'):
        new_cif_lines.append(line)
        continue
    if len(line.split()) > 5:
        parts = line.split()
        # Swapping the first and second columns
        parts[0], parts[1] = parts[1], parts[0]
        new_line = ' '.join(parts) + '\n'
        new_cif_lines.append(new_line)
    else:
        new_cif_lines.append(line)

# Writing the adjusted CIF file
with open('optimized_structure.cif', 'w') as new_cif_file:
    new_cif_file.writelines(new_cif_lines)
os.remove('optimized_structure_0.cif')

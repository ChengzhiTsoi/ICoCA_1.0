# -*- coding: utf-8 -*-

import shutil
import os

cycle_number=2
os.makedirs('New_structure_summary/' + 'Cycle ' + str(cycle_number))

for i in os.listdir('new_designed_structures'):
    if '.cif' not in i:
        pass
    else:
        shutil.copy('new_designed_structures/' + i, 'New_structure_summary/Cycle ' + str(cycle_number) + '/' + i)
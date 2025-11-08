# -*- coding: utf-8 -*-

def EM(Structure_folder, linker_folder):
    import os
    from ntencode import deldot, encode  
    import numpy as np
    from rdkit import Chem
    from rdkit.Chem import AllChem
    import operator

    Structure_name = []
    Structure_dir = []
    linker_name = []
    lin_dir = []
    # 1. Choosing Structures' file
    for each in os.listdir(Structure_folder):
        if each.endswith((".cif")):
            Structure_name.append(each)
            Structure_dir.append(Structure_folder + "\\" + each)

    # 2. Choosing linkers' file
    for each in os.listdir(linker_folder):
        if each.endswith((".mol")):
               linker_name.append(each)
               lin_dir.append(linker_folder + "\\" + each)

    # 3. Inputing Structures' name   
    sub_name_topo = deldot(os.listdir('all_topologies'), '.template')
    sub_name_node = deldot(os.listdir('all_nodes'), '.cif')
    node_code = np.array(encode(sub_name_node, Structure_name))
    topo_code = np.array(encode(sub_name_topo, Structure_name))
    NT_code = np.append(node_code, topo_code, axis = 1) # nodes, topologies summary

    # 4. Inputing linker, and calculating MACCS keys
    sub_name_linker = deldot(os.listdir(linker_folder), '.mol') # linker's name
    linker = []
    for i in Structure_name:
        for j in sub_name_linker:
            if f'_{j}_' in i:
                edge_row = Chem.MolFromMolFile(linker_folder+'/'+str(j)+'.mol')
                linker.append(edge_row)
    linker_fp1 = [AllChem.GetMACCSKeysFingerprint(mol) for mol in linker]
    linker_fp2 = np.array(linker_fp1)
    X_test1 = np.append(linker_fp2, NT_code, axis = 1) # linkers, nodes, topologies

    # 5、Inputing crystal parameter
    string1 = "_cell_length_a"
    string2 = "_cell_length_b"
    string3 = "_cell_length_c"
    length_list = []
    for i in Structure_name:
        with open(Structure_folder+'/'+str(i),'r') as f:
            length = []
            for line in f.readlines():
                if string1 in line:
                    p=line.split()
                    f.close()
                    length.append(float(p[1]))
                if string2 in line:
                    p=line.split()
                    f.close()
                    length.append(float(p[1]))
                if string3 in line:
                    p=line.split()
                    f.close()
                    length.append(float(p[1]))
            length_list.append(length)
    length_list = np.array(length_list)              
    X_test = np.append(X_test1, length_list, axis = 1) # node, topology linker and crystal parameter
    number = len(X_test)
    bbb = []
    z = 0
    while z in range(number):
        aa = str(X_test[z]).split()
        aaa = []
        for zz in aa:
            if zz == "[":
                pass
            else:
                if len(zz) == 2:
                    zzz = zz.split(".")
                    aaa.append(zzz[0])
                else:
                    zzz = zz.split("]")
                    aaa.append(zzz[0])
        z = z + 1
        bbb.append(aaa)
    return X_test, sub_name_node, sub_name_topo, linker_fp2, Structure_name, bbb
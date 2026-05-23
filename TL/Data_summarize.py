# -*- coding: utf-8 -*-

import pandas as pd
import json
import os
import numpy as np
import shutil
import sys
import re

COUNTER_JSON = "counter.json"
EXCEL_PATH = "final_data.xlsx"
TRAIN_XLSX = "TL_data_target_task_train.xlsx"
TEST_XLSX = "TL_data_target_task_test.xlsx"

# ---------- Helpers ----------
def detect_last_cycle(xlsx_path: str) -> int:
    """Return the highest 'Cycle N' found in the existing workbook, or 0 if none."""
    if not os.path.exists(xlsx_path):
        return 0
    try:
        xl = pd.ExcelFile(xlsx_path, engine="openpyxl")
        nums = []
        for s in xl.sheet_names:
            m = re.fullmatch(r"Cycle\s+(\d+)", s)
            if m:
                nums.append(int(m.group(1)))
        return max(nums) if nums else 0
    except Exception:
        return 0

def load_counter(counter_path: str, xlsx_path: str) -> int:
    """Prefer counter.json when present and sane; otherwise infer from Excel."""
    inferred = detect_last_cycle(xlsx_path)
    try:
        with open(counter_path, "r") as f:
            val = int(json.load(f).get("counter", 0))
            # if json counter lags behind workbook, trust workbook
            return max(val, inferred)
    except Exception:
        return inferred

def save_counter(counter_path: str, value: int):
    with open(counter_path, "w", encoding="utf-8") as f:
        json.dump({"counter": int(value)}, f)

def tsn_max(df: pd.DataFrame) -> float:
    """Max priority: TSN_pred -> TSN_simu -> TSN. Return -inf if nothing valid."""
    if df is None:
        return float("-inf")
    for col in ("TSN_pred", "TSN_simu", "TSN"):
        if col in df.columns:
            s = pd.to_numeric(df[col], errors="coerce")
            if s.notna().any():
                return float(s.max(skipna=True))
    return float("-inf")

def pick_scores(df: pd.DataFrame, k: int = 50):
    """
    For ranking top-K:
      - Prefer TSN_pred (Cycle >= 2)
      - Fallback to TSN (Cycle 1)
      - Fallback to TSN_simu as last resort
    Returns (top_indices, score_col). If no valid column, returns ([], None).
    """
    for col in ("TSN_pred", "TSN", "TSN_simu"):
        if col in df.columns:
            scores = pd.to_numeric(df[col], errors="coerce").fillna(-np.inf).values
            order = np.argsort(scores)[::-1]
            return order[:min(k, len(order))], col
    return np.array([], dtype=int), None

# ---------- 1) Determine current cycle ----------
last_cycle = load_counter(COUNTER_JSON, EXCEL_PATH)  # Cycle 0 already exists in your workbook
counter = last_cycle + 1                              # new cycle number
sheet_now = f"Cycle {counter}"
sheet_prev = f"Cycle {counter-1}"

# ---------- 2) Read and combine current train/test (vertical concat) ----------
df1 = pd.read_excel(TRAIN_XLSX, engine="openpyxl")
df2 = pd.read_excel(TEST_XLSX, engine="openpyxl")
combined_df = pd.concat([df1, df2], ignore_index=True)
# IMPORTANT: Do NOT rename columns by position; your files already carry TSN/TSN_simu/TSN_pred as designed.

# ---------- 3) Write the current cycle sheet ----------
mode = "a" if os.path.exists(EXCEL_PATH) else "w"
with pd.ExcelWriter(EXCEL_PATH, mode=mode, engine="openpyxl") as writer:
    combined_df.to_excel(writer, sheet_name=sheet_now, index=False)
save_counter(COUNTER_JSON, counter)

# ---------- 4) Load current/previous sheets and compare maxima ----------
df_now = pd.read_excel(EXCEL_PATH, sheet_name=sheet_now, engine="openpyxl")
try:
    df_last = pd.read_excel(EXCEL_PATH, sheet_name=sheet_prev, engine="openpyxl") if counter > 1 else None
except ValueError:
    df_last = None  # previous sheet missing; treat as -inf

TSN_now_max  = tsn_max(df_now)
TSN_last_max = tsn_max(df_last)

# ---------- 5) Prepare directories ----------
cwd = os.getcwd()
parent_dir = os.path.dirname(cwd)
best_edges_dir = os.path.join(parent_dir, "best_edges_mol")
optimal_linker_dir = os.path.join(parent_dir, "optimal_linker")

# ---------- 6) If improved, copy top-50 linkers ----------
if TSN_last_max <= TSN_now_max:
    # pick scores and top indices
    top_idx, used_col = pick_scores(df_now, k=50)

    # If no valid scores, treat as not improved/do nothing
    if used_col is None or len(top_idx) == 0:
        sys.exit(1)

    # names from first column
    name_now = df_now.iloc[:, 0].astype(str).values

    # ensure target folder and clear files
    os.makedirs(optimal_linker_dir, exist_ok=True)
    for fname in os.listdir(optimal_linker_dir):
        fpath = os.path.join(optimal_linker_dir, fname)
        if os.path.isfile(fpath):
            try:
                os.remove(fpath)
            except Exception:
                pass

    # copy .mol files (names must contain 'best_mol_')
    for i in top_idx:
        molf_name = name_now[i]
        if "best_mol_" not in molf_name:
            continue
        linker_part = molf_name.split("best_mol_")[1].split(" ")[0]
        linker_part = os.path.splitext(linker_part)[0]
        linker_core = linker_part.split("_")[0]
        src = os.path.join(best_edges_dir, f"{linker_core}.mol")
        dst = os.path.join(optimal_linker_dir, f"{linker_core}.mol")
        if os.path.exists(src):
            try:
                shutil.copy(src, dst)
            except Exception:
                pass  # ignore copy errors for robustness

    sys.exit(0)
else:
    sys.exit(1)
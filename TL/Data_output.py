# -*- coding: utf-8 -*-

import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import re
from matplotlib.ticker import MaxNLocator
from typing import Optional

excel_file = 'final_data.xlsx'
xls = pd.ExcelFile(excel_file, engine='openpyxl')

# ---- helpers ------------------------------------------------------------
def cycle_key(name: str) -> int:
    """Extract numeric key from 'Cycle N' for sorting; unknown -> big number."""
    m = re.fullmatch(r'\s*Cycle\s+(\d+)\s*', str(name))
    return int(m.group(1)) if m else 10**9

def pick_tsn_series(df: pd.DataFrame) -> Optional[pd.Series]:
    """Prefer TSN_pred -> TSN_simu -> TSN; returns numeric series (NaN allowed)."""
    for col in ('TSN_pred', 'TSN_simu', 'TSN'):
        if col in df.columns:
            return pd.to_numeric(df[col], errors='coerce')
    return None

color_dict = {
    'TSN<1': '#fff3b0',     # 1 > TSN
    '1=TSN<2': '#ffd27f',   # 2 > TSN > 1
    '2=TSN<3': '#f7a9a8',   # 3 > TSN > 2
    '3=TSN<4': '#e0aaff',   # 4 > TSN > 3
    'TSN=4': '#b388eb'      # TSN > 4
}

# ---- load & compute -----------------------------------------------------
sheet_names_sorted = sorted(xls.sheet_names, key=cycle_key)

bins = [0, 1, 2, 3, 4, float('inf')]
labels = ['TSN<1', '1=TSN<2', '2=TSN<3', '3=TSN<4', 'TSN=4']

avg_tsn_list, max_tsn_list, count_list = [], [], []
prop_rows = []

for sheet in sheet_names_sorted:
    df = pd.read_excel(excel_file, sheet_name=sheet, engine='openpyxl')
    s = pick_tsn_series(df)

    # safety for missing TSN columns
    if s is None:
        # all zeros to keep plot running
        avg_tsn_list.append(0.0)
        max_tsn_list.append(0.0)
        count_list.append(len(df))
        prop_rows.append(pd.Series([0,0,0,0,0], index=labels))
        continue

    avg_tsn_list.append(float(s.mean(skipna=True)))
    max_tsn_list.append(float(s.max(skipna=True)))
    count_list.append(int(s.shape[0]))

    # distribution by bins
    cat = pd.cut(s, bins=bins, labels=labels, include_lowest=True)
    vc = cat.value_counts().sort_index()  # aligned to labels
    prop = (vc / max(vc.sum(), 1)).reindex(labels).fillna(0.0)
    prop_rows.append(prop)

tsn_prop_df = pd.DataFrame(prop_rows, index=sheet_names_sorted, columns=labels)

# ---- build figure -------------------------------------------------------
plt.rcParams.update({
    'font.size': 14,
    'axes.titlesize': 20,
    'axes.labelsize': 16,
    'xtick.labelsize': 14,
    'ytick.labelsize': 14,
    'legend.fontsize': 13
})

fig, ax1 = plt.subplots(figsize=(10, 6))
indices = np.arange(len(sheet_names_sorted))
bar_width = 0.4

# stacked bars (transpose to get stacks per cycle)
(tsn_prop_df.rename_axis('Cycle')
            .set_index(pd.Index(sheet_names_sorted, name='Cycle'))
            ).plot(
    kind='bar',
    stacked=True,
    ax=ax1,
    edgecolor='black',
    width=bar_width,
    color=[color_dict[c] for c in tsn_prop_df.columns]
)

ax1.set_xlabel('Cycle')
ax1.set_ylabel('Proportion of Structures', labelpad=12)
ax1.set_title('Structure Performance Distribution and Statistics', pad=16)
ax1.set_ylim(0, 1.0)
ax1.set_xticks(indices)
ax1.set_xticklabels(sheet_names_sorted, rotation=0)

# right axis 1: Avg TSN
ax2 = ax1.twinx()
line_avg, = ax2.plot(indices, avg_tsn_list, marker='o', linewidth=2, label='Avg TSN', zorder=3)
# y-range padding with NaN safety
avg_min = np.nanmin(avg_tsn_list) if len(avg_tsn_list) else 0.0
avg_max = np.nanmax(avg_tsn_list) if len(avg_tsn_list) else 1.0
if not np.isfinite(avg_min): avg_min = 0.0
if not np.isfinite(avg_max): avg_max = 1.0
pad = (avg_max - avg_min) * 0.1 if avg_max > avg_min else 0.5
ax2.set_ylim(avg_min - pad, avg_max + pad)
ax2.set_ylabel('Average TSN', labelpad=8)

# right axis 2: Max TSN
ax3 = ax1.twinx()
ax3.spines['right'].set_position(('outward', 70))
line_max, = ax3.plot(indices, max_tsn_list, marker='s', linewidth=2, label='Max TSN', zorder=3)
mx_min = np.nanmin(max_tsn_list) if len(max_tsn_list) else 0.0
mx_max = np.nanmax(max_tsn_list) if len(max_tsn_list) else 1.0
if not np.isfinite(mx_min): mx_min = 0.0
if not np.isfinite(mx_max): mx_max = 1.0
pad2 = (mx_max - mx_min) * 0.1 if mx_max > mx_min else 0.5
ax3.set_ylim(mx_min - pad2, mx_max + pad2)
ax3.set_ylabel('Max TSN', labelpad=8)

# right axis 3: Structure Count
ax4 = ax1.twinx()
ax4.spines['right'].set_position(('outward', 140))
line_cnt, = ax4.plot(indices, count_list, marker='^', linewidth=2, label='Structure Count', zorder=3)
ct_min = np.nanmin(count_list) if len(count_list) else 0.0
ct_max = np.nanmax(count_list) if len(count_list) else 1.0
if not np.isfinite(ct_min): ct_min = 0.0
if not np.isfinite(ct_max): ct_max = 1.0
pad3 = (ct_max - ct_min) * 0.1 if ct_max > ct_min else 1
ax4.set_ylim(ct_min - pad3, ct_max + pad3)
ax4.set_ylabel('Structure Count', labelpad=8)
ax4.yaxis.set_major_locator(MaxNLocator(nbins=5))
# ? show full numbers (disable scientific notation)
ax4.ticklabel_format(style='plain', axis='y')
ax4.get_yaxis().get_offset_text().set_visible(False)


# legend (bars + 3 lines)
lns1, labs1 = ax1.get_legend_handles_labels()
lns2, labs2 = ax2.get_legend_handles_labels()
lns3, labs3 = ax3.get_legend_handles_labels()
lns4, labs4 = ax4.get_legend_handles_labels()
ax1.legend(
    lns1 + [line_avg, line_max, line_cnt],
    labs1 + [labs2[0] if labs2 else 'Avg TSN',
             labs3[0] if labs3 else 'Max TSN',
             labs4[0] if labs4 else 'Structure Count'],
    loc='upper center',
    bbox_to_anchor=(0.5, -0.15),
    ncol=3
)

# ---- annotations --------------------------------------------------------
def annotate_points(ax, x, y, fmt, color=None, offset_fn=None):
    for i, val in enumerate(y):
        if not np.isfinite(val):
            continue
        dx, dy = offset_fn(i, val) if offset_fn else (0, 10)
        ax.annotate(
            fmt.format(val),
            (x[i], y[i]),
            textcoords="offset points",
            xytext=(dx, dy),
            ha='center',
            color=color if color else 'black',
            fontsize=9,
            bbox=dict(boxstyle="round,pad=0.3", facecolor="white", edgecolor=color if color else 'black'),
            zorder=10
        )

def offset_avg(i, v):  # slight up, zig-zag to avoid overlap
    return (-18, 10) if i % 2 == 0 else (18, 10)

def offset_max(i, v):  # slight down, zig-zag
    return (-18, -14) if i % 2 == 0 else (18, -14)

def offset_cnt(i, v):  # up if big, down if small
    return (0, 14) if v >= (ct_min + ct_max) / 2 else (0, -16)

annotate_points(ax2, indices, avg_tsn_list, '{:.2f}', color='tab:red',   offset_fn=offset_avg)
annotate_points(ax3, indices, max_tsn_list, '{:.2f}', color='tab:blue',  offset_fn=offset_max)
annotate_points(ax4, indices, count_list,    '{:d}',   color='tab:green', offset_fn=offset_cnt)

plt.tight_layout()
plt.savefig("Output.png", bbox_inches='tight')

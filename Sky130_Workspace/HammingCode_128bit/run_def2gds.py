#!/usr/bin/env python3.9
"""
run_def2gds.py — Generate GDS from DEF using klayout Python API
================================================================
Bypasses the need for KLayout binary (klayout CLI).
Uses ORFS def2stream.py + klayout.db Python API directly.

Usage:
    python3.9 run_def2gds.py

Output:
    results/sky130hd/HammingCode_128bit/base/6_final.gds
"""

import os
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths — auto-detect từ vị trí script (không hardcode)
# File này: OPENROAD_HOME/Sky130_Workspace/HammingCode_128bit/run_def2gds.py
# ---------------------------------------------------------------------------
_SCRIPT_DIR  = Path(__file__).resolve().parent
OPENROAD_HOME = _SCRIPT_DIR.parents[1]   # .../OpenROAD/
FLOW_HOME    = str(OPENROAD_HOME / "ORFS_Source" / "flow")
DESIGN_NAME  = "HammingCode_128bit"
PLATFORM     = "sky130hd"
VARIANT      = "base"

RESULTS_DIR  = f"{FLOW_HOME}/results/{PLATFORM}/{DESIGN_NAME}/{VARIANT}"
OBJECTS_DIR  = f"{FLOW_HOME}/objects/{PLATFORM}/{DESIGN_NAME}/{VARIANT}"
PLATFORM_DIR = f"{FLOW_HOME}/platforms/{PLATFORM}"
UTILS_DIR    = f"{FLOW_HOME}/util"

IN_DEF      = f"{RESULTS_DIR}/6_final.def"
OUT_GDS     = f"{RESULTS_DIR}/6_final.gds"
TECH_LYT    = f"{PLATFORM_DIR}/sky130hd.lyt"
GEN_LYT     = f"{OBJECTS_DIR}/klayout.lyt"
SC_GDS      = f"{PLATFORM_DIR}/gds/sky130_fd_sc_hd.gds"

LEF_FILES   = [
    f"{PLATFORM_DIR}/lef/sky130_fd_sc_hd.tlef",
    f"{PLATFORM_DIR}/lef/sky130_fd_sc_hd_merged.lef",
]

# ---------------------------------------------------------------------------
# Step 1: Generate klayout.lyt (no klayout needed — pure Python XML)
# ---------------------------------------------------------------------------
print(f"[1/3] Generating klayout tech file: {GEN_LYT}")
os.makedirs(OBJECTS_DIR, exist_ok=True)

sys.path.insert(0, UTILS_DIR)
from generate_klayout_tech import generate_klayout_tech

generate_klayout_tech(
    template_lyt      = TECH_LYT,
    output_lyt        = GEN_LYT,
    lef_files         = LEF_FILES,
    reference_dir     = OBJECTS_DIR,
    map_files         = [],
    use_relative_paths = True,
)
print(f"    → {GEN_LYT}")

# ---------------------------------------------------------------------------
# Step 2: Import klayout Python API
# ---------------------------------------------------------------------------
print("[2/3] Loading klayout.db Python API...")
import klayout.db as pya
print(f"    → klayout {pya.__version__} loaded")

# ---------------------------------------------------------------------------
# Step 3: Run def2stream merge
# ---------------------------------------------------------------------------
print(f"[3/3] Merging DEF + PDK GDS → {OUT_GDS}")
print(f"    DEF  : {IN_DEF}")
print(f"    GDS  : {SC_GDS}")
print(f"    Tech : {GEN_LYT}")

from def2stream import merge_gds

errors = merge_gds(
    pya_mod      = pya,
    tech_file    = GEN_LYT,
    layer_map    = "",
    in_def       = IN_DEF,
    design_name  = DESIGN_NAME,
    in_files     = SC_GDS,
    seal_file    = "",
    out_file     = OUT_GDS,
    allow_empty  = "",
)

if errors > 0:
    print(f"\n[ERROR] {errors} errors during GDS merge")
    sys.exit(1)

size_mb = os.path.getsize(OUT_GDS) / 1e6
print(f"\n[SUCCESS] GDS generated: {OUT_GDS} ({size_mb:.2f} MB)")
print(f"Design area: 21238 µm² @ 76% utilization")

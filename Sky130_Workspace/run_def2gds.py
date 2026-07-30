"""
Convert 6_final.def → 6_final.gds using KLayout Python API
Emulates ORFS klayout.tcl behavior
"""
import sys
from pathlib import Path

# Auto-detect OPENROAD_HOME từ vị trí script (không hardcode)
# File này: OPENROAD_HOME/Sky130_Workspace/run_def2gds.py
_SCRIPT_DIR   = Path(__file__).resolve().parent
OPENROAD_HOME = _SCRIPT_DIR.parent   # .../OpenROAD/
FLOW_HOME     = str(OPENROAD_HOME / "ORFS_Source" / "flow")

sys.path.insert(0, f"{FLOW_HOME}/util")

import klayout.db as pya
import def2stream

RESULTS  = f"{FLOW_HOME}/results/sky130hd/gcd/base"
PLATFORM = f"{FLOW_HOME}/platforms/sky130hd"
OUTPUT   = str(_SCRIPT_DIR / "GCD_signoff")

import os
os.makedirs(OUTPUT, exist_ok=True)

def2stream.merge_gds(
    pya_mod     = pya,
    tech_file   = f"{PLATFORM}/sky130hd.lyt",
    layer_map   = "",
    in_def      = f"{RESULTS}/6_final.def",
    design_name = "gcd",
    in_files    = f"{PLATFORM}/gds/sky130_fd_sc_hd.gds",
    seal_file   = "",
    out_file    = f"{OUTPUT}/gcd_final.gds",
)

print(f"GDS written to {OUTPUT}/gcd_final.gds")

export DESIGN_NAME      = HammingCode_128bit
export PLATFORM         = sky130hd

# Auto-detect design directory từ vị trí file này (không hardcode paths)
_THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

export VERILOG_FILES    = $(_THIS_DIR)src/HammingCode_128bit.v
export SDC_FILE         = $(_THIS_DIR)constraints/constraint.sdc

# Die size: small design ~1500-3000 cells, pure XOR logic
export CORE_UTILIZATION  = 50
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN       = 2.0
export PLACE_DENSITY     = 0.65

# Clock: 100 MHz (10 ns), realistic for Sky130HD
# (500 MHz requires 3-4 pipeline stages, 100 MHz is achievable combinationally)
export CLOCK_PERIOD      = 10.0

# Disable equivalence check (eqy not built on macOS M1)
export TNS_END_PERCENT   = 100
export EQUIVALENCE_CHECK = 0
export LEC_CHECK         = 0

export DESIGN_NAME      = Bio_health
export PLATFORM         = asap7

_THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

export VERILOG_FILES    = $(_THIS_DIR)src/Bio_health.v
export SDC_FILE         = $(_THIS_DIR)constraints/constraint.sdc

export CORE_UTILIZATION  = 65
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN       = 2.0
export PLACE_DENSITY     = 0.55

export TNS_END_PERCENT   = 100
export EQUIVALENCE_CHECK = 0
export LEC_CHECK         = 0

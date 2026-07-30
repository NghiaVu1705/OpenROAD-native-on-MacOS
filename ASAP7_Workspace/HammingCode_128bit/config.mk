export DESIGN_NAME      = HammingCode_128bit
export PLATFORM         = asap7

export VERILOG_FILES    = $(shell pwd)/src/HammingCode_128bit.v
export SDC_FILE         = $(shell pwd)/constraints/constraint.sdc

export CORE_UTILIZATION  = 65
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN       = 2.0
export PLACE_DENSITY     = 0.65

export TNS_END_PERCENT   = 100
export EQUIVALENCE_CHECK = 0
export LEC_CHECK         = 0

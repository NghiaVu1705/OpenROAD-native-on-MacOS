##############################################################
# HammingCode_128bit Verification Makefile
# Supports: Icarus Verilog + Verilator via cocotb
##############################################################

TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/../src/HammingCode_128bit.v
TOPLEVEL        = HammingCode_128bit
MODULE          = tests.test_HammingCode_128bit

# Simulator: icarus | verilator
SIM ?= icarus

# Waveform dump
WAVES ?= 1
ifeq ($(WAVES),1)
  COCOTB_HDL_TIMEUNIT      = 1ns
  COCOTB_HDL_TIMEPRECISION = 1ps
  ifeq ($(SIM),icarus)
    PLUSARGS += -fst
  endif
endif

# Verilator specific
ifeq ($(SIM),verilator)
  EXTRA_ARGS += --trace --trace-fst
  EXTRA_ARGS += --no-timing
  COMPILE_ARGS += -Wall
endif

# cocotb Makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# Helpers
.PHONY: icarus verilator waves clean-waves report

icarus:
	$(MAKE) SIM=icarus

verilator:
	$(MAKE) SIM=verilator

waves:
	gtkwave waves/HammingCode_128bit.fst &

clean-waves:
	rm -f waves/*.fst waves/*.vcd

report:
	@echo "=== Test Report ===" && cat reports/functional/*.txt 2>/dev/null || echo "No reports yet"

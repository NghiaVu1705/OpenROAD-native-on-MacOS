##############################################################
# Bio_health Verification Makefile
# Supports: Icarus Verilog + Verilator via cocotb
##############################################################

MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

TOPLEVEL_LANG   = verilog
VERILOG_SOURCES = $(MAKEFILE_DIR)../src/Bio_health.v
TOPLEVEL        = Bio_health
MODULE          = tests.test_Bio_health

export PYTHONPATH := $(MAKEFILE_DIR)tb:$(MAKEFILE_DIR)../reference:$(PYTHONPATH)

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

# cocotb-config: macOS user-install path → PATH fallback
COCOTB_CONFIG ?= $(or \
    $(wildcard $(HOME)/Library/Python/3.9/bin/cocotb-config), \
    $(shell which cocotb-config 2>/dev/null))
include $(shell $(COCOTB_CONFIG) --makefiles)/Makefile.sim

# Helpers
.PHONY: icarus verilator waves clean-waves report

icarus:
	$(MAKE) SIM=icarus

verilator:
	$(MAKE) SIM=verilator

waves:
	gtkwave waves/Bio_health.fst &

clean-waves:
	rm -f waves/*.fst waves/*.vcd

report:
	@echo "=== Test Report ===" && cat reports/functional/*.txt 2>/dev/null || echo "No reports yet"

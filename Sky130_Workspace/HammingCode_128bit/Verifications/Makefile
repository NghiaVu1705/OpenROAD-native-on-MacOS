##############################################################
# HammingCode_128bit Verification Makefile
# Supports: Icarus Verilog + Verilator via cocotb
##############################################################

# Auto-detect thư mục Makefile này (không phụ thuộc vào $(shell pwd))
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

TOPLEVEL_LANG   = verilog
VERILOG_SOURCES = $(MAKEFILE_DIR)../src/HammingCode_128bit.v
TOPLEVEL        = HammingCode_128bit
MODULE          = tests.test_HammingCode_128bit

# PYTHONPATH: tb/ (for tests.*) + reference/ (for hamming_golden)
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

# cocotb-config: thử theo thứ tự ưu tiên
# 1. Override từ env (COCOTB_CONFIG=...)
# 2. macOS Python 3.9 user-install path
# 3. PATH (cocotb-config in current shell)
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
	gtkwave waves/HammingCode_128bit.fst &

clean-waves:
	rm -f waves/*.fst waves/*.vcd

report:
	@echo "=== Test Report ===" && cat reports/functional/*.txt 2>/dev/null || echo "No reports yet"

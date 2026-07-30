#!/usr/bin/env bash
# Run simulation with Icarus Verilog (standalone, no cocotb)
set -e
SRC=../../src/Bio_health.v
OUT=../../waves/Bio_health_icarus.vcd

iverilog -g2012 -o /tmp/Bio_health_sim $SRC
vvp /tmp/Bio_health_sim -fst
echo "Done. Waveform: $OUT"
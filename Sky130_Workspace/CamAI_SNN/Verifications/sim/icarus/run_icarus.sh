#!/usr/bin/env bash
# Run simulation with Icarus Verilog (standalone, no cocotb)
set -e
SRC=../../src/CamAI_SNN.v
OUT=../../waves/CamAI_SNN_icarus.vcd

iverilog -g2012 -o /tmp/CamAI_SNN_sim $SRC
vvp /tmp/CamAI_SNN_sim -fst
echo "Done. Waveform: $OUT"
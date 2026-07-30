#!/usr/bin/env bash
# Run simulation with Icarus Verilog (standalone, no cocotb)
set -e
SRC=../../src/HammingCode_128bit.v
OUT=../../waves/HammingCode_128bit_icarus.vcd

iverilog -g2012 -o /tmp/HammingCode_128bit_sim $SRC
vvp /tmp/HammingCode_128bit_sim -fst
echo "Done. Waveform: $OUT"
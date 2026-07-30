#!/usr/bin/env bash
# Run lint + simulation with Verilator
set -e
SRC=../../src/HammingCode_128bit.v

echo "[1/2] Linting..."
verilator --lint-only -Wall $SRC && echo "Lint PASSED"

echo "[2/2] Compiling..."
verilator --cc $SRC --exe --build --trace -j4 -o /tmp/HammingCode_128bit_verilator
echo "Build done."
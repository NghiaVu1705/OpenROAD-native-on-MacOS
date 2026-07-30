#!/usr/bin/env bash
# Run lint + simulation with Verilator
set -e
SRC=../../src/CamAI_SNN.v

echo "[1/2] Linting..."
verilator --lint-only -Wall $SRC && echo "Lint PASSED"

echo "[2/2] Compiling..."
verilator --cc $SRC --exe --build --trace -j4 -o /tmp/CamAI_SNN_verilator
echo "Build done."
#!/usr/bin/env bash
set -e

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORFS="$(cd "$_SCRIPT_DIR/.." && pwd)/ORFS_Source"
unset _SCRIPT_DIR
export PATH="$ORFS/tools/install/OpenROAD/bin:$ORFS/tools/install/yosys/bin:$PATH"

echo "[INFO] OpenROAD: $(openroad -version)"
echo "[INFO] Yosys:    $(yosys --version)"
echo ""
echo "[INFO] Running GCD on ASAP7..."

cd "$ORFS/flow"
make DESIGN_CONFIG=./designs/asap7/gcd/config.mk -j4

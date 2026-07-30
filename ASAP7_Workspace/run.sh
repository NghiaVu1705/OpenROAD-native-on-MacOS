#!/usr/bin/env bash
# ============================================================
# Chạy flow OpenROAD cho ASAP7
# Usage: ./run.sh <project_name>
# Example: ./run.sh CamAI_SNN
# ============================================================

set -e

# Auto-detect OPENROAD_HOME từ vị trí script (không hardcode)
# File này: OPENROAD_HOME/ASAP7_Workspace/run.sh
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENROAD_HOME="$(cd "$_SCRIPT_DIR/.." && pwd)"
ORFS="$OPENROAD_HOME/ORFS_Source"

# Detect Homebrew prefix (arm64 vs x86)
_BREW="$( [[ -x /opt/homebrew/bin/brew ]] && echo /opt/homebrew || echo /usr/local )"
export PATH="$_BREW/opt/coreutils/libexec/gnubin:$ORFS/tools/install/OpenROAD/bin:$ORFS/tools/install/yosys/bin:$PATH"
unset _BREW

PROJECT=$1

if [ -z "$PROJECT" ]; then
    echo "Usage: ./run.sh <project>"
    echo "Available: CamAI_SNN | Bio_health | HammingCode_128bit"
    exit 1
fi

CONFIG="$_SCRIPT_DIR/$PROJECT/config.mk"
unset _SCRIPT_DIR

if [ ! -f "$CONFIG" ]; then
    echo "Error: $CONFIG not found"
    exit 1
fi

echo "========================================"
echo " Running: $PROJECT on ASAP7"
echo "========================================"

cd $ORFS/flow
make DESIGN_CONFIG="$CONFIG" EQUIVALENCE_CHECK=0 LEC_CHECK=0

echo ""
echo "========================================"
echo " Done! Results at:"
echo " $ORFS/flow/results/asap7/$PROJECT/base/"
echo "========================================"

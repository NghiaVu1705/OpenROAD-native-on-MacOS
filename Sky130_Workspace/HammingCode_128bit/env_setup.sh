#!/usr/bin/env bash
# =============================================================================
# env_setup.sh — OpenROAD Tool Environment Setup
# Source file này trước khi chạy bất kỳ bước nào trong flow:
#   source env_setup.sh
# Tương thích bash + zsh (không hardcode OPENROAD_HOME).
# =============================================================================

# ─── Auto-detect OPENROAD_HOME (bash + zsh khi source) ────────────────────────
# File này: OPENROAD_HOME/Sky130_Workspace/HammingCode_128bit/env_setup.sh
_or_env_src=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    # bash (và zsh nếu BASH_SOURCE được set)
    _or_env_src="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    # zsh: %x = path của file đang được source
    # shellcheck disable=SC2296
    _or_env_src="${(%):-%x}"
else
    _or_env_src="$0"
fi
_SCRIPT_DIR="$(cd "$(dirname "$_or_env_src")" && pwd)"
OPENROAD_HOME="$(cd "$_SCRIPT_DIR/../.." && pwd)"
unset _or_env_src _SCRIPT_DIR

# Sanity: nếu detect sai (không có ORFS_Source), fallback cứng theo path thường dùng
if [[ ! -d "$OPENROAD_HOME/ORFS_Source" ]]; then
    if [[ -d "$HOME/Documents/OpenROAD/ORFS_Source" ]]; then
        OPENROAD_HOME="$HOME/Documents/OpenROAD"
    fi
fi

# ─── Detect Homebrew prefix (arm64 vs x86) ────────────────────────────────────
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    _BREW_PREFIX="/opt/homebrew"
elif [[ -x "/usr/local/bin/brew" ]]; then
    _BREW_PREFIX="/usr/local"
else
    _BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
fi

# ─── PATH: base tools trước, ORFS/OpenROAD sau cùng (ưu tiên cao nhất) ───────
# Homebrew (generic)
export PATH="$_BREW_PREFIX/bin:$PATH"
# GNU tools (bắt buộc cho ORFS trên macOS)
export PATH="$_BREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
export PATH="$_BREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH"
# Python 3.9 (Xcode CLT) + user pip scripts (cocotb-config, …)
_PY39_CLT="/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/bin"
if [[ -x "$_PY39_CLT/python3.9" ]]; then
    export PATH="$_PY39_CLT:$PATH"
fi
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
unset _PY39_CLT
# KLayout CLI wrapper
export PATH="$OPENROAD_HOME/Sky130_Workspace/bin:$PATH"
# EDA tools từ project — PHẢI ở đầu PATH (sau cùng khi prepend)
export PATH="$OPENROAD_HOME/tools/install/netgen/bin:$PATH"
export PATH="$OPENROAD_HOME/tools/install/magic/bin:$PATH"
export PATH="$OPENROAD_HOME/ORFS_Source/tools/install/yosys/bin:$PATH"
export PATH="$OPENROAD_HOME/ORFS_Source/tools/install/OpenROAD/bin:$PATH"

unset _BREW_PREFIX

# ─── Export cho sub-processes ─────────────────────────────────────────────────
export OPENROAD_HOME
export FLOW_HOME="$OPENROAD_HOME/ORFS_Source/flow"
export MAGIC_BIN="$OPENROAD_HOME/tools/install/magic/bin/magic"
export CAD_ROOT="$OPENROAD_HOME/tools/install/magic/lib"

# ─── Status report ────────────────────────────────────────────────────────────
echo "=== OpenROAD Environment Ready ==="
echo "  OPENROAD_HOME : $OPENROAD_HOME"
for tool in openroad yosys magic netgen realpath iverilog python3.9 klayout; do
    loc=$(command -v "$tool" 2>/dev/null || echo "NOT FOUND")
    if [[ "$loc" == "NOT FOUND" ]]; then
        echo "  $tool : NOT FOUND ⚠"
    else
        echo "  $tool : $loc"
    fi
done
# klayout là Python API — báo thêm nếu module import được
if command -v python3.9 >/dev/null 2>&1; then
    if python3.9 -c "import klayout" 2>/dev/null; then
        echo "  klayout API : OK ($(python3.9 -c 'import klayout; print(klayout.__version__)'))"
    else
        echo "  klayout API : NOT FOUND ⚠  (python3.9 -m pip install --user klayout)"
    fi
fi
echo "==================================="

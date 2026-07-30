#!/usr/bin/env bash
# =============================================================================
# bootstrap_macos.sh — Cài deps macOS Apple Silicon cho lab OpenROAD
# Chạy từ ROOT repo:  ./scripts/bootstrap_macos.sh
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}  ✓${RESET} $*"; }
warn() { echo -e "${YELLOW}  ⚠${RESET} $*"; }
err()  { echo -e "${RED}  ✗${RESET} $*"; }
hdr()  { echo -e "\n${BOLD}$*${RESET}"; }

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Bootstrap OpenROAD Lab — macOS Apple Silicon               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  ROOT = $ROOT"

# ─── 0. Kiến trúc ────────────────────────────────────────────────────────────
hdr "0) Kiểm tra máy"
ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
  err "Cần Apple Silicon (arm64). Máy này: $ARCH"
  err "Intel Mac: dùng Docker/Linux thay vì hướng dẫn native này."
  exit 1
fi
ok "arch = arm64"
ok "macOS $(sw_vers -productVersion 2>/dev/null || echo '?')"

# ─── 1. Xcode CLT ────────────────────────────────────────────────────────────
hdr "1) Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
  ok "Xcode CLT: $(xcode-select -p)"
else
  warn "Chưa có Xcode CLT — đang mở installer..."
  xcode-select --install || true
  echo "  Hãy cài xong rồi chạy lại script này."
  exit 1
fi

PY39="/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/bin/python3.9"
if [[ ! -x "$PY39" ]]; then
  # fallback
  PY39="$(command -v python3.9 2>/dev/null || true)"
fi
if [[ -x "$PY39" ]]; then
  ok "python3.9 → $PY39 ($($PY39 --version 2>&1))"
else
  err "Không tìm thấy python3.9 (cần Xcode CLT)"
  exit 1
fi

# ─── 2. Homebrew ─────────────────────────────────────────────────────────────
hdr "2) Homebrew"
if ! command -v brew &>/dev/null; then
  warn "Chưa có Homebrew — cài đặt..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"
ok "brew → $(brew --prefix)"

# ─── 3. Packages ─────────────────────────────────────────────────────────────
hdr "3) Cài Homebrew packages (có thể mất 10–20 phút)"
brew install \
  coreutils gnu-sed \
  tcl-tk@8 or-tools protobuf re2 highs scip \
  libomp qt@5 yaml-cpp spdlog fmt \
  icarus-verilog verilator \
  cmake ninja swig bison flex \
  git wget pkg-config 2>&1 | tail -20

ok "Homebrew packages OK"

# ─── 4. Python packages ──────────────────────────────────────────────────────
hdr "4) Python packages (klayout, cocotb, pyyaml)"
"$PY39" -m pip install --user --upgrade pip setuptools wheel 2>&1 | tail -3
"$PY39" -m pip install --user \
  "klayout" \
  "cocotb>=1.9.0" \
  "cocotb-bus>=0.2.1" \
  "pyuvm>=3.0.0" \
  "pyyaml" \
  "numpy" 2>&1 | tail -15

"$PY39" -c "import klayout.db as p; print('klayout', p.__version__)"
"$PY39" -c "import cocotb; print('cocotb', cocotb.__version__)"
ok "Python packages OK"

# ─── 5. Clone ORFS ───────────────────────────────────────────────────────────
hdr "5) OpenROAD-flow-scripts → ORFS_Source/"
if [[ -d "$ROOT/ORFS_Source/.git" ]]; then
  ok "ORFS_Source đã tồn tại — bỏ qua clone"
elif [[ -d "$ROOT/ORFS_Source" ]]; then
  warn "ORFS_Source tồn tại nhưng không phải git repo — giữ nguyên"
else
  echo "  Cloning (recursive, có thể lâu / nặng)..."
  git clone --recursive \
    https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git \
    "$ROOT/ORFS_Source"
  ok "Clone xong"
fi

# ─── 6. Gợi ý bước tiếp ──────────────────────────────────────────────────────
hdr "6) Bước tiếp theo (bạn chạy tay)"
cat << EOF

  ${BOLD}A. Build OpenROAD + Yosys (30–90 phút):${RESET}
     cd $ROOT/ORFS_Source
     export OpenMP_ROOT=\$(brew --prefix libomp)
     export LDFLAGS="-L\$(brew --prefix libomp)/lib"
     export CPPFLAGS="-I\$(brew --prefix libomp)/include -Xpreprocessor -fopenmp"
     ./build_openroad.sh --local

  ${BOLD}B. Chuẩn bị PDK sky130hd:${RESET}
     cd $ROOT
     ./scripts/prepare_sky130hd_platform.sh

  ${BOLD}C. Setup PATH lab:${RESET}
     ./setup.sh
     source ~/.zprofile
     source Sky130_Workspace/HammingCode_128bit/env_setup.sh

  ${BOLD}D. Chạy design mẫu:${RESET}
     cd Sky130_Workspace && ./run.sh HammingCode_128bit

  Hướng dẫn chi tiết: docs/HUONG_DAN_DAY_DU.md
  Quickstart 1 trang:  docs/QUICKSTART.md

EOF
ok "Bootstrap deps hoàn tất"

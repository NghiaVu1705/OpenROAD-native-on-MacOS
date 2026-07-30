#!/usr/bin/env bash
# =============================================================================
# prepare_sky130hd_platform.sh — Bổ sung file PDK sky130hd còn thiếu cho ORFS
# Chạy sau khi đã có ORFS_Source (đã clone, tốt nhất đã build xong).
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORFS="$ROOT/ORFS_Source"
PLAT="$ORFS/flow/platforms/sky130hd"
TEST_HD="$ORFS/tools/OpenROAD/test/sky130hd"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}  ✓${RESET} $*"; }
warn() { echo -e "${YELLOW}  ⚠${RESET} $*"; }
err()  { echo -e "${RED}  ✗${RESET} $*"; }

echo -e "${BOLD}Prepare sky130hd platform files${RESET}"
echo "  PLATFORM = $PLAT"

if [[ ! -d "$PLAT" ]]; then
  err "Không thấy $PLAT — hãy clone ORFS_Source trước (./scripts/bootstrap_macos.sh)"
  exit 1
fi

mkdir -p "$PLAT/lib" "$PLAT/lef" "$PLAT/gds"

# ─── Liberty + LEF từ OpenROAD test (có sẵn trong submodule) ─────────────────
if [[ -d "$TEST_HD" ]]; then
  for f in \
    sky130_fd_sc_hd__tt_025C_1v80.lib \
    sky130_fd_sc_hd__ff_n40C_1v95.lib \
    sky130_fd_sc_hd__ss_n40C_1v40.lib
  do
    if [[ -f "$TEST_HD/$f" ]]; then
      cp -n "$TEST_HD/$f" "$PLAT/lib/" 2>/dev/null || cp "$TEST_HD/$f" "$PLAT/lib/"
      ok "lib/$f"
    fi
  done
  for f in sky130_fd_sc_hd_merged.lef sky130_fd_sc_hd.lef; do
    if [[ -f "$TEST_HD/$f" ]]; then
      cp -n "$TEST_HD/$f" "$PLAT/lef/" 2>/dev/null || cp "$TEST_HD/$f" "$PLAT/lef/"
      ok "lef/$f"
    fi
  done
  if [[ -f "$TEST_HD/sky130hd.rcx_rules" ]]; then
    cp "$TEST_HD/sky130hd.rcx_rules" "$PLAT/rcx_patterns.rules"
    ok "rcx_patterns.rules (từ sky130hd.rcx_rules)"
  fi
else
  warn "Không có $TEST_HD — submodule OpenROAD chưa đủ?"
  warn "Chạy: cd ORFS_Source && git submodule update --init --recursive"
fi

# Fallback RCX từ sky130hs
if [[ ! -f "$PLAT/rcx_patterns.rules" && -f "$ORFS/flow/platforms/sky130hs/rcx_patterns.rules" ]]; then
  cp "$ORFS/flow/platforms/sky130hs/rcx_patterns.rules" "$PLAT/rcx_patterns.rules"
  ok "rcx_patterns.rules (fallback sky130hs)"
fi

# ─── GDS standard cells (merge từ efabless library nếu thiếu) ────────────────
GDS_OUT="$PLAT/gds/sky130_fd_sc_hd.gds"
if [[ -f "$GDS_OUT" && -s "$GDS_OUT" ]]; then
  ok "gds/sky130_fd_sc_hd.gds đã có ($(du -h "$GDS_OUT" | awk '{print $1}'))"
else
  warn "Chưa có sky130_fd_sc_hd.gds — đang tải & merge (cần mạng, ~vài phút)..."
  PY39="/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/bin/python3.9"
  [[ -x "$PY39" ]] || PY39="$(command -v python3.9 || true)"
  if [[ ! -x "$PY39" ]]; then
    err "Cần python3.9 + klayout để merge GDS"
    exit 1
  fi
  if ! "$PY39" -c "import klayout.db" 2>/dev/null; then
    err "Cần: python3.9 -m pip install --user klayout"
    exit 1
  fi

  TMP="${TMPDIR:-/tmp}/sky130_sc_hd_$$"
  rm -rf "$TMP"
  git clone --depth 1 \
    https://github.com/efabless/skywater-pdk-libs-sky130_fd_sc_hd.git \
    "$TMP"

  "$PY39" << PY
import klayout.db as pya
from pathlib import Path
paths = sorted(Path("$TMP").rglob("*.gds"))
print(f"Merging {len(paths)} GDS cells...")
layout = pya.Layout()
for i, p in enumerate(paths):
    layout.read(str(p))
    if (i + 1) % 100 == 0:
        print(f"  {i+1}/{len(paths)}")
out = Path("$GDS_OUT")
out.parent.mkdir(parents=True, exist_ok=True)
layout.write(str(out))
print(f"Wrote {out} ({out.stat().st_size} bytes, cells={layout.cells()})")
PY
  rm -rf "$TMP"
  ok "gds/sky130_fd_sc_hd.gds"
fi

# ─── Kiểm tra file bắt buộc ──────────────────────────────────────────────────
echo ""
echo "Kiểm tra file bắt buộc:"
NEED=(
  "$PLAT/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
  "$PLAT/lef/sky130_fd_sc_hd_merged.lef"
  "$PLAT/lef/sky130_fd_sc_hd.tlef"
  "$PLAT/rcx_patterns.rules"
  "$PLAT/gds/sky130_fd_sc_hd.gds"
)
FAIL=0
for f in "${NEED[@]}"; do
  if [[ -f "$f" && -s "$f" ]]; then
    ok "${f#$ORFS/}"
  else
    err "THIẾU: ${f#$ORFS/}"
    FAIL=1
  fi
done

if [[ $FAIL -ne 0 ]]; then
  err "Còn thiếu file — xem docs/HUONG_DAN_DAY_DU.md"
  exit 1
fi

echo ""
ok "sky130hd platform sẵn sàng cho P&R + GDS"

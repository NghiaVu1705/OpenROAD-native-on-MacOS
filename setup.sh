#!/usr/bin/env bash
# =============================================================================
# setup.sh — OpenROAD Project Installer
# =============================================================================
# Chạy file này MỘT LẦN sau khi copy/clone thư mục sang máy mới.
# Script sẽ:
#   1. Tự detect OPENROAD_HOME (vị trí thư mục này)
#   2. Kiểm tra tất cả công cụ đã cài chưa
#   3. Hỏi có muốn thêm PATH vào ~/.zprofile không
#   4. Thay thế username cũ trong tất cả scripts (nếu cần)
#
# Cách dùng:
#   cd /path/to/OpenROAD
#   ./setup.sh
# =============================================================================

set -euo pipefail

# ─── Màu sắc ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}  ✓${RESET} $*"; }
warn() { echo -e "${YELLOW}  ⚠${RESET} $*"; }
err()  { echo -e "${RED}  ✗${RESET} $*"; }
info() { echo -e "${BLUE}  →${RESET} $*"; }
hdr()  { echo -e "\n${BOLD}${CYAN}$*${RESET}"; }

# ─── Auto-detect OPENROAD_HOME ────────────────────────────────────────────────
OPENROAD_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          OpenROAD Project Setup — macOS Apple Silicon       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
info "OPENROAD_HOME = $OPENROAD_HOME"

# ─── Detect username ──────────────────────────────────────────────────────────
CURRENT_USER=$(whoami)
CURRENT_HOME="$HOME"

# ─── Detect Homebrew prefix ───────────────────────────────────────────────────
if command -v brew &>/dev/null; then
    HOMEBREW_PREFIX=$(brew --prefix)
else
    # Default ARM64
    HOMEBREW_PREFIX="/opt/homebrew"
    warn "Homebrew không tìm thấy. Giả sử: $HOMEBREW_PREFIX"
fi

# ─── Detect Python 3.9 ────────────────────────────────────────────────────────
PYTHON39=""
for candidate in \
    "$HOMEBREW_PREFIX/bin/python3.9" \
    "/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/bin/python3.9" \
    "$(which python3.9 2>/dev/null || true)"; do
    if [[ -x "$candidate" ]]; then
        PYTHON39="$candidate"
        break
    fi
done

# ─── STEP 1: Thay thế username cũ trong scripts ───────────────────────────────
hdr "BƯỚC 1: Cập nhật paths trong scripts"

# Tìm các username cũ (không phải username hiện tại)
OLD_USERS=$(grep -rh "/Users/[^/]*/" \
    "$OPENROAD_HOME/Sky130_Workspace" \
    "$OPENROAD_HOME/ASAP7_Workspace" \
    --include="*.sh" --include="*.py" --include="*.mk" \
    2>/dev/null \
    | grep -oP "/Users/\K[^/]+" \
    | sort -u \
    | grep -v "^$CURRENT_USER$" || true)

if [[ -n "$OLD_USERS" ]]; then
    echo "  Phát hiện username cũ trong scripts: $OLD_USERS"
    echo -n "  Thay tất cả bằng '$CURRENT_USER'? [Y/n] "
    read -r REPLY
    REPLY=${REPLY:-Y}
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        REPLACED=0
        for OLD_USER in $OLD_USERS; do
            while IFS= read -r -d '' f; do
                if grep -q "/Users/$OLD_USER" "$f" 2>/dev/null; then
                    sed -i '' "s|/Users/$OLD_USER|/Users/$CURRENT_USER|g" "$f"
                    info "  Fixed: ${f#$OPENROAD_HOME/}"
                    REPLACED=$((REPLACED+1))
                fi
            done < <(find \
                "$OPENROAD_HOME/Sky130_Workspace" \
                "$OPENROAD_HOME/ASAP7_Workspace" \
                -type f \( -name "*.sh" -o -name "*.py" -o -name "*.mk" -o -name "*.tcl" \) \
                -print0 2>/dev/null)
        done
        ok "Đã cập nhật $REPLACED files"
    fi
else
    ok "Không cần thay thế username (đã dùng '$CURRENT_USER' hoặc dùng auto-detect)"
fi

# ─── STEP 2: Kiểm tra công cụ ─────────────────────────────────────────────────
hdr "BƯỚC 2: Kiểm tra công cụ đã cài"

MISSING=()
FOUND=()

check_tool() {
    local name="$1"; local path="$2"; local version_cmd="${3:-}"
    if [[ -x "$path" ]]; then
        local ver=""
        if [[ -n "$version_cmd" ]]; then
            ver=" ($(eval "$version_cmd" 2>&1 | head -1 | sed 's/.*version //;s/ .*//'))"
        fi
        ok "$name$ver → $path"
        FOUND+=("$name")
    else
        err "$name → NOT FOUND: $path"
        MISSING+=("$name")
    fi
}

ORFS_DIR="$OPENROAD_HOME/ORFS_Source"

check_tool "openroad"  "$ORFS_DIR/tools/install/OpenROAD/bin/openroad"
check_tool "yosys"     "$ORFS_DIR/tools/install/yosys/bin/yosys"
check_tool "magic"     "$OPENROAD_HOME/tools/install/magic/bin/magic"
check_tool "netgen"    "$OPENROAD_HOME/tools/install/netgen/bin/netgen"
check_tool "iverilog"  "$HOMEBREW_PREFIX/bin/iverilog"
check_tool "verilator" "$HOMEBREW_PREFIX/bin/verilator"
check_tool "realpath"  "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin/realpath"
check_tool "sed(gnu)"  "$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin/sed"

# Python + klayout
if [[ -n "$PYTHON39" ]]; then
    ok "python3.9 → $PYTHON39"
    FOUND+=("python3.9")
    if "$PYTHON39" -c "import klayout.db" 2>/dev/null; then
        KLAYOUT_VER=$("$PYTHON39" -c "import klayout.db as p; print(p.__version__)")
        ok "klayout Python API ($KLAYOUT_VER)"
        FOUND+=("klayout")
    else
        err "klayout Python API → NOT FOUND (pip install klayout)"
        MISSING+=("klayout")
    fi

    COCOTB_CFG="$CURRENT_HOME/Library/Python/3.9/bin/cocotb-config"
    if [[ -x "$COCOTB_CFG" ]]; then
        COCOTB_VER=$("$COCOTB_CFG" --version 2>/dev/null || echo "?")
        ok "cocotb ($COCOTB_VER)"
        FOUND+=("cocotb")
    else
        err "cocotb → NOT FOUND (python3.9 -m pip install --user cocotb)"
        MISSING+=("cocotb")
    fi
else
    err "python3.9 → NOT FOUND (xcode-select --install)"
    MISSING+=("python3.9" "klayout" "cocotb")
fi

echo ""
echo "  Tìm thấy: ${#FOUND[@]} tools | Thiếu: ${#MISSING[@]} tools"

if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "Công cụ còn thiếu: ${MISSING[*]}"
    warn "Xem docs/HUONG_DAN_DAY_DU.md hoặc docs/QUICKSTART.md để biết cách cài"
fi

# ─── STEP 3: Ghi openroad.cfg ─────────────────────────────────────────────────
hdr "BƯỚC 3: Ghi cấu hình"

CFG="$OPENROAD_HOME/openroad.cfg"
cat > "$CFG" << CFGEOF
# =============================================================================
# openroad.cfg — OpenROAD Project Configuration
# Auto-generated by setup.sh on $(date)
# =============================================================================

# Đường dẫn gốc project (tự detect khi scripts chạy — không cần sửa)
# OPENROAD_HOME=/path/override   # Bỏ comment chỉ khi cần override

# Phiên bản Python
PYTHON_VERSION=3.9

# Homebrew prefix (tự detect — bỏ comment chỉ khi cần override)
# HOMEBREW_PREFIX=$HOMEBREW_PREFIX
CFGEOF

ok "Đã ghi: $CFG"

# ─── STEP 4: Hỏi thêm vào ~/.zprofile ────────────────────────────────────────
hdr "BƯỚC 4: Cấu hình PATH shell"

ZPROFILE="$CURRENT_HOME/.zprofile"
MARKER="# >>> OpenROAD PATH block <<<"

if grep -q "$MARKER" "$ZPROFILE" 2>/dev/null; then
    ok "PATH block đã có trong $ZPROFILE"
    echo -n "  Cập nhật lại? [y/N] "
    read -r REPLY2
    REPLY2=${REPLY2:-N}
    if [[ "$REPLY2" =~ ^[Yy]$ ]]; then
        # Xóa block cũ
        sed -i '' "/$MARKER/,/# <<< OpenROAD PATH block <<</d" "$ZPROFILE"
        WRITE_PATH=1
    else
        WRITE_PATH=0
    fi
else
    echo -n "  Thêm PATH của tất cả OpenROAD tools vào $ZPROFILE? [Y/n] "
    read -r REPLY3
    REPLY3=${REPLY3:-Y}
    WRITE_PATH=0
    [[ "$REPLY3" =~ ^[Yy]$ ]] && WRITE_PATH=1
fi

if [[ "${WRITE_PATH:-0}" -eq 1 ]]; then
    cat >> "$ZPROFILE" << PATHEOF

$MARKER
# OpenROAD tool stack — auto-generated by setup.sh
_ORFS="$ORFS_DIR"
export PATH="\$_ORFS/tools/install/OpenROAD/bin:\$PATH"
export PATH="\$_ORFS/tools/install/yosys/bin:\$PATH"
export PATH="$OPENROAD_HOME/tools/install/magic/bin:\$PATH"
export PATH="$OPENROAD_HOME/tools/install/netgen/bin:\$PATH"
export PATH="$OPENROAD_HOME/Sky130_Workspace/bin:\$PATH"
export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:\$PATH"
export PATH="$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:\$PATH"
export PATH="$HOMEBREW_PREFIX/bin:\$PATH"
export PATH="\$HOME/Library/Python/3.9/bin:\$PATH"
unset _ORFS
# <<< OpenROAD PATH block <<<
PATHEOF
    ok "Đã thêm vào $ZPROFILE"
    info "Chạy: source $ZPROFILE   (hoặc mở terminal mới)"
fi

# ─── STEP 5: Summary ──────────────────────────────────────────────────────────
hdr "KẾT QUẢ SETUP"

echo ""
echo -e "  ${BOLD}OPENROAD_HOME${RESET} = $OPENROAD_HOME"
echo ""
echo "  Các lệnh tiếp theo:"
echo ""
echo -e "  ${CYAN}# Kiểm tra môi trường${RESET}"
echo "  source $OPENROAD_HOME/Sky130_Workspace/HammingCode_128bit/env_setup.sh"
echo ""
echo -e "  ${CYAN}# Chạy kiểm thử chức năng${RESET}"
echo "  cd $OPENROAD_HOME/Sky130_Workspace/HammingCode_128bit/Verifications"
echo "  make SIM=icarus"
echo ""
echo -e "  ${CYAN}# Chạy flow RTL→GDSII hoàn chỉnh${RESET}"
echo "  $OPENROAD_HOME/Sky130_Workspace/HammingCode_128bit/run_flow_complete.sh --from 5"
echo ""
echo -e "  ${CYAN}# Chạy P&R cho bất kỳ design nào${RESET}"
echo "  cd $OPENROAD_HOME/Sky130_Workspace && ./run.sh HammingCode_128bit"
echo "  cd $OPENROAD_HOME/ASAP7_Workspace  && ./run.sh CamAI_SNN"
echo ""

if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}  ✓ Setup hoàn tất — tất cả tools sẵn sàng!${RESET}"
else
    echo -e "${YELLOW}${BOLD}  ⚠ Setup xong nhưng còn ${#MISSING[@]} tool chưa cài.${RESET}"
fi
echo ""

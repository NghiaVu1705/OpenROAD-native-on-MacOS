# Hướng dẫn Toàn diện: 
# OpenROAD trên macOS Apple Silicon (M1/M2/M3/M4/M5)
> Tác giả: Vũ Hiếu Nghĩa

> **Đối tượng:** Người dùng macOS mới — chưa có kinh nghiệm với OpenROAD / EDA tools.

> **Phạm vi:** Toàn bộ hệ thống — cài đặt, 2 workspace (Sky130HD & ASAP7), 3 thiết kế chip, kiểm thử, RTL → GDSII, sign-off

> **Thời gian setup lần đầu:** ~60–90 phút

---

## Mục lục

### PHẦN I — BẮT ĐẦU NHANH
1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Yêu cầu hệ thống](#2-yêu-cầu-hệ-thống)

**2A. [Nhận thư mục từ người khác — setup chỉ 1 lần](#2a-nhận-thư-mục-từ-người-khác--setup-nhanh)** ← **Đọc đây trước** nếu đã có thư mục OpenROAD

### PHẦN II — CÀI ĐẶT TỪ ĐẦU (BUILD FROM SCRATCH)
3. [Cài đặt công cụ cơ bản (Bước 1/7)](#3-cài-đặt-công-cụ-cơ-bản)
4. [Cài đặt OpenROAD Flow Scripts — ORFS (Bước 2/7)](#4-cài-đặt-openroad-flow-scripts)
5. [Cài đặt KLayout + Python dependencies (Bước 3/7)](#5-cài-đặt-klayout--python-dependencies)
6. [Build Magic VLSI — DRC (Bước 4/7)](#6-build-magic-vlsi)
7. [Build Netgen — LVS (Bước 5/7)](#7-build-netgen)
8. [Cài đặt Sky130A PDK cho Magic (Bước 6/7)](#8-cài-đặt-sky130a-pdk-cho-magic)
9. [Cấu hình PATH toàn hệ thống (Bước 7/7)](#9-cấu-hình-path-toàn-hệ-thống)

### PHẦN III — CẤU TRÚC DỰ ÁN
10. [Cấu trúc thư mục dự án](#10-cấu-trúc-thư-mục-dự-án)
11. [3 Thiết kế chip mẫu](#11-3-thiết-kế-chip-mẫu)

### PHẦN IV — LUỒNG THIẾT KẾ RTL → GDSII
12. [Chạy flow RTL → GDSII — Sky130HD](#12-chạy-flow-rtl--gdsii--sky130hd)

**12A. [Chi tiết từng giai đoạn P&R (Tcl commands)](#12a-chi-tiết-từng-giai-đoạn-pr-tcl-commands)** ← Synthesis → Floorplan → Place → CTS → Route → Finish
13. [Chạy flow RTL → GDSII — ASAP7](#13-chạy-flow-rtl--gdsii--asap7)

### PHẦN V — KIỂM THỬ CHỨC NĂNG (VERIFICATION)
14. [Chạy kiểm thử chức năng (cocotb)](#14-chạy-kiểm-thử-chức-năng-cocotb)

**14A. [Kiến trúc UVM chi tiết](#14a-kiến-trúc-uvm-chi-tiết)** ← Driver, Monitor, Scoreboard, Coverage, Sequences

### PHẦN VI — SIGN-OFF
15. [Sign-off: DRC + LVS + GDS](#15-sign-off-drc--lvs--gds)

### PHẦN VII — TẠO THIẾT KẾ MỚI
**20. [Tạo thiết kế mới từ con số 0](#20-tạo-thiết-kế-mới-từ-con-số-0)** ← Hướng dẫn 11 bước đầy đủ với ví dụ cụ thể

### PHẦN VIII — VẬN HÀNH & THAM KHẢO
16. [Đọc hiểu kết quả đầu ra](#16-đọc-hiểu-kết-quả-đầu-ra)
17. [Quy trình làm việc hàng ngày](#17-quy-trình-làm-việc-hàng-ngày)
18. [Xử lý lỗi thường gặp](#18-xử-lý-lỗi-thường-gặp)
19. [Tài nguyên tham khảo](#19-tài-nguyên-tham-khảo)

### PHỤ LỤC
- [Phụ lục A — Benchmark Hiệu Năng trên Apple M1](#phụ-lục-a--benchmark-hiệu-năng-trên-apple-m1)
- [Phụ lục B — 14 Vấn Đề Build & Giải Pháp](#phụ-lục-b--14-vấn-đề-build--giải-pháp-macos-m1)
- [Phụ lục C — So sánh Native vs Docker vs VM](#phụ-lục-c--so-sánh-native-vs-docker-vs-vm)
- [Phụ lục D — Tài liệu tham khảo](#phụ-lục-d--tài-liệu-tham-khảo)

---

## 1. Tổng quan hệ thống

### 1.1 OpenROAD là gì?

**OpenROAD** (Open Road towards Zero Barrier Electronic Design Automation) là bộ công cụ EDA (Electronic Design Automation) mã nguồn mở cho phép thiết kế chip từ mô tả RTL (Verilog) đến file GDSII sẵn sàng gửi nhà máy sản xuất — hoàn toàn miễn phí.

### 1.2 Luồng thiết kế tổng thể

```
Verilog RTL
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│  ORFS (OpenROAD Flow Scripts)                                │
│                                                              │
│  [1] Synthesis       Yosys        → netlist.v (~gates)       │
│  [2] Floorplan       OpenROAD     → floorplan.odb            │
│  [3] Placement       OpenROAD     → place.odb                │
│  [4] CTS             OpenROAD     → clock tree               │
│  [5] Routing         OpenROAD     → route.odb                │
│  [6] Final           OpenROAD     → 6_final.def              │
└──────────────────────────────────────────────────────────────┘
    │
    ▼
GDS Generation     KLayout Python API → 6_final.gds
    │
    ▼
┌─────────────────────────────────────┐
│  Sign-off                           │
│  Magic DRC  → DRC violations = 0?   │
│  Netgen LVS → layout = schematic?   │
└─────────────────────────────────────┘
    │
    ▼
Tape-out (Efabless Chipignite)
```

### 1.3 Hai công nghệ (PDK) được hỗ trợ

| PDK | Tên | Nút công nghệ | Mục đích |
|-----|-----|---------------|----------|
| **Sky130HD** | SkyWater 130nm | 130 nm (thực tế) | Tape-out thực, Efabless Chipignite |
| **ASAP7** | Arizona State 7nm | 7 nm (học thuật) | Nghiên cứu, không tape-out thực |

### 1.4 Ba thiết kế chip có sẵn

| Thiết kế | Mô tả | Sky130HD | ASAP7 |
|----------|-------|----------|-------|
| **HammingCode_128bit** | Bộ mã sửa lỗi SEC-DED Hamming(137,128) | ✅ P&R + DRC done | ✅ Config ready |
| **CamAI_SNN** | Mạng nơ-ron xung LIF (4→4→2 neurons) | ✅ Config ready | ✅ Config ready |
| **Bio_health** | Bộ xử lý tín hiệu sinh học ECG/PPG | ✅ Config ready | ✅ Config ready |

---

## 2. Yêu cầu hệ thống

| Yêu cầu | Tối thiểu | Khuyến nghị |
|---------|-----------|-------------|
| **macOS** | 13.0 Ventura | 14.0+ Sonoma / 15.x Sequoia |
| **CPU** | Apple M1 | Apple M2/M3 |
| **RAM** | 8 GB | 16 GB |
| **Ổ cứng trống** | 20 GB | 40 GB |
| **Internet** | Cần khi setup | Không cần sau đó |

**Kiểm tra chip:**
```bash
uname -m          # bắt buộc ra: arm64
sw_vers           # xem macOS version
sysctl hw.memsize # RAM (bytes)
```

---

## 2A. Nhận thư mục từ người khác — setup nhanh

> **Dành cho:** Người nhận được thư mục `OpenROAD/` đã build sẵn (qua USB, AirDrop, cloud), **không** cần build lại từ đầu.

### 2A.1 Điều kiện bắt buộc — kiểm tra trước khi bắt đầu

**Máy tính yêu cầu:** Apple Silicon (M1/M2/M3) — **KHÔNG chạy được trên Intel Mac**.
Tất cả binary đã được build cho kiến trúc `arm64`.

```bash
uname -m   # Phải ra: arm64
```

**Homebrew dependencies bắt buộc** — openroad binary link động đến các thư viện này:

```bash
# Cài tất cả dependencies cần thiết (chạy 1 lần)
brew install \
    tcl-tk@8 or-tools protobuf re2 highs scip \
    libomp qt@5 yaml-cpp spdlog fmt \
    coreutils gnu-sed icarus-verilog verilator

# Xcode CLT (để có python3.9)
xcode-select --install

# Python packages
python3.9 -m pip install --user klayout cocotb pyuvm
```

> **Tại sao cần những thứ này?** Binary `openroad` không đóng gói thư viện vào trong
> (không phải static build) — nó tìm `.dylib` trong `/opt/homebrew/opt/...` lúc chạy.
> Nếu thiếu một thư viện, openroad sẽ báo lỗi `Library not loaded`.

### 2A.2 Chạy setup.sh — chỉ 1 lần

Sau khi copy thư mục `OpenROAD/` vào bất kỳ vị trí nào trên máy:

```bash
cd /path/to/OpenROAD     # thay bằng đường dẫn thực tế của bạn
chmod +x setup.sh
./setup.sh
```

`setup.sh` sẽ tự động:

| Bước | Việc làm |
|------|----------|
| **1** | Phát hiện `OPENROAD_HOME` từ vị trí của chính nó |
| **2** | Tìm username cũ trong scripts → hỏi thay bằng username của bạn |
| **3** | Kiểm tra tất cả tools (`openroad`, `yosys`, `magic`, `netgen`, `iverilog`, `python3.9`, `klayout`) |
| **4** | Hỏi thêm PATH block vào `~/.zprofile` (khuyên chọn **Y**) |

Ví dụ output khi thành công:

```
╔══════════════════════════════════════════════════════════════╗
║          OpenROAD Project Setup — macOS Apple Silicon        ║
╚══════════════════════════════════════════════════════════════╝

→ OPENROAD_HOME = /Users/yourname/Documents/OpenROAD

BƯỚC 1: Cập nhật paths trong scripts
  Không cần thay thế username (đã dùng auto-detect)

BƯỚC 2: Kiểm tra công cụ đã cài
  ✓ openroad → .../OpenROAD/bin/openroad
  ✓ yosys    → .../OpenROAD/bin/yosys
  ✓ magic    → .../OpenROAD/bin/magic
  ✓ netgen   → .../OpenROAD/bin/netgen
  ✓ iverilog → /opt/homebrew/bin/iverilog
  ✓ python3.9 → ...
  ✓ klayout Python API (0.30.7)
  ✓ cocotb (2.0.1)

BƯỚC 4: Cấu hình PATH shell
  Thêm PATH của tất cả OpenROAD tools vào ~/.zprofile? [Y/n] Y
  ✓ Đã thêm vào ~/.zprofile

✓ Setup hoàn tất — tất cả tools sẵn sàng!
```

### 2A.3 Kích hoạt môi trường và chạy thử

```bash
# Kích hoạt PATH (hoặc mở terminal mới)
source ~/.zprofile

# Kiểm tra nhanh
source OpenROAD/Sky130_Workspace/HammingCode_128bit/env_setup.sh

# Chạy thử DRC (kiểm tra toàn bộ chuỗi công cụ)
OpenROAD/Sky130_Workspace/HammingCode_128bit/run_flow_complete.sh --only 6
# Kết quả mong đợi: [PASS] Magic DRC: CLEAN (0 violations)
```

### 2A.4 Vì sao không cần sửa paths thủ công?

Tất cả scripts đã được viết lại theo chuẩn **portable** — tự detect đường dẫn từ vị trí của chính mình:

| Loại file | Kỹ thuật |
|-----------|----------|
| Shell scripts (`.sh`) | `BASH_SOURCE[0]` → tính OPENROAD_HOME tương đối |
| Python scripts (`.py`) | `Path(__file__).resolve().parent` → tính OPENROAD_HOME |
| Makefile (`config.mk`) | `$(dir $(abspath $(lastword $(MAKEFILE_LIST))))` |
| Verifications/Makefile | `MAKEFILE_DIR` từ `MAKEFILE_LIST` + cocotb auto-detect |

Không có file nào chứa `/Users/username/...` cứng — thư mục hoạt động ở bất kỳ đường dẫn nào.

### 2A.5 Tóm tắt nhanh — copy sang máy mới

```
Máy nguồn                          Máy đích (Apple Silicon M1/M2/M3)
─────────────────                  ──────────────────────────────────
OpenROAD/  ──── copy ────────────→ /bất/kỳ/đường/dẫn/OpenROAD/
                                   │
                                   ├─ 1. brew install <deps>       (~10 phút)
                                   ├─ 2. xcode-select --install    (~5 phút)
                                   ├─ 3. pip install klayout cocotb pyuvm
                                   ├─ 4. ./setup.sh                (~1 phút)
                                   └─ 5. source ~/.zprofile → chạy được!
```

> **Lưu ý:** Nếu máy đích là **Intel Mac** → phải build lại toàn bộ từ phần 3.

---

## 3. Cài đặt công cụ cơ bản

### 3.1 Xcode Command Line Tools

```bash
xcode-select --install
```

Popup hiện ra → nhấn **Install** → đợi 5–10 phút.

Xác nhận:
```bash
xcode-select -p
# /Library/Developer/CommandLineTools

python3.9 --version
# Python 3.9.6   ← có sẵn trong Xcode CLT, bắt buộc cho ORFS
```

### 3.2 Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Thêm Homebrew vào PATH (làm theo hướng dẫn sau khi cài)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Xác nhận: `brew --version`

### 3.3 Tất cả packages cần thiết

```bash
brew install \
  icarus-verilog \
  verilator \
  gtkwave \
  gnu-sed \
  coreutils \
  cmake \
  ninja \
  git \
  wget \
  tcl-tk \
  cairo \
  fontconfig \
  freetype \
  libx11 \
  pkg-config \
  libomp \
  bison \
  flex \
  swig@4
```

> **Giải thích một số packages quan trọng:**
> - `gnu-sed`, `coreutils` — ORFS cần GNU `realpath` và `sed`, không dùng được phiên bản BSD của macOS
> - `libomp` — OpenMP cho OpenROAD build (macOS M1 không có native OpenMP)
> - `swig@4` — language binding cho Yosys/OpenROAD
> - `icarus-verilog`, `verilator` — simulator cho kiểm thử cocotb

### 3.4 Thêm GNU tools vào PATH vĩnh viễn

Mở file `~/.zprofile` (hoặc `~/.zshrc`) và thêm:

```bash
cat >> ~/.zprofile << 'EOF'

# ─── OpenROAD / EDA Environment ───────────────────────────────
# GNU coreutils (realpath, etc.) — bắt buộc cho ORFS
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
# GNU sed — bắt buộc cho Magic build
export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
# Python user tools (cocotb-config, etc.)
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
# ──────────────────────────────────────────────────────────────
EOF

source ~/.zprofile
```

Xác nhận:
```bash
realpath --version    # GNU coreutils ...
sed --version         # GNU sed ...
which python3.9       # /Library/Developer/CommandLineTools/.../python3.9
```

---

## 4. Cài đặt OpenROAD Flow Scripts

ORFS chứa OpenROAD (P&R), Yosys (synthesis), và tất cả PDK files.

### 4.1 Clone

```bash
mkdir -p ~/Documents/OpenROAD
cd ~/Documents/OpenROAD

git clone --recursive \
  https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git \
  ORFS_Source

cd ORFS_Source
```

> ⚠️ `--recursive` bắt buộc để lấy submodules (OpenROAD, Yosys, PDK platforms)

### 4.2 Build (Yosys + OpenROAD)

```bash
cd ~/Documents/OpenROAD/ORFS_Source

# Build tất cả tools — mất 30–60 phút tùy máy
./build_openroad.sh --local
```

**Nếu gặp lỗi OpenMP:**
```bash
brew install libomp

export OpenMP_ROOT=$(brew --prefix libomp)
export CC=clang
export CXX=clang++
export LDFLAGS="-L$(brew --prefix libomp)/lib"
export CPPFLAGS="-I$(brew --prefix libomp)/include -Xpreprocessor -fopenmp"

./build_openroad.sh --local
```

**Nếu gặp lỗi FLEX:**
```bash
FLEX_INCLUDE_DIRS=/opt/homebrew/opt/flex/include \
  ./build_openroad.sh --local
```

### 4.3 Xác nhận build thành công

```bash
~/Documents/OpenROAD/ORFS_Source/tools/install/OpenROAD/bin/openroad --version
# OpenROAD vXXQX-XXXX-gXXXXXXXX

~/Documents/OpenROAD/ORFS_Source/tools/install/yosys/bin/yosys --version
# Yosys 0.xx (git sha1 ...)
```

---

## 5. Cài đặt KLayout + Python dependencies

### 5.1 KLayout Python API

KLayout dùng để tạo GDS từ DEF. Trên Apple Silicon **chỉ dùng Python API** (không dùng binary):

```bash
python3.9 -m pip install --user klayout
```

Xác nhận:
```bash
python3.9 -c "import klayout.db as pya; print(f'KLayout {pya.__version__} OK')"
# KLayout 0.30.x OK
```

### 5.2 cocotb, pyuvm và thư viện kiểm thử

```bash
python3.9 -m pip install --user \
  "cocotb>=1.9.0" \
  "cocotb-bus>=0.2.1" \
  "pyuvm>=3.0.0" \
  pytest \
  numpy \
  matplotlib
```

Xác nhận:
```bash
~/Library/Python/3.9/bin/cocotb-config --version
# 1.x.x hoặc 2.x.x
```

---

## 6. Build Magic VLSI

Magic là công cụ DRC layout và trích xuất netlist cho sign-off.

### 6.1 Clone và build

```bash
mkdir -p ~/Documents/OpenROAD/tools
cd ~/Documents/OpenROAD

git clone https://github.com/RTimothyEdwards/magic.git magic_src
cd magic_src

# Configure với đúng paths Homebrew ARM64
./configure \
  --prefix=$HOME/Documents/OpenROAD/tools/install/magic \
  --x-includes=/opt/homebrew/include \
  --x-libraries=/opt/homebrew/lib \
  CPPFLAGS="-I/opt/homebrew/include" \
  LDFLAGS="-L/opt/homebrew/lib \
           -L/opt/homebrew/opt/cairo/lib \
           -L/opt/homebrew/opt/fontconfig/lib \
           -L/opt/homebrew/opt/freetype/lib"

# Patch Makefile để dùng GNU sed (macOS BSD sed không tương thích)
sed -i.bak \
  's|^SED\s*=.*|SED = /opt/homebrew/opt/gnu-sed/libexec/gnubin/sed|' \
  defs.mak

# Build và install
make -j$(sysctl -n hw.logicalcpu)
make install
```

### 6.2 Xác nhận

```bash
~/Documents/OpenROAD/tools/install/magic/bin/magic --version
# 8.3.xxx
```

---

## 7. Build Netgen

Netgen dùng để kiểm tra LVS (Layout vs Schematic).

```bash
cd ~/Documents/OpenROAD

git clone https://github.com/RTimothyEdwards/netgen.git netgen_src
cd netgen_src

./configure \
  --prefix=$HOME/Documents/OpenROAD/tools/install/netgen \
  CFLAGS="-Wno-error=implicit-function-declaration"

make -j$(sysctl -n hw.logicalcpu)

# Tạo thư mục python nếu thiếu
mkdir -p ~/Documents/OpenROAD/tools/install/netgen/lib/python3.9/

make install
```

Xác nhận:
```bash
~/Documents/OpenROAD/tools/install/netgen/bin/netgen 2>&1 | head -1
# Netgen 1.5.xxx: Copyright ...
```

---

## 8. Cài đặt Sky130A PDK cho Magic

Magic cần file `sky130A.tech` để biết DRC rules của công nghệ Sky130.

```bash
cd ~/Documents/OpenROAD

# Clone open_pdks (chứa tech files cho mọi PDK)
git clone https://github.com/RTimothyEdwards/open_pdks.git open_pdks

# Copy tech file vào Magic sys directory
MAGIC_SYS=~/Documents/OpenROAD/tools/install/magic/lib/magic/sys

cp open_pdks/sky130/magic/sky130.tech    $MAGIC_SYS/sky130A.tech
cp open_pdks/sky130/magic/sky130.magicrc $MAGIC_SYS/sky130A.magicrc
```

Xác nhận:
```bash
ls ~/Documents/OpenROAD/tools/install/magic/lib/magic/sys/sky130A.*
# sky130A.magicrc  sky130A.tech
```

> **Lưu ý quan trọng:** File `sky130A.magicrc` là template chưa xử lý (chứa placeholder `TECHNAME`). Khi chạy Magic batch DRC, **không dùng `-rcfile sky130A.magicrc`** — dùng `-T sky130A` là đủ (tech đã load từ flag `-T`).

---

## 9. Cấu hình PATH toàn hệ thống

Thêm **tất cả** tool paths vào `~/.zprofile`:

```bash
cat >> ~/.zprofile << 'EOF'

# ─── OpenROAD Full Tool Stack ─────────────────────────────────
OPENROAD_HOME="$HOME/Documents/OpenROAD"

# ORFS tools
export PATH="$OPENROAD_HOME/ORFS_Source/tools/install/OpenROAD/bin:$PATH"
export PATH="$OPENROAD_HOME/ORFS_Source/tools/install/yosys/bin:$PATH"

# Sign-off tools
export PATH="$OPENROAD_HOME/tools/install/magic/bin:$PATH"
export PATH="$OPENROAD_HOME/tools/install/netgen/bin:$PATH"

# KLayout CLI wrapper (ARM64 Python)
export PATH="$OPENROAD_HOME/Sky130_Workspace/bin:$PATH"
# ──────────────────────────────────────────────────────────────
EOF

source ~/.zprofile
```

### Xác nhận toàn bộ tool stack

```bash
echo "=== Tool Check ===" && \
echo "openroad : $(openroad --version 2>&1 | head -1)" && \
echo "yosys    : $(yosys --version 2>&1 | head -1)" && \
echo "magic    : $(magic --version 2>&1 | grep 'revision' | head -1)" && \
echo "iverilog : $(iverilog -V 2>&1 | head -1)" && \
echo "verilator: $(verilator --version 2>&1 | head -1)" && \
echo "python3.9: $(python3.9 --version)" && \
echo "realpath : $(realpath --version | head -1)"
```

Kết quả mong đợi:
```
=== Tool Check ===
openroad : OpenROAD v26Q1-...
yosys    : Yosys 0.63 ...
magic    : 8.3 revision 625
iverilog : Icarus Verilog version 13.x
verilator: Verilator 5.x
python3.9: Python 3.9.6
realpath : realpath (GNU coreutils) ...
```

---

## 10. Cấu trúc thư mục dự án

```
~/Documents/OpenROAD/
│
├── ORFS_Source/                    ← OpenROAD Flow Scripts (clone từ GitHub)
│   ├── flow/
│   │   ├── platforms/
│   │   │   ├── sky130hd/           ← PDK Sky130HD (130nm, thực)
│   │   │   └── asap7/              ← PDK ASAP7 (7nm, học thuật)
│   │   ├── designs/                ← ORFS sample designs (gcd, etc.)
│   │   └── results/                ← OUTPUT: kết quả P&R
│   │       ├── sky130hd/<design>/base/
│   │       │   ├── 1_synth.v       ← Synthesis netlist
│   │       │   ├── 6_final.def     ← Final layout (DEF)
│   │       │   ├── 6_final.gds     ← GDSII (file gửi nhà máy)
│   │       │   └── 6_final.spef    ← Parasitics
│   │       └── asap7/<design>/base/
│   └── tools/install/              ← OpenROAD + Yosys binaries
│
├── Sky130_Workspace/               ← Workspace thiết kế Sky130HD
│   ├── bin/
│   │   └── klayout                 ← KLayout CLI wrapper (Python)
│   ├── run.sh                      ← Script chạy bất kỳ project nào
│   ├── CamAI_SNN/                  ← Project 1: SNN accelerator
│   │   ├── src/CamAI_SNN.v
│   │   ├── config.mk
│   │   ├── constraints/constraint.sdc
│   │   ├── Verifications/          ← cocotb tests
│   │   └── Docs/
│   ├── Bio_health/                 ← Project 2: ECG/PPG processor
│   │   ├── src/Bio_health.v
│   │   ├── config.mk
│   │   ├── constraints/constraint.sdc
│   │   └── Verifications/
│   └── HammingCode_128bit/         ← Project 3: SEC-DED Hamming
│       ├── src/HammingCode_128bit.v
│       ├── config.mk
│       ├── constraints/constraint.sdc
│       ├── reference/hamming_golden.py
│       ├── Verifications/
│       ├── Docs/algorithm.md
│       ├── env_setup.sh            ← Source để setup PATH
│       ├── run_flow_complete.sh    ← Flow RTL→GDSII hoàn chỉnh
│       └── run_def2gds.py          ← GDS generation script
│
├── ASAP7_Workspace/                ← Workspace thiết kế ASAP7
│   ├── run.sh
│   ├── CamAI_SNN/
│   ├── Bio_health/
│   └── HammingCode_128bit/
│
├── tools/                          ← Sign-off tools (build từ source)
│   └── install/
│       ├── magic/bin/magic
│       └── netgen/bin/netgen
│
├── open_pdks/                      ← PDK files (sky130A.tech, etc.)
├── magic_src/                      ← Magic source code
├── netgen_src/                     ← Netgen source code
└── ReSearchDocument/               ← Tài liệu (bạn đang đọc)
```

---

## 11. Ba thiết kế chip mẫu

### 11.1 HammingCode_128bit — Bộ mã sửa lỗi SEC-DED

```
Chức năng : Mã hóa 128-bit data → 137-bit codeword có khả năng:
              - SEC: sửa tự động 1-bit lỗi
              - DED: phát hiện (không sửa) 2-bit lỗi
Kiến trúc : Encoder + Decoder thuần tổ hợp, wrapped trong
             pipeline 1 chu kỳ, clock 100 MHz
Ứng dụng  : Bảo vệ bộ nhớ SRAM/DRAM, bộ đệm cache
```

| Thông số | Sky130HD |
|---------|----------|
| Diện tích | ~21,238 µm² |
| Standard cells | ~1,500–2,500 |
| Clock | 100 MHz |
| P&R status | ✅ Hoàn thành + DRC CLEAN |

### 11.2 CamAI_SNN — Spiking Neural Network

```
Chức năng : Mạng nơ-ron xung LIF (Leaky Integrate-and-Fire)
              4 input → 4 hidden → 2 output neurons
              Xử lý spike theo từng clock cycle
Kiến trúc : Fully combinational + registered membrane potentials
             DATA_W=8 bit, THRESHOLD=0xC0, LEAK=0x08
Ứng dụng  : Edge AI, nhận dạng pattern năng lượng thấp
```

### 11.3 Bio_health — Biosignal Processor

```
Chức năng : Xử lý tín hiệu sinh học ECG/PPG
              - Moving average filter (window=8)
              - Peak detection (threshold-based)
              - Heart rate computation
Kiến trúc : 12-bit ADC input, FIFO depth=16, pipeline
Ứng dụng  : Thiết bị y tế đeo tay, IoT sức khỏe
```

---

## 12. Chạy flow RTL → GDSII — Sky130HD

### 12.1 Cách nhanh nhất: dùng run.sh

```bash
cd ~/Documents/OpenROAD/Sky130_Workspace

# Chạy HammingCode_128bit
./run.sh HammingCode_128bit

# Chạy CamAI_SNN
./run.sh CamAI_SNN

# Chạy Bio_health
./run.sh Bio_health
```

Script tự động:
1. Setup PATH
2. Gọi ORFS `make` với đúng `DESIGN_CONFIG`
3. Chạy synthesis → floorplan → placement → CTS → routing → final

**Output** tại:
```
ORFS_Source/flow/results/sky130hd/<DESIGN>/base/
  ├── 1_synth.v       ← gate-level netlist
  ├── 6_final.def     ← final layout
  ├── 6_final.odb     ← OpenROAD database
  └── 6_final.spef    ← timing parasitics
```

### 12.2 Chạy thủ công từng bước

```bash
# Setup PATH
source ~/Documents/OpenROAD/Sky130_Workspace/HammingCode_128bit/env_setup.sh

cd ~/Documents/OpenROAD/ORFS_Source/flow

# Định nghĩa config (thay tên design)
CONFIG=~/Documents/OpenROAD/Sky130_Workspace/HammingCode_128bit/config.mk

# Chạy từng bước riêng
make DESIGN_CONFIG=$CONFIG synth            # Bước 1: Synthesis
make DESIGN_CONFIG=$CONFIG floorplan        # Bước 2: Floorplan
make DESIGN_CONFIG=$CONFIG place            # Bước 3: Placement
make DESIGN_CONFIG=$CONFIG cts             # Bước 4: Clock Tree
make DESIGN_CONFIG=$CONFIG route           # Bước 5: Routing
make DESIGN_CONFIG=$CONFIG finish          # Bước 6: Finishing

# Hoặc chạy thẳng đến final
make DESIGN_CONFIG=$CONFIG 6_final.def
```

### 12.3 Kết quả quan trọng cần xem

```bash
# Xem timing report
cat ORFS_Source/flow/logs/sky130hd/HammingCode_128bit/base/6_report.log | \
  grep -E "WNS|TNS|Power|Area"

# Kết quả mẫu:
# [INFO] Design Area    : 21238 µm² @ 76% utilization
# [INFO] WNS            : -0.xx ns   (nhỏ hơn 0 = setup violation nhỏ)
# [INFO] Power          : x.xx mW
```

**Giải thích WNS (Worst Negative Slack):**
- `WNS = 0` → timing sạch 100%
- `WNS < 0` → có setup violation, nhưng nếu nhỏ (<1ns) thường chấp nhận được ở giai đoạn học
- Để cải thiện: tăng `CLOCK_PERIOD` trong `config.mk` (giảm tốc độ clock)

---

## 12A. Chi tiết từng giai đoạn P&R (Tcl commands)

> Phần này mô tả chi tiết từng stage của OpenROAD P&R flow — hữu ích khi cần debug hoặc chạy từng bước riêng lẻ.

### Giai đoạn 1 — Synthesis (Yosys)

**Công cụ:** Yosys 0.63 | **Input:** `.v` RTL | **Output:** `1_synth.odb`

```bash
# Chỉ chạy synthesis
make DESIGN_CONFIG=.../config.mk EQUIVALENCE_CHECK=0 do-synth

# Output files:
# results/.../1_1_yosys_canonicalize.rtlil  ← IR sau canonicalize
# results/.../1_2_yosys.sdc                  ← SDC propagated
# results/.../1_2_yosys.v                    ← Gate-level netlist ★
# results/.../1_synth.odb                    ← OpenROAD database

# Kiểm tra kết quả
cat reports/.../synth_stat.txt
# Number of cells: 442
# sky130_fd_sc_hd__dfxtp_1: 32  (flip-flops = độ phức tạp logic)
```

### Giai đoạn 2 — Floorplan (OpenROAD)

**Mục đích:** Xác định kích thước chip, vị trí IO pins, power grid (PDN)
**Input:** `1_synth.odb` | **Output:** `2_floorplan.odb`

```bash
make DESIGN_CONFIG=.../config.mk EQUIVALENCE_CHECK=0 do-floorplan
```

Các Tcl commands quan trọng:
```tcl
# Xác định die/core area theo utilization
initialize_floorplan \
    -utilization    40 \     # % diện tích dùng cells
    -aspect_ratio   1  \     # vuông (width/height)
    -core_space     2        # μm lề

# Đặt IO pins lên boundary chip
place_pins -hor_layers met2 -ver_layers met3

# Tap cell: ngăn latch-up effect
tapcell -distance 14 \
        -tapcell_master "sky130_fd_sc_hd__tapvpwrvgnd_1" \
        -endcap_master  "sky130_fd_sc_hd__decap_3"

# Power Distribution Network
add_global_connection -net VDD -pin_pattern "^VPB$" -power
add_global_connection -net VSS -pin_pattern "^VNB$" -ground
pdngen
```

### Giai đoạn 3 — Placement (OpenROAD)

**Mục đích:** Đặt standard cells, tối ưu timing | **Output:** `3_place.odb`

```bash
make DESIGN_CONFIG=.../config.mk EQUIVALENCE_CHECK=0 do-place
```

```tcl
global_placement -density 0.60     # đặt cells theo mật độ
place_pins -hor_layers met2 -ver_layers met3

estimate_parasitics -placement      # ước lượng RC
repair_design                       # fix max cap/slew violations
repair_timing -setup                # fix setup timing violations

detailed_placement                  # legalize vị trí cells
check_placement -verbose

report_wns    # Worst Negative Slack → phải gần 0
report_tns    # Total Negative Slack → phải = 0
```

Sub-steps output:
```
3_1_place_gp_skip_io.odb   ← Global place (skip IO)
3_2_place_iop.odb          ← IO placement
3_3_place_gp.odb           ← Global placement
3_4_place_resized.odb      ← Sau timing repair
3_5_place_dp.odb           ← Detail placement ★
```

### Giai đoạn 4 — CTS: Clock Tree Synthesis

**Mục đích:** Xây cây phân phối clock, cân bằng skew | **Output:** `4_cts.odb`

```bash
make DESIGN_CONFIG=.../config.mk EQUIVALENCE_CHECK=0 do-cts
```

```tcl
# Xây clock tree với buffer cells
clock_tree_synthesis \
    -root_buf   "sky130_fd_sc_hd__clkbuf_4" \
    -buf_list   "sky130_fd_sc_hd__clkbuf_4" \
    -wire_unit  20

set_propagated_clock [all_clocks]
estimate_parasitics -global_routing
repair_timing -setup -hold           # fix cả setup và hold

detailed_placement                   # re-legalize sau thêm buffer

report_clock_skew                    # skew phải < 100–200 ps
report_checks -path_delay min_max -fields {slew cap nets fanout}
```

### Giai đoạn 5 — Routing (OpenROAD — TritonRoute)

**Mục đích:** Vẽ dây kim loại kết nối cells | **Output:** `5_route.odb`
**Đây là giai đoạn chậm nhất (~72% tổng thời gian), dùng 8 threads.**

```bash
make DESIGN_CONFIG=.../config.mk EQUIVALENCE_CHECK=0 do-route
```

```tcl
# Global routing: lập kế hoạch đường dây theo layer
set_global_routing_layer_adjustment met1 0.65
set_routing_layers -signal "met1-met5" -clock "met3-met5"
global_route -congestion_iterations 30 -verbose

# Detail routing (TritonRoute): vẽ dây chính xác
detailed_route \
    -output_drc  results/.../5_route_drc.rpt \
    -verbose 0

# Filler cells: lấp khoảng trống giữa cells
filler_placement "sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2 \
                  sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_8"
check_placement
```

DRC sau routing — số lý tưởng là 0:
```bash
cat reports/.../5_route_drc.rpt
# [DRC] Number of violations: 0
```

### Giai đoạn 6 — Finish (OpenROAD)

**Mục đích:** Metal density fill, final reports, xuất DEF/SPEF | **Output:** `6_final.*`

```bash
make DESIGN_CONFIG=.../config.mk EQUIVALENCE_CHECK=0 do-finish
```

```tcl
density_fill -rules platforms/sky130hd/fill.json   # antenna fill

# Final timing/power reports
report_design_area
report_power    -corner "tt_025C_1v80"
report_timing   -path_count 10 -fields {slew cap nets fanout}
report_tns;  report_wns

# Xuất kết quả
write_def     results/.../6_final.def     # ★ input cho GDS step
write_verilog results/.../6_final.v       # ★ gate-level netlist
write_spef    results/.../6_final.spef    # parasitic RC
```

Output files quan trọng:
```
6_final.odb    ← Layout database (2–5 MB tùy design)
6_final.def    ← Layout text (→ GDS generation)
6_final.v      ← Post-route netlist (→ LVS)
6_final.spef   ← Parasitics RC (→ post-route STA)
```

### Đọc báo cáo sau flow

```bash
RESULTS=ORFS_Source/flow/results/sky130hd/MyDesign/base
REPORTS=ORFS_Source/flow/reports/sky130hd/MyDesign/base

# Timing tổng kết
cat $REPORTS/6_finish.rpt | grep -A5 "WNS\|TNS\|Power"

# Cell count và area
cat $REPORTS/synth_stat.txt

# Routing violations
cat $REPORTS/5_route_drc.rpt

# Congestion map (routing)
cat $REPORTS/5_global_route.rpt

# Power breakdown
grep -A10 "Group" $REPORTS/6_finish.rpt
```

---

## 13. Chạy flow RTL → GDSII — ASAP7

ASAP7 là PDK học thuật 7nm — không dùng tape-out thực nhưng hữu ích cho nghiên cứu và so sánh hiệu năng.

```bash
cd ~/Documents/OpenROAD/ASAP7_Workspace

# Chạy bất kỳ design
./run.sh HammingCode_128bit
./run.sh CamAI_SNN
./run.sh Bio_health
```

**Output** tại:
```
ORFS_Source/flow/results/asap7/<DESIGN>/base/
```

> **So sánh Sky130HD vs ASAP7:**
> - ASAP7 cho diện tích nhỏ hơn ~20x, power thấp hơn ~5x
> - ASAP7 timing chặt hơn nhiều → WNS thường âm lớn hơn
> - GDS từ ASAP7 không dùng cho Efabless tape-out

---

## 14. Chạy kiểm thử chức năng (cocotb)

Kiểm thử chức năng xác nhận logic Verilog đúng trước khi đưa vào P&R.

### 14.1 Chạy test cho HammingCode_128bit

```bash
cd ~/Documents/OpenROAD/Sky130_Workspace/HammingCode_128bit/Verifications

# Chạy với Icarus Verilog (nhanh, đơn giản)
make SIM=icarus

# Chạy với Verilator (chặt hơn, phát hiện nhiều lỗi hơn)
make SIM=verilator
```

**8 test cases:**

| Test | Mô tả | Kỳ vọng |
|------|-------|---------|
| `test_smoke` | Encode/decode data = 0 | PASS |
| `test_encoder_random` | 500 vector ngẫu nhiên vs Python golden | PASS (bit-exact) |
| `test_decoder_no_error` | 500 codeword sạch | PASS |
| `test_sec_exhaustive` | Flip từng bit 1..136 → kiểm tra SEC | PASS (100%) |
| `test_ded_random` | 500 cặp lỗi 2-bit → kiểm tra DED | PASS (100%) |
| `test_parity_bit_errors` | 8 vị trí parity → data không đổi | PASS |
| `test_pipeline_throughput` | 100 cycles liên tục | PASS |
| `test_roundtrip` | 200 vectors encode→decode | PASS |

**Kết quả mong đợi:**
```
test_smoke                 PASS
test_encoder_random        PASS
test_decoder_no_error      PASS
test_sec_exhaustive        PASS
test_ded_random            PASS
test_parity_bit_errors     PASS
test_pipeline_throughput   PASS
test_roundtrip             PASS
──────────────────────────────
8 passed, 0 failed in X.Xs
```

### 14.2 Chạy test cho CamAI_SNN

```bash
cd ~/Documents/OpenROAD/Sky130_Workspace/CamAI_SNN/Verifications
make SIM=icarus
```

### 14.3 Chạy test cho Bio_health

```bash
cd ~/Documents/OpenROAD/Sky130_Workspace/Bio_health/Verifications
make SIM=icarus
```

### 14.4 Xem waveform

Sau khi chạy test, waveform được lưu tại `waves/`:
```bash
gtkwave waves/HammingCode_128bit.fst &
```

### 14.5 Chạy 1 test cụ thể

```bash
TESTCASE=test_sec_exhaustive make SIM=icarus
```

### 14.6 Cài lại Python dependencies nếu cần

```bash
cd Verifications
python3.9 -m pip install --user -r requirements.txt
```

---

## 14A. Kiến trúc UVM chi tiết

> Phần này dành cho người muốn hiểu sâu về cấu trúc testbench pyUVM — hữu ích khi viết testbench mới hoặc debug verification.

### Sơ đồ tổng thể UVM Environment

```
┌─────────────────────────── UVM Environment ────────────────────────────┐
│                                                                        │
│  ┌─────────────── Agent ─────────────────┐                             │
│  │                                       │                             │
│  │  ┌──────────┐    ┌──────────────┐     │     ┌───────────────────┐   │
│  │  │Sequencer │───▶│   Driver     │─────┼───▶ │    DUT (RTL)      │   │
│  │  │(seqr)    │    │(drives pins) │     │     │                   │   │
│  │  └──────────┘    └──────────────┘     │     │  .v source file   │   │
│  │       ▲                               │     └────────┬──────────┘   │
│  │  ┌────┴──────┐   ┌───────────────┐    │              │              │
│  │  │ Sequence  │   │   Monitor     │◀───┼──────────────┘              │
│  │  │(test data)│   │(observe pins) │    │    (observe output signals) │
│  │  └───────────┘   └───────┬───────┘    │                             │
│  └──────────────────────────│────────────┘                             │
│                             │ Analysis Port                            │
│              ┌──────────────┼──────────────┐                           │
│              ▼              ▼              ▼                           │
│       ┌────────────┐ ┌────────────┐                                    │
│       │Scoreboard  │ │  Coverage  │                                    │
│       │(check pass │ │(bins/bins) │                                    │
│       │  /fail)    │ │            │                                    │
│       └────────────┘ └────────────┘                                    │
└────────────────────────────────────────────────────────────────────────┘
```

### Vai trò từng thành phần

| Thành phần | Class pyUVM | File | Vai trò |
|-----------|------------|------|---------|
| **Sequence** | `uvm_sequence` | `tb/sequences/` | Tạo luồng transaction (test data) |
| **Sequencer** | `uvm_sequencer` | (tạo trong Agent) | Điều phối sequence → driver |
| **Driver** | `uvm_driver` | `tb/env/agent/driver.py` | Gán giá trị lên DUT pins |
| **Monitor** | `uvm_monitor` | `tb/env/agent/monitor.py` | Đọc DUT pins, tạo transaction |
| **Scoreboard** | `uvm_component` | `tb/env/scoreboard/` | So sánh kết quả vs expected |
| **Coverage** | `uvm_subscriber` | `tb/env/coverage/` | Đo coverage bins |
| **Agent** | `uvm_agent` | `tb/env/env.py` | Gom driver + monitor + sequencer |
| **Env** | `uvm_env` | `tb/env/env.py` | Gom agent + scoreboard + coverage |
| **Test** | `uvm_test` | `tb/tests/` | Điểm vào, tạo env + chạy sequence |

### Luồng thực thi chi tiết

```
make SIM=icarus
     │
     ▼
cocotb: iverilog -g2012 -o /tmp/sim Design.v
     │
     ▼
cocotb: vvp /tmp/sim -fst
     │
     ▼
Python test function chạy (async coroutine)
     │
     ├─ Clock 5–10ns khởi động
     ├─ Reset 5 cycles
     ├─ uvm_root().run_test("SmokeTest")  ← UVM phase engine bắt đầu
     │     ├─ build_phase  : tạo Env → Agent → Driver/Monitor/Seqr
     │     ├─ connect_phase: nối Analysis Ports
     │     └─ run_phase    : Sequence → Driver drives DUT → Monitor captures → Scoreboard checks
     │
     ▼
Waveform: waves/Design.fst
```

### Transaction và Sequences mẫu

```python
# Transaction — 1 đơn vị dữ liệu
class SpikeTransaction(uvm_sequence_item):
    spike_data: list[int]   # 4 bytes input
    valid_in:   int         # 1 bit valid flag

# Sequence có sẵn trong project
class ZeroInputSeq(uvm_sequence):
    """Smoke test — không spike nào"""
    async def body(self):
        for _ in range(10):
            txn = SpikeTransaction()
            txn.spike_data = [0x00] * 4
            txn.valid_in   = 1
            await self.start_item(txn)
            await self.finish_item(txn)

# Thêm sequence mới
class BurstSpikeSeq(uvm_sequence):
    """Gửi burst 100 spikes liên tiếp"""
    async def body(self):
        for i in range(100):
            txn = SpikeTransaction()
            txn.spike_data = [0xFF if i % 2 == 0 else 0x00] * 4
            await self.start_item(txn)
            await self.finish_item(txn)
```

### Driver — gán giá trị lên DUT

```python
class SpikeDriver(uvm_driver):
    async def run_phase(self):
        dut = cocotb.top
        while True:
            txn = await self.seq_item_port.get_next_item()
            # Gán giá trị vào DUT pins
            dut.valid_in.value = 1
            dut.spike_in.value = int.from_bytes(txn.spike_data, 'big')
            await RisingEdge(dut.clk)
            dut.valid_in.value = 0
            self.seq_item_port.item_done()
```

### Monitor — đọc output DUT

```python
class SpikeMonitor(uvm_monitor):
    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)   # broadcast đến scoreboard

    async def run_phase(self):
        dut = cocotb.top
        while True:
            await RisingEdge(dut.clk)
            if dut.valid_out.value == 1:
                txn = SpikeTransaction()
                txn.spike_data = [int(dut.spike_out.value)]
                self.ap.write(txn)    # gửi đến scoreboard + coverage
```

### Scoreboard — kiểm tra kết quả

```python
class SpikeScoreboard(uvm_component):
    def build_phase(self):
        self.result_export = uvm_analysis_export("result_export", self)
        self.result_fifo   = uvm_tlm_analysis_fifo("result_fifo", self)

    async def run_phase(self):
        while True:
            txn = await self.result_fifo.get()
            if not self._check(txn):
                self.logger.error(f"MISMATCH: got {txn.spike_data}")
```

### Coverage — đo độ phủ test

```python
class SpikeCoverage(uvm_subscriber):
    def __init__(self, name, parent):
        super().__init__(name, parent)
        self.bins = {"zero": 0, "low": 0, "mid": 0, "high": 0}

    def write(self, txn):
        val = txn.spike_data[0] if txn.spike_data else 0
        if val == 0:        self.bins["zero"] += 1
        elif val < 0x40:    self.bins["low"]  += 1
        elif val < 0xC0:    self.bins["mid"]  += 1
        else:               self.bins["high"] += 1
```

### So sánh Icarus Verilog vs Verilator

| Tiêu chí | Icarus Verilog | Verilator |
|----------|----------------|-----------|
| **Tốc độ** | Chậm (event-driven) | Nhanh (compiled C++) |
| **Compile time** | Ngắn (~1s) | Dài hơn (~10–30s) |
| **Waveform** | VCD, FST | VCD, FST |
| **Standard** | Verilog-2005, SV cơ bản | SystemVerilog đầy đủ |
| **Lint** | Không mạnh | `--lint-only -Wall` rất tốt |
| **Dùng cho** | Debug lần đầu, prototype | Regression lớn, performance |
| **cocotb** | Ổn định | Ổn định (từ v5.0) |

**Khuyến nghị:** Icarus khi debug lần đầu, Verilator khi chạy regression nhiều lần.

### Standalone simulation (không dùng cocotb)

```bash
# Icarus standalone — kiểm tra syntax nhanh
iverilog -g2012 -o /tmp/sim src/MyDesign.v && echo "Compile OK"
vvp /tmp/sim -fst   # chạy (cần $dumpfile/$dumpvars trong Verilog)

# Verilator lint check (rất mạnh)
verilator --lint-only -Wall src/MyDesign.v
# Cảnh báo thường gặp:
# UNOPTFLAT: combinational loop (cần fix)
# UNUSED: signal không dùng (có thể bỏ qua)
```

---

## 15. Sign-off: DRC + LVS + GDS

Sign-off là bước cuối trước khi gửi chip cho nhà máy (chỉ áp dụng cho Sky130HD).

### 15.1 Flow sign-off tự động (HammingCode_128bit)

```bash
cd ~/Documents/OpenROAD/Sky130_Workspace/HammingCode_128bit

# Chạy toàn bộ sign-off (GDS + DRC + LVS)
./run_flow_complete.sh --from 5

# Hoặc chỉ sign-off (giả sử đã có 6_final.def từ P&R)
./run_flow_complete.sh --only 5   # GDS generation
./run_flow_complete.sh --only 6   # Magic DRC
./run_flow_complete.sh --only 7   # Netgen LVS
```

**Kết quả mong đợi:**
```
STEP 5: GDS Generation
  → KLayout 0.30.x loaded
  → All LEF cells have matching GDS/OAS cells
  → No orphan cells
  [PASS] GDS generated: 6_final.gds (2.0M)

STEP 6: Magic DRC Sign-off
  → DRC Total Violations: 0
  → CLEAN: 0 DRC violations
  [PASS] Magic DRC: CLEAN (0 violations)

STEP 7: Netgen LVS Sign-off
  → Extracted SPICE: HammingCode_128bit_extracted.spice
  [PASS] Netgen LVS: extraction complete
```

### 15.2 Tạo GDS thủ công

```bash
python3.9 ~/Documents/OpenROAD/Sky130_Workspace/HammingCode_128bit/run_def2gds.py
```

### 15.3 Chạy Magic DRC thủ công

```bash
# Quan trọng: KHÔNG dùng -rcfile (template magicrc có lệnh quit)
~/Documents/OpenROAD/tools/install/magic/bin/magic \
  -dnull -noconsole -T sky130A << 'EOF'
gds read /path/to/6_final.gds
load HammingCode_128bit
drc euclidean on
drc check
drc catchup
set n [drc list count total]
puts "=== DRC Violations: $n ==="
quit
EOF
```

### 15.4 Trích xuất SPICE cho LVS

```bash
~/Documents/OpenROAD/tools/install/magic/bin/magic \
  -dnull -noconsole -T sky130A << 'EOF'
gds read /path/to/6_final.gds
load HammingCode_128bit
select top cell
extract all
ext2spice hierarchy on
ext2spice format ngspice
ext2spice -o /path/to/output.spice
quit
EOF
```

---

## 16. Đọc hiểu kết quả đầu ra

### 16.1 Files quan trọng sau P&R

| File | Vị trí | Mô tả |
|------|--------|-------|
| `1_synth.v` | `results/.../base/` | Gate-level netlist sau synthesis |
| `6_final.def` | `results/.../base/` | Layout cuối cùng — định dạng DEF |
| `6_final.gds` | `results/.../base/` | **File GDSII gửi nhà máy** |
| `6_final.odb` | `results/.../base/` | OpenROAD database (cho debug) |
| `6_final.spef` | `results/.../base/` | Parasitics cho timing analysis |
| `6_final.v` | `results/.../base/` | Gate-level Verilog cuối cùng |

### 16.2 Logs quan trọng

```bash
# Xem log synthesis
cat ORFS_Source/flow/logs/sky130hd/<DESIGN>/base/1_1_yosys.log | tail -30

# Xem timing report cuối
cat ORFS_Source/flow/logs/sky130hd/<DESIGN>/base/6_report.log | \
  grep -A5 "Timing"

# Xem power report
cat ORFS_Source/flow/logs/sky130hd/<DESIGN>/base/6_report.log | \
  grep -A5 "Power"
```

### 16.3 Hiểu các chỉ số timing

```
WNS (Worst Negative Slack):
  WNS = 0.0 ns  → Perfect timing, không có violation
  WNS = -0.3 ns → Nhỏ, thường chấp nhận được
  WNS = -2.0 ns → Lớn, cần tăng clock period hoặc optimize

TNS (Total Negative Slack):
  TNS = 0.0 ns  → Không có endpoint nào bị trễ
  TNS < 0.0 ns  → Tổng slack âm của tất cả violated paths

→ Để fix timing: tăng CLOCK_PERIOD trong config.mk
  Ví dụ: 10.0 (100 MHz) → 12.0 (83 MHz)
```

### 16.4 Hiểu thông số DRC

```
DRC violations = 0  → Layout sạch, sẵn sàng tape-out
DRC violations > 0  → Cần xem chi tiết:
  - Cell boundary violations: thường do PDK cells, không phải lỗi thiết kế
  - Metal spacing violations: lỗi routing thực sự, cần fix
  - Well tap violations: thiếu tap cells

Với OpenROAD Sky130HD, DRC = 0 là kết quả bình thường.
```

### 16.5 Hiểu LVS

```
LVS = CLEAN         → Schematic và layout khớp nhau
LVS = mismatches    → Có sự khác biệt giữa netlist và layout:
  - Net mismatch: dây bị nối sai
  - Instance mismatch: thiếu hoặc thừa cells
  - Port mismatch: tên cổng không khớp
```

---

## 17. Quy trình làm việc hàng ngày

### 17.1 Lần đầu mở terminal (setup PATH)

```bash
source ~/Documents/OpenROAD/Sky130_Workspace/HammingCode_128bit/env_setup.sh
```

Hoặc thêm vào `~/.zprofile` để tự động (đã làm ở Mục 9).

### 17.2 Workflow thông thường

```bash
# 1. Sửa RTL Verilog
open Sky130_Workspace/HammingCode_128bit/src/HammingCode_128bit.v

# 2. Chạy kiểm thử chức năng
cd Sky130_Workspace/HammingCode_128bit/Verifications
make SIM=icarus

# 3. Nếu test PASS → chạy P&R
cd ..
# Cách nhanh:
cd ~/Documents/OpenROAD/Sky130_Workspace
./run.sh HammingCode_128bit

# 4. Xem kết quả timing
grep "WNS\|TNS\|Area\|Power" \
  ~/Documents/OpenROAD/ORFS_Source/flow/logs/sky130hd/HammingCode_128bit/base/6_report.log

# 5. Tạo GDS + DRC
cd ~/Documents/OpenROAD/Sky130_Workspace/HammingCode_128bit
./run_flow_complete.sh --from 5
```

### 17.3 Thêm thiết kế mới

Để thêm một design mới vào workspace:

```bash
# 1. Tạo thư mục
mkdir -p ~/Documents/OpenROAD/Sky130_Workspace/MyDesign/src
mkdir -p ~/Documents/OpenROAD/Sky130_Workspace/MyDesign/constraints

# 2. Viết RTL
cat > ~/Documents/OpenROAD/Sky130_Workspace/MyDesign/src/MyDesign.v << 'EOF'
module MyDesign (
    input  wire clk,
    input  wire rst_n,
    input  wire [7:0] data_in,
    output reg  [7:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_out <= 8'h00;
        else        data_out <= data_in;
    end
endmodule
EOF

# 3. Tạo SDC constraint
cat > ~/Documents/OpenROAD/Sky130_Workspace/MyDesign/constraints/constraint.sdc << 'EOF'
create_clock -name clk -period 10.0 [get_ports clk]
set_clock_uncertainty 0.1 [get_clocks clk]
set_input_delay  2.0 -clock clk [all_inputs]
set_output_delay 2.0 -clock clk [all_outputs]
EOF

# 4. Tạo config.mk
cat > ~/Documents/OpenROAD/Sky130_Workspace/MyDesign/config.mk << 'EOF'
export DESIGN_NAME      = MyDesign
export PLATFORM         = sky130hd
export VERILOG_FILES    = /Users/YOUR_USERNAME/Documents/OpenROAD/Sky130_Workspace/MyDesign/src/MyDesign.v
export SDC_FILE         = /Users/YOUR_USERNAME/Documents/OpenROAD/Sky130_Workspace/MyDesign/constraints/constraint.sdc
export CORE_UTILIZATION  = 50
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN       = 2.0
export PLACE_DENSITY     = 0.65
export CLOCK_PERIOD      = 10.0
export EQUIVALENCE_CHECK = 0
export LEC_CHECK         = 0
EOF

# 5. Chạy flow
cd ~/Documents/OpenROAD/Sky130_Workspace
./run.sh MyDesign
```

---

## 18. Xử lý lỗi thường gặp

### 18.1 Lỗi: Đường dẫn không tồn tại (username khác)

**Triệu chứng:**
```
/Users/vuhieunghia/Documents/OpenROAD/...: No such file or directory
```

**Fix:** Thay username trong tất cả files:
```bash
YOUR_USER=$(whoami)
OLD_USER="vuhieunghia"

cd ~/Documents/OpenROAD/Sky130_Workspace

# Tìm tất cả files có đường dẫn cũ
grep -rl "/Users/$OLD_USER" . --include="*.sh" --include="*.py" \
  --include="*.mk" --include="*.tcl" | while read f; do
  sed -i '' "s|/Users/$OLD_USER|/Users/$YOUR_USER|g" "$f"
  echo "Fixed: $f"
done

# Cũng fix trong ASAP7_Workspace
cd ~/Documents/OpenROAD/ASAP7_Workspace
grep -rl "/Users/$OLD_USER" . --include="*.sh" --include="*.py" \
  --include="*.mk" | while read f; do
  sed -i '' "s|/Users/$OLD_USER|/Users/$YOUR_USER|g" "$f"
done
```

### 18.2 Lỗi: `realpath: command not found`

```bash
brew install coreutils
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
realpath --version  # phải ra GNU coreutils
```

### 18.3 Lỗi: `cocotb-config: command not found`

```bash
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
# Sau đó thêm dòng này vào ~/.zprofile
```

### 18.4 Lỗi: `Error: KLayout not found` khi chạy ORFS make

```bash
export PATH="$HOME/Documents/OpenROAD/Sky130_Workspace/bin:$PATH"
which klayout  # phải tìm thấy wrapper Python
klayout -zz    # test wrapper
```

### 18.5 Lỗi: Magic không chạy DRC commands (stdin bị ignore)

**Nguyên nhân:** `sky130A.magicrc` là template, chứa lệnh `quit -noprompt` trước khi đọc stdin.

**Fix:** Bỏ flag `-rcfile`:
```bash
# ❌ Sai
magic -dnull -noconsole -T sky130A -rcfile sky130A.magicrc << 'EOF'

# ✅ Đúng
magic -dnull -noconsole -T sky130A << 'EOF'
```

### 18.6 Lỗi: `ModuleNotFoundError: No module named 'hamming_golden'`

```bash
cd ~/Documents/OpenROAD/Sky130_Workspace/HammingCode_128bit/Verifications

# Thêm reference/ vào PYTHONPATH thủ công
export PYTHONPATH="$(pwd)/tb:$(pwd)/../reference:$PYTHONPATH"
make SIM=icarus
```

### 18.7 Lỗi build ORFS: `cannot find -lOpenMP`

```bash
brew install libomp

export OpenMP_ROOT=$(brew --prefix libomp)
export LDFLAGS="-L$(brew --prefix libomp)/lib"
export CPPFLAGS="-I$(brew --prefix libomp)/include -Xpreprocessor -fopenmp"

cd ~/Documents/OpenROAD/ORFS_Source
./build_openroad.sh --local
```

### 18.8 Lỗi: Synthesis dừng giữa chừng (out of memory)

```bash
# Giảm số core (giảm RAM sử dụng)
cd ~/Documents/OpenROAD/ORFS_Source/flow
make DESIGN_CONFIG=... synth NPROC=2

# Tắt các app khác để giải phóng RAM
```

### 18.9 Lỗi build Magic: linker error với cairo/freetype

```bash
# Cài đầy đủ dependencies
brew install cairo fontconfig freetype pkg-config

export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig"
export LDFLAGS="-L/opt/homebrew/lib"
export CPPFLAGS="-I/opt/homebrew/include"

cd ~/Documents/OpenROAD/magic_src
make clean
./configure \
  --prefix=$HOME/Documents/OpenROAD/tools/install/magic \
  --x-includes=/opt/homebrew/include \
  --x-libraries=/opt/homebrew/lib
make -j$(sysctl -n hw.logicalcpu)
make install
```

### 18.10 Kiểm tra nhanh toàn bộ môi trường

```bash
source ~/Documents/OpenROAD/Sky130_Workspace/HammingCode_128bit/env_setup.sh
```

Dòng nào hiện `NOT FOUND` → cài công cụ đó theo hướng dẫn tương ứng.

---

## 19. Tài nguyên tham khảo

### Tài liệu trong dự án này

| File | Nội dung |
|------|---------|
| `ReSearchDocument/task.md` | Tiến độ dự án (các bước đã hoàn thành) |
| `ReSearchDocument/openroad_flow_rtl_to_gdsii.md` | Chi tiết flow RTL→GDSII |
| `ReSearchDocument/verification_flow.md` | Hướng dẫn cocotb + pyUVM |
| `ReSearchDocument/openroad_native_macos_m1_research.md` | Research build trên M1 |
| `Sky130_Workspace/HammingCode_128bit/Docs/algorithm.md` | Đặc tả thuật toán Hamming SEC-DED |

### Tài nguyên bên ngoài

| Tài nguyên | Mô tả |
|-----------|-------|
| [OpenROAD Project](https://theopenroadproject.org) | Trang chủ OpenROAD |
| [ORFS GitHub](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts) | Source code + tài liệu |
| [OpenROAD Docs](https://openroad.readthedocs.io) | Documentation đầy đủ |
| [Magic VLSI](http://opencircuitdesign.com/magic/) | Magic documentation |
| [Sky130 PDK](https://github.com/google/skywater-pdk) | SkyWater 130nm PDK |
| [Efabless Chipignite](https://efabless.com/chipignite) | Tape-out shuttle (miễn phí) |
| [cocotb docs](https://docs.cocotb.org) | Python verification framework |
| [GTKWave](http://gtkwave.sourceforge.net) | Waveform viewer |

---

## Tóm tắt setup nhanh (Checklist)

### Trường hợp A: Nhận thư mục OpenROAD đã build sẵn

```
Yêu cầu: Apple Silicon Mac (M1/M2/M3) — không chạy được trên Intel

□ 1. xcode-select --install                         (~5 phút)
□ 2. brew install tcl-tk@8 or-tools protobuf re2 highs scip \
         libomp qt@5 yaml-cpp spdlog fmt \
         coreutils gnu-sed icarus-verilog verilator  (~10 phút)
□ 3. python3.9 -m pip install --user klayout cocotb pyuvm
□ 4. Copy thư mục OpenROAD/ vào bất kỳ đường dẫn nào
□ 5. cd OpenROAD && ./setup.sh                      (~1 phút)
□ 6. source ~/.zprofile

─── Kiểm tra ───────────────────────────────────────────
□ source Sky130_Workspace/HammingCode_128bit/env_setup.sh
   → tất cả 8 tools hiện "→ /path/to/tool" (không có NOT FOUND)

□ Sky130_Workspace/HammingCode_128bit/run_flow_complete.sh --only 6
   → [PASS] Magic DRC: CLEAN (0 violations)
```

### Trường hợp B: Build từ đầu hoàn toàn

```
□ 1. xcode-select --install
□ 2. Cài Homebrew
□ 3. brew install icarus-verilog verilator gtkwave gnu-sed coreutils ...
□ 4. Thêm GNU tools vào PATH trong ~/.zprofile
□ 5. pip install klayout cocotb pyuvm
□ 6. git clone ORFS_Source && ./build_openroad.sh --local   (~60 phút)
□ 7. Build Magic (./configure && make install)
□ 8. Build Netgen (./configure && make install)
□ 9. Copy sky130A.tech từ open_pdks → Magic sys/
□ 10. cd OpenROAD && ./setup.sh

─── Kiểm tra ───────────────────────────────────────────
□ openroad --version   → OK
□ yosys --version      → OK
□ magic --version      → OK
□ iverilog -V          → OK
□ python3.9 -c "import klayout.db; print('OK')"

─── Chạy thử ───────────────────────────────────────────
□ cd Sky130_Workspace && ./run.sh HammingCode_128bit
□ cd HammingCode_128bit/Verifications && make SIM=icarus
□ cd HammingCode_128bit && ./run_flow_complete.sh --from 5
```

---

## 20. Tạo thiết kế mới từ con số 0

> **Mục tiêu:** Hướng dẫn tạo hoàn chỉnh một thiết kế chip mới — từ ý tưởng đến GDSII — theo đúng cấu trúc project.
>
> **Ví dụ sử dụng trong hướng dẫn này:** `MyAdder` — bộ cộng 8-bit có carry, pipeline 1 tầng.
> Bạn thay `MyAdder` bằng tên thiết kế thực của mình ở mọi nơi.

---

### 20.1 Tổng quan các bước

```
Bước 1: Tạo cấu trúc thư mục
Bước 2: Viết RTL (Verilog)
Bước 3: Viết timing constraints (SDC)
Bước 4: Viết config.mk
Bước 5: Viết Verifications/Makefile
Bước 6: Viết golden reference model (Python)
Bước 7: Viết cocotb tests
Bước 8: Chạy kiểm thử chức năng
Bước 9: Chạy flow RTL → GDSII (Synthesis + P&R)
Bước 10: Tạo GDS
Bước 11: DRC sign-off
```

---

### 20.2 Bước 1 — Tạo cấu trúc thư mục

```bash
cd /path/to/OpenROAD/Sky130_Workspace   # hoặc ASAP7_Workspace

DESIGN=MyAdder   # thay bằng tên thiết kế của bạn

mkdir -p $DESIGN/src
mkdir -p $DESIGN/constraints
mkdir -p $DESIGN/reference
mkdir -p $DESIGN/Verifications/tb/interfaces
mkdir -p $DESIGN/Verifications/tb/env/agent
mkdir -p $DESIGN/Verifications/tb/env/scoreboard
mkdir -p $DESIGN/Verifications/tb/env/coverage
mkdir -p $DESIGN/Verifications/tb/sequences
mkdir -p $DESIGN/Verifications/tb/tests
mkdir -p $DESIGN/Verifications/sim/icarus
mkdir -p $DESIGN/Verifications/sim/verilator
mkdir -p $DESIGN/Verifications/waves
mkdir -p $DESIGN/Verifications/reports
mkdir -p $DESIGN/logs
mkdir -p $DESIGN/reports
mkdir -p $DESIGN/Docs
```

Kết quả cấu trúc:
```
Sky130_Workspace/MyAdder/
├── src/
│   └── MyAdder.v               ← RTL chính
├── constraints/
│   └── constraint.sdc          ← timing constraints
├── reference/
│   └── myadder_golden.py       ← golden model Python
├── config.mk                   ← ORFS config
├── Docs/
│   └── spec.md                 ← đặc tả thiết kế (tùy chọn)
└── Verifications/
    ├── Makefile                ← cocotb Makefile
    ├── requirements.txt
    └── tb/
        ├── interfaces/         ← port wrappers
        ├── env/
        │   ├── agent/          ← driver + monitor
        │   ├── scoreboard/     ← so sánh kết quả
        │   └── coverage/       ← đo độ phủ test
        ├── sequences/          ← stimulus sequences
        └── tests/              ← test cases
```

---

### 20.3 Bước 2 — Viết RTL (Verilog)

Tạo file `src/MyAdder.v`:

```verilog
// ============================================================
// Project  : MyAdder
// Design   : 8-bit pipelined adder with carry
// Platform : Sky130HD | Clock: 200 MHz (5 ns)
// Interface:
//   clk      - clock input
//   rst_n    - active-low synchronous reset
//   a_in     - 8-bit operand A
//   b_in     - 8-bit operand B
//   valid_in - input valid strobe
//   sum_out  - 8-bit sum output (registered, 1-cycle latency)
//   carry_out - carry bit
//   valid_out - output valid (1 cycle after valid_in)
// ============================================================

`default_nettype none

module MyAdder (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] a_in,
    input  wire [7:0] b_in,
    input  wire       valid_in,
    output reg  [7:0] sum_out,
    output reg        carry_out,
    output reg        valid_out
);

    // Pipeline register: compute sum combinationally, register output
    wire [8:0] result = {1'b0, a_in} + {1'b0, b_in};

    always @(posedge clk) begin
        if (!rst_n) begin
            sum_out   <= 8'b0;
            carry_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            sum_out   <= result[7:0];
            carry_out <= result[8];
            valid_out <= valid_in;
        end
    end

endmodule
```

**Quy tắc đặt tên bắt buộc:**
- Tên module phải **giống hệt** tên thư mục (`MyAdder`) và tên file (`MyAdder.v`)
- ORFS dùng tên này để tìm top-level cell trong netlist

---

### 20.4 Bước 3 — Viết timing constraints (SDC)

Tạo file `constraints/constraint.sdc`:

```tcl
# ============================================================
# constraint.sdc — Timing Constraints cho MyAdder
# ============================================================
current_design MyAdder

# Clock: 200 MHz = 5 ns period
# Sky130HD: tổ hợp đơn giản (cộng 8-bit) → 5 ns là vừa phải
set clk_name   core_clock
set clk_port   clk
set clk_period 5.0
set clk_io_pct 0.2       # I/O delay = 20% clock period

create_clock -name $clk_name -period $clk_period [get_ports $clk_port]

# I/O delays
set non_clk_inputs [all_inputs -no_clocks]
set_input_delay  [expr $clk_period * $clk_io_pct] -clock $clk_name $non_clk_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_name [all_outputs]
```

**Chọn clock period hợp lý:**

| Loại logic | Sky130HD | ASAP7 |
|-----------|---------|-------|
| Combinational đơn giản (AND/OR) | 2–5 ns | 0.5–1 ns |
| Adder/Comparator 8-bit | 5–10 ns | 1–2 ns |
| Multiplier 8×8 | 15–20 ns | 3–5 ns |
| XOR tree 128-bit | 8–12 ns | 2–3 ns |
| Complex FSM | 10–15 ns | 2–4 ns |

> **Mẹo:** Bắt đầu với clock dài (thoải mái), sau khi P&R xem WNS — nếu WNS > 2ns thì
> có thể giảm clock period xuống để tối ưu.

---

### 20.5 Bước 4 — Viết config.mk

Tạo file `config.mk`:

```makefile
# ============================================================
# config.mk — ORFS Configuration cho MyAdder / Sky130HD
# ============================================================
export DESIGN_NAME      = MyAdder
export PLATFORM         = sky130hd    # hoặc: asap7

# Auto-detect đường dẫn (không hardcode)
_THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

export VERILOG_FILES    = $(_THIS_DIR)src/MyAdder.v
export SDC_FILE         = $(_THIS_DIR)constraints/constraint.sdc

# ── Floorplan ───────────────────────────────────────────────
# CORE_UTILIZATION: tỷ lệ lấp đầy cell (%)
#   Thiết kế nhỏ/tổ hợp: 40–55%
#   Thiết kế vừa:         55–65%
#   Thiết kế lớn:         65–75%
export CORE_UTILIZATION  = 45
export CORE_ASPECT_RATIO = 1     # 1 = chip vuông
export CORE_MARGIN       = 2.0   # μm lề xung quanh core

# ── Placement ────────────────────────────────────────────────
# PLACE_DENSITY: mật độ đặt cell trong vùng core
# Thường = CORE_UTILIZATION / 100 + 0.1 (nhưng ≤ 0.8)
export PLACE_DENSITY     = 0.60

# ── Timing ───────────────────────────────────────────────────
export TNS_END_PERCENT   = 100   # fix 100% endpoints có violation
export EQUIVALENCE_CHECK = 0     # tắt (eqy không build được trên macOS M1)
export LEC_CHECK         = 0     # tắt
```

**Giải thích các tham số quan trọng:**

| Tham số | Ý nghĩa | Khi nào điều chỉnh |
|---------|---------|-------------------|
| `CORE_UTILIZATION` | % diện tích chip dùng để đặt cell | Tăng nếu chip quá lớn, giảm nếu routing bị nghẽn |
| `PLACE_DENSITY` | Mật độ placement cục bộ | Giảm nếu bị DRC violations do crowding |
| `CORE_MARGIN` | Khoảng cách từ core đến I/O (μm) | Tăng nếu có nhiều I/O pins |
| `CORE_ASPECT_RATIO` | width/height | 2.0 = chip rộng gấp đôi cao |

---

### 20.6 Bước 5 — Viết Verifications/Makefile

Tạo file `Verifications/Makefile`:

```makefile
##############################################################
# MyAdder Verification Makefile
##############################################################

# Auto-detect thư mục Makefile (không phụ thuộc $(shell pwd))
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

TOPLEVEL_LANG   = verilog
VERILOG_SOURCES = $(MAKEFILE_DIR)../src/MyAdder.v
TOPLEVEL        = MyAdder
MODULE          = tests.test_MyAdder

# PYTHONPATH: tb/ (cho tests.*) + reference/ (cho golden model)
export PYTHONPATH := $(MAKEFILE_DIR)tb:$(MAKEFILE_DIR)../reference:$(PYTHONPATH)

# Simulator: icarus | verilator
SIM ?= icarus

# Waveform dump
WAVES ?= 1
ifeq ($(WAVES),1)
  COCOTB_HDL_TIMEUNIT      = 1ns
  COCOTB_HDL_TIMEPRECISION = 1ps
  ifeq ($(SIM),icarus)
    PLUSARGS += -fst
  endif
endif

# Verilator flags
ifeq ($(SIM),verilator)
  EXTRA_ARGS   += --trace --trace-fst
  EXTRA_ARGS   += --no-timing
  COMPILE_ARGS += -Wall
endif

# cocotb-config: macOS user-install path → PATH fallback
COCOTB_CONFIG ?= $(or \
    $(wildcard $(HOME)/Library/Python/3.9/bin/cocotb-config), \
    $(shell which cocotb-config 2>/dev/null))
include $(shell $(COCOTB_CONFIG) --makefiles)/Makefile.sim

# Targets
.PHONY: icarus verilator waves clean-waves

icarus:
	$(MAKE) SIM=icarus

verilator:
	$(MAKE) SIM=verilator

waves:
	gtkwave waves/MyAdder.fst &

clean-waves:
	rm -f waves/*.fst waves/*.vcd
```

---

### 20.7 Bước 6 — Viết Golden Reference Model

Golden model là **đặc tả chính xác bằng Python** — không phụ thuộc RTL, dùng để so sánh kết quả simulation.

Tạo file `reference/myadder_golden.py`:

```python
#!/usr/bin/env python3
"""
MyAdder Golden Reference Model
================================
8-bit adder: sum = a + b (mod 256), carry = overflow bit.
Đây là đặc tả CHÍNH XÁC của hành vi mong muốn.
RTL phải khớp 100% với model này.
"""


def add(a: int, b: int) -> tuple[int, int]:
    """
    Cộng 2 số 8-bit.
    Trả về: (sum_8bit, carry_bit)

    Ví dụ:
      add(100, 200) → (44, 1)   # 300 = 0x12C → sum=0x2C=44, carry=1
      add(10, 20)   → (30, 0)
    """
    result = a + b
    return (result & 0xFF, (result >> 8) & 1)


def add_many(pairs: list[tuple[int, int]]) -> list[tuple[int, int]]:
    """Cộng nhiều cặp số — dùng trong batch test."""
    return [add(a, b) for a, b in pairs]
```

**Nguyên tắc viết golden model:**
- Viết đơn giản, dễ đọc — đây là tài liệu đặc tả, không cần tối ưu hiệu năng
- Không tham chiếu đến RTL hay cocotb — hoàn toàn độc lập
- Thêm docstring và ví dụ cụ thể

---

### 20.8 Bước 7 — Viết cocotb Tests

Tạo các `__init__.py` rỗng trước:

```bash
touch Verifications/tb/__init__.py
touch Verifications/tb/interfaces/__init__.py
touch Verifications/tb/env/__init__.py
touch Verifications/tb/env/agent/__init__.py
touch Verifications/tb/env/scoreboard/__init__.py
touch Verifications/tb/env/coverage/__init__.py
touch Verifications/tb/sequences/__init__.py
touch Verifications/tb/tests/__init__.py
```

#### 20.8.1 Interface wrapper (`tb/interfaces/MyAdder_if.py`)

```python
"""
MyAdder Interface Definitions
Bọc DUT ports thành Python interface sạch
"""
import cocotb
from cocotb.handle import SimHandleBase


class AdderInputIF:
    """Interface cho input ports của DUT"""
    def __init__(self, dut: SimHandleBase):
        self.clk      = dut.clk
        self.rst_n    = dut.rst_n
        self.a_in     = dut.a_in
        self.b_in     = dut.b_in
        self.valid_in = dut.valid_in

    async def reset(self, cycles: int = 5):
        self.rst_n.value    = 0
        self.valid_in.value = 0
        self.a_in.value     = 0
        self.b_in.value     = 0
        for _ in range(cycles):
            await cocotb.triggers.RisingEdge(self.clk)
        self.rst_n.value = 1


class AdderOutputIF:
    """Interface cho output ports của DUT"""
    def __init__(self, dut: SimHandleBase):
        self.sum_out   = dut.sum_out
        self.carry_out = dut.carry_out
        self.valid_out = dut.valid_out
```

#### 20.8.2 Test cases (`tb/tests/test_MyAdder.py`)

```python
"""
MyAdder Test Suite (cocotb)
============================
Tests cho 8-bit pipelined adder.

Chạy:
  make SIM=icarus    (từ Verifications/)
  make SIM=verilator
"""
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# Import golden model
from myadder_golden import add

CLOCK_NS = 5  # 200 MHz


# ── Helpers ────────────────────────────────────────────────

async def _setup(dut):
    """Khởi động clock và reset DUT."""
    cocotb.start_soon(Clock(dut.clk, CLOCK_NS, units="ns").start())
    dut.rst_n.value    = 0
    dut.valid_in.value = 0
    dut.a_in.value     = 0
    dut.b_in.value     = 0
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def _add_cycle(dut, a: int, b: int) -> tuple[int, int]:
    """Gửi 1 phép cộng, đợi 1 cycle, trả về (sum, carry)."""
    dut.a_in.value     = a
    dut.b_in.value     = b
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    await Timer(1, units="ns")  # để combo settle
    return (int(dut.sum_out.value), int(dut.carry_out.value))


# ── Test 1: Smoke ───────────────────────────────────────────

@cocotb.test()
async def test_smoke(dut):
    """Smoke test: 0+0 = 0, không carry."""
    await _setup(dut)
    s, c = await _add_cycle(dut, 0, 0)
    assert s == 0, f"0+0: sum={s}, expect 0"
    assert c == 0, f"0+0: carry={c}, expect 0"
    dut._log.info("SMOKE TEST PASSED")


# ── Test 2: Giá trị cơ bản ─────────────────────────────────

@cocotb.test()
async def test_basic(dut):
    """Kiểm tra các phép cộng cơ bản, so với golden model."""
    await _setup(dut)
    cases = [
        (1, 1),    # 2
        (10, 20),  # 30
        (127, 1),  # 128
        (255, 0),  # 255 (không overflow)
        (255, 1),  # 256 → sum=0, carry=1
        (200, 100), # 300 → sum=44, carry=1
    ]
    fail = 0
    for a, b in cases:
        s_rtl, c_rtl = await _add_cycle(dut, a, b)
        s_gold, c_gold = add(a, b)
        if s_rtl != s_gold or c_rtl != c_gold:
            dut._log.error(
                f"{a}+{b}: RTL=({s_rtl},{c_rtl}), golden=({s_gold},{c_gold})"
            )
            fail += 1
    assert fail == 0, f"Basic: {fail} failures"
    dut._log.info("BASIC TEST PASSED")


# ── Test 3: Random 500 vectors ─────────────────────────────

@cocotb.test()
async def test_random(dut):
    """So sánh RTL vs golden model với 500 vector ngẫu nhiên."""
    await _setup(dut)
    random.seed(42)
    N = 500
    fail = 0
    for i in range(N):
        a = random.randint(0, 255)
        b = random.randint(0, 255)
        s_rtl, c_rtl = await _add_cycle(dut, a, b)
        s_gold, c_gold = add(a, b)
        if s_rtl != s_gold or c_rtl != c_gold:
            dut._log.error(
                f"[{i}] {a}+{b}: RTL=({s_rtl},{c_rtl}), gold=({s_gold},{c_gold})"
            )
            fail += 1
    assert fail == 0, f"Random: {fail}/{N} failures"
    dut._log.info(f"RANDOM TEST PASSED ({N} vectors)")


# ── Test 4: Boundary — all carry cases ─────────────────────

@cocotb.test()
async def test_carry_boundary(dut):
    """Kiểm tra toàn bộ các trường hợp sinh carry (a+b >= 256)."""
    await _setup(dut)
    fail = 0
    # Duyệt: a từ 128..255, b = 256-a (carry boundary)
    for a in range(128, 256):
        b = 256 - a           # a + b = 256 → sum=0, carry=1
        s_rtl, c_rtl = await _add_cycle(dut, a, b & 0xFF)
        s_gold, c_gold = add(a, b & 0xFF)
        if c_rtl != 1 or s_rtl != 0:
            dut._log.error(
                f"carry boundary {a}+{b&0xFF}: RTL=({s_rtl},{c_rtl})"
            )
            fail += 1
    assert fail == 0, f"Carry boundary: {fail} failures"
    dut._log.info("CARRY BOUNDARY TEST PASSED")


# ── Test 5: Reset behavior ─────────────────────────────────

@cocotb.test()
async def test_reset(dut):
    """Sau reset: outputs = 0, valid_out = 0."""
    await _setup(dut)
    # Gửi 1 transaction rồi reset giữa chừng
    dut.a_in.value     = 100
    dut.b_in.value     = 200
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    # Assert reset
    dut.rst_n.value    = 0
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, units="ns")
    assert int(dut.sum_out.value)   == 0, f"After reset: sum={int(dut.sum_out.value)}"
    assert int(dut.carry_out.value) == 0, f"After reset: carry={int(dut.carry_out.value)}"
    assert int(dut.valid_out.value) == 0, f"After reset: valid={int(dut.valid_out.value)}"
    dut._log.info("RESET TEST PASSED")
```

---

### 20.9 Bước 8 — Chạy kiểm thử chức năng

```bash
cd Sky130_Workspace/MyAdder/Verifications

# Chạy với Icarus Verilog (nhanh hơn)
make SIM=icarus

# Hoặc Verilator (strict syntax check)
make SIM=verilator

# Xem waveform
make waves
```

**Output khi pass:**
```
test_smoke              PASS
test_basic              PASS
test_random             PASS
test_carry_boundary     PASS
test_reset              PASS

=========================================
 5 tests passed, 0 failed in X.XXs
=========================================
```

**Debug khi fail:**
```bash
# Xem log chi tiết
cat sim_build/*.log

# Xem waveform (cần gtkwave)
gtkwave waves/MyAdder.fst &

# Chạy 1 test cụ thể
TESTCASE=test_smoke make SIM=icarus
```

---

### 20.10 Bước 9 — Chạy Synthesis + P&R

Sau khi verification pass, chạy flow RTL → layout:

```bash
# Đứng ở Sky130_Workspace/
./run.sh MyAdder

# Hoặc trực tiếp từ ORFS:
cd /path/to/OpenROAD/ORFS_Source/flow
make DESIGN_CONFIG=/path/to/Sky130_Workspace/MyAdder/config.mk \
     EQUIVALENCE_CHECK=0 LEC_CHECK=0
```

**Theo dõi từng bước riêng lẻ:**
```bash
# Chỉ synthesis
make DESIGN_CONFIG=.../MyAdder/config.mk synth

# Chỉ floorplan
make DESIGN_CONFIG=.../MyAdder/config.mk floorplan

# Chỉ placement
make DESIGN_CONFIG=.../MyAdder/config.mk place

# Đến CTS
make DESIGN_CONFIG=.../MyAdder/config.mk cts

# Đến routing
make DESIGN_CONFIG=.../MyAdder/config.mk route

# Toàn bộ đến final DEF
make DESIGN_CONFIG=.../MyAdder/config.mk 6_final.def
```

**Kết quả mong đợi sau synthesis:**
```
Results in: flow/results/sky130hd/MyAdder/base/1_synth.v
Cell count:  ~50–150 cells (8-bit adder là thiết kế rất nhỏ)
```

**Kết quả mong đợi sau P&R:**
```
Results in: flow/results/sky130hd/MyAdder/base/
  6_final.def    ← layout DEF
  6_final.v      ← gate-level netlist
  6_final.spice  ← SPICE netlist

Timing summary:
  WNS: +X.XX ns  (dương = timing met ✓)
  TNS: 0.000     (0 = không có violation ✓)
```

**Xử lý khi timing bị vi phạm (WNS âm):**
- WNS = -0.1 ~ -0.5 ns → thường tự fix sau vài iteration, hoặc tăng `CLOCK_PERIOD` thêm 1–2 ns
- WNS < -1 ns → cần tăng `CLOCK_PERIOD` hoặc giảm `PLACE_DENSITY`
- TNS lớn → nhiều paths fail, cần redesign hoặc thêm pipeline stage

---

### 20.11 Bước 10 — Tạo GDS

#### 10a. Tạo `run_def2gds.py`

Tạo file `MyAdder/run_def2gds.py`:

```python
#!/usr/bin/env python3.9
"""
run_def2gds.py — Generate GDS from DEF using KLayout Python API
"""
import os
import sys
from pathlib import Path

# Auto-detect OPENROAD_HOME
_SCRIPT_DIR   = Path(__file__).resolve().parent
OPENROAD_HOME = _SCRIPT_DIR.parents[1]    # .../OpenROAD/
FLOW_HOME     = str(OPENROAD_HOME / "ORFS_Source" / "flow")

DESIGN_NAME  = "MyAdder"
PLATFORM     = "sky130hd"
VARIANT      = "base"

RESULTS_DIR  = f"{FLOW_HOME}/results/{PLATFORM}/{DESIGN_NAME}/{VARIANT}"
OBJECTS_DIR  = f"{FLOW_HOME}/objects/{PLATFORM}/{DESIGN_NAME}/{VARIANT}"
PLATFORM_DIR = f"{FLOW_HOME}/platforms/{PLATFORM}"
UTILS_DIR    = f"{FLOW_HOME}/util"

IN_DEF      = f"{RESULTS_DIR}/6_final.def"
OUT_GDS     = f"{RESULTS_DIR}/6_final.gds"
TECH_LYT    = f"{PLATFORM_DIR}/sky130hd.lyt"
GEN_LYT     = f"{OBJECTS_DIR}/klayout.lyt"
SC_GDS      = f"{PLATFORM_DIR}/gds/sky130_fd_sc_hd.gds"
LEF_FILES   = [
    f"{PLATFORM_DIR}/lef/sky130_fd_sc_hd.tlef",
    f"{PLATFORM_DIR}/lef/sky130_fd_sc_hd_merged.lef",
]

# Step 1: Generate klayout tech file
print(f"[1/3] Generating klayout tech file...")
os.makedirs(OBJECTS_DIR, exist_ok=True)
sys.path.insert(0, UTILS_DIR)
from generate_klayout_tech import generate_klayout_tech
generate_klayout_tech(
    template_lyt       = TECH_LYT,
    output_lyt         = GEN_LYT,
    lef_files          = LEF_FILES,
    reference_dir      = OBJECTS_DIR,
    map_files          = [],
    use_relative_paths = True,
)

# Step 2: Load KLayout
print("[2/3] Loading klayout.db...")
import klayout.db as pya
print(f"    → klayout {pya.__version__}")

# Step 3: Merge DEF + GDS
print(f"[3/3] Merging DEF + PDK GDS → {OUT_GDS}")
from def2stream import merge_gds
errors = merge_gds(
    pya_mod     = pya,
    tech_file   = GEN_LYT,
    layer_map   = "",
    in_def      = IN_DEF,
    design_name = DESIGN_NAME,
    in_files    = SC_GDS,
    seal_file   = "",
    out_file    = OUT_GDS,
    allow_empty = "",
)

if errors > 0:
    print(f"[ERROR] {errors} errors during GDS merge")
    sys.exit(1)

size_mb = os.path.getsize(OUT_GDS) / 1e6
print(f"[SUCCESS] GDS: {OUT_GDS} ({size_mb:.2f} MB)")
```

#### 10b. Chạy GDS generation

```bash
# Đảm bảo DEF đã có từ bước 9
ls flow/results/sky130hd/MyAdder/base/6_final.def

# Tạo GDS
python3.9 Sky130_Workspace/MyAdder/run_def2gds.py

# Kết quả
ls -lh flow/results/sky130hd/MyAdder/base/6_final.gds
# → file .gds vài trăm KB đến vài MB
```

---

### 20.12 Bước 11 — DRC Sign-off

#### Cách 1: Script nhanh (Magic trực tiếp)

```bash
MAGIC=/path/to/OpenROAD/tools/install/magic/bin/magic
GDS=flow/results/sky130hd/MyAdder/base/6_final.gds

"$MAGIC" -dnull -noconsole -T sky130A <<'EOF'
gds read /path/to/6_final.gds
load MyAdder
drc euclidean on
drc check
drc catchup
set drc_total [drc list count total]
puts "DRC Total Violations: $drc_total"
if {$drc_total == 0} { puts "CLEAN" } else { drc listall why }
quit
EOF
```

#### Cách 2: Tạo `run_magic_drc.sh` (khuyến nghị)

Tạo file `MyAdder/run_magic_drc.sh`:

```bash
#!/bin/bash
# Magic DRC wrapper cho MyAdder
set -e

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENROAD_HOME="$(cd "$_SCRIPT_DIR/../.." && pwd)"

MAGIC="$OPENROAD_HOME/tools/install/magic/bin/magic"
GDS="$OPENROAD_HOME/ORFS_Source/flow/results/sky130hd/MyAdder/base/6_final.gds"
LOG="$_SCRIPT_DIR/logs/drc_magic.log"
DESIGN=MyAdder

mkdir -p "$_SCRIPT_DIR/logs"
echo "=== Magic DRC: $DESIGN ===" | tee "$LOG"

"$MAGIC" -dnull -noconsole -T sky130A <<MAGIC_EOF 2>&1 | tee -a "$LOG"
gds read $GDS
load $DESIGN
drc euclidean on
drc check
drc catchup
set drc_total [drc list count total]
puts "=== DRC Total Violations: \$drc_total ==="
if {\$drc_total > 0} {
    set drc_list [drc listall why]
    foreach {cell reasons} \$drc_list {
        puts "Cell: \$cell"
        foreach reason \$reasons { puts "  \$reason" }
    }
} else {
    puts "CLEAN: 0 DRC violations"
}
quit
MAGIC_EOF

chmod +x run_magic_drc.sh
```

```bash
chmod +x Sky130_Workspace/MyAdder/run_magic_drc.sh
./Sky130_Workspace/MyAdder/run_magic_drc.sh
```

**Kết quả mong đợi:**
```
=== DRC Total Violations: 0 ===
CLEAN: 0 DRC violations
```

Nếu có violations:
- `< 5000` violations với sky130hd: thường là cell-boundary interactions — chấp nhận được
- Violations liên quan đến tên design: kiểm tra tên module trong Verilog có khớp với `load <DESIGN>` không

---

### 20.13 Checklist thiết kế mới

```
□ Bước 1: Tạo thư mục đúng cấu trúc
□ Bước 2: src/MyAdder.v  — tên module = tên thư mục
□ Bước 3: constraints/constraint.sdc  — clock period hợp lý
□ Bước 4: config.mk  — dùng MAKEFILE_LIST (không pwd)
□ Bước 5: Verifications/Makefile  — MAKEFILE_DIR + cocotb detect
□ Bước 6: reference/myadder_golden.py  — model độc lập
□ Bước 7: tb/__init__.py (rỗng ở mọi thư mục)
□ Bước 7: tb/tests/test_MyAdder.py  — ít nhất: smoke, basic, random
□ Bước 8: make SIM=icarus  → tất cả pass
□ Bước 9: ./run.sh MyAdder  → synthesis + P&R thành công
□ Bước 9: WNS ≥ 0 (không có timing violation)
□ Bước 10: run_def2gds.py  → 6_final.gds được tạo
□ Bước 11: run_magic_drc.sh  → 0 violations
```

---

### 20.14 Lỗi thường gặp khi tạo thiết kế mới

**`Error: module 'MyAdder' not found in VERILOG_FILES`**
→ Kiểm tra tên module trong `.v` có khớp với `DESIGN_NAME` trong `config.mk` không.

**`ImportError: No module named 'myadder_golden'`**
→ File `reference/myadder_golden.py` thiếu hoặc `PYTHONPATH` chưa có `../reference`.
Kiểm tra trong `Makefile`: `export PYTHONPATH := $(MAKEFILE_DIR)tb:$(MAKEFILE_DIR)../reference:...`

**`cocotb: DUT port 'a_in' not found`**
→ Tên port trong test (`dut.a_in`) không khớp với tên trong Verilog.
Magic rule: port name trong Python = port name trong Verilog, case-sensitive.

**`WNS = -3.5 ns` (timing violation nặng)**
→ Thiết kế không đạt timing. Giải pháp theo thứ tự:
1. Tăng `CLOCK_PERIOD` trong SDC (thử +2 ns)
2. Giảm `PLACE_DENSITY` xuống 0.5
3. Nếu vẫn fail → thiết kế cần thêm pipeline register

**`gds read: cannot find cell MyAdder`**
→ Tên cell trong GDS không khớp. Kiểm tra `6_final.v`: tìm dòng `module` ở đầu file.

**`cocotb-config: command not found`**
→ cocotb chưa được cài. Chạy:
```bash
python3.9 -m pip install --user cocotb
# Sau đó kiểm tra:
~/Library/Python/3.9/bin/cocotb-config --version
```

---

## Phụ lục A — Benchmark Hiệu Năng trên Apple M1

> Dữ liệu thực đo trên MacBook Air M1 (8GB RAM, macOS 15.6.1), design GCD Sky130HD, 264 cells.

### A.1 Thời gian từng stage

| Stage | Wall Time | CPU Time | Ghi chú |
|-------|----------:|----------:|---------|
| Synthesis (Yosys) | 1.45s | 1.45s | Single-thread |
| Floorplan | 2.43s | 2.43s | Single-thread |
| Placement | 3.37s | 3.37s | Single-thread |
| CTS | 3.06s | 3.06s | Single-thread |
| **Global Routing** | **37.57s** | 107.72s | **8 threads (2.87x speedup)** |
| **Detail Routing** | **29.42s** | 101.68s | **8 threads (3.46x speedup)** |
| Finish | 2.70s | 2.70s | Single-thread |
| **TỔNG** | **~93s** | | **~1 phút 33 giây** |

```
Phân bổ thời gian:
  Synthesis:   1.45s  ( 1.6%)
  Floorplan:   2.43s  ( 2.6%)
  Placement:   3.37s  ( 3.6%)
  CTS:         3.06s  ( 3.3%)
  Routing:    67.58s  (72.7%)  ← BOTTLENECK
  Finish:      2.70s  ( 2.9%)
  Overhead:   12.31s  (13.2%)
```

### A.2 Sử dụng bộ nhớ (RAM)

| Stage | RAM sử dụng |
|-------|:-----------:|
| Synthesis → Placement | < 50 MB |
| Global Routing | 109 MB |
| Detail Routing | **454 MB (peak)** |
| RAM còn lại (8GB - 454MB) | **~7.5 GB** |

GCD chỉ dùng **5.5% RAM** — M1 8GB đủ cho designs tầm trung.

### A.3 Chất lượng thiết kế (GCD Design Quality)

| Metric | Giá trị | Đánh giá |
|--------|---------|---------|
| WNS | -1.80 ns | Acceptable (GCD là benchmark đơn giản) |
| TNS | -81.25 ps | Nhỏ, chấp nhận được |
| Total Power | 6.99 mW | |
| Design area | 4,905 µm² @ 77% | |
| Cell count | 264 cells | |
| Magic DRC | **0 violations** ✅ | PASS — tape-out ready |

### A.4 Ước tính theo kích thước design

| Design size | Cells | Routing time | Peak RAM | Khả thi trên M1? |
|-------------|------:|:------------:|:--------:|:----------------:|
| GCD (benchmark) | 264 | ~93s | 454 MB | ✅ |
| Small design | ~1,000 | ~5–8 phút | ~800 MB | ✅ |
| Medium design | ~10,000 | ~30–60 phút | ~2–3 GB | ✅ |
| Large design | ~100,000 | ~4–8 giờ | ~5–7 GB | ⚠️ Giới hạn |
| SoC (~500k) | 500,000 | ~2–3 ngày | >8 GB | ❌ OOM |

### A.5 So sánh với các nền tảng khác

| Platform | GCD Routing Time | So với M1 native |
|----------|:----------------:|:----------------:|
| **Apple M1 native (nghiên cứu này)** | **~68s** | 1.0x (baseline) |
| Intel i7-12700 (12C) Ubuntu | ~50s | 1.36x nhanh hơn |
| Intel i9-13900K (24C) Ubuntu | ~30s | 2.3x nhanh hơn |
| Docker x86 + Rosetta 2 trên M1 | ~185s | 2.7x **chậm hơn** |
| Apple M2 Pro (ước tính) | ~50s | ~1.4x nhanh hơn |
| Apple M4 Pro (ước tính) | ~35s | ~1.9x nhanh hơn |

---

## Phụ lục B — 14 Vấn Đề Build & Giải Pháp (macOS M1)

Bảng này ghi lại tất cả các vấn đề gặp phải khi build OpenROAD native trên Apple Silicon — có thể dùng làm reference khi gặp lỗi build tương tự.

| # | Vấn đề | Nguyên nhân gốc | Giải pháp |
|---|--------|-----------------|-----------|
| 1 | `OpenMP_CXX not found` | Apple Clang không bundle OpenMP | Patch 4 CMakeLists: `-Xpreprocessor -fopenmp` + Homebrew libomp |
| 2 | `FLEX_INCLUDE_DIR NOTFOUND` | `find_package(FLEX)` override giá trị set trước | Dùng `CACHE PATH ... FORCE` **sau** `find_package` |
| 3 | `CUDD_LIB NOTFOUND` | CUDD không có trên Homebrew | Clone OpenROAD fork CUDD, build từ source |
| 4 | `omp.h not found` | Eigen include omp.h không có global path | Thêm `include_directories(/opt/homebrew/opt/libomp/include)` |
| 5 | `Boost::system` link error | Boost 1.87+ header-only, không còn lib | Remove `Boost::system` khỏi `dst/CMakeLists.txt` |
| 6 | Build timeout (GTests) | GoogleTest discover timeout trên macOS | Build chỉ `--target openroad` |
| 7 | `realpath` fails | BSD realpath ≠ GNU realpath | `brew install coreutils`, thêm gnubin vào PATH |
| 8 | `pyyaml not found` | Makefile dùng Python 3.9 CLT, pip cài cho Python 3.14 | `python3.9 -m pip install pyyaml` |
| 9 | `eqy not found` tại CTS | eqy (equivalence checker) chưa build | `EQUIVALENCE_CHECK=0 LEC_CHECK=0` |
| 10 | Magic: `sed -i` fails | BSD sed ≠ GNU sed | `brew install gnu-sed`, patch `defs.mak` SED line |
| 11 | Magic: `tclmagic.dylib` không build | `LD_SHARED` rỗng, wrong X11 include path | Configure với `--x-includes=/opt/homebrew/include` |
| 12 | Magic: `cairo not found` lúc link | `GR_LIBS` thiếu `-L` cairo path | Thêm `-L/opt/homebrew/opt/cairo/lib` vào `defs.mak` |
| 13 | Netgen: implicit function error | C23 strict mode | `CFLAGS=-Wno-error=implicit-function-declaration` |
| 14 | KLayout cask = x86_64 only | Homebrew cask chưa có ARM64 | `pip install klayout` (ARM64 wheel available on PyPI) |

### CMake patch OpenMP (áp dụng cho 4 files trong OpenROAD source)

Thêm vào đầu mỗi `CMakeLists.txt` chứa `find_package(OpenMP)`:

```cmake
if(APPLE)
  set(OpenMP_C_FLAGS   "-Xpreprocessor -fopenmp")
  set(OpenMP_CXX_FLAGS "-Xpreprocessor -fopenmp")
  set(OpenMP_C_LIB_NAMES   "omp")
  set(OpenMP_CXX_LIB_NAMES "omp")
  set(OpenMP_omp_LIBRARY /opt/homebrew/opt/libomp/lib/libomp.dylib)
  include_directories(/opt/homebrew/opt/libomp/include)
  link_directories(/opt/homebrew/opt/libomp/lib)
endif()
find_package(OpenMP REQUIRED)
```

Files cần patch:
```
src/gpl/CMakeLists.txt
src/grt/CMakeLists.txt
src/drt/CMakeLists.txt
src/ant/src/CMakeLists.txt
```

### Thời gian build ước tính

| Giai đoạn | Thời gian |
|-----------|----------:|
| Clone ORFS + dependencies | ~15 phút |
| Build CUDD từ source | ~5 phút |
| Build OpenROAD (`--target openroad`) | ~25–35 phút |
| Build Yosys | ~10 phút |
| Build Magic VLSI | ~5 phút |
| Build Netgen | ~3 phút |
| **Tổng** | **~60–70 phút** |

---

## Phụ lục C — So sánh: Native vs Docker vs VM

| Metric | Native M1 (nghiên cứu này) | Docker x86 + Rosetta | Docker ARM64 (Colima) | UTM Ubuntu VM |
|--------|:--------------------------:|:--------------------:|:---------------------:|:-------------:|
| Setup time | ~70 phút (build once) | ~5 phút | ~10 phút | ~30 phút |
| GCD total time | **~93s** | ~250–280s | ~120–150s | ~110–130s |
| Full sign-off | ✅ Native | ❌ Không có script | ❌ Không có script | ✅ Linux tools |
| KLayout GUI | ❌ (Python API only) | ✅ (x86 GUI) | ✅ | ✅ |
| Magic DRC | ✅ ARM64 native | ✅ (trong container) | ✅ | ✅ |
| Fragile? | ⚠️ brew upgrade có thể break | Không | Không | Không |
| **Overhead lâu dài** | **Thấp** | **Cao** (mỗi lần chạy chậm) | Trung bình | Thấp |

**Khuyến nghị theo use case:**
- **Học tập / research**: Native build (nghiên cứu này) — nhanh nhất, full control
- **Prototype nhanh**: Docker ARM64 với Colima — dễ setup nhất
- **Production design**: Linux server (Ubuntu 22.04) — chính thức hỗ trợ

---

## Phụ lục D — Tài liệu tham khảo

| Nguồn | Mô tả |
|-------|-------|
| [OpenROAD Project](https://theopenroadproject.org) | Trang chủ OpenROAD |
| [ORFS GitHub](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts) | Source code + docs |
| [OpenROAD Docs](https://openroad.readthedocs.io) | Documentation đầy đủ |
| [OpenROAD Discussion #9033](https://github.com/The-OpenROAD-Project/OpenROAD/discussions/9033) | M1/macOS native build (Dec 2025) |
| [OpenROAD Discussion #6474](https://github.com/The-OpenROAD-Project/OpenROAD/discussions/6474) | M1 Pro build difficulties (Jan 2025) |
| [OpenROAD Discussion #2971](https://github.com/The-OpenROAD-Project/OpenROAD/discussions/2971) | ARM64 official support request |
| [Magic VLSI](http://opencircuitdesign.com/magic/) | Magic documentation |
| [Magic GitHub](https://github.com/RTimothyEdwards/magic) | Magic source repository |
| [Netgen GitHub](https://github.com/RTimothyEdwards/netgen) | Netgen source repository |
| [open_pdks](https://github.com/RTimothyEdwards/open_pdks) | Sky130A PDK tech files |
| [Sky130 PDK](https://github.com/google/skywater-pdk) | SkyWater 130nm PDK |
| [Efabless Chipignite](https://efabless.com/chipignite) | Sky130 tape-out shuttle (miễn phí) |
| [cocotb docs](https://docs.cocotb.org) | Python verification framework |
| [pyUVM](https://github.com/pyuvm/pyuvm) | Python UVM framework |
| [GTKWave](http://gtkwave.sourceforge.net) | Waveform viewer |
| [KLayout](https://www.klayout.de) | Layout viewer + DRC |

---

*Tài liệu này bao gồm toàn bộ hệ thống OpenROAD trên macOS Apple Silicon.*
*Phiên bản: 2026-03-21 | Tested on: macOS 15.6.1, Apple M1, Homebrew 5.1.0*
*Nguồn: tổng hợp từ verification_flow.md, openroad_flow_rtl_to_gdsii.md, openroad_native_macos_m1_research.md, huong_dan_openroad_m1.md*

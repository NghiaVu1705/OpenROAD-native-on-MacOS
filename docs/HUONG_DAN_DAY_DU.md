# Hướng dẫn đầy đủ — OpenROAD native trên macOS Apple Silicon

> Dành cho người **mới**, muốn clone repo và chạy được flow **RTL → GDSII**.  
> Repo: https://github.com/NghiaVu1705/OpenROAD-native-on-MacOS

| Mục | Giá trị |
|-----|---------|
| Hệ điều hành | macOS 13+ (khuyên 14/15) |
| CPU | **Apple Silicon only** (M1/M2/M3/M4) |
| RAM | Tối thiểu 8 GB (khuyên 16 GB) |
| Ổ trống | ~25–40 GB lần đầu |
| Thời gian setup lần 1 | **~1.5–3 giờ** (chủ yếu build) |
| Design demo | `HammingCode_128bit` (Sky130) |

**Bản 1 trang:** [QUICKSTART.md](QUICKSTART.md)  
**Chi tiết nghiên cứu / patch sâu:** [../ReSearchDocument/README.md](../ReSearchDocument/README.md)

---

## Mục lục

1. [Bạn sẽ làm được gì?](#1-bạn-sẽ-làm-được-gì)
2. [Hai kịch bản dùng repo](#2-hai-kịch-bản-dùng-repo)
3. [Chuẩn bị máy](#3-chuẩn-bị-máy)
4. [Cài lab kit + dependencies](#4-cài-lab-kit--dependencies)
5. [Build OpenROAD + Yosys](#5-build-openroad--yosys)
6. [Chuẩn bị PDK Sky130](#6-chuẩn-bị-pdk-sky130)
7. [Kích hoạt môi trường](#7-kích-hoạt-môi-trường)
8. [Kiểm thử RTL (cocotb)](#8-kiểm-thử-rtl-cocotb)
9. [Chạy RTL → GDS từng bước](#9-chạy-rtl--gds-từng-bước)
10. [Xem kết quả & layout](#10-xem-kết-quả--layout)
11. [Sign-off DRC (tuỳ chọn)](#11-sign-off-drc-tuỳ-chọn)
12. [Design khác & ASAP7](#12-design-khác--asap7)
13. [Lỗi thường gặp](#13-lỗi-thường-gặp)
14. [Cấu trúc thư mục](#14-cấu-trúc-thư-mục)
15. [FAQ](#15-faq)

---

## 1. Bạn sẽ làm được gì?

```text
Verilog RTL  →  Synthesis (Yosys)
             →  Floorplan / Place / CTS / Route (OpenROAD)
             →  DEF + SPEF + reports
             →  GDSII (KLayout Python)
             →  (tuỳ chọn) Magic DRC
```

Sau setup, design mẫu **HammingCode_128bit** (mã sửa lỗi SEC-DED 128-bit) chạy trên **SkyWater 130nm (sky130hd)**.

---

## 2. Hai kịch bản dùng repo

| Kịch bản | Ai dùng | Cách làm |
|----------|---------|----------|
| **A. Clone GitHub (phổ biến)** | Mọi người tải từ GitHub | Làm **mục 3 → 11** bên dưới |
| **B. Nhận full folder prebuilt** | Ai được copy USB/AirDrop đã build sẵn | Chỉ `./setup.sh` + `source env` + chạy design |

> GitHub **không** chứa binary OpenROAD (~GB). Kịch bản A **bắt buộc build một lần**.  
> Không phải “download zip là chạy ngay”, nhưng script đã gom bước cài deps.

---

## 3. Chuẩn bị máy

### 3.1 Bắt buộc Apple Silicon

```bash
uname -m
# Phải in: arm64
```

Nếu ra `x86_64` → máy Intel: **đừng** dùng hướng dẫn native này; dùng Docker/Linux.

### 3.2 Xcode Command Line Tools

```bash
xcode-select --install
xcode-select -p
# /Library/Developer/CommandLineTools
```

### 3.3 Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
brew --version
```

---

## 4. Cài lab kit + dependencies

### 4.1 Clone repo

```bash
cd ~/Documents
git clone https://github.com/NghiaVu1705/OpenROAD-native-on-MacOS.git
cd OpenROAD-native-on-MacOS
```

Gọi thư mục này là **`OPENROAD_HOME`** (ví dụ: `/Users/ban/Documents/OpenROAD-native-on-MacOS`).

### 4.2 Chạy bootstrap (khuyên dùng)

Script cài:

- coreutils, gnu-sed, thư viện runtime OpenROAD  
- icarus-verilog, verilator  
- Python packages: klayout, cocotb, pyuvm, pyyaml  
- Clone `ORFS_Source` (OpenROAD-flow-scripts recursive)

```bash
chmod +x scripts/*.sh setup.sh
./scripts/bootstrap_macos.sh
```

Nếu không dùng script, cài tay:

```bash
brew install \
  coreutils gnu-sed \
  tcl-tk@8 or-tools protobuf re2 highs scip \
  libomp qt@5 yaml-cpp spdlog fmt \
  icarus-verilog verilator cmake ninja swig bison flex git wget pkg-config

PY39=/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/bin/python3.9
$PY39 -m pip install --user klayout "cocotb>=1.9.0" cocotb-bus pyuvm pyyaml

git clone --recursive \
  https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git \
  ORFS_Source
```

---

## 5. Build OpenROAD + Yosys

Đây là bước **lâu nhất** (thường 30–90 phút).

```bash
cd ~/Documents/OpenROAD-native-on-MacOS/ORFS_Source

export OpenMP_ROOT=$(brew --prefix libomp)
export LDFLAGS="-L$(brew --prefix libomp)/lib"
export CPPFLAGS="-I$(brew --prefix libomp)/include -Xpreprocessor -fopenmp"
export CC=clang
export CXX=clang++

./build_openroad.sh --local
```

### Kiểm tra build

```bash
./tools/install/OpenROAD/bin/openroad -version
# Ví dụ: 26Q1-....

./tools/install/yosys/bin/yosys -V
# Yosys 0.xx ...
```

### Lỗi build thường gặp

| Lỗi | Cách xử lý |
|-----|------------|
| `OpenMP_CXX not found` | Cài `libomp`, export `OpenMP_ROOT` / `LDFLAGS` / `CPPFLAGS` như trên |
| `FLEX_INCLUDE_DIR NOTFOUND` | `brew install flex`; có thể cần `FLEX_INCLUDE_DIRS=$(brew --prefix flex)/include` |
| `CUDD_LIB NOTFOUND` | ORFS thường tự build CUDD; xem log build; chi tiết trong ReSearchDocument |
| Build test timeout | Build chỉ target openroad nếu cần (xem ReSearchDocument Phụ lục B) |
| Link `Boost::system` | Boost header-only mới: bỏ `Boost::system` trong CMake dst (ReSearchDocument) |

**Chi tiết 14 lỗi M1:** [ReSearchDocument/README.md — Phụ lục B](../ReSearchDocument/README.md)

> Lưu ý: OpenROAD **link động** tới Homebrew. Sau `brew upgrade` lớn, binary có thể **gãy** → build lại hoặc pin version thư viện.

---

## 6. Chuẩn bị PDK Sky130

ORFS clone về đôi khi **thiếu** liberty / LEF merge / GDS / RCX rules. Chạy:

```bash
cd ~/Documents/OpenROAD-native-on-MacOS
./scripts/prepare_sky130hd_platform.sh
```

Script sẽ:

1. Copy `.lib` / `.lef` / `rcx_patterns.rules` từ `ORFS_Source/tools/OpenROAD/test/sky130hd`  
2. Nếu thiếu GDS: clone cell library efabless và **merge** thành `sky130_fd_sc_hd.gds` (cần `klayout` Python)

Kiểm tra tay:

```bash
ls -lh ORFS_Source/flow/platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
ls -lh ORFS_Source/flow/platforms/sky130hd/lef/sky130_fd_sc_hd_merged.lef
ls -lh ORFS_Source/flow/platforms/sky130hd/rcx_patterns.rules
ls -lh ORFS_Source/flow/platforms/sky130hd/gds/sky130_fd_sc_hd.gds
```

---

## 7. Kích hoạt môi trường

```bash
cd ~/Documents/OpenROAD-native-on-MacOS
./setup.sh
# Hỏi thêm PATH vào ~/.zprofile → chọn Y

source ~/.zprofile
source Sky130_Workspace/HammingCode_128bit/env_setup.sh
```

**In ra đúng kiểu này mới OK:**

```text
OPENROAD_HOME : /Users/.../OpenROAD-native-on-MacOS
openroad : .../ORFS_Source/tools/install/OpenROAD/bin/openroad
yosys    : .../ORFS_Source/tools/install/yosys/bin/yosys
python3.9: .../python3.9
klayout  : .../Sky130_Workspace/bin/klayout
realpath : GNU coreutils ...
```

Nếu `OPENROAD_HOME` thành `/Users/tenban` (sai): đang dùng script cũ hoặc `source` lỗi — cập nhật `env_setup.sh` từ repo (đã hỗ trợ **zsh**).

Mỗi terminal mới:

```bash
source ~/.zprofile
source ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace/HammingCode_128bit/env_setup.sh
```

---

## 8. Kiểm thử RTL (cocotb)

Không bắt buộc trước P&R, nhưng **nên** chạy:

```bash
cd ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace/HammingCode_128bit/Verifications
make SIM=icarus
```

Mong đợi các test Hamming PASS (encoder/decoder/SEC/DED…).

---

## 9. Chạy RTL → GDS từng bước

Luôn bật env trước (mục 7).

### Cách A — Script gọn (P&R)

```bash
cd ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace
./run.sh HammingCode_128bit
```

Sinh ra `6_final.def` (và các stage odb) trong:

```text
ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/
```

### Cách B — Từng stage (học / debug) ← khuyên dùng lần đầu

```bash
source ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace/HammingCode_128bit/env_setup.sh
cd ~/Documents/OpenROAD-native-on-MacOS/ORFS_Source/flow

export DESIGN_CONFIG=~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace/HammingCode_128bit/config.mk
# Gợi ý: dùng path tuyệt đối
export DESIGN_CONFIG="$(cd ../.. && pwd)/Sky130_Workspace/HammingCode_128bit/config.mk"
```

| Bước | Lệnh | Output chính |
|------|------|----------------|
| 1. Synthesis | `make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 synth` | `1_2_yosys.v`, `1_synth.odb` |
| 2. Floorplan | `make ... floorplan` | `2_floorplan.odb` |
| 3. Place | `make ... place` | `3_place.odb` |
| 4. CTS | `make ... cts` | `4_cts.odb` |
| 5. Route | `make ... route` | `5_route.odb` (lâu nhất) |
| 6. Finish/report | `make ... do-6_report` | `6_final.def`, `.spef`, reports |

`...` = `DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0`

**Ví dụ một lệnh đầy đủ:**

```bash
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 route
```

### GDS (DEF → GDSII)

ORFS `make finish` đôi khi đòi binary KLayout GUI. Lab này dùng **Python API**:

```bash
cd ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace/HammingCode_128bit
python3.9 ./run_def2gds.py
```

**File GDS:**

```text
ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.gds
```

### One-shot script (khi đã quen)

```bash
cd ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace/HammingCode_128bit
./run_flow_complete.sh --from 3
# --from 3: synth → P&R → GDS → DRC (nếu có Magic)
# ./run_flow_complete.sh --help
```

---

## 10. Xem kết quả & layout

### Metrics timing / area

```bash
cd ~/Documents/OpenROAD-native-on-MacOS/ORFS_Source/flow

grep -E "wns|tns|Design area" \
  reports/sky130hd/HammingCode_128bit/base/6_finish.rpt

ls -lh results/sky130hd/HammingCode_128bit/base/6_final.*
```

Ý nghĩa nhanh:

| Chỉ số | Ý nghĩa |
|--------|---------|
| **WNS = 0** | Timing setup đạt (tốt) |
| **WNS &lt; 0** | Vi phạm setup — nới `CLOCK_PERIOD` trong `config.mk` / SDC |
| **Design area** | Diện tích core (µm²) + % utilization |
| **Power** | Ước lượng từ report (góc liberty) |

### Mở GUI OpenROAD

```bash
source ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace/HammingCode_128bit/env_setup.sh
openroad -gui -db \
  ~/Documents/OpenROAD-native-on-MacOS/ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.odb
```

### Ảnh layout tĩnh (nếu ORFS đã render)

```bash
open ~/Documents/OpenROAD-native-on-MacOS/ORFS_Source/flow/reports/sky130hd/HammingCode_128bit/base/
# final_all.webp, final_routing.webp, ...
```

---

## 11. Sign-off DRC (tuỳ chọn)

Cần build **Magic** + tech `sky130A` (xem ReSearchDocument mục build Magic).

Khi đã có `tools/install/magic/bin/magic`:

```bash
source ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace/HammingCode_128bit/env_setup.sh
cd ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace/HammingCode_128bit
./run_flow_complete.sh --only 6
```

Mong đợi: `DRC Total Violations: 0`.

LVS (Netgen) phức tạp hơn trên Mac — xem research doc; không bắt buộc để học P&R.

---

## 12. Design khác & ASAP7

### Sky130 — design khác

```bash
cd ~/Documents/OpenROAD-native-on-MacOS/Sky130_Workspace
./run.sh CamAI_SNN
./run.sh Bio_health
```

### ASAP7 (học thuật 7nm)

```bash
cd ~/Documents/OpenROAD-native-on-MacOS/ASAP7_Workspace
./run.sh HammingCode_128bit
```

ASAP7 **không** dùng tape-out Efabless; phù hợp so sánh / nghiên cứu.

### Thêm design mới

1. Copy thư mục `HammingCode_128bit` → `MyDesign`  
2. Sửa `src/*.v`, `config.mk` (`DESIGN_NAME`, `VERILOG_FILES`), `constraints/constraint.sdc`  
3. `./run.sh MyDesign`  

Chi tiết: ReSearchDocument mục “Tạo thiết kế mới”.

---

## 13. Lỗi thường gặp

### Môi trường

| Triệu chứng | Nguyên nhân | Cách xử |
|-------------|-------------|---------|
| `OPENROAD_HOME` = `/Users/you` | `source` zsh + script cũ | Dùng `env_setup.sh` mới từ repo |
| `realpath: command not found` / BSD realpath | Thiếu GNU coreutils trong PATH | `brew install coreutils`; `source env_setup.sh` |
| `python3.9: command not found` | CLT Python chưa trong PATH | `source env_setup.sh` hoặc thêm path CLT |
| `openroad` exit 137 / Library not loaded | Thiếu/sai version dylib Homebrew | `brew install` lại deps; rebuild openroad |
| `yosys` lấy bản Homebrew | PATH ưu tiên brew | `source env_setup.sh` (ưu tiên ORFS yosys) |

### Flow

| Triệu chứng | Cách xử |
|-------------|---------|
| `Nothing to be done for synth` nhưng fail `1_synth.v` | ORFS mới dùng `1_2_yosys.v` / `1_synth.odb` — script mới đã sửa |
| Missing `sky130_fd_sc_hd__tt_025C_1v80.lib` | `./scripts/prepare_sky130hd_platform.sh` |
| `RCX-0468 Can't open rcx_patterns.rules` | Cùng script prepare (copy rcx rules) |
| `KLayout not found` khi `make finish` | Dùng `python3.9 run_def2gds.py` thay GUI |
| WNS âm lớn | Tăng `CLOCK_PERIOD` trong `config.mk` và SDC (ví dụ 10 → 12 ns) |

### Xoá kết quả cũ để chạy lại

```bash
cd ~/Documents/OpenROAD-native-on-MacOS/ORFS_Source/flow
export DESIGN_CONFIG=.../HammingCode_128bit/config.mk
make DESIGN_CONFIG=$DESIGN_CONFIG clean_all
# hoặc
rm -rf results/sky130hd/HammingCode_128bit logs/sky130hd/HammingCode_128bit \
       reports/sky130hd/HammingCode_128bit objects/sky130hd/HammingCode_128bit
```

---

## 14. Cấu trúc thư mục

```text
OpenROAD-native-on-MacOS/          ← OPENROAD_HOME (repo GitHub)
├── README.md
├── docs/
│   ├── QUICKSTART.md              ← 1 trang
│   └── HUONG_DAN_DAY_DU.md        ← file này
├── scripts/
│   ├── bootstrap_macos.sh         ← deps + clone ORFS
│   └── prepare_sky130hd_platform.sh
├── setup.sh
├── Sky130_Workspace/
│   ├── run.sh
│   ├── HammingCode_128bit/
│   │   ├── src/                   ← RTL
│   │   ├── config.mk
│   │   ├── constraints/
│   │   ├── Verifications/         ← cocotb
│   │   ├── env_setup.sh
│   │   ├── run_flow_complete.sh
│   │   └── run_def2gds.py
│   ├── CamAI_SNN/
│   └── Bio_health/
├── ASAP7_Workspace/
├── ReSearchDocument/              ← guide nghiên cứu dài + benchmark
└── ORFS_Source/                   ← KHÔNG có trên GitHub; bạn clone/build
    ├── tools/install/OpenROAD/bin/openroad
    ├── tools/install/yosys/bin/yosys
    └── flow/results/...           ← output P&R
```

---

## 15. FAQ

**Hỏi: Clone xong chạy 1 lệnh là xong?**  
Không. Phải bootstrap + **build OpenROAD một lần**, rồi prepare PDK, rồi chạy design. Sau lần 1, mỗi ngày chỉ `source env` + `./run.sh`.

**Hỏi: Có chạy được trên Windows / Intel Mac?**  
Hướng dẫn này: **không**. Dùng WSL2/Linux hoặc Docker.

**Hỏi: Cần GPU không?**  
Không.

**Hỏi: RAM 8 GB có đủ không?**  
Đủ cho Hamming / design nhỏ–vừa. Design rất lớn có thể swap chậm hoặc OOM.

**Hỏi: Có phải gửi chip nhà máy được không?**  
GDS Sky130 là **hướng tape-out học thuật/open** (Efabless-class). Vẫn cần DRC/LVS/sign-off đầy đủ và tuân thủ yêu cầu shuttle — **không bảo đảm** tape-out chỉ vì có file GDS.

**Hỏi: License?**  
Script/doc lab: Apache-2.0 (repo). OpenROAD/Yosys/Magic/PDK: license riêng của từng dự án.

**Hỏi: Gặp lỗi build không có trong list?**  
Mở issue trên GitHub kèm: macOS version, `uname -m`, log lỗi, commit ORFS.

---

## Lộ trình học gợi ý

| Ngày | Việc |
|------|------|
| 1 | Bootstrap + build ORFS + prepare PDK |
| 2 | cocotb Hamming + synth + floorplan + place |
| 3 | CTS + route + finish + GDS + xem GUI |
| 4 | Đọc WNS/area; thử đổi `CLOCK_PERIOD` |
| 5 | Chạy CamAI_SNN hoặc tạo design 8-bit adder riêng |

---

## Liên kết nhanh

| Tài liệu | Link |
|----------|------|
| Repo | https://github.com/NghiaVu1705/OpenROAD-native-on-MacOS |
| Quickstart | [QUICKSTART.md](QUICKSTART.md) |
| Research (VI, sâu) | [../ReSearchDocument/README.md](../ReSearchDocument/README.md) |
| OpenROAD upstream | https://github.com/The-OpenROAD-Project/OpenROAD |
| ORFS | https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts |

---

*Chúc bạn chạy flow thành công. Nếu doc này giúp được, star repo giúp người khác tìm thấy.*

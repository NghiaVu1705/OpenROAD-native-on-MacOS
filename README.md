# OpenROAD Native on macOS (Apple Silicon)

[![Platform](https://img.shields.io/badge/platform-macOS%20Apple%20Silicon-black)](https://github.com/NghiaVu1705/OpenROAD-native-on-MacOS)
[![Flow](https://img.shields.io/badge/flow-RTL%20→%20GDSII-blue)](docs/HUONG_DAN_DAY_DU.md)
[![PDK](https://img.shields.io/badge/PDK-Sky130%20%7C%20ASAP7-green)](docs/HUONG_DAN_DAY_DU.md)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Lab kit chạy **[OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD) native** trên Mac **M1/M2/M3/M4** (không cần Docker cho luồng chính): RTL → place & route → GDS, kèm design mẫu và tài liệu tiếng Việt.

---

## Bắt đầu từ đây (chọn 1)

| Bạn là… | Đọc file |
|---------|----------|
| **Muốn làm theo từ A→Z (tiếng Việt)** | **[docs/HUONG_DAN_DAY_DU.md](docs/HUONG_DAN_DAY_DU.md)** ← **đầy đủ nhất** |
| Chỉ cần checklist 1 trang | [docs/QUICKSTART.md](docs/QUICKSTART.md) |
| Muốn hiểu patch build / benchmark M1 | [ReSearchDocument/README.md](ReSearchDocument/README.md) |
| English summary | Sections below |

---

## Cài nhanh (tóm tắt)

```bash
# 1) Clone
git clone https://github.com/NghiaVu1705/OpenROAD-native-on-MacOS.git
cd OpenROAD-native-on-MacOS

# 2) Deps + clone OpenROAD-flow-scripts
chmod +x scripts/*.sh setup.sh
./scripts/bootstrap_macos.sh

# 3) Build OpenROAD + Yosys (30–90 phút)
cd ORFS_Source
export OpenMP_ROOT=$(brew --prefix libomp)
export LDFLAGS="-L$(brew --prefix libomp)/lib"
export CPPFLAGS="-I$(brew --prefix libomp)/include -Xpreprocessor -fopenmp"
./build_openroad.sh --local
cd ..

# 4) PDK sky130hd (lib / lef / rcx / gds)
./scripts/prepare_sky130hd_platform.sh

# 5) PATH
./setup.sh && source ~/.zprofile
source Sky130_Workspace/HammingCode_128bit/env_setup.sh

# 6) Chạy design mẫu
cd Sky130_Workspace && ./run.sh HammingCode_128bit

# 7) GDS
cd HammingCode_128bit && python3.9 ./run_def2gds.py
```

**Yêu cầu:** `uname -m` → `arm64` · macOS 13+ · ~25 GB trống · lần đầu **không** xong trong 5 phút (phải build tool).

---

## Repo có gì / không có gì

| Có trên GitHub | Bạn tự cài / build |
|----------------|-------------------|
| Workspace 3 design (Sky130 + ASAP7) | `ORFS_Source/` (OpenROAD + Yosys) |
| Script chạy flow, GDS, cocotb | Binary `openroad`, `yosys` |
| `bootstrap_macos.sh`, `prepare_sky130hd_platform.sh` | (Tuỳ chọn) Magic / Netgen DRC·LVS |
| Hướng dẫn VI đầy đủ | |

Không push full prebuilt (~GB) vì giới hạn GitHub và binary gắn máy.

---

## Design mẫu

| Design | Mô tả |
|--------|--------|
| **HammingCode_128bit** | SEC-DED Hamming — demo chính RTL→GDS |
| **CamAI_SNN** | Mạng nơ-ron xung LIF nhỏ |
| **Bio_health** | Pipeline xử lý tín hiệu sinh học đơn giản |

---

## Xem layout

```bash
source Sky130_Workspace/HammingCode_128bit/env_setup.sh
openroad -gui -db ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.odb
```

---

## English overview

This repository is a **portable OpenROAD lab** for **Apple Silicon Macs**: sample RTL, cocotb tests, run scripts, and docs to build **OpenROAD-flow-scripts natively** (not Docker-first).

1. Run `./scripts/bootstrap_macos.sh`  
2. Build with `./build_openroad.sh --local` inside `ORFS_Source`  
3. Run `./scripts/prepare_sky130hd_platform.sh`  
4. `./setup.sh` + `source Sky130_Workspace/HammingCode_128bit/env_setup.sh`  
5. `./Sky130_Workspace/run.sh HammingCode_128bit` then `python3.9 run_def2gds.py`  

Full Vietnamese walkthrough: **[docs/HUONG_DAN_DAY_DU.md](docs/HUONG_DAN_DAY_DU.md)**.

---

## License & upstream

- Lab scripts & docs: [Apache-2.0](LICENSE)  
- OpenROAD, Yosys, Magic, Netgen, PDKs: their own licenses  

**Disclaimer:** Educational / research use. Not a guarantee of foundry tape-out readiness.

---

## Contributing

Issues/PRs welcome (macOS ARM build tips, doc fixes, new small designs).  
Please do **not** commit multi‑GB `ORFS_Source/tools` trees or machine-local install binaries.

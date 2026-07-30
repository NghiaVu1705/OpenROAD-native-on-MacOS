# Quickstart — 1 trang (macOS Apple Silicon)

> Mục tiêu: từ máy mới → chạy được **HammingCode_128bit** RTL → DEF/GDS.  
> Máy: **M1/M2/M3/M4** (`uname -m` phải là `arm64`). **Không** hỗ trợ Intel Mac trong hướng dẫn này.

Thời gian ước tính lần đầu: **1.5–3 giờ** (chủ yếu build OpenROAD).

---

## Checklist nhanh

```text
[ ] 1. Clone repo lab
[ ] 2. Cài Xcode CLT + Homebrew
[ ] 3. Chạy scripts/bootstrap_macos.sh   (deps + Python + clone ORFS)
[ ] 4. Build OpenROAD + Yosys
[ ] 5. scripts/prepare_sky130hd_platform.sh
[ ] 6. ./setup.sh && source env
[ ] 7. Chạy flow Hamming
```

---

## Lệnh copy-paste (tóm tắt)

```bash
# 0) Kiểm tra chip
uname -m   # phải: arm64

# 1) Clone lab kit
cd ~/Documents
git clone https://github.com/NghiaVu1705/OpenROAD-native-on-MacOS.git
cd OpenROAD-native-on-MacOS

# 2) Bootstrap (Homebrew deps, Python, clone ORFS)
chmod +x scripts/*.sh setup.sh
./scripts/bootstrap_macos.sh

# 3) Build ORFS (lâu — 30–90 phút)
cd ORFS_Source
./build_openroad.sh --local
# Nếu lỗi OpenMP / FLEX: xem docs/HUONG_DAN_DAY_DU.md mục "Lỗi build thường gặp"
cd ..

# 4) Bổ sung file PDK sky130hd (lib/lef/rcx/gds)
./scripts/prepare_sky130hd_platform.sh

# 5) PATH + kiểm tra tool
./setup.sh
source ~/.zprofile
source Sky130_Workspace/HammingCode_128bit/env_setup.sh

# 6) Verify tool
openroad -version
yosys -V
realpath --version

# 7a) Chỉ P&R (RTL → DEF)
cd Sky130_Workspace && ./run.sh HammingCode_128bit

# 7b) Hoặc từng bước + GDS (khuyên dùng khi học)
cd ~/Documents/OpenROAD-native-on-MacOS
source Sky130_Workspace/HammingCode_128bit/env_setup.sh
cd ORFS_Source/flow
export DESIGN_CONFIG="$(cd ../.. && pwd)/Sky130_Workspace/HammingCode_128bit/config.mk"
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 synth
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 floorplan
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 place
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 cts
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 route
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 do-6_report

cd ../../Sky130_Workspace/HammingCode_128bit
python3.9 ./run_def2gds.py
```

**Kết quả mong đợi:**

```text
ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.def
ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.gds
```

**Xem layout:**

```bash
openroad -gui -db ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.odb
```

---

## Nếu kẹt

| Lỗi | Xem |
|-----|-----|
| Build fail | [HUONG_DAN_DAY_DU.md](HUONG_DAN_DAY_DU.md) § Build |
| Thiếu lib/GDS/RCX | Chạy lại `prepare_sky130hd_platform.sh` |
| `OPENROAD_HOME` sai | `source .../env_setup.sh` (đã hỗ trợ zsh) |
| Chi tiết đầy đủ | [HUONG_DAN_DAY_DU.md](HUONG_DAN_DAY_DU.md) |
| Nghiên cứu / benchmark | [../ReSearchDocument/README.md](../ReSearchDocument/README.md) |

# OpenROAD Native on macOS (Apple Silicon)

[![Platform](https://img.shields.io/badge/platform-macOS%20Apple%20Silicon-black)](.)
[![Flow](https://img.shields.io/badge/flow-RTL%20%E2%86%92%20GDSII-blue)](.)
[![PDK](https://img.shields.io/badge/PDK-Sky130%20%7C%20ASAP7-green)](.)

**Open-source digital ASIC lab kit** for running [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD) **natively** on MacBooks with Apple Silicon (M1/M2/M3/M4) — without Docker/Rosetta for the main flow.

> **What you get:** portable workspaces, sample RTL designs, cocotb verification, RTL→GDS scripts, sign-off helpers (Magic DRC / Netgen LVS), and a full Vietnamese+English research guide for building ORFS on macOS ARM64.

**Author / maintainer context:** research & teaching setup for OpenROAD on Apple Silicon.

---

## Why this repo?

| Problem | This project |
|---------|----------------|
| OpenROAD is Linux/Docker-first | Documented **native ARM64** build path |
| “Just clone ORFS” is painful on Mac | **14 known build issues + fixes** (see docs) |
| Only GCD demo | **3 real designs** + verification harness |
| P&R without sign-off | Scripts toward **GDS + Magic DRC** |

**Not a replacement** for commercial EDA or a production foundry tape-out kit.  
**Is** a reproducible lab for learning and research on Mac.

---

## Repository layout

```text
OpenROAD-native-on-MacOS/
├── README.md                 ← you are here
├── setup.sh                  ← one-time PATH / tool check after tools exist
├── openroad.cfg
├── Sky130_Workspace/         ← SkyWater 130nm designs + run scripts
│   ├── run.sh
│   ├── HammingCode_128bit/   ← SEC-DED Hamming (RTL→GDS path mature)
│   ├── CamAI_SNN/            ← LIF spiking neural net (config ready)
│   └── Bio_health/           ← ECG/PPG-style biosignal (config ready)
├── ASAP7_Workspace/          ← same designs for ASAP7 (academic 7nm)
└── ReSearchDocument/         ← full setup guide + benchmarks (macOS M1)
```

**Not vendored here** (too large / machine-specific — install yourself):

- `ORFS_Source/` — OpenROAD-flow-scripts + OpenROAD + Yosys  
- `magic/`, `netgen/`, `open_pdks/`, `tools/install/` — sign-off builds  

See [ReSearchDocument/README.md](ReSearchDocument/README.md) for the complete native install guide.

---

## Quick start (after tools are built)

### 1. Prerequisites

- **macOS** on **Apple Silicon** (`uname -m` → `arm64`)
- Xcode Command Line Tools, Homebrew
- Built **ORFS** under `ORFS_Source/` (or symlink your build there)
- Optional: Magic, Netgen, open_pdks for DRC/LVS

Homebrew packages commonly required at **runtime**:

```bash
brew install \
  tcl-tk@8 or-tools protobuf re2 highs scip \
  libomp qt@5 yaml-cpp spdlog fmt \
  coreutils gnu-sed icarus-verilog verilator

# Python 3.9 (Xcode CLT) packages for verify + GDS
/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/bin/python3.9 \
  -m pip install --user klayout cocotb cocotb-bus pyuvm pyyaml
```

Pin Homebrew library majors when possible — OpenROAD links **dynamically**; a `brew upgrade` can break binaries until rebuild.

### 2. Clone this lab kit

```bash
git clone https://github.com/NghiaVu1705/OpenROAD-native-on-MacOS.git
cd OpenROAD-native-on-MacOS
```

### 3. Place or build ORFS

```bash
# Example: recursive clone beside this repo layout
git clone --recursive \
  https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git \
  ORFS_Source

cd ORFS_Source
./build_openroad.sh --local   # long; see ReSearchDocument for M1 patches
```

Expected binaries:

```text
ORFS_Source/tools/install/OpenROAD/bin/openroad
ORFS_Source/tools/install/yosys/bin/yosys
```

Sky130 platform may need liberty/LEF/GDS/RCX files under  
`ORFS_Source/flow/platforms/sky130hd/` (from OpenROAD tests / PDK — see research doc).

### 4. Environment + health check

```bash
chmod +x setup.sh Sky130_Workspace/run.sh ASAP7_Workspace/run.sh \
  Sky130_Workspace/HammingCode_128bit/*.sh 2>/dev/null

./setup.sh
source ~/.zprofile
source Sky130_Workspace/HammingCode_128bit/env_setup.sh
```

`OPENROAD_HOME` must point at **this** repo root (e.g. `.../OpenROAD-native-on-MacOS`).

### 5. Run RTL → GDS (Hamming, recommended first design)

**Step-by-step (ORFS):**

```bash
source Sky130_Workspace/HammingCode_128bit/env_setup.sh
cd ORFS_Source/flow
export DESIGN_CONFIG=$PWD/../../Sky130_Workspace/HammingCode_128bit/config.mk

make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 synth
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 floorplan
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 place
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 cts
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 route
make DESIGN_CONFIG=$DESIGN_CONFIG EQUIVALENCE_CHECK=0 LEC_CHECK=0 do-6_report
```

**GDS (KLayout Python API, no GUI binary required):**

```bash
cd ../../Sky130_Workspace/HammingCode_128bit
python3.9 ./run_def2gds.py
```

**One-shot script** (when tools + PDK files are complete):

```bash
cd Sky130_Workspace/HammingCode_128bit
./run_flow_complete.sh --from 3
```

**Outputs:**

```text
ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.def
ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.gds
```

**View layout:**

```bash
openroad -gui -db ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.odb
# or open reports/*.webp
```

### 6. Functional verification only

```bash
cd Sky130_Workspace/HammingCode_128bit/Verifications
make SIM=icarus
```

---

## Sample designs

| Design | Description | Sky130 | ASAP7 |
|--------|-------------|--------|-------|
| **HammingCode_128bit** | SEC-DED Hamming(137,128), ~100 MHz target | Primary demo | Config |
| **CamAI_SNN** | Small LIF SNN accelerator | Config | Config |
| **Bio_health** | Simple biosignal processing pipeline | Config | Config |

Example **measured** Hamming on Sky130 (native Apple Silicon lab run): area ~21k µm² @ ~76% util, **WNS/TNS = 0** @ 10 ns clock, GDS ~2 MB.  
Your numbers will vary with ORFS/OpenROAD version and PDK files.

---

## Performance notes (native M1)

From research appendix (GCD-class design):

- Full GCD P&R on the order of **~1–2 minutes** wall time  
- Routing dominates (~70%+)  
- Native ARM often **~2–3× faster** than Docker x86 under Rosetta  
- Still typically slower on detail route than high-core Linux desktops  

See **Phụ lục A–C** in [ReSearchDocument/README.md](ReSearchDocument/README.md).

---

## Documentation

| Doc | Content |
|-----|---------|
| [ReSearchDocument/README.md](ReSearchDocument/README.md) | Full Vietnamese guide: install, P&R stages, verify, DRC/LVS, new design |
| [ReSearchDocument/task.md](ReSearchDocument/task.md) | Checklist / status notes |
| Design `Docs/` under each workspace | Algorithm / task notes per chip |

---

## Troubleshooting (short)

| Symptom | Fix |
|---------|-----|
| `OPENROAD_HOME` is `$HOME` under zsh | Use updated `env_setup.sh` (zsh-safe `%x`) |
| `Library not loaded` / exit 137 | Reinstall brew deps matching link versions; rebuild OpenROAD |
| Missing `1_synth.v` | Newer ORFS uses `1_2_yosys.v` / `1_synth.odb` |
| Missing `rcx_patterns.rules` | Copy from OpenROAD `test/sky130hd/sky130hd.rcx_rules` |
| `KLayout not found` in make | Use `python3.9 run_def2gds.py` + `KLAYOUT_CMD=klayout` wrapper |
| `realpath` / `sed` errors | GNU coreutils + gnu-sed **before** BSD tools in `PATH` |

---

## Upstream projects

- [OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD)  
- [OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)  
- [Magic VLSI](https://github.com/RTimothyEdwards/magic)  
- [Netgen](https://github.com/RTimothyEdwards/netgen)  
- [open_pdks](https://github.com/RTimothyEdwards/open_pdks)  
- SkyWater SKY130 / ASAP7 PDKs  

Respect their licenses when redistributing binaries or PDK data.

---

## Contributing

Issues and PRs welcome for:

- macOS ARM build patches that stay compatible with current ORFS  
- Extra design configs / CI smoke tests  
- Doc fixes (EN/VI)

Please **do not** commit multi‑GB `ORFS_Source/tools` trees or machine-specific `tools/install` binaries in PRs.

---

## License

Lab scripts and documentation in this repository: see [LICENSE](LICENSE) (Apache-2.0).  
OpenROAD, Yosys, Magic, Netgen, and PDKs remain under **their own** licenses.

---

## Disclaimer

Educational / research use. No warranty that results are tape-out ready for any foundry shuttle. Always re-validate timing, DRC, LVS, and PDK versions for your target process.

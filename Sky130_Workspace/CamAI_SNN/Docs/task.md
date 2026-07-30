# CamAI_SNN – Task List
## Spiking CNN Accelerator for Smart City Traffic Monitoring
### Target: Tape-out on Sky130HD via Efabless Chipignite

**Platform:** Sky130HD (130nm) | **Tool:** OpenROAD native macOS M1
**Goal:** Energy-efficient SNN accelerator, ~18K cells, ~3–6mW, tape-out ready

---

## PHASE 1 – SOFTWARE

### 1.1 Environment Setup
- [ ] Cài PyTorch với MPS support (Apple Silicon)
  ```bash
  pip install torch torchvision torchaudio
  ```
- [ ] Cài SNN frameworks
  ```bash
  pip install snntorch          # primary: PyTorch-based, dễ dùng nhất
  pip install spikingjelly      # secondary: nhanh hơn, nhiều model hơn
  pip install tonic             # neuromorphic dataset loader (N-MNIST, DVS, Gen1...)
  ```
- [ ] Cài công cụ frame→spike conversion
  ```bash
  pip install v2e               # video → DVS event simulation
  # ESIM: git clone https://github.com/uzh-rpg/rpg_esim (nếu dùng CARLA)
  ```
- [ ] Cài thư viện phụ trợ
  ```bash
  pip install numpy matplotlib scikit-learn pandas tqdm tensorboard
  pip install opencv-python albumentations  # augmentation
  pip install roboflow                      # download Vietnamese datasets
  ```
- [ ] Verify MPS backend hoạt động trên M1
  ```python
  import torch
  print(torch.backends.mps.is_available())  # True
  ```

---

### 1.2 Dataset Preparation

> **Chiến lược 5 giai đoạn:** Pre-train → Domain train → Vietnamese fine-tune → Neuromorphic → Synthetic

#### Giai đoạn 1 – Baseline (SNN architecture validation)
- [ ] **CIFAR-10** — standard image classification baseline
  - `torchvision.datasets.CIFAR10` (tự download, ~163 MB)
  - Classes dùng: automobile (1), truck (9) → binary test trước
  - Mục tiêu: verify SNN architecture train được, >80% accuracy
  - Spike encoding: rate coding, T=4 timesteps

- [ ] **DVS-CIFAR10 (CIFAR10-DVS)** — event-native version
  - `tonic.datasets.CIFAR10DVS` (auto-download, ~5 GB)
  - 128×128 event stream, 10 classes
  - Mục tiêu: test SNN với data spike thật (không cần encode)

- [ ] **N-MNIST** — neuromorphic benchmark cơ bản nhất
  - `tonic.datasets.NMNIST` (auto-download, ~2 GB)
  - Mục tiêu: sanity check, SNN phải đạt >99% trước khi chuyển sang traffic

---

#### Giai đoạn 2 – Vehicle Detection (frame-based, quốc tế)
- [ ] **COCO Traffic Subset** — 40,000 ảnh, CC BY 4.0 (dùng được tự do)
  - Download: https://cocodataset.org/#download (train2017 ~19 GB)
  - Filter classes: person(1), bicycle(2), car(3), motorcycle(4), bus(6), truck(8), traffic light(10), stop sign(13)
  - Tool: `pip install pycocotools`

- [ ] **BDD100K** — 100K ảnh, motorcycle+bicycle classes
  - Download: http://bdd-data.berkeley.edu/ (đăng ký free, ~5 GB images)
  - Classes dùng: person, rider, car, truck, bus, motor, bike, traffic light, traffic sign

- [ ] **MIO-TCD** — 786,702 ảnh từ camera giám sát giao thông
  - Download: http://tcd.miovision.com/ (research license)
  - Classes: car, bus, truck, motorcycle, bicycle, pedestrian, pickup truck, articulated truck, work van
  - **Lý do chọn:** Largest traffic surveillance dataset, motorcycle class có nhãn rõ

- [ ] **UA-DETRAC** — 140,000 frame từ camera giao thông Bắc Kinh
  - Download Roboflow sample: https://universe.roboflow.com/vehicle-detection-loakn/ua-detrac-10k-sample
  - **Lý do chọn:** Quay tại Bắc Kinh → Asian traffic pattern, gần với Việt Nam
  - Lưu ý: chỉ có car/bus/truck/van, không có motorcycle

---

#### Giai đoạn 3 – Vietnamese/Asian Traffic (fine-tuning, quan trọng nhất)
- [ ] **Vietnam AI Challenge 2020** — 11,000 ảnh từ camera Hà Nội + HCMC
  - Download: https://github.com/QuangTranUTE/Vehicle-Detection
  - Classes: car, bus, truck, motorcycle
  - **Lý do chọn:** Quay tại Việt Nam, traffic pattern thực tế nhất, xe máy chiếm đa số
  - Split: 9,000 train / 1,276 test (theo paper)

- [ ] **Vietnamese Vehicle Dataset (Roboflow)** — 1,547 ảnh
  - Download: `roboflow download` hoặc https://universe.roboflow.com/car-classification/vietnamese-vehicle/dataset/3
  - Dùng làm validation set bổ sung

- [ ] **HCMC Vehicle Detection** — camera TPHCM realtime
  - GitHub: https://github.com/LeNguyenGiaBao/vehicle_detection
  - Dùng làm test set cuối

- [ ] **DATS_2022 — Indian Traffic** (CC BY, tốt nhất cho Asian traffic)
  - Download: https://data.mendeley.com/datasets/nfc34n8svj/2 (~2 GB)
  - 10,000+ ảnh, 45 classes kể cả rickshaw, auto-rickshaw (= xe ba gác Việt Nam)
  - **Lý do chọn:** CC BY license (hoàn toàn mở), Indian traffic ≈ Vietnamese traffic (hỗn loạn, xe máy nhiều)

- [ ] **Poribohon-BD / Vehicle-BD** — Bangladesh (9,058 + 12,413 ảnh)
  - GitHub: https://github.com/shairatabassum/BangladeshiVehiclesDataset
  - Classes: bus, motorbike, three-wheeler rickshaw, truck, car, CNG auto-rickshaw, easy bike, bicycle, van
  - **Lý do chọn:** CNG / rickshaw = proxy cho xe ba gác, xe lôi Việt Nam

- [ ] **nuScenes Singapore Subset** — ~450 scenes chụp tại Singapore
  - Download: https://www.nuscenes.org/ (registration, free)
  - Filter location = Singapore (One-North, Queenstown, Holland Village)
  - **Lý do chọn:** Southeast Asian urban, labeled motorcycle/bicycle, chất lượng cao nhất trong nhóm

---

#### Giai đoạn 4 – Neuromorphic Event Data (ideal for SNN hardware)
- [ ] **NCARS (N-Cars)** — car vs background, event camera
  - `tonic.datasets.NCARS` (auto-download, ~3.5 GB)
  - 24,029 samples, binary classification, 100×100 pixels
  - **Mục tiêu:** Validate SNN hardware với event data thật

- [ ] **Gen1 Automotive Detection (Prophesee)** — 39 giờ lái xe
  - Download: https://www.prophesee.ai/2020/01/24/prophesee-gen1-automotive-detection-dataset/ (đăng ký)
  - 228,000 annotated bounding boxes, car + pedestrian
  - **Đây là benchmark chính cho SNN automotive detection**
  - SpikeYOLO 2025 đạt 67.2% mAP@50 trên dataset này

- [ ] **1Mpx Detection Dataset (Prophesee)** — HD 1 megapixel, two-wheeler class
  - Download: https://www.prophesee.ai/2020/11/24/automotive-megapixel-event-based-dataset/ (đăng ký)
  - 25 triệu bounding boxes, **two-wheeler class** có nhãn rõ
  - **Lý do chọn:** Two-wheeler = proxy cho xe máy

- [ ] **DSEC** — stereo event camera, CC BY-SA 4.0
  - Download: https://dsec.ifi.uzh.ch/dsec-datasets/download/ (~450 GB train+test)
  - Stereo events + RGB + LiDAR + RTK GPS
  - **Lý do chọn:** Duy nhất có CC BY-SA license trong nhóm event automotive

---

#### Giai đoạn 5 – Synthetic Data (augmentation + Hanoi simulation)
- [ ] **v2e: Video → DVS event conversion**
  - `pip install v2e`
  - Áp dụng cho: video giao thông Hà Nội bất kỳ → event stream cho SNN
  - **Quan trọng:** Không cần event camera vật lý, dùng video quay bằng điện thoại được

- [ ] **CARLA + SUMO: Hanoi traffic simulation**
  - Cài CARLA: https://carla.org/ (~30 GB)
  - Import bản đồ Hà Nội từ OpenStreetMap qua SUMO
  - Cấu hình: 70% xe máy, 20% ô tô, 10% xe tải/buýt
  - Generate synthetic training images từ góc camera giám sát
  - Tùy chọn: dùng ESIM để convert sang event stream

- [ ] **GTA V Traffic Dataset** — 10,000 ảnh tổng hợp
  - Download: https://zenodo.org/records/6560038 (~8 GB)
  - Dùng cho domain adaptation experiments

---

#### Tổng Hợp Dataset Theo Priority

| Priority | Dataset | Samples | Đặc điểm | License | Size |
|----------|---------|---------|-----------|---------|------|
| ⭐⭐⭐ | Vietnam AI Challenge 2020 | 11,000 | Camera Hà Nội + HCMC thật | Research | ~3 GB |
| ⭐⭐⭐ | DATS_2022 (India) | 10,000+ | Asian traffic, CC BY | CC BY ✅ | ~2 GB |
| ⭐⭐⭐ | CIFAR-10 | 60,000 | Baseline validation | MIT ✅ | 163 MB |
| ⭐⭐ | MIO-TCD | 786,702 | Largest surveillance dataset | Research | ~20 GB |
| ⭐⭐ | BDD100K | 100,000 | Motor/bike classes | Research | ~5 GB |
| ⭐⭐ | NCARS | 24,029 | Event-native car detection | Research | 3.5 GB |
| ⭐⭐ | Gen1 Automotive | 228K boxes | Event automotive SOTA | Research | ~270 GB |
| ⭐ | nuScenes Singapore | ~450 scenes | SE Asian, high quality | Research | ~300 GB |
| ⭐ | Poribohon-BD | 21,471 | Rickshaw/CNG ≈ xe ba gác VN | Research | ~1.5 GB |
| ⭐ | DVS-CIFAR10 | 10,000 | Event-native, SNN validation | CC | 5 GB |
| tool | v2e converter | — | Video Hà Nội → event spike | MIT ✅ | — |

---

#### Data Pipeline Tasks
- [ ] Viết `dataset.py`: unified DataLoader cho tất cả datasets trên
- [ ] Viết `spike_encoder.py`: 3 loại encoding
  - Rate coding: `snntorch.spikegen.rate(data, num_steps=T)`
  - Latency coding: `snntorch.spikegen.latency(data, num_steps=T)`
  - Delta modulation (video): `snntorch.spikegen.delta(data, threshold=0.1)`
- [ ] Viết `preprocess.py`: resize về 28×28 grayscale, normalize, augment
- [ ] Viết `v2e_convert.py`: batch convert video giao thông Hà Nội → event stream
- [ ] Tạo unified label map: {0:car, 1:truck, 2:bus, 3:motorcycle, 4:bicycle, 5:pedestrian, 6:traffic_light, 7:background}

---

### 1.3 Model Architecture
- [ ] Định nghĩa Spiking CNN architecture (`model.py`)
  ```
  Input: 28×28×1 (grayscale)
  SpikeConv1: 3×3, 4 filters, LIF, padding=0 → 26×26×4
  SpikePool1: 2×2 → 13×13×4
  SpikeConv2: 3×3, 8 filters, LIF, padding=0 → 11×11×8
  SpikePool2: 2×2 → 5×5×8 = 200
  FC1: 200 → 64, LIF
  FC2: 64 → 8, LIF
  Output: 8 classes (argmax)
  ```
- [ ] Implement LIF neuron layer với snnTorch
  - beta (leak): trainable hoặc fixed
  - threshold: 1.0
  - reset mechanism: zero reset
- [ ] Implement membrane potential recording (cần cho hardware mapping)

---

### 1.4 Training
- [ ] Viết training loop (`train.py`)
  - Loss: Cross-entropy trên spike count output
  - Optimizer: Adam, lr=1e-3
  - Scheduler: CosineAnnealingLR
  - T=4 timesteps
  - Device: MPS (M1 GPU) hoặc CPU fallback
- [ ] Train trên CIFAR-10
  - Target accuracy: **>80%**
  - Epochs: 50–100
  - Batch size: 128
  - Log với TensorBoard
- [ ] Fine-tune trên traffic dataset
  - Target accuracy: **>85%**
  - Transfer learning từ CIFAR-10 weights
- [ ] Lưu best model checkpoint (`best_model.pth`)

---

### 1.5 Evaluation & Analysis
- [ ] Confusion matrix cho 8 classes
- [ ] Per-class accuracy (đặc biệt quan tâm: xe máy vs xe đạp, xe tải vs xe buýt)
- [ ] Đo **spike sparsity** (% neurons fire = 0) → quan trọng cho energy estimate
  - Target: >60% sparsity (energy saving)
- [ ] Đo inference latency trên M1 CPU
- [ ] So sánh với ANN baseline cùng topology:
  - Accuracy gap: SNN vs ANN
  - Parameter count: SNN vs ANN
- [ ] Viết báo cáo accuracy (`reports/accuracy_report.md`)

---

### 1.6 Quantization (Float → Integer cho Hardware)
- [ ] Post-training quantization: float32 → **int8**
  - Weights: 8-bit signed integer
  - Membrane potential: 16-bit signed integer
  - Threshold: 8-bit
- [ ] Kiểm tra accuracy sau quantization
  - Target accuracy drop: **< 2%**
  - Nếu >2%: dùng Quantization-Aware Training (QAT)
- [ ] Symmetric quantization (hardware-friendly hơn asymmetric)
- [ ] Viết `quantize.py`: tự động quantize và evaluate

---

### 1.7 Weight Export (Software → Hardware Bridge)
- [ ] Extract tất cả weights sau quantization
  ```
  conv1_weights: [4, 1, 3, 3] × int8 = 36 bytes
  conv2_weights: [8, 4, 3, 3] × int8 = 288 bytes
  fc1_weights:   [64, 200]    × int8 = 12,800 bytes
  fc2_weights:   [8, 64]      × int8 = 512 bytes
  Total:         ~13.6 KB
  ```
- [ ] Export ra format `.hex` cho SRAM initialization
- [ ] Export ra format `.mif` (Memory Initialization File)
- [ ] Tạo `weight_map.json`: mapping weights vào SRAM address space
- [ ] Viết `export_weights.py`: tự động pipeline quantize → export

---

### 1.8 Software Validation (Golden Reference)
- [ ] Viết **C model** (`reference_model.c`): integer-only inference
  - Dùng int8 weights, int16 membrane potential
  - Không dùng float
  - Đây là "golden reference" để so sánh với hardware RTL
- [ ] Viết **Python bit-accurate model** (`bit_accurate_model.py`)
  - Mô phỏng chính xác overflow, truncation, rounding như hardware
- [ ] Test: Python bit-accurate == RTL simulation output (trước khi build hardware)
- [ ] Tạo test vectors: 100 sample inputs + expected outputs

---

## PHASE 2 – HARDWARE

### 2.1 Architecture Design
- [ ] Vẽ block diagram chi tiết (`Docs/architecture.md`)
- [ ] Xác định dataflow: weight stationary vs output stationary vs row stationary
- [ ] Quyết định parallelism: số PE (Processing Elements) = 8
- [ ] Thiết kế memory hierarchy:
  - Weight SRAM: sky130_sram_1rw0r_32_256_8 (hoặc tương đương)
  - Membrane potential SRAM: lưu trạng thái LIF neurons
  - Input buffer: thanh ghi 28×28
- [ ] Thiết kế interface với Caravel (Wishbone slave)
- [ ] Clock domain: single clock (50 MHz target)

---

### 2.2 RTL Implementation

#### 2.2.1 Processing Element (PE)
- [ ] `pe.v`: Spike × Weight accumulator
  ```verilog
  // Khi spike=1: accumulate += weight
  // Khi spike=0: skip (energy saving)
  // Không cần multiplier, chỉ cần adder
  ```
- [ ] Testbench: `tb_pe.v`

#### 2.2.2 LIF Neuron Module
- [ ] `lif_neuron.v`: Leaky Integrate-and-Fire
  ```verilog
  // membrane = membrane × beta - leak + input
  // if membrane >= threshold: fire=1, reset
  // else: fire=0
  ```
- [ ] Configurable: threshold, leak via registers
- [ ] Testbench: `tb_lif.v`

#### 2.2.3 Convolutional Engine
- [ ] `conv_engine.v`: Time-multiplexed conv layer
  - Đọc input từ buffer
  - Đọc weights từ SRAM
  - Gửi vào PE array
  - Ghi membrane potentials ra SRAM
- [ ] Support cả Conv1 và Conv2 (reuse same module)

#### 2.2.4 Pooling Module
- [ ] `spike_pool.v`: Max pooling trên spike domain
  - 2×2 max pool: fire=1 nếu bất kỳ input nào fire

#### 2.2.5 FC Engine
- [ ] `fc_engine.v`: Fully connected layer
  - Reuse PE array
  - Khác conv: không có sliding window

#### 2.2.6 Spike Encoder
- [ ] `spike_encoder.v`: Pixel → rate-coded spike
  - Input: 8-bit pixel value
  - Output: spike probability = pixel/255
  - Dùng LFSR để random fire

#### 2.2.7 Control FSM
- [ ] `control_fsm.v`: Top-level sequencer
  ```
  IDLE → LOAD_INPUT → CONV1 → POOL1 → CONV2 →
  POOL2 → FC1 → FC2 → OUTPUT → IDLE
  ```
- [ ] Handshake signals: valid/ready

#### 2.2.8 SRAM Interface
- [ ] `sram_ctrl.v`: Controller cho sky130 SRAM macros
- [ ] Address mapping cho weights vs membrane potentials

#### 2.2.9 Wishbone Interface (Caravel)
- [ ] `wb_interface.v`: Wishbone slave
  - Config registers: threshold, beta, T (timesteps)
  - Data registers: input frame write, output class read
  - Status registers: busy, done, error
- [ ] Follow Caravel user project template

#### 2.2.10 Top-level
- [ ] `sct_accel.v`: Kết nối tất cả modules
- [ ] `user_project_wrapper.v`: Caravel wrapper

---

### 2.3 Functional Verification
- [ ] Cập nhật cocotb testbench trong `Verifications/`
- [ ] Test từng module riêng lẻ (unit tests):
  - [ ] `test_pe.py`
  - [ ] `test_lif.py`
  - [ ] `test_conv_engine.py`
  - [ ] `test_spike_pool.py`
  - [ ] `test_fc_engine.py`
  - [ ] `test_spike_encoder.py`
  - [ ] `test_control_fsm.py`
  - [ ] `test_wb_interface.py`
- [ ] Integration test:
  - [ ] `test_full_inference.py`: chạy 100 test vectors từ Phase 1.8
  - [ ] So sánh RTL output vs Python bit-accurate model output
  - [ ] Target: **100% match** trên tất cả test vectors
- [ ] Coverage:
  - [ ] Line coverage > 95%
  - [ ] FSM state coverage 100%
  - [ ] Corner cases: tất cả 0 spikes, tất cả 1 spikes

---

### 2.4 Synthesis (Yosys)
- [ ] Cập nhật `config.mk` cho SCT-Accel
  ```makefile
  DESIGN_NAME = sct_accel
  PLATFORM    = sky130hd
  CLOCK_PERIOD = 20.0  # 50 MHz
  CORE_UTILIZATION = 40  # thấp để route dễ
  ```
- [ ] Chạy synthesis: `make synth`
- [ ] Kiểm tra synthesis report:
  - [ ] Cell count trong range ~15,000–22,000
  - [ ] Không có latch inference ngoài ý muốn
  - [ ] Timing estimate sau synth
- [ ] Fix synthesis warnings

---

### 2.5 Place & Route (OpenROAD)
- [ ] Floorplan: xác định die size, power ring
- [ ] Đặt SRAM macros (manual placement)
- [ ] Chạy full P&R: `make EQUIVALENCE_CHECK=0 LEC_CHECK=0`
- [ ] Kiểm tra kết quả:
  - [ ] WNS > -0.5 ns (timing gần met)
  - [ ] 0 DRC violations sau routing
  - [ ] Routing congestion < 90%
- [ ] Fix timing violations nếu cần (tăng CLOCK_PERIOD hoặc resize cells)
- [ ] Generate final reports:
  - [ ] Timing report
  - [ ] Power report
  - [ ] Area report

---

### 2.6 Sign-off
- [ ] Export GDS: `python3 run_def2gds.py`
- [ ] **Magic DRC**: `magic -dnull -noconsole -T sky130A run_magic_drc.tcl`
  - [ ] Target: **0 violations**
- [ ] **Netgen LVS**: so sánh netlist vs schematic
  - [ ] Target: **0 mismatches**
- [ ] KLayout DRC (double-check): Python API
- [ ] Tạo `signoff_report.md` với kết quả

---

### 2.7 Caravel Integration
- [ ] Clone Caravel harness từ Efabless
  ```bash
  git clone https://github.com/efabless/caravel_user_project
  ```
- [ ] Đặt `sct_accel.v` vào `verilog/rtl/`
- [ ] Kết nối với `user_project_wrapper.v`
- [ ] Map GPIO/LA/Wishbone signals
- [ ] Chạy Caravel precheck:
  ```bash
  make precheck
  ```
- [ ] Fix precheck violations

---

### 2.8 Final Submission
- [ ] Đăng ký tài khoản Efabless (efabless.com)
- [ ] Tạo project trên Efabless platform
- [ ] Upload GDS + netlist + LEF
- [ ] Submit precheck online
- [ ] Chờ shuttle announcement (Q2/Q3 hàng năm)
- [ ] **Tape-out!** 🎯

---

## Timeline Ước Tính

| Phase | Công việc | Thời gian |
|-------|-----------|-----------|
| 1.1–1.3 | Setup + Dataset + Architecture | 1 tuần |
| 1.4–1.5 | Training + Evaluation | 1–2 tuần |
| 1.6–1.8 | Quantization + Export + Golden ref | 1 tuần |
| 2.1–2.2 | RTL Design | 2–3 tuần |
| 2.3 | Verification | 1–2 tuần |
| 2.4–2.5 | Synthesis + P&R | 3–5 ngày |
| 2.6–2.7 | Sign-off + Caravel | 3–5 ngày |
| 2.8 | Submission | 1 ngày |
| **Tổng** | | **~8–12 tuần** |

---

## Metrics Mục Tiêu

| Metric | Target |
|--------|--------|
| Accuracy (traffic dataset) | > 85% |
| Spike sparsity | > 60% |
| Cell count | ~15,000–22,000 |
| Clock frequency | 50 MHz (Sky130HD) |
| Power | < 6 mW |
| Die area | < 0.5 mm² |
| DRC violations | 0 |
| LVS mismatches | 0 |
| RTL vs golden match | 100% |

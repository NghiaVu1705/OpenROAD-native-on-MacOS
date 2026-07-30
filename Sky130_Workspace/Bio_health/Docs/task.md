# Bio_health – Task List
## Multi-Biosignal Processing ASIC: STFT + CNN + FSM Fusion
### Target: Tape-out on Sky130HD via Efabless Chipignite

**Platform:** Sky130HD (130nm) | **Tool:** OpenROAD native macOS M1
**Goal:** Wearable multi-biosignal ASIC, ~48K cells, ~17–35mW active, tape-out ready

**Tín hiệu xử lý:**
- **Type 1** (STFT → CNN): EEG, ECG, EMG
- **Type 2** (direct): HeartRate, SpO2, BodyTemp

**Pipeline:**
```
Sensors → [UART/I2C/SPI] → Type1: [STFT] → [CNN] ─┐
                          → Type2: [Threshold/Formula] ─┤→ [FSM Fusion] → Diagnosis Output
```

---

## PHASE 1 – SOFTWARE

### 1.1 Environment Setup
- [ ] Cài PyTorch với MPS support (Apple Silicon)
  ```bash
  pip install torch torchvision torchaudio
  ```
- [ ] Cài thư viện xử lý tín hiệu y sinh
  ```bash
  pip install numpy scipy matplotlib scikit-learn pandas tqdm
  pip install wfdb           # đọc PhysioNet WFDB format (.dat/.hea/.atr)
  pip install mne            # EEG processing (EDF files, filtering, epoching)
  pip install neurokit2      # ECG/PPG/EMG signal processing toolkit
  pip install pyEDFlib       # đọc EDF/BDF files (EEG/Sleep datasets)
  ```
- [ ] Cài thư viện STFT và signal processing
  ```bash
  pip install librosa        # STFT, spectrogram visualization
  pip install pywavelets     # wavelet transform (so sánh với STFT)
  pip install tensorboard
  ```
- [ ] Verify MPS backend hoạt động
  ```python
  import torch
  print(torch.backends.mps.is_available())  # True
  ```

---

### 1.2 Dataset Preparation

> **Chiến lược:** 3 CNN riêng biệt (EEG/ECG/EMG) + multi-modal dataset cho FSM validation
> Tất cả datasets từ PhysioNet — miễn phí, open license

#### Giai đoạn 1 – ECG Dataset (dễ nhất, bắt đầu đây)
- [ ] **MIT-BIH Arrhythmia Database** — dataset ECG chuẩn nhất thế giới
  - Download: `wfdb.dl_database('mitdb', './data/mitdb')`
  - 48 records × 30 phút, 360 Hz, 11-bit, 2 channels
  - 17 loại arrhythmia: N, L, R, V, A, F, J, S, E, f, j, a, +, Q, !, x, |
  - License: ODC-BY 1.0 ✅
  - Size: 104 MB
  - Target CNN accuracy: **>99%** (SOTA: 99.11%)

- [ ] **PTB-XL ECG Database** — lớn nhất, 12-lead
  - Download: `wfdb.dl_database('ptb-xl', './data/ptbxl')`
  - 21,799 records, 500 Hz, 12-lead, 71 diagnostic labels
  - License: CC-BY 4.0 ✅
  - Size: 3 GB
  - Dùng cho fine-tune sau MIT-BIH pre-train

- [ ] **Apnea-ECG Database** — ECG + sleep apnea label
  - Download: `wfdb.dl_database('apnea-ecg', './data/apnea')`
  - 70 records, 100 Hz, apnea/normal labels per minute
  - License: ODC-BY 1.0 ✅
  - Size: ~10 MB
  - Dùng cho FSM validation: ECG + SpO2 → Sleep Apnea detection

#### Giai đoạn 2 – EEG Dataset
- [ ] **CHB-MIT Scalp EEG Database** — seizure detection
  - Download: `wfdb.dl_database('chbmit', './data/chbmit')`
  - 22 bệnh nhi (5–22 tuổi), 23 channels, 256 Hz, 24-bit
  - 664 seizures có label chính xác
  - License: ODC-BY 1.0 ✅
  - Size: 42.6 GB (download từng subject)
  - Target CNN accuracy: **>96%** sensitivity

- [ ] **Sleep-EDF Expanded Database** — sleep staging
  - Download: `wfdb.dl_database('sleep-edfx', './data/sleepedf')`
  - 197 người, EEG + EOG + EMG + BodyTemp, 100 Hz
  - 5-class sleep staging: W/N1/N2/N3/REM
  - License: ODC-BY 1.0 ✅
  - Size: ~30 GB
  - Target CNN accuracy: **>85%** (5-class)
  - Bonus: BodyTemp signal có sẵn → dùng cho Type 2 testing

- [ ] **EEG Motor Movement/Imagery Database**
  - Download: `wfdb.dl_database('eegmmidb', './data/eegmmi')`
  - 109 người, 64-channel EEG, 160 Hz
  - Motor imagery tasks (left/right hand, feet, tongue)
  - License: ODC-BY 1.0 ✅
  - Size: ~3 GB

#### Giai đoạn 3 – EMG Dataset
- [ ] **GRABMyo Database** — HD-sEMG gesture recognition
  - Download từ PhysioNet: https://physionet.org/content/grabmyo/1.0.0/
  - 43 người, 16-channel HD-sEMG, 2048 Hz
  - 17 hand gestures
  - License: ODC-BY 1.0 ✅
  - Target CNN accuracy: **>94%**

- [ ] **Surface EMG for Non-Invasive Assessment of Muscles**
  - Download: `wfdb.dl_database('emgdb', './data/emgdb')`
  - Multi-channel EMG khi đi bộ, 2000 Hz
  - Dùng cho fatigue/movement disorder detection

#### Giai đoạn 4 – Multi-Modal Dataset (cho FSM validation)
- [ ] **MIMIC-III Waveform Database** (cần tài khoản PhysioNet credentialed)
  - Đăng ký: https://physionet.org/credential/
  - Chứa: ECG + PPG(SpO2) + HeartRate + BodyTemp cho 30,000 bệnh nhân ICU
  - Format: WFDB
  - License: ODbL ✅ (open với credential)
  - Size: ~6.7 TB (download subset theo patient)
  - Quan trọng nhất: validate multi-signal FSM trên data ICU thực tế

- [ ] **VitalDB** — vital signs database
  - Download: https://vitaldb.net/dataset/
  - ICU patients: ECG, SpO2, HR, Temp, respiration
  - License: CC-BY ✅
  - Size: ~50 GB
  - Backup nếu MIMIC credential chưa được approve

#### Tổng Hợp Dataset Theo Priority

| Priority | Dataset | Tín hiệu | Samples | License | Size |
|----------|---------|----------|---------|---------|------|
| ⭐⭐⭐ | MIT-BIH Arrhythmia | ECG | 48 records | ODC-BY ✅ | 104 MB |
| ⭐⭐⭐ | CHB-MIT EEG | EEG | 22 subjects | ODC-BY ✅ | 42.6 GB |
| ⭐⭐⭐ | PTB-XL | ECG 12-lead | 21,799 | CC-BY ✅ | 3 GB |
| ⭐⭐ | GRABMyo | EMG | 43 subjects | ODC-BY ✅ | ~5 GB |
| ⭐⭐ | Sleep-EDF | EEG+EMG+Temp | 197 subjects | ODC-BY ✅ | 30 GB |
| ⭐⭐ | Apnea-ECG | ECG+apnea | 70 records | ODC-BY ✅ | 10 MB |
| ⭐⭐ | VitalDB | ECG+SpO2+HR+Temp | ICU | CC-BY ✅ | 50 GB |
| ⭐ | MIMIC-III Waveform | All signals | 30,000 ICU | ODbL ✅ | 6.7 TB |

#### Data Pipeline Tasks
- [ ] Viết `load_ecg.py`: WFDB reader → numpy array, beat segmentation, label extraction
- [ ] Viết `load_eeg.py`: EDF reader (MNE) → epoch extraction, band filtering, seizure label alignment
- [ ] Viết `load_emg.py`: raw EMG → windowed segments, gesture label
- [ ] Viết `stft_transform.py`: signal → STFT spectrogram
  - Window: Hann, 256-point (EEG/EMG), 128-point (ECG)
  - Output: magnitude spectrogram, log-scaled, resize to 64×64
  - Fixed-point simulation: 16-bit arithmetic để validate hardware
- [ ] Viết `type2_processor.py`: HeartRate (R-R interval), SpO2 (ratio formula), TempBody (threshold)
- [ ] Viết `dataset_unified.py`: unified DataLoader cho 3 signal types

---

### 1.3 STFT Preprocessing Pipeline

> **Quan trọng:** STFT phải được implement theo đúng fixed-point 16-bit để match hardware RTL

- [ ] **Floating-point STFT** (reference)
  - Hann window, 256-point FFT cho EEG/EMG, 128-point cho ECG
  - Output: magnitude spectrogram (log scale), resize 64×64
  - Visualize: spectrograms cho từng loại tín hiệu

- [ ] **Fixed-point STFT simulation** (hardware-accurate)
  - Quantize input signal về 16-bit (Q1.15 format)
  - Twiddle factors: 16-bit cosine/sine lookup table
  - Hann window coefficients: 16-bit, 256 entries
  - Butterfly operation: 32-bit accumulator (tránh overflow)
  - Output magnitude: 16-bit
  - Viết `fixed_point_stft.py`: numpy simulation với int16/int32

- [ ] So sánh floating-point vs fixed-point spectrogram
  - Quantization SNR phải > 60 dB
  - Spectral leakage < -60 dB với Hann window

- [ ] Viết `stft_hardware_model.py`: bit-exact model để generate test vectors cho RTL

---

### 1.4 Model Architecture (3 CNN Riêng Biệt)

> **Cùng architecture, khác trained weights và output classes**

- [ ] Định nghĩa `cnn_model.py` — shared architecture:
  ```
  Input:   64×64 spectrogram (INT8 sau quantize)
  Conv1:   8 filters 3×3, ReLU, MaxPool 2×2 → 32×32×8
  Conv2:   16 filters 3×3, ReLU, MaxPool 2×2 → 16×16×16
  Conv3:   32 filters 3×3, ReLU, MaxPool 2×2 → 8×8×32
  Flatten: 2048
  FC1:     2048 → 64, ReLU
  FC2:     64 → N_classes
  ```
  - Parameters: ~85,000 weights
  - Shared MAC hardware: 3 models load weights vào cùng 1 CNN accelerator

- [ ] **ECG CNN** (`ecg_cnn.py`):
  - N_classes = 8: Normal, LBBB, RBBB, PVC, APC, PAB, VFib, STElev
  - Dataset: MIT-BIH pre-train → PTB-XL fine-tune
  - Target: >99% accuracy

- [ ] **EEG CNN** (`eeg_cnn.py`):
  - N_classes = 6: Normal, Seizure, Delta-dominant, Alpha-dominant, REM, Deep-sleep
  - Dataset: CHB-MIT (seizure) + Sleep-EDF (staging)
  - Target: >96% sensitivity (seizure), >85% sleep staging

- [ ] **EMG CNN** (`emg_cnn.py`):
  - N_classes = 8: Rest, Grasp, Pinch, Point, Open, Wrist-flex, Wrist-ext, Fatigue
  - Dataset: GRABMyo
  - Target: >94% accuracy

---

### 1.5 Training

- [ ] Viết `train.py` — chung cho cả 3 models:
  - Optimizer: Adam, lr=1e-3
  - Scheduler: CosineAnnealingLR
  - Loss: Weighted cross-entropy (class imbalance!)
  - Device: MPS (M1 GPU)
  - Early stopping: patience=10 epochs
  - Checkpoint: save best val accuracy

- [ ] **Train ECG CNN**
  - Pre-train: MIT-BIH (47 records train / 1 val)
  - Fine-tune: PTB-XL (80/10/10 split)
  - Epochs: 100, Batch: 64
  - Log với TensorBoard

- [ ] **Train EEG CNN**
  - CHB-MIT: leave-one-subject-out cross-validation (22 folds)
  - Sleep-EDF: 80/10/10 split
  - Epochs: 150, Batch: 32 (EEG nhỏ hơn)

- [ ] **Train EMG CNN**
  - GRABMyo: 80/10/10 split, subject-independent
  - Epochs: 100, Batch: 64

- [ ] Lưu checkpoints: `ecg_best.pth`, `eeg_best.pth`, `emg_best.pth`

---

### 1.6 Evaluation & Analysis

- [ ] Confusion matrix cho từng CNN
- [ ] Per-class accuracy + F1 score
- [ ] **ECG:** Sensitivity/Specificity cho từng arrhythmia type
- [ ] **EEG:** False alarm rate (FAR per hour) cho seizure detection
  - Target: <0.5 false alarms/hour (clinical acceptable)
- [ ] **EMG:** Gesture confusion matrix
- [ ] So sánh floating-point vs INT8 accuracy gap (phải <0.5%)
- [ ] Viết `evaluate.py` và `reports/model_accuracy.md`

---

### 1.7 Type 2 Signal Processing (Software Model)

- [ ] **HeartRate** (`hr_processor.py`):
  - Pan-Tompkins algorithm: R-peak detection từ ECG
  - HR = 60 / mean(R-R intervals)
  - Thresholds: Bradycardia <50 BPM, Normal 50–100, Tachycardia >100, Critical >150 hoặc <40

- [ ] **SpO2** (`spo2_processor.py`):
  - Ratio: R = (AC_red/DC_red) / (AC_ir/DC_ir)
  - SpO2 = 110 − 25×R (empirical Beer-Lambert)
  - Thresholds: Normal ≥95%, Low 90–94%, Hypoxia <90%

- [ ] **BodyTemp** (`temp_processor.py`):
  - Input: 16-bit I2C word từ MAX30205
  - Convert: temp_C = raw × 0.00390625
  - Thresholds: Hypothermia <35°C, Normal 36.1–37.2°C, Low fever 37.3–38.0°C, Fever 38.1–39°C, High fever >39°C

---

### 1.8 FSM Fusion Logic (Software Model)

- [ ] Viết `fsm_fusion.py` — Python FSM model:

  ```python
  # Inputs:
  # ecg_class: 0=Normal, 1=Arrhythmia, ...
  # eeg_class: 0=Normal, 1=Seizure, ...
  # emg_class: 0=Normal, ...
  # hr_state:  0=Normal, 1=Brady, 2=Tachy, 3=Critical
  # spo2_state: 0=Normal, 1=Low, 2=Hypoxia
  # temp_state: 0=Normal, 1=Fever, 2=HighFever, 3=Hypo

  # Output states:
  NORMAL       = 0  # Tất cả bình thường
  CARDIAC_RISK = 1  # ECG arrhythmia hoặc HR bất thường
  NEURO_RISK   = 2  # EEG seizure detected
  HYPOXIA      = 3  # SpO2 < 90% liên tục > 10s
  SLEEP_APNEA  = 4  # SpO2 drop + HR surge + EEG delta power ↑
  SUDEP_RISK   = 5  # EEG seizure AND ECG arrhythmia đồng thời
  PARKINSON    = 6  # EEG low-beta + EMG atonia pattern
  FEVER        = 7  # Temp > 38.5°C
  CRITICAL     = 8  # Nhiều alerts đồng thời
  ```

- [ ] Validate FSM trên MIMIC-III / VitalDB:
  - Tìm ground-truth ICU events (cardiac arrest, apnea episodes)
  - Tính True Positive Rate của FSM
  - Target: >85% TPR cho CARDIAC_RISK và HYPOXIA states

- [ ] Viết `fsm_test_vectors.py`: generate 500 test cases → dùng để verify RTL FSM

---

### 1.9 Quantization (Float → INT8 cho Hardware)

- [ ] Post-training quantization tất cả 3 models: float32 → **int8**
  - Weights: 8-bit symmetric signed
  - Activations: 8-bit unsigned
  - Accumulator: 32-bit (giữ precision trong MAC)

- [ ] Kiểm tra accuracy sau quantize:
  - ECG: phải >98.5% (drop <0.6%)
  - EEG: phải >95.5% sensitivity
  - EMG: phải >93.5%

- [ ] **Quantization-Aware Training (QAT)** nếu accuracy drop > target:
  - Insert fake quantization nodes vào training graph
  - Re-train 20 epochs với QAT

- [ ] Viết `quantize.py`: automated pipeline float → INT8 → evaluate

---

### 1.10 Weight Export (Software → Hardware Bridge)

- [ ] Extract weights từ 3 models sau quantize:
  ```
  ECG CNN:   ~85K weights × 1 byte = ~85 KB
  EEG CNN:   ~85K weights × 1 byte = ~85 KB
  EMG CNN:   ~85K weights × 1 byte = ~85 KB
  Tổng:      ~255 KB → 5 SRAM macros của Sky130
  ```

- [ ] Export từng model ra:
  - `ecg_weights.hex`: hex dump, 1 byte/line, địa chỉ SRAM
  - `eeg_weights.hex`: tương tự
  - `emg_weights.hex`: tương tự
  - `weight_map.json`: address mapping cho từng layer

- [ ] Viết `export_weights.py`: automated quantize → export pipeline

---

### 1.11 Golden Reference (Software → RTL Verification Bridge)

- [ ] Viết `fixed_point_cnn.py` — bit-exact INT8 inference:
  - Tất cả operations dùng int8/int32 (không float)
  - Simulate overflow/saturation giống hardware
  - Simulate STFT → spectrogram → CNN → class output

- [ ] Viết `golden_reference.c` — C model (integer only):
  - Portable C99, không dùng float
  - Chạy trên host để double-check Python model
  - Output format: class_id per inference

- [ ] Generate test vectors:
  - 200 ECG segments (từ MIT-BIH)
  - 200 EEG epochs (từ CHB-MIT)
  - 200 EMG windows (từ GRABMyo)
  - 100 multi-signal FSM cases (từ MIMIC-III/VitalDB)
  - Save: `test_vectors/ecg_inputs.bin`, `ecg_expected.bin`, v.v.
  - **RTL simulation phải match 100%**

---

## PHASE 2 – HARDWARE

### 2.1 Architecture Design

- [ ] Vẽ block diagram chi tiết (`Docs/architecture.md`)
- [ ] Xác định dataflow toàn chip:
  ```
  SENSOR → [Interface] → [Sample Buffer] → [STFT Engine] → [Spectrogram Buffer]
                                         ↘ [Type2 Proc]
  [Spectrogram Buffer] → [CNN Accelerator] ← [Weight SRAM (3 models)]
  [CNN output] + [Type2 output] → [FSM Fusion] → [Output Register]
  [Output Register] → [Wishbone Interface] → Caravel host
  ```
- [ ] Xác định clock domains:
  - Primary: 10 MHz (STFT + CNN, latency-tolerant)
  - Sensor: configurable divider (256 Hz/500 Hz/2 kHz)
- [ ] Thiết kế memory map (SRAM address space):
  - 0x00000–0x154FF: ECG weights (85 KB)
  - 0x15500–0x2A9FF: EEG weights (85 KB)
  - 0x2AA00–0x3FEFF: EMG weights (85 KB)
  - 0x3FF00–0x3FFFF: Spectrogram buffer + membrane buffers
- [ ] Caravel interface: Wishbone slave, 32 config registers

---

### 2.2 RTL Implementation

#### 2.2.1 Sensor Interfaces
- [ ] `uart_rx.v`: UART receiver, 8N1, configurable baud (9600–921600)
- [ ] `i2c_master.v`: I2C master, 100/400 kHz, 7-bit address
  - Targets: MAX30205 (temp), MAX30102 (SpO2/HR)
- [ ] `spi_master.v`: SPI master, CPOL/CPHA configurable
  - Target: ADS1299 (EEG 8-ch), ADS1115 (ECG/EMG)
- [ ] `sensor_mux.v`: round-robin arbitration giữa 3 interfaces
- [ ] Testbenches: `tb_uart.v`, `tb_i2c.v`, `tb_spi.v`

#### 2.2.2 Sample Buffer & Decimation Filter
- [ ] `sample_buffer.v`: circular buffer 512 samples × 16-bit per channel
- [ ] `cic_filter.v`: CIC decimation filter (từ 2kHz xuống 256Hz cho EMG)
  - Order: 4, Differential delay: 1
- [ ] `dc_removal.v`: 1st-order IIR high-pass (fc=0.5 Hz) để loại DC drift EEG

#### 2.2.3 STFT Engine (Core của Type 1)
- [ ] `hann_window.v`: ROM 256×16-bit, Hann coefficients
  - w[n] = 0.5 × (1 − cos(2πn/N)), lưu dạng Q1.15
- [ ] `twiddle_rom.v`: ROM 128×32-bit (16-bit real + 16-bit imag)
  - W_N^k = cos(2πk/N) − j×sin(2πk/N)
- [ ] `butterfly_unit.v`: Complex butterfly (16-bit input, 32-bit accumulator)
  - a' = a + W×b, b' = a − W×b
  - Overflow protection: arithmetic right shift
- [ ] `fft_controller.v`: time-multiplexed radix-2 DIT FFT controller
  - 256-point: 8 stages × 256 cycles = 2048 cycles total
  - Bit-reversal permutation FSM
- [ ] `magnitude_calc.v`: |X|² = Re² + Im², right-shift 4 bits → 16-bit output
- [ ] `stft_top.v`: kết nối window → FFT → magnitude → spectrogram buffer
  - Hỗ trợ 3 channels (EEG/ECG/EMG), time-multiplexed
- [ ] Testbench `tb_stft.v`:
  - Input: known sine wave (256 Hz, 50 Hz, 10 Hz)
  - Expected output: spike tại đúng frequency bin
  - So sánh với `fixed_point_stft.py` golden reference

#### 2.2.4 CNN Accelerator
- [ ] `mac_unit.v`: 8-bit × 8-bit signed multiply-accumulate, 32-bit accumulator
- [ ] `pe_array.v`: 8 parallel MAC units (8 output channels tính cùng lúc)
- [ ] `activation.v`: ReLU (max(0,x)), clamp về 8-bit output
- [ ] `conv_engine.v`: time-multiplexed 2D convolution
  - Đọc spectrogram từ buffer (input activations)
  - Đọc kernel weights từ Weight SRAM
  - Tính partial sums, ghi output feature map
  - Support 3×3 kernel, configurable stride và padding
- [ ] `pool_engine.v`: 2×2 max pooling
- [ ] `fc_engine.v`: fully connected layer (reuse MAC array)
- [ ] `weight_sram_ctrl.v`: address generation cho Weight SRAM
  - Model select: 2-bit (00=ECG, 01=EEG, 10=EMG)
  - Layer select: base address offset per layer
- [ ] `cnn_top.v`: kết nối conv + pool + fc + activation
  - FSM: IDLE → LOAD_WEIGHT → CONV1 → POOL1 → CONV2 → POOL2 → CONV3 → POOL3 → FC1 → FC2 → OUTPUT
- [ ] Testbench `tb_cnn.v`:
  - Load test vectors từ Phase 1.11
  - So sánh RTL output vs `fixed_point_cnn.py` golden reference
  - Target: **100% match** trên 200 ECG + 200 EEG + 200 EMG vectors

#### 2.2.5 Type 2 Signal Processor
- [ ] `hr_detector.v`: Pan-Tompkins R-peak detector
  - Differentiation → squaring → moving window integration → threshold
  - Output: HR in BPM (8-bit), HR_state (2-bit: Normal/Brady/Tachy/Critical)
- [ ] `spo2_calc.v`: SpO2 ratio computation
  - AC/DC ratio từ red và IR channels
  - LUT: 32-entry lookup table (ratio → SpO2 %)
  - Output: SpO2% (8-bit), SpO2_state (2-bit)
- [ ] `temp_convert.v`: 16-bit I2C word → temperature °C × 10
  - Threshold comparators: 350/361/372/380/385/390/420
  - Output: Temp_state (3-bit)

#### 2.2.6 FSM Fusion Engine
- [ ] `diagnosis_fsm.v`: 9-state Moore FSM
  ```verilog
  // Inputs: ecg_class[3:0], eeg_class[2:0], emg_class[2:0]
  //         hr_state[1:0], spo2_state[1:0], temp_state[2:0]
  // Output: diagnosis[3:0], alert_level[1:0]
  //
  // States: NORMAL(0), CARDIAC(1), NEURO(2), HYPOXIA(3),
  //         SLEEP_APNEA(4), SUDEP(5), PARKINSON(6), FEVER(7), CRITICAL(8)
  ```
  - Priority encoder: CRITICAL > SUDEP > HYPOXIA > NEURO > CARDIAC > FEVER > NORMAL
  - Hysteresis: state change chỉ khi condition kéo dài > N cycles
- [ ] Testbench `tb_fsm.v`:
  - 100 multi-signal test vectors từ `fsm_test_vectors.py`
  - Verify tất cả state transitions

#### 2.2.7 Wishbone Interface (Caravel)
- [ ] `wb_regs.v`: 32 configuration/status registers
  ```
  Reg 0:  Control (start/stop/reset/model_select)
  Reg 1:  Status (busy/done/error/current_state)
  Reg 2:  ECG data write (1 sample per write)
  Reg 3:  EEG data write
  Reg 4:  EMG data write
  Reg 5:  SpO2 raw data write
  Reg 6:  HR data write (BPM)
  Reg 7:  Temp data write
  Reg 8:  Diagnosis output (read-only)
  Reg 9:  ECG CNN class output
  Reg 10: EEG CNN class output
  Reg 11: EMG CNN class output
  Reg 12: HR/SpO2/Temp states
  Reg 13: STFT status
  Reg 14-31: Reserved
  ```
- [ ] Follow Caravel `user_project_wrapper.v` interface

#### 2.2.8 Top-level
- [ ] `bio_health.v`: kết nối tất cả modules
  - Clock gating: tắt STFT/CNN engine khi không có signal mới
  - Scan chain: DFT (Design for Test) basic
- [ ] `user_project_wrapper.v`: Caravel wrapper

---

### 2.3 Functional Verification

#### Unit Tests (cocotb)
- [ ] `test_uart.py`: loopback test, sai baud rate
- [ ] `test_i2c.py`: read MAX30205, ACK/NACK handling
- [ ] `test_spi.py`: ADS1299 register read/write
- [ ] `test_hann_window.py`: verify ROM values vs scipy.signal.windows.hann
- [ ] `test_fft.py`: sine input → verify peak at correct frequency bin
- [ ] `test_stft.py`: multi-tone input → verify spectrogram vs fixed_point_stft.py
- [ ] `test_mac_unit.py`: corner cases: overflow, negative numbers, zero
- [ ] `test_conv_engine.py`: 3×3 conv trên known input vs Python reference
- [ ] `test_pool_engine.py`: 2×2 max pool
- [ ] `test_hr_detector.py`: MIT-BIH segment → verify HR output ±2 BPM
- [ ] `test_spo2_calc.py`: verify LUT output vs formula
- [ ] `test_temp_convert.py`: known I2C words → expected Celsius values
- [ ] `test_fsm.py`: 100 test vectors từ Phase 1.8

#### Integration Tests
- [ ] `test_ecg_full.py`: 200 ECG segments → RTL class == Python golden
- [ ] `test_eeg_full.py`: 200 EEG epochs → RTL class == Python golden
- [ ] `test_emg_full.py`: 200 EMG windows → RTL class == Python golden
- [ ] `test_multimodal.py`: 100 multi-signal → FSM state == expected

#### Coverage Targets
- [ ] Line coverage > 95%
- [ ] FSM: 100% state coverage, 100% transition coverage
- [ ] Corner cases: all-zero input, max amplitude input, signal dropout

---

### 2.4 Synthesis (Yosys)

- [ ] Cập nhật `config.mk`:
  ```makefile
  DESIGN_NAME      = bio_health
  PLATFORM         = sky130hd
  CLOCK_PERIOD     = 100.0   # 10 MHz
  CORE_UTILIZATION = 35      # thấp vì cần chỗ cho SRAM macros
  CORE_ASPECT_RATIO = 1.0
  ```
- [ ] Chạy synthesis: `make DESIGN_CONFIG=... synth`
- [ ] Kiểm tra synthesis report:
  - [ ] Cell count trong range 40,000–60,000
  - [ ] Không có latch inference
  - [ ] Timing estimate sau synth (setup slack tại 10 MHz)
  - [ ] Không có multi-driven nets
- [ ] Fix synthesis warnings

---

### 2.5 Place & Route (OpenROAD)

- [ ] Floorplan: die size ~2.5mm × 2.5mm
- [ ] Manual placement SRAM macros (5 macros ~1mm × 0.5mm mỗi macro)
  - Đặt Weight SRAM gần CNN accelerator
  - Đặt Spectrogram buffer gần STFT engine
- [ ] Chạy full P&R:
  ```bash
  make DESIGN_CONFIG=./designs/sky130hd/bio_health/config.mk \
       EQUIVALENCE_CHECK=0 LEC_CHECK=0
  ```
- [ ] Kiểm tra kết quả:
  - [ ] WNS > -0.5 ns tại 10 MHz
  - [ ] 0 DRC violations sau routing
  - [ ] Routing congestion < 85%
  - [ ] Power report: active <35mW, idle <3mW
- [ ] Generate reports:
  - [ ] `reports/timing.rpt`
  - [ ] `reports/power.rpt`
  - [ ] `reports/area.rpt`

---

### 2.6 Sign-off

- [ ] Export GDS: `python3 run_def2gds.py`
- [ ] **Magic DRC**: `magic -dnull -noconsole -T sky130A run_magic_drc.tcl`
  - [ ] Target: **0 violations**
- [ ] **Netgen LVS**: schematic vs layout match
  - [ ] Target: **0 mismatches**
- [ ] KLayout DRC (double-check)
- [ ] Tạo `Docs/signoff_report.md`

---

### 2.7 Caravel Integration

- [ ] Clone Caravel user project template:
  ```bash
  git clone https://github.com/efabless/caravel_user_project
  ```
- [ ] Copy RTL vào `verilog/rtl/`
- [ ] Wrap vào `user_project_wrapper.v`
- [ ] Map signals:
  - Wishbone: wb_clk_i, wb_rst_i, wbs_stb_i, wbs_cyc_i, wbs_we_i, wbs_sel_i, wbs_dat_i, wbs_adr_i, wbs_ack_o, wbs_dat_o
  - GPIO: sensor interrupt, alert output
  - Logic Analyzer: debug probes (STFT done, CNN done, FSM state)
- [ ] Chạy Caravel precheck: `make precheck`
- [ ] Fix violations

---

### 2.8 Final Submission (Tape-out)

- [ ] Đăng ký Efabless tài khoản
- [ ] Tạo project: "Bio_health: Multi-Biosignal ASIC on Sky130HD"
- [ ] Upload: GDS + LEF + netlist
- [ ] Submit precheck online (automated DRC/LVS)
- [ ] Chờ shuttle announcement (Q2/Q3 hàng năm)
- [ ] **Tape-out!** 🎯
- [ ] Nhận chip (~6 tháng), test trên PCB

---

## Timeline Ước Tính

| Phase | Công việc | Thời gian |
|-------|-----------|-----------|
| 1.1–1.2 | Setup + Dataset download | 1 tuần |
| 1.3 | STFT pipeline (float + fixed-point) | 1 tuần |
| 1.4–1.5 | Model design + Training | 2–3 tuần |
| 1.6–1.7 | Evaluation + Type 2 processing | 1 tuần |
| 1.8 | FSM fusion software model | 1 tuần |
| 1.9–1.11 | Quantization + Export + Golden ref | 1 tuần |
| 2.1–2.2 | RTL Design (9 modules) | 3–4 tuần |
| 2.3 | Verification (unit + integration) | 2 tuần |
| 2.4–2.5 | Synthesis + P&R | 3–5 ngày |
| 2.6–2.7 | Sign-off + Caravel | 3–5 ngày |
| 2.8 | Submission | 1 ngày |
| **Tổng** | | **~12–16 tuần** |

---

## Metrics Mục Tiêu

| Metric | Target |
|--------|--------|
| ECG CNN accuracy (MIT-BIH) | > 99% |
| EEG seizure sensitivity (CHB-MIT) | > 96%, FAR < 0.5/h |
| EMG gesture accuracy (GRABMyo) | > 94% |
| INT8 accuracy drop | < 0.6% |
| RTL vs golden match | 100% trên tất cả test vectors |
| Cell count | ~40,000–60,000 |
| Clock frequency | 10 MHz (Sky130HD) |
| Active power | < 35 mW |
| Idle power | < 3 mW |
| Die area | < 3 mm² (fits Caravel 10.28 mm²) |
| DRC violations | 0 |
| LVS mismatches | 0 |
| FSM TPR (CARDIAC/HYPOXIA) | > 85% trên MIMIC-III |

---

## Tài Liệu Tham Khảo

| Paper | Nội dung | Link |
|-------|----------|------|
| Ullah et al. 2020 | CNN on ECG STFT → 99.11% MIT-BIH | arXiv:2005.06902 |
| ConvMambaNet 2026 | EEG seizure 99% CHB-MIT | arXiv:2505.x |
| XMANet 2025 | CNN on EMG spectrogram | arXiv:2504.14708 |
| ECSLIF-YOLO 2025 | Quantized CNN accuracy | Scientific Reports |
| arXiv:2012.00307 | INT8 quantization for EEG | arXiv:2012.00307 |
| arXiv:2504.15178 | INT4/INT3 ECG LSTM 97% | arXiv:2504.15178 |
| arXiv:2512.08257 | SUDEP: EEG+ECG fusion | arXiv:2512.08257 |
| arXiv:2110.00660 | Sleep apnea: ECG+SpO2 | arXiv:2110.00660 |
| PhysioNet MIT-BIH | ECG arrhythmia dataset | physionet.org/mitdb |
| PhysioNet CHB-MIT | EEG seizure dataset | physionet.org/chbmit |
| PhysioNet PTB-XL | 12-lead ECG dataset | physionet.org/ptb-xl |

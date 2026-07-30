# HammingCode_128bit – Task List
## Hamming(137,128) SEC-DED Encoder/Decoder ASIC
### Target: Tape-out on Sky130HD via Efabless Chipignite

**Platform:** Sky130HD (130nm) | **Tool:** OpenROAD native macOS M1
**Goal:** Correct single-bit errors, detect double-bit errors in 128-bit data words
**Scope:** Nhỏ nhất trong 3 dự án — warm-up project, hoàn thành nhanh nhất

---

## Tổng Quan Kỹ Thuật

### Hamming(137,128) SEC-DED là gì

```
Input:  128-bit data
Output: 137-bit codeword = 128 data bits + 9 parity bits

Parity bits: p1, p2, p4, p8, p16, p32, p64, p128 (ở các vị trí power-of-2)
             + p0 (overall parity cho SEC-DED)

Decode:
  Syndrome = recalculated_parity XOR received_parity
  syndrome == 0            → No error
  syndrome[8:1] != 0, p0 changed → Single bit error → CORRECT
  syndrome[8:1] != 0, p0 unchanged → Double bit error → DETECT, flag
```

### Ứng Dụng Thực Tế

| Ứng dụng | Mô tả |
|----------|-------|
| **DRAM ECC** | Bảo vệ bộ nhớ máy chủ, server-grade RAM |
| **Cache ECC** | L1/L2/L3 cache trong CPU/SoC |
| **Space/Rad-hard** | Vệ tinh, tàu vũ trụ (radiation-induced bit flips) |
| **Automotive (ISO 26262)** | Safety-critical memory trong xe hơi |
| **Storage controllers** | NVMe SSD, RAID controller ECC |
| **Network switches** | Packet buffer protection |

### So Sánh 3 Dự Án

| | HammingCode_128bit | CamAI_SNN | Bio_health |
|--|:-----------------:|:---------:|:---------:|
| **Cells** | ~1,500–3,000 | ~18,000 | ~48,000 |
| **Phức tạp** | ⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Training cần** | Không | Có | Có |
| **Timeline** | **2–4 tuần** | 8–12 tuần | 12–16 tuần |
| **Combinational** | Chủ yếu | Không | Không |
| **Mục đích** | Warm-up + học flow | Research | Research |

---

## BUG ANALYSIS – RTL Hiện Tại Có Vấn Đề

> **Cần fix trước khi chạy flow. 4 bugs được phát hiện khi đọc source.**

### Bug 1: Decoder parity_in assignment sai
```verilog
// ❌ SAI (file hiện tại):
assign parity_in = codeword_in[8:0];  // [8] = data[0], không phải parity!

// ✅ ĐÚNG:
// Encoder tạo: codeword = {p0, data[127:0], p8,p7,p6,p5,p4,p3,p2,p1}
//              [136]=p0, [135:8]=data, [7:0]={p8..p1}
assign parity_in[8:1] = codeword_in[7:0];   // p8..p1 ở bits [7:0]
assign parity_in[0]   = codeword_in[136];   // p0 ở bit [136]
```

### Bug 2: Decoder recalc bị truncate
```verilog
// ❌ SAI: recalc[1] và recalc[2] chỉ XOR ~10 bits thay vì 64+ bits
assign recalc[1] = ^{data_in[0],...,data_in[63],data_in[127]};  // thiếu 60+ bits giữa

// ✅ ĐÚNG: phải XOR đầy đủ tất cả positions có bit0=1 (odd positions)
// recalc[k] = XOR của tất cả data bits tại positions có bit k = 1
```

### Bug 3: Error correction dùng codeword position, không phải data position
```verilog
// ❌ SAI:
if (error_position <= 128)
    data_out[error_position-1] = ~data_in[error_position-1];
// syndrome cho vị trí trong 137-bit codeword, không phải trực tiếp index data

// ✅ ĐÚNG: cần mapping từ codeword position → data bit index
// Codeword positions: p1(1), p2(2), d1(3), p4(4), d2(5), d3(6), d4(7), p8(8), ...
// Cần lookup table: codeword_pos → data_bit_index
```

### Bug 4: overall_p (p0) không được dùng trong syndrome logic
```verilog
// ❌ SAI: overall_p được assign nhưng không dùng để phân biệt SEC vs DED
assign overall_p = codeword_in[136];
// ... nhưng không có logic: if (overall_p_error) SEC else DED

// ✅ ĐÚNG:
// received_overall = codeword_in[136]
// expected_overall = ^codeword_in[135:0]
// overall_error = received_overall ^ expected_overall
// if (syndrome[8:1] != 0 && overall_error) → single error
// if (syndrome[8:1] != 0 && !overall_error) → double error
```

---

## PHASE 1 – ALGORITHM & SPECIFICATION

### 1.1 Mathematical Specification
- [ ] Viết `Docs/algorithm.md`: mô tả đầy đủ Hamming(137,128)
  - Codeword structure: vị trí từng parity bit
  - Parity bit coverage: p_k covers tất cả positions có bit k = 1
  - Syndrome interpretation: syndrome → error position trong codeword
  - Overall parity (p0): SEC vs DED disambiguation
  - Codeword position → data index mapping table (128 entries)

- [ ] Xây dựng **Position Mapping Table**:
  ```
  Codeword pos | Type     | Data index
  -------------|----------|------------
  1            | p1       | —
  2            | p2       | —
  3            | data     | 0
  4            | p4       | —
  5            | data     | 1
  6            | data     | 2
  7            | data     | 3
  8            | p8       | —
  9..15        | data     | 4..10
  16           | p16      | —
  ...
  128          | p128     | —
  129..136     | data     | 119..126
  (+ p0 at pos 0/overall)
  ```

- [ ] Verify: 2^8 = 256 ≥ 128 + 8 + 1 = 137 → 8 parity bits đủ ✅

---

### 1.2 Golden Reference Model
- [ ] Viết `reference/hamming_golden.py` — Python reference:
  ```python
  def encode(data_128bit: int) -> int:   # returns 137-bit codeword
  def decode(codeword_137bit: int) -> tuple[int, str, int]:
      # returns (data, status, error_pos)
      # status: "ok" | "single_corrected" | "double_detected"
  def inject_error(codeword: int, bit_pos: int) -> int:
  def inject_double_error(codeword: int, pos1: int, pos2: int) -> int:
  ```

- [ ] Viết `reference/hamming_golden.c` — C reference (integer only):
  - Portable C99, bitwise operations only
  - Dùng làm golden reference cho RTL cocotb testbench
  - Compile: `gcc -O2 hamming_golden.c -o hamming_golden`

- [ ] Verify Python vs C reference khớp 100%

---

### 1.3 Test Vector Generation
- [ ] `reference/gen_test_vectors.py`:

  **Test Group 1 – No Error (1000 vectors):**
  - Random 128-bit data → encode → decode → verify data_out == data_in
  - Status phải là "ok"

  **Test Group 2 – Single Bit Error (137 vectors):**
  - Inject lần lượt từng bit (pos 0..136) → decode → verify correction
  - Status phải là "single_corrected"
  - data_out phải == original data

  **Test Group 3 – Double Bit Error (9,316 vectors = C(137,2)):**
  - Inject tất cả pairs (i,j) → decode → verify detection
  - Status phải là "double_detected"
  - data_out KHÔNG được dùng (uncorrectable)

  **Test Group 4 – Parity bit errors (9 vectors):**
  - Flip từng parity bit p0..p8 → verify detection không corrupt data

  **Tổng: ~10,453 test vectors** → save `test_vectors/`:
  - `no_error_vectors.bin`
  - `single_error_vectors.bin`
  - `double_error_vectors.bin`
  - `parity_error_vectors.bin`

---

## PHASE 2 – RTL DESIGN

### 2.1 Fix RTL Bugs (Ưu tiên cao nhất)

- [ ] **Fix Bug 1:** Sửa parity_in extraction trong decoder
  ```verilog
  wire [8:1] parity_received;
  wire       overall_received;
  assign parity_received = codeword_in[7:0];  // p8..p1
  assign overall_received = codeword_in[136]; // p0
  ```

- [ ] **Fix Bug 2:** Viết lại đầy đủ recalc parity trong decoder
  - recalc[1]: XOR tất cả codeword positions có bit0=1 (positions 1,3,5,7,9,11,...)
  - recalc[2]: XOR tất cả positions có bit1=1 (positions 2,3,6,7,10,11,...)
  - recalc[3]: XOR tất cả positions có bit2=1 (positions 4..7, 12..15, ...)
  - recalc[4]: XOR tất cả positions có bit3=1 (positions 8..15, 24..31, ...)
  - recalc[5]: XOR tất cả positions có bit4=1 (positions 16..31, 48..63, ...)
  - recalc[6]: XOR tất cả positions có bit5=1 (positions 32..63, 96..127, ...)
  - recalc[7]: XOR tất cả positions có bit6=1 (positions 64..127)
  - recalc[8]: XOR tất cả positions có bit7=1 (positions 128..136 → chỉ 9 data bits)
  - recalc[0] = overall = XOR toàn bộ 137 bits

- [ ] **Fix Bug 3:** Tạo position mapping logic
  ```verilog
  // Syndrome [8:1] = vị trí lỗi trong codeword (1-indexed, 1..136)
  // Cần map sang: là parity bit hay data bit? nếu data: index nào?
  reg [7:0] codeword_pos;
  assign codeword_pos = syndrome[8:1];  // 1..136

  // Lookup: codeword_pos → data_bit_index (0..127), hay parity (no correction needed)
  // Dùng case statement hoặc calculate: skip power-of-2 positions
  ```

- [ ] **Fix Bug 4:** Sửa SEC vs DED logic
  ```verilog
  wire overall_error;
  assign overall_error = overall_received ^ (^codeword_in[135:0]);

  // Sau khi tính syndrome:
  if (syndrome[8:1] == 0 && !overall_error) → no error
  if (syndrome[8:1] != 0 && overall_error)  → single error (correctable)
  if (syndrome[8:1] != 0 && !overall_error) → double error (detected only)
  if (syndrome[8:1] == 0 && overall_error)  → p0 itself is wrong (harmless)
  ```

---

### 2.2 Thiết Kế Lại RTL Từ Đầu (Recommended)

> Nhiều bug → viết lại sạch hơn là patch từng cái

- [ ] `src/hamming_encoder_128.v` — Encoder (combinational):
  ```verilog
  module hamming_encoder_128 (
      input  wire [127:0] data_in,
      output wire [136:0] codeword_out  // [136]=p0, [135:8]=data, [7:0]={p8..p1}
  );
  // Step 1: Build 136-bit codeword (without p0) by inserting data at non-parity positions
  // Step 2: Calculate p1..p8 via XOR of covered positions
  // Step 3: Calculate p0 = XOR of all 136 bits + p0 placeholder
  // Step 4: Output {p0, codeword_without_p0}
  endmodule
  ```

- [ ] `src/hamming_decoder_128.v` — Decoder (combinational):
  ```verilog
  module hamming_decoder_128 (
      input  wire [136:0] codeword_in,
      output wire [127:0] data_out,
      output wire         sec,          // single error corrected
      output wire         ded,          // double error detected
      output wire [7:0]   error_cw_pos  // error position in codeword (0=none)
  );
  // Step 1: Recalculate p1..p8 from received codeword
  // Step 2: Syndrome = recalc XOR received_parity
  // Step 3: Check overall parity for SEC vs DED disambiguation
  // Step 4: If SEC: flip bit at syndrome position, extract data
  // Step 5: If DED: pass through data with ded flag (don't correct)
  endmodule
  ```

- [ ] `src/HammingCode_128bit.v` — Top with registered pipeline:
  - Giữ cấu trúc hiện tại (clk, rst_n, enc/dec ports)
  - Fix clock period: 2.0ns → **10.0ns** (100 MHz, thực tế hơn cho Sky130HD)
  - Thêm Wishbone interface cho Caravel (optional)

---

### 2.3 Extensions (Optional, nếu design quá nhỏ)

> ~1,500 cells là rất nhỏ. Có thể thêm tính năng để fill Caravel area tốt hơn

- [ ] **Option A: Multi-word pipeline**
  - 4 encoder + 4 decoder instances → throughput 4× tại cùng frequency
  - Cells: ~6,000–10,000

- [ ] **Option B: Configurable width (64/128/256-bit)**
  - Parameterized: `DATA_WIDTH = 64, 128, 256`
  - 256-bit: 9 parity bits → Hamming(265,256)
  - Cells: ~4,000–8,000

- [ ] **Option C: Wishbone interface cho Caravel**
  ```
  Reg 0: Control (mode: encode/decode, start)
  Reg 1-4:  data_in[127:0] (4 × 32-bit writes)
  Reg 5:    codeword[31:0]
  Reg 6:    codeword[63:32]
  Reg 7:    codeword[95:64]
  Reg 8:    codeword[105:96] + {sec, ded, err_pos[7:0]}
  Reg 9:    Status (done, sec, ded, error_position)
  ```
  - Cells: ~2,000–3,000 thêm

---

## PHASE 3 – FUNCTIONAL VERIFICATION

### 3.1 Python Testbench (trước khi viết RTL)
- [ ] Verify `hamming_golden.py` bằng test vectors:
  - All 1000 no-error cases pass
  - All 137 single-bit injection cases corrected
  - All 9,316 double-bit cases detected (không corrected)
  - All 9 parity-only errors handled đúng

### 3.2 RTL Testbench (cocotb)
- [ ] `Verifications/tb/test_hamming_encoder.py`:
  - 1000 random data → encode → verify parity bits theo formula
  - Verify codeword structure (parity at correct positions)

- [ ] `Verifications/tb/test_hamming_decoder.py`:
  - Replay tất cả test vectors từ Phase 1.3
  - Compare RTL output vs golden reference bit-exact

- [ ] `Verifications/tb/test_sec_ded.py`:
  - **Single error exhaustive:** inject all 137 bit positions
  - Verify: `sec==1`, `ded==0`, `data_out == original`
  - **Double error exhaustive:** inject all C(137,2) = 9,316 pairs
  - Verify: `sec==0`, `ded==1`
  - **Triple error sample:** 100 random triple errors
  - Verify: không phải false SEC (safety requirement)

- [ ] `Verifications/tb/test_pipeline.py`:
  - Back-to-back transactions: encode liên tục 1000 cycles
  - Verify no pipeline stall, throughput = 1 word/cycle

- [ ] `Verifications/tb/test_wishbone.py` (nếu có WB interface):
  - Read/write registers, encode/decode via Wishbone

### 3.3 Coverage
- [ ] Line coverage: **100%** (design đơn giản, phải đạt được)
- [ ] Functional coverage:
  - [ ] error_position = 0 (no error)
  - [ ] error_position = 1..8 (parity bit error)
  - [ ] error_position = 9..136 (data bit error)
  - [ ] double error với 2 adjacent bits
  - [ ] double error với 2 non-adjacent bits
  - [ ] double error khi 2 parity bits bị lỗi

---

## PHASE 4 – SYNTHESIS (Yosys)

- [ ] Cập nhật `config.mk`:
  ```makefile
  DESIGN_NAME      = HammingCode_128bit
  PLATFORM         = sky130hd
  CLOCK_PERIOD     = 10.0    # 100 MHz (thực tế cho Sky130HD)
                             # 2.0ns quá aggressive → cần deep pipeline
  CORE_UTILIZATION = 50
  CORE_ASPECT_RATIO = 1
  CORE_MARGIN      = 2.0
  ```

- [ ] Cập nhật `constraints/constraint.sdc`:
  ```tcl
  set clk_period 10.0   # 100 MHz thay vì 2.0ns (500 MHz không khả thi)
  ```

- [ ] Chạy synthesis: `make DESIGN_CONFIG=... synth`
- [ ] Kiểm tra synthesis report:
  - [ ] Cell count: **1,500–3,000 cells** (pure XOR logic)
  - [ ] Không có latch inference
  - [ ] Timing: combinational logic < 10ns (XOR tree ~2–4ns)
  - [ ] Check: nếu muốn 500 MHz → cần thêm pipeline registers (5–6 stages)
- [ ] So sánh 3 options:
  - Combinational only: ~1,500 cells, 1 cycle latency
  - With WB interface: ~4,000 cells
  - Multi-word (4×): ~6,000 cells

---

## PHASE 5 – PLACE & ROUTE (OpenROAD)

- [ ] Die size: nhỏ, ~200µm × 200µm là đủ (hoặc dùng min size Caravel)
- [ ] Chạy full P&R:
  ```bash
  make DESIGN_CONFIG=./designs/sky130hd/HammingCode_128bit/config.mk \
       EQUIVALENCE_CHECK=0 LEC_CHECK=0
  ```
- [ ] Kiểm tra:
  - [ ] WNS > -0.5ns tại 100 MHz
  - [ ] 0 DRC violations
  - [ ] Area report: <0.1 mm²
  - [ ] Power: <1 mW (combinational XOR, rất thấp)
- [ ] **Quan sát thú vị:** XOR tree tổ chức thành cây nhị phân đẹp trong layout

---

## PHASE 6 – SIGN-OFF

- [ ] Export GDS: `python3 run_def2gds.py`
- [ ] **Magic DRC**: 0 violations
- [ ] **Netgen LVS**: 0 mismatches
- [ ] KLayout DRC double-check
- [ ] Tạo `Docs/signoff_report.md`

---

## PHASE 7 – CARAVEL INTEGRATION & TAPE-OUT

- [ ] Clone Caravel user project template
- [ ] Wrap vào `user_project_wrapper.v`
- [ ] Map Wishbone interface (nếu có)
- [ ] Hoặc dùng GPIO trực tiếp (design đủ nhỏ để fit interface trong GPIO)
- [ ] Chạy precheck: `make precheck`
- [ ] Submit Efabless Chipignite
- [ ] **Tape-out!** 🎯

---

## Timeline Ước Tính

| Phase | Công việc | Thời gian |
|-------|-----------|-----------|
| 1 | Algorithm spec + golden reference | 2–3 ngày |
| 2.1 | Fix RTL bugs | 1–2 ngày |
| 2.2 | Viết lại RTL sạch | 2–3 ngày |
| 3 | Verification (cocotb) | 3–5 ngày |
| 4–5 | Synthesis + P&R | 1–2 ngày |
| 6–7 | Sign-off + Tape-out | 1–2 ngày |
| **Tổng** | | **~2–3 tuần** |

---

## Metrics Mục Tiêu

| Metric | Target |
|--------|--------|
| SEC: Correct all single-bit errors | **100%** (deterministic) |
| DED: Detect all double-bit errors | **100%** (deterministic) |
| False correction rate | **0%** |
| RTL vs golden match | **100%** (bit-exact) |
| Cell count | **1,500–3,000** (pure combinational) |
| Clock frequency | **100 MHz** (Sky130HD realistic) |
| Combinational delay | < 5 ns (XOR tree depth ~8 levels) |
| Power | **< 1 mW** |
| Die area | **< 0.1 mm²** |
| DRC violations | 0 |
| LVS mismatches | 0 |

---

## Ghi Chú Kỹ Thuật

### Tại Sao 500 MHz (2ns) Không Khả Thi Trên Sky130HD
```
Sky130HD là process 130nm từ 2020.
Typical gate delay: ~0.1–0.3 ns/gate
XOR tree cho 128 inputs: ~8 levels × 0.25ns = ~2 ns combinational
+ routing delay + setup time: thêm ~2–3 ns
→ Critical path: ~4–6 ns → max frequency ~160–250 MHz

Để đạt 500 MHz: cần 3–4 pipeline stages, phức tạp hóa thiết kế
Recommendation: 100 MHz (10 ns) là thực tế và đủ cho mọi ứng dụng
```

### Tại Sao Dự Án Này Quan Trọng Dù Nhỏ
```
1. Học toàn bộ RTL → tape-out flow trong thời gian ngắn
2. Thuật toán hoàn toàn deterministic → verify được 100%
3. Thực tế: ECC được dùng trong mọi server, SoC, automotive
4. Có thể nhúng vào các dự án lớn hơn (Bio_health SRAM cần ECC!)
5. Open-source SEC-DED ASIC trên Sky130: chưa có ai làm
```

### Khả Năng Mở Rộng
```
HammingCode_128bit → nhúng vào Bio_health
→ Bảo vệ Weight SRAM (255 KB weights) khỏi bit flips
→ Đặc biệt quan trọng cho thiết bị y tế (radiation immunity)
→ Tăng reliability của toàn hệ thống Bio_health
```

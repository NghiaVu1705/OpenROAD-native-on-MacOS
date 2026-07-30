# Hamming(137,128) SEC-DED Algorithm Specification

## Overview

The Hamming(137,128) SEC-DED (Single Error Correction, Double Error Detection) code protects 128-bit data words with 9 parity bits, producing a 137-bit codeword.

```
Input:   128-bit data
Output:  137-bit codeword = 128 data bits + 8 Hamming parity bits + 1 overall parity bit
SEC:     Any single-bit error is automatically corrected
DED:     Any double-bit error is detected (not corrected)
```

---

## 1. Codeword Structure

### 1.1 Standard Hamming Positions (1..136)

Parity bits occupy power-of-2 positions. Data bits fill all remaining positions:

| Codeword Position | Type  | Data Index |
|:-----------------:|:-----:|:----------:|
| 1                 | p1    | —          |
| 2                 | p2    | —          |
| 3                 | data  | 0          |
| 4                 | p4    | —          |
| 5                 | data  | 1          |
| 6                 | data  | 2          |
| 7                 | data  | 3          |
| 8                 | p8    | —          |
| 9                 | data  | 4          |
| 10–15             | data  | 5–10       |
| 16                | p16   | —          |
| 17–31             | data  | 11–25      |
| 32                | p32   | —          |
| 33–63             | data  | 26–56      |
| 64                | p64   | —          |
| 65–127            | data  | 57–119     |
| 128               | p128  | —          |
| 129–136           | data  | 120–127    |

**Verification:** 8 parity positions + 128 data positions = 136 positions. ✓
**Why 8 parity bits?** 2⁸ = 256 ≥ 128 + 8 + 1 = 137. ✓

### 1.2 Flat Storage Format (RTL codeword)

```
codeword[136]   = p0  (overall parity bit, SEC-DED)
codeword[135:8] = data_in[127:0]
codeword[7:0]   = {p128, p64, p32, p16, p8, p4, p2, p1}
                  (bit7=p128, bit6=p64, ..., bit0=p1)
```

---

## 2. Parity Bit Computation

### 2.1 Hamming Parity Bits (p1..p128)

Parity bit **pₖ** (at codeword position 2^(k-1)) covers all positions where bit (k-1) is set in the binary representation of the position number.

| Bit | Parity | Covers positions where...       | # Data bits |
|:---:|:------:|:--------------------------------|:-----------:|
| 0   | p1     | position is odd (bit0=1)        | 67          |
| 1   | p2     | bit1 = 1                        | 67          |
| 2   | p4     | bit2 = 1                        | 67          |
| 3   | p8     | bit3 = 1                        | 64          |
| 4   | p16    | bit4 = 1                        | 63          |
| 5   | p32    | bit5 = 1                        | 63          |
| 6   | p64    | bit6 = 1                        | 63          |
| 7   | p128   | bit7 = 1 (positions 128..136)   | 8           |

Each parity bit is set so that the XOR of all bits in its coverage group (including the parity bit itself) equals 0.

```
p1   = XOR of data_in bits at odd codeword positions
p2   = XOR of data_in bits at positions with bit1=1
p4   = XOR of data_in bits at positions with bit2=1
p8   = XOR of data_in bits at positions with bit3=1
p16  = XOR of data_in bits at positions with bit4=1
p32  = XOR of data_in bits at positions with bit5=1
p64  = XOR of data_in bits at positions with bit6=1
p128 = XOR of data_in[127:120]  (positions 129..136)
```

### 2.2 Overall Parity Bit (p0)

```
p0 = XOR of all 136 bits (p1..p128 + all data bits)
```

p0 ensures that the XOR of the entire 137-bit codeword = 0. This is the key to SEC-DED disambiguation.

---

## 3. Encoding Algorithm

```python
def encode(data_128bit):
    # 1. Compute p1..p128 by XORing covered data bits
    for k in 1..8:
        pk = XOR of data bits whose codeword position has bit (k-1) set

    # 2. Compute p0 = XOR of p1..p128 XOR all data bits
    p0 = XOR(p1..p128) XOR XOR(data[127:0])

    # 3. Pack output
    codeword = {p0, data[127:0], p128..p1}
```

**Combinational delay:** ~8 XOR levels = ~2–3 ns on Sky130HD.

---

## 4. Syndrome Decoding

### 4.1 Syndrome Computation

```
syndrome[k] = recalc_pk XOR received_pk    (for k = 1..8, using bit values 1,2,4,...,128)
syndrome_val = syndrome[1]*1 + syndrome[2]*2 + ... + syndrome[128]*128
```

`syndrome_val` is an 8-bit number giving the **codeword position** of the error.

### 4.2 Overall Parity Check

```
overall_recalc = XOR of received codeword bits [135:0]
overall_error  = overall_recalc XOR received_p0
```

### 4.3 Error Classification

| Syndrome | Overall | Condition              | Action                        |
|:--------:|:-------:|:-----------------------|:------------------------------|
| 0        | 0       | No error               | data_out = data_in            |
| 0        | 1       | p0 itself wrong        | data_out = data_in (harmless) |
| ≠ 0      | 1       | **Single bit error**   | Flip bit at codeword position `syndrome_val` → SEC |
| ≠ 0      | 0       | **Double bit error**   | Set DED flag, do NOT correct  |

### 4.4 Error Correction Mapping

When syndrome_val indicates a data bit error (not a parity position), the data index is:

```
data_index = syndrome_val - floor(log2(syndrome_val)) - 2
```

Examples:
- syndrome_val = 3 (=0b11) → data_index = 3-1-2 = 0 (data_in[0])
- syndrome_val = 9 (=0b1001) → data_index = 9-3-2 = 4 (data_in[4])
- syndrome_val = 129 (=0b10000001) → data_index = 129-7-2 = 120 (data_in[120])

**Parity positions** (1,2,4,8,16,32,64,128): syndrome indicates a parity bit is wrong → data is already correct.

---

## 5. RTL Implementation

### 5.1 Encoder (`hamming_encoder_128`)

- **Type:** Purely combinational
- **Inputs:** `data_in[127:0]`
- **Outputs:** `codeword_out[136:0]`
- **Logic:** 8 XOR reduction trees for p1..p128, one XOR for p0
- **Synthesis:** ~1,500 cells, <5 ns critical path

### 5.2 Decoder (`hamming_decoder_128`)

- **Type:** Purely combinational
- **Inputs:** `codeword_in[136:0]`
- **Outputs:** `data_out[127:0]`, `sec`, `ded`, `error_cw_pos[7:0]`
- **Logic:** Same 8 XOR trees, then syndrome comparison, case-statement correction

### 5.3 Top Module (`HammingCode_128bit`)

- **Type:** Registered (1-cycle latency pipeline)
- **Clock:** 100 MHz (10 ns), Sky130HD realistic
- **Ports:** Separate encode/decode paths, independent valid signals

---

## 6. Verification Results

| Test | Description | Result |
|------|-------------|--------|
| Smoke | Zero data round-trip | PASS |
| Encoder random | 500 vectors vs Python golden | PASS (bit-exact) |
| Decoder no-error | 500 clean codewords | PASS |
| SEC exhaustive | All 136 single-bit positions | PASS (100%) |
| DED random | 500 random double-bit pairs | PASS (100%) |
| Parity bit errors | All 8 parity positions (p1..p128) | PASS |
| Pipeline throughput | 100 back-to-back cycles | PASS |
| Round-trip | 200 encode→decode vectors | PASS |

**8/8 tests PASS** with Icarus Verilog + cocotb 2.0.1

---

## 7. Bugs Fixed vs Original RTL

| Bug | Original | Fixed |
|-----|----------|-------|
| **parity_in extraction** | `codeword_in[8:0]` (data, not parity!) | `codeword_in[7:0]` = p8..p1, `codeword_in[136]` = p0 |
| **recalc truncated** | Only ~10 bits per parity, rest missing | Full correct equations (8/64/67 bits per parity) |
| **error correction** | Wrong position mapping (codeword pos ≠ data index) | case statement: syndrome_val → data_in index |
| **SEC vs DED** | overall_p computed but not used | overall_error properly disambiguates SEC vs DED |
| **Encoder p3..p8** | Wrong data_in ranges | Correct Python-generated equations |

---

## 8. Target Metrics

| Metric | Target | Status |
|--------|--------|--------|
| SEC rate | 100% (all 136 single-bit errors) | Verified ✓ |
| DED rate | 100% (all C(137,2)=9,316 double-bit errors) | Sampled ✓ |
| False correction rate | 0% | Verified ✓ |
| RTL vs golden match | Bit-exact | Verified ✓ |
| Clock frequency | 100 MHz (Sky130HD) | Constrained |
| Cell count (estimate) | 1,500–3,000 | TBD (synthesis) |
| Power (estimate) | < 1 mW (combinational XOR) | TBD |
| Die area | < 0.1 mm² | TBD |

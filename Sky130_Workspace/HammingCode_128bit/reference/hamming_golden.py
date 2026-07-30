#!/usr/bin/env python3
"""
Hamming(137,128) SEC-DED Golden Reference Model
=================================================
128-bit data → 137-bit codeword using extended Hamming code.

Codeword layout (standard interleaved):
  Positions 1..136: parity at powers-of-2 (1,2,4,8,16,32,64,128), data elsewhere
  Position 0 (bit 136 in our flat format): overall parity p0 (SEC-DED)

Flat storage format (same as RTL):
  codeword[136]   = p0  (overall parity)
  codeword[135:8] = data_in[127:0]
  codeword[7:0]   = {p8, p7, p6, p5, p4, p3, p2, p1}  (p8 at bit7, p1 at bit0)

Syndrome decoding:
  syndrome = recalc XOR received_parity  (8-bit value = codeword error position)
  syndrome == 0, overall_ok  → no error
  syndrome != 0, overall_err → single bit error (correctable)
  syndrome != 0, overall_ok  → double bit error (detected only)
  syndrome == 0, overall_err → p0 itself flipped (data ok)
"""

# ---------------------------------------------------------------------------
# Position mapping: build codeword_pos → data_index and data_index → codeword_pos
# ---------------------------------------------------------------------------
PARITY_POSITIONS = {1 << k for k in range(8)}  # {1, 2, 4, 8, 16, 32, 64, 128}

_cw_to_data = {}   # codeword_pos (1..136) → data_in index (0..127)
_data_to_cw = {}   # data_in index (0..127) → codeword_pos (1..136)

_di = 0
for _cwpos in range(1, 137):
    if _cwpos not in PARITY_POSITIONS:
        _cw_to_data[_cwpos] = _di
        _data_to_cw[_di]    = _cwpos
        _di += 1

assert len(_cw_to_data) == 128, f"Expected 128 data positions, got {len(_cw_to_data)}"

# ---------------------------------------------------------------------------
# Parity coverage: for each parity bit pk, which data_in indices it covers
# ---------------------------------------------------------------------------
_pk_covers = {}  # pk_bit (1,2,4,...,128) → list of data_in indices
for _pk in PARITY_POSITIONS:
    _pk_covers[_pk] = [
        _cw_to_data[_cwpos]
        for _cwpos in range(1, 137)
        if (_cwpos & _pk) and (_cwpos != _pk) and (_cwpos not in PARITY_POSITIONS)
    ]


def encode(data: int) -> int:
    """
    Encode 128-bit data to 137-bit codeword.

    Args:
        data: integer with bits [127:0]
    Returns:
        137-bit codeword in flat format:
          bit[136]=p0, bit[135:8]=data, bit[7:0]={p8..p1}
    """
    assert 0 <= data < (1 << 128), "data must be 128-bit"

    # Compute parity bits p1..p8
    parity = {}  # pk → parity bit value
    for pk in PARITY_POSITIONS:
        p = 0
        for di in _pk_covers[pk]:
            if (data >> di) & 1:
                p ^= 1
        parity[pk] = p

    # Build flat codeword
    cw = 0
    cw |= (data << 8)         # data at bits [135:8]
    for k in range(8):
        pk = 1 << k
        cw |= (parity[pk] << k)  # p1 at bit0, p2 at bit1, ..., p128 at bit7

    # Compute p0 = XOR of all 136 bits (bits [135:0] of codeword)
    p0 = bin(cw & ((1 << 136) - 1)).count('1') % 2
    cw |= (p0 << 136)

    return cw


def decode(codeword: int) -> tuple:
    """
    Decode 137-bit codeword to 128-bit data with error detection/correction.

    Args:
        codeword: 137-bit integer in flat format
    Returns:
        (data_out, status, error_cw_pos) where
          status ∈ {"ok", "single_corrected", "double_detected", "p0_only"}
          error_cw_pos: codeword position of error (0 = none)
    """
    assert 0 <= codeword < (1 << 137), "codeword must be 137-bit"

    p0_received   = (codeword >> 136) & 1
    data          = (codeword >> 8) & ((1 << 128) - 1)
    parity_bits   = codeword & 0xFF  # bits [7:0] = {p8..p1}

    # Recalculate parity bits from received data
    syndrome = 0
    for k in range(8):
        pk = 1 << k
        recalc = 0
        for di in _pk_covers[pk]:
            if (data >> di) & 1:
                recalc ^= 1
        received_pk = (parity_bits >> k) & 1
        if recalc ^ received_pk:
            syndrome |= pk  # syndrome accumulates bit positions

    # Check overall parity: XOR of all received bits [135:0]
    received_bits_without_p0 = codeword & ((1 << 136) - 1)
    overall_recalc = bin(received_bits_without_p0).count('1') % 2
    overall_error  = overall_recalc ^ p0_received

    if syndrome == 0 and not overall_error:
        return data, "ok", 0

    elif syndrome == 0 and overall_error:
        # Only p0 is wrong — data and parity[8:1] are fine
        return data, "p0_only", 0

    elif syndrome != 0 and overall_error:
        # Single bit error at codeword position = syndrome value
        error_cwpos = syndrome
        data_out = data
        if error_cwpos in _cw_to_data:
            # Data bit error — correct it
            di = _cw_to_data[error_cwpos]
            data_out ^= (1 << di)
        # else: parity bit error — data is already correct
        return data_out, "single_corrected", error_cwpos

    else:  # syndrome != 0, not overall_error
        # Double bit error — detected, uncorrectable
        return data, "double_detected", syndrome


def inject_error(codeword: int, bit_pos: int) -> int:
    """Flip bit at position bit_pos (0..136) in the flat codeword."""
    assert 0 <= bit_pos <= 136
    return codeword ^ (1 << bit_pos)


def inject_double_error(codeword: int, pos1: int, pos2: int) -> int:
    """Flip bits at pos1 and pos2 in the flat codeword."""
    return codeword ^ (1 << pos1) ^ (1 << pos2)


def codeword_to_str(codeword: int) -> str:
    """Human-readable breakdown of a codeword."""
    p0  = (codeword >> 136) & 1
    data = (codeword >> 8) & ((1 << 128) - 1)
    parity = codeword & 0xFF
    return (f"p0={p0}  data=0x{data:032x}  "
            f"p8..p1={parity:08b}  (p1 at lsb)")


def get_mapping():
    """Return the codeword_pos → data_in_index mapping (for documentation)."""
    return dict(_cw_to_data)


# ---------------------------------------------------------------------------
# Self-test
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import random
    random.seed(42)
    errors = 0

    print("=== Hamming(137,128) Golden Reference Self-Test ===\n")

    # Test 1: No error (1000 random vectors)
    print("Test 1: No-error encode/decode (1000 vectors)...")
    for i in range(1000):
        data = random.randint(0, (1 << 128) - 1)
        cw = encode(data)
        data_out, status, pos = decode(cw)
        if data_out != data or status != "ok":
            print(f"  FAIL: data=0x{data:032x} → status={status}, data_out=0x{data_out:032x}")
            errors += 1
    print(f"  {'PASS' if errors == 0 else 'FAIL'} ({1000} vectors)\n")

    # Test 2: Single bit error at every bit position (137 vectors)
    print("Test 2: Single-bit error exhaustive (137 positions)...")
    data = random.randint(0, (1 << 128) - 1)
    cw_clean = encode(data)
    fail2 = 0
    for bit in range(137):
        cw_err = inject_error(cw_clean, bit)
        data_out, status, pos = decode(cw_err)
        if bit == 136:
            # bit 136 = p0 — p0-only error, data is fine
            if status != "p0_only" or data_out != data:
                print(f"  FAIL at p0 bit: status={status}, data match={data_out == data}")
                fail2 += 1
        elif status != "single_corrected":
            print(f"  FAIL at bit {bit}: status={status}")
            fail2 += 1
        elif 8 <= bit <= 135:
            # Data bit — must be corrected
            if data_out != data:
                print(f"  FAIL at bit {bit}: data not corrected, "
                      f"got 0x{data_out:032x}, want 0x{data:032x}")
                fail2 += 1
        elif bit < 8:
            # Parity bit (p1..p8) — data unchanged
            if data_out != data:
                print(f"  FAIL at parity bit {bit}: data corrupted")
                fail2 += 1
    errors += fail2
    print(f"  {'PASS' if fail2 == 0 else f'FAIL ({fail2} errors)'}\n")

    # Test 3: Double bit error — sample 1000 random pairs from C(137,2)=9316
    print("Test 3: Double-bit error detection (1000 random pairs)...")
    data = random.randint(0, (1 << 128) - 1)
    cw_clean = encode(data)
    fail3 = 0
    tested_pairs = set()
    for _ in range(1000):
        p1 = random.randint(0, 136)
        p2 = random.randint(0, 136)
        while p2 == p1:
            p2 = random.randint(0, 136)
        pair = (min(p1,p2), max(p1,p2))
        if pair in tested_pairs:
            continue
        tested_pairs.add(pair)
        cw_err = inject_double_error(cw_clean, p1, p2)
        data_out, status, pos = decode(cw_err)
        if status != "double_detected":
            print(f"  FAIL at bits ({p1},{p2}): status={status}")
            fail3 += 1
    errors += fail3
    print(f"  {'PASS' if fail3 == 0 else f'FAIL ({fail3} errors)'} ({len(tested_pairs)} unique pairs)\n")

    # Test 4: p0-only error
    print("Test 4: p0-only error (overall parity bit)...")
    data = random.randint(0, (1 << 128) - 1)
    cw_clean = encode(data)
    cw_p0err = inject_error(cw_clean, 136)  # bit 136 = p0
    data_out, status, pos = decode(cw_p0err)
    fail4 = 0
    if status != "p0_only" or data_out != data:
        print(f"  FAIL: status={status}, data match={data_out == data}")
        fail4 = 1
    errors += fail4
    print(f"  {'PASS' if fail4 == 0 else 'FAIL'}\n")

    # Test 5: Verify codeword structure
    print("Test 5: Codeword structure verification...")
    data = 0xDEADBEEF_CAFEBABE_12345678_90ABCDEF
    cw = encode(data)
    # data bits at [135:8] should equal data
    assert (cw >> 8) & ((1 << 128) - 1) == data, "Data bits not at [135:8]!"
    # decode should give back data
    data_out, status, _ = decode(cw)
    assert data_out == data and status == "ok", "Round-trip failed!"
    print("  PASS\n")

    # Summary
    print(f"=== {'ALL TESTS PASSED' if errors == 0 else f'FAILED ({errors} errors)'} ===")
    if errors == 0:
        print("\nCoverage info:")
        for pk in sorted(PARITY_POSITIONS):
            print(f"  p{pk:3d} covers {len(_pk_covers[pk]):2d} data bits")

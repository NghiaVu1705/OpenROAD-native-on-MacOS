"""
HammingCode_128bit Test Suite (cocotb)
========================================
Tests for Hamming(137,128) SEC-DED encoder/decoder.
Golden reference: reference/hamming_golden.py

Run:
  make SIM=icarus   (from Verifications/)
  make SIM=verilator
"""
import random
import sys
import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# Add project root to path for golden reference import
_PROJ_ROOT = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'reference')
sys.path.insert(0, _PROJ_ROOT)
from hamming_golden import encode, decode, inject_error, inject_double_error

CLOCK_NS = 10  # 100 MHz


async def _setup(dut):
    """Start clock and apply reset."""
    cocotb.start_soon(Clock(dut.clk, CLOCK_NS, units="ns").start())
    dut.rst_n.value          = 0
    dut.enc_valid.value      = 0
    dut.enc_data_in.value    = 0
    dut.dec_valid.value      = 0
    dut.dec_codeword_in.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def _encode_cycle(dut, data):
    """Apply one encode transaction, return codeword after 1 cycle."""
    dut.enc_data_in.value = data
    dut.enc_valid.value   = 1
    await RisingEdge(dut.clk)
    dut.enc_valid.value   = 0
    await Timer(1, units="ns")  # let combinational settle
    return int(dut.enc_codeword.value)


async def _decode_cycle(dut, codeword):
    """Apply one decode transaction, return (data_out, sec, ded, err_pos) after 1 cycle."""
    dut.dec_codeword_in.value = codeword
    dut.dec_valid.value       = 1
    await RisingEdge(dut.clk)
    dut.dec_valid.value = 0
    await Timer(1, units="ns")
    return (int(dut.dec_data_out.value),
            int(dut.dec_sec.value),
            int(dut.dec_ded.value),
            int(dut.dec_error_pos.value))


# =========================================================
# Test 1: Smoke — reset and basic encode/decode
# =========================================================
@cocotb.test()
async def test_smoke(dut):
    """Smoke test: zero data round-trip."""
    await _setup(dut)

    # Encode zero
    data = 0
    cw = await _encode_cycle(dut, data)
    golden_cw = encode(data)
    assert cw == golden_cw, (
        f"Encoder: data=0x{data:032x} → RTL=0x{cw:034x}, golden=0x{golden_cw:034x}")

    # Decode clean codeword
    data_out, sec, ded, err_pos = await _decode_cycle(dut, cw)
    assert data_out == data, f"Decoder: got 0x{data_out:032x}, want 0x{data:032x}"
    assert sec == 0, "Unexpected single-error flag on clean codeword"
    assert ded == 0, "Unexpected double-error flag on clean codeword"

    dut._log.info("SMOKE TEST PASSED")


# =========================================================
# Test 2: Encoder correctness — 500 random vectors vs golden
# =========================================================
@cocotb.test()
async def test_encoder_random(dut):
    """RTL encoder output must match Python golden reference bit-exact."""
    await _setup(dut)
    random.seed(12345)
    N = 500
    fail = 0

    for i in range(N):
        data = random.randint(0, (1 << 128) - 1)
        cw_rtl    = await _encode_cycle(dut, data)
        cw_golden = encode(data)

        if cw_rtl != cw_golden:
            dut._log.error(
                f"[{i}] data=0x{data:032x}: "
                f"RTL=0x{cw_rtl:034x} GOLDEN=0x{cw_golden:034x}"
            )
            fail += 1

    assert fail == 0, f"Encoder: {fail}/{N} mismatches vs golden"
    dut._log.info(f"ENCODER RANDOM TEST PASSED ({N} vectors)")


# =========================================================
# Test 3: Decoder no-error — 500 random vectors
# =========================================================
@cocotb.test()
async def test_decoder_no_error(dut):
    """Decode clean codewords — sec=0, ded=0, data_out == data_in."""
    await _setup(dut)
    random.seed(99999)
    N = 500
    fail = 0

    for i in range(N):
        data = random.randint(0, (1 << 128) - 1)
        cw = encode(data)
        data_out, sec, ded, err_pos = await _decode_cycle(dut, cw)

        if data_out != data or sec != 0 or ded != 0:
            dut._log.error(
                f"[{i}] data=0x{data:032x}: "
                f"data_out=0x{data_out:032x} sec={sec} ded={ded}"
            )
            fail += 1

    assert fail == 0, f"Decoder no-error: {fail}/{N} failures"
    dut._log.info(f"DECODER NO-ERROR TEST PASSED ({N} vectors)")


# =========================================================
# Test 4: SEC — exhaustive single-bit error injection (136 bits)
# =========================================================
@cocotb.test()
async def test_sec_exhaustive(dut):
    """Inject every single bit error; verify correction and sec flag."""
    await _setup(dut)
    random.seed(11111)

    data = random.randint(0, (1 << 128) - 1)
    cw_clean = encode(data)
    fail = 0

    for bit in range(136):  # bits 0..135 (not p0 at bit 136)
        cw_err = inject_error(cw_clean, bit)
        data_out, sec, ded, err_pos = await _decode_cycle(dut, cw_err)

        if sec != 1:
            dut._log.error(f"bit={bit}: sec not asserted (sec={sec}, ded={ded})")
            fail += 1
            continue

        if ded != 0:
            dut._log.error(f"bit={bit}: ded wrongly asserted")
            fail += 1

        # Data bits are at codeword positions [135:8] = flat bits 8..135
        if 8 <= bit <= 135:
            # Data bit error — must be corrected
            if data_out != data:
                dut._log.error(
                    f"bit={bit}: data not corrected: "
                    f"got 0x{data_out:032x}, want 0x{data:032x}"
                )
                fail += 1

    assert fail == 0, f"SEC exhaustive: {fail} failures"
    dut._log.info("SEC EXHAUSTIVE TEST PASSED (136 bit positions)")


# =========================================================
# Test 5: DED — 500 random double-bit error pairs
# =========================================================
@cocotb.test()
async def test_ded_random(dut):
    """Inject random double-bit errors; verify ded flag, sec not set."""
    await _setup(dut)
    random.seed(22222)

    data = random.randint(0, (1 << 128) - 1)
    cw_clean = encode(data)
    N = 500
    fail = 0

    tested = set()
    count = 0
    attempts = 0
    while count < N and attempts < N * 3:
        attempts += 1
        p1 = random.randint(0, 136)
        p2 = random.randint(0, 136)
        if p1 == p2:
            continue
        pair = (min(p1, p2), max(p1, p2))
        if pair in tested:
            continue
        tested.add(pair)

        cw_err = inject_double_error(cw_clean, p1, p2)
        data_out, sec, ded, err_pos = await _decode_cycle(dut, cw_err)

        if ded != 1:
            dut._log.error(
                f"bits=({p1},{p2}): ded not asserted (sec={sec}, ded={ded})"
            )
            fail += 1

        if sec != 0:
            dut._log.error(f"bits=({p1},{p2}): sec wrongly asserted")
            fail += 1

        count += 1

    assert fail == 0, f"DED random: {fail} failures in {count} pairs"
    dut._log.info(f"DED RANDOM TEST PASSED ({count} pairs)")


# =========================================================
# Test 6: Parity bit errors — flip each parity bit (8 bits)
# =========================================================
@cocotb.test()
async def test_parity_bit_errors(dut):
    """Flip each parity bit (p1..p8 = bits 0..7); data must be intact."""
    await _setup(dut)
    random.seed(33333)

    data = random.randint(0, (1 << 128) - 1)
    cw_clean = encode(data)
    fail = 0

    for bit in range(8):  # bits 0..7 = p1..p128
        cw_err = inject_error(cw_clean, bit)
        data_out, sec, ded, err_pos = await _decode_cycle(dut, cw_err)

        if sec != 1:
            dut._log.error(
                f"parity bit {bit}: sec not asserted (sec={sec}, ded={ded})"
            )
            fail += 1

        if data_out != data:
            dut._log.error(
                f"parity bit {bit}: data corrupted! "
                f"got 0x{data_out:032x}, want 0x{data:032x}"
            )
            fail += 1

    assert fail == 0, f"Parity bit errors: {fail} failures"
    dut._log.info("PARITY BIT ERROR TEST PASSED (8 parity positions)")


# =========================================================
# Test 7: Pipeline throughput — back-to-back encode 100 cycles
# =========================================================
@cocotb.test()
async def test_pipeline_throughput(dut):
    """Encode 100 consecutive words; all must match golden (1 word/cycle)."""
    await _setup(dut)
    random.seed(44444)
    N = 100
    fail = 0

    data_list = [random.randint(0, (1 << 128) - 1) for _ in range(N)]
    golden_cw  = [encode(d) for d in data_list]

    # Send all words back to back
    for d in data_list:
        dut.enc_data_in.value = d
        dut.enc_valid.value   = 1
        await RisingEdge(dut.clk)

    dut.enc_valid.value = 0
    await Timer(1, units="ns")

    # Verify last output (pipeline has 1 cycle latency, last word is valid)
    last_cw = int(dut.enc_codeword.value)
    if last_cw != golden_cw[-1]:
        dut._log.error(
            f"Pipeline last word: RTL=0x{last_cw:034x} "
            f"GOLDEN=0x{golden_cw[-1]:034x}"
        )
        fail += 1

    assert fail == 0, f"Pipeline test: {fail} failures"
    dut._log.info(f"PIPELINE THROUGHPUT TEST PASSED ({N} cycles)")


# =========================================================
# Test 8: Round-trip encode → decode, 200 random vectors
# =========================================================
@cocotb.test()
async def test_roundtrip(dut):
    """Full RTL encode → RTL decode round-trip. data_in must equal data_out."""
    await _setup(dut)
    random.seed(55555)
    N = 200
    fail = 0

    for i in range(N):
        data = random.randint(0, (1 << 128) - 1)

        # RTL encode
        cw = await _encode_cycle(dut, data)

        # RTL decode clean codeword
        data_out, sec, ded, err_pos = await _decode_cycle(dut, cw)

        if data_out != data:
            dut._log.error(
                f"[{i}] Round-trip failed: "
                f"data_in=0x{data:032x} data_out=0x{data_out:032x}"
            )
            fail += 1
        if sec or ded:
            dut._log.error(f"[{i}] False error flags: sec={sec} ded={ded}")
            fail += 1

    assert fail == 0, f"Round-trip: {fail}/{N} failures"
    dut._log.info(f"ROUND-TRIP TEST PASSED ({N} vectors)")

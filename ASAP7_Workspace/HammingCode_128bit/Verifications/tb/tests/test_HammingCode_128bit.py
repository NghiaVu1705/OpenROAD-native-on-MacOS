"""
HammingCode_128bit Test Suite (cocotb + pyUVM)
Run with: make SIM=icarus  or  make SIM=verilator
"""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from pyuvm import *

from tb.env.env           import HammingCode_128bit_Env
from tb.sequences.spike_sequences import (
    ZeroInputSeq, MaxInputSeq, RandomSpikeSeq, RampInputSeq
)


# ---------------------------------------------------------------
# Base Test
# ---------------------------------------------------------------
class CamAI_BaseTest(uvm_test):
    """Base test: setup clock + reset"""

    def build_phase(self):
        self.env = HammingCode_128bit_Env.create("env", self)

    async def _setup(self):
        dut = cocotb.top
        cocotb.start_soon(Clock(dut.clk, 5, units="ns").start())
        dut.rst_n.value    = 0
        dut.valid_in.value = 0
        dut.spike_in.value = 0
        for _ in range(5):
            await RisingEdge(dut.clk)
        dut.rst_n.value = 1

    def get_seqr(self):
        return self.env.agent.seqr


# ---------------------------------------------------------------
# Test: Smoke (zero input)
# ---------------------------------------------------------------
class SmokeTest(CamAI_BaseTest):
    """Basic sanity: apply zero inputs, check no crash"""

    async def run_phase(self):
        await self._setup()
        seq = ZeroInputSeq()
        await seq.start(self.get_seqr())


# ---------------------------------------------------------------
# Test: Max activation
# ---------------------------------------------------------------
class MaxActivationTest(CamAI_BaseTest):
    """Apply max inputs, expect spikes at output"""

    async def run_phase(self):
        await self._setup()
        seq = MaxInputSeq()
        await seq.start(self.get_seqr())


# ---------------------------------------------------------------
# Test: Random stimulus
# ---------------------------------------------------------------
class RandomTest(CamAI_BaseTest):
    """50 random transactions, coverage-driven"""

    async def run_phase(self):
        await self._setup()
        seq = RandomSpikeSeq(n=50)
        await seq.start(self.get_seqr())


# ---------------------------------------------------------------
# Test: Ramp
# ---------------------------------------------------------------
class RampTest(CamAI_BaseTest):
    """Ramp input from 0 to 255"""

    async def run_phase(self):
        await self._setup()
        seq = RampInputSeq()
        await seq.start(self.get_seqr())


# ---------------------------------------------------------------
# cocotb entry points (called by Makefile)
# ---------------------------------------------------------------
@cocotb.test()
async def test_smoke(dut):
    await uvm_root().run_test("SmokeTest")

@cocotb.test()
async def test_max_activation(dut):
    await uvm_root().run_test("MaxActivationTest")

@cocotb.test()
async def test_random(dut):
    await uvm_root().run_test("RandomTest")

@cocotb.test()
async def test_ramp(dut):
    await uvm_root().run_test("RampTest")

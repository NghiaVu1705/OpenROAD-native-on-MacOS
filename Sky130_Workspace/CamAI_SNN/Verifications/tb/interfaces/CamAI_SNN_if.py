"""
CamAI_SNN Interface Definitions
Wraps DUT ports into a clean Python interface
"""
import cocotb
from cocotb.handle import SimHandleBase


class SpikeInputIF:
    """Interface for spike input port"""
    def __init__(self, dut: SimHandleBase):
        self.clk       = dut.clk
        self.rst_n     = dut.rst_n
        self.spike_in  = dut.spike_in
        self.valid_in  = dut.valid_in

    async def reset(self, cycles: int = 5):
        self.rst_n.value     = 0
        self.valid_in.value  = 0
        self.spike_in.value  = 0
        for _ in range(cycles):
            await cocotb.triggers.RisingEdge(self.clk)
        self.rst_n.value = 1


class SpikeOutputIF:
    """Interface for spike output port"""
    def __init__(self, dut: SimHandleBase):
        self.spike_out  = dut.spike_out
        self.valid_out  = dut.valid_out

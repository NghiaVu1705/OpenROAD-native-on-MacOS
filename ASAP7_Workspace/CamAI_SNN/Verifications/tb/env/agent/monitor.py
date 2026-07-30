"""
CamAI_SNN Monitor
Observes DUT outputs and broadcasts transactions
"""
from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge


class SpikeOutputTransaction(uvm_sequence_item):
    """Captured output from DUT"""
    def __init__(self, name="SpikeOutputTransaction"):
        super().__init__(name)
        self.spike_out = 0
        self.valid_out = 0

    def __str__(self):
        return f"SpikeOut: {bin(self.spike_out)} valid={self.valid_out}"


class SpikeMonitor(uvm_monitor):
    """Monitors spike_out and valid_out"""

    def start_of_simulation_phase(self):
        self.dut = cocotb.top
        self.ap  = uvm_analysis_port("ap", self)

    async def run_phase(self):
        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.valid_out.value == 1:
                txn = SpikeOutputTransaction()
                txn.spike_out = int(self.dut.spike_out.value)
                txn.valid_out = int(self.dut.valid_out.value)
                self.ap.write(txn)

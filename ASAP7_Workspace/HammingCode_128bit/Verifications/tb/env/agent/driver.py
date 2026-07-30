"""
HammingCode_128bit Driver
Drives spike_in stimulus to DUT
"""
from pyuvm import *
import cocotb
from cocotb.triggers import RisingEdge, Timer


class SpikeTransaction(uvm_sequence_item):
    """A single transaction: 4x 8-bit spike inputs"""
    def __init__(self, name="SpikeTransaction"):
        super().__init__(name)
        self.spike_data = [0] * 4   # 4 input neurons
        self.valid      = True

    def __str__(self):
        return f"SpikeTransaction: {[hex(s) for s in self.spike_data]}"


class SpikeDriver(uvm_driver):
    """Drives SpikeTransaction onto DUT input"""

    def start_of_simulation_phase(self):
        self.dut = cocotb.top

    async def run_phase(self):
        while True:
            txn = await self.seq_item_port.get_next_item()
            await self._drive(txn)
            self.seq_item_port.item_done()

    async def _drive(self, txn: SpikeTransaction):
        await RisingEdge(self.dut.clk)
        self.dut.valid_in.value = int(txn.valid)
        spike_word = 0
        for i, val in enumerate(txn.spike_data):
            spike_word |= (val & 0xFF) << (i * 8)
        self.dut.spike_in.value = spike_word
        await RisingEdge(self.dut.clk)
        self.dut.valid_in.value = 0

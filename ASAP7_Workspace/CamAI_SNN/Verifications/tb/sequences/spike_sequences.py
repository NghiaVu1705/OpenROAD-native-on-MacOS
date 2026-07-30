"""
CamAI_SNN Sequences
"""
from pyuvm import *
from tb.env.agent.driver import SpikeTransaction
import random


class ZeroInputSeq(uvm_sequence):
    """All inputs = 0 (no spikes)"""
    async def body(self):
        for _ in range(10):
            txn = SpikeTransaction()
            txn.spike_data = [0x00] * 4
            await self.start_item(txn)
            await self.finish_item(txn)


class MaxInputSeq(uvm_sequence):
    """All inputs = 0xFF (maximum activation)"""
    async def body(self):
        for _ in range(10):
            txn = SpikeTransaction()
            txn.spike_data = [0xFF] * 4
            await self.start_item(txn)
            await self.finish_item(txn)


class RandomSpikeSeq(uvm_sequence):
    """Random spike pattern, N transactions"""
    def __init__(self, name="RandomSpikeSeq", n=50):
        super().__init__(name)
        self.n = n

    async def body(self):
        for _ in range(self.n):
            txn = SpikeTransaction()
            txn.spike_data = [random.randint(0, 255) for _ in range(4)]
            await self.start_item(txn)
            await self.finish_item(txn)


class RampInputSeq(uvm_sequence):
    """Ramp: gradually increasing input"""
    async def body(self):
        for val in range(0, 256, 16):
            txn = SpikeTransaction()
            txn.spike_data = [val] * 4
            await self.start_item(txn)
            await self.finish_item(txn)

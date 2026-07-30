"""
CamAI_SNN Coverage Collector
Functional coverage for spike patterns
"""
from pyuvm import *
from tb.env.agent.monitor import SpikeOutputTransaction


class SpikeCoverage(uvm_subscriber):
    """Collects functional coverage"""

    def start_of_simulation_phase(self):
        self.covered = {
            "no_spike"     : False,   # spike_out = 0b00
            "neuron0_only" : False,   # spike_out = 0b01
            "neuron1_only" : False,   # spike_out = 0b10
            "both_spikes"  : False,   # spike_out = 0b11
        }

    def write(self, txn: SpikeOutputTransaction):
        s = txn.spike_out
        if   s == 0b00: self.covered["no_spike"]     = True
        elif s == 0b01: self.covered["neuron0_only"]  = True
        elif s == 0b10: self.covered["neuron1_only"]  = True
        elif s == 0b11: self.covered["both_spikes"]   = True

    def report_phase(self):
        hit   = sum(self.covered.values())
        total = len(self.covered)
        pct   = hit / total * 100
        self.logger.info(f"Coverage: {hit}/{total} bins hit ({pct:.1f}%)")
        for name, hit in self.covered.items():
            status = "HIT" if hit else "MISS"
            self.logger.info(f"  [{status}] {name}")

"""
CamAI_SNN UVM Environment
"""
from pyuvm import *
from tb.env.agent.driver  import SpikeDriver
from tb.env.agent.monitor import SpikeMonitor
from tb.env.scoreboard.scoreboard import SpikeScoreboard
from tb.env.coverage.coverage     import SpikeCoverage


class SpikeAgent(uvm_agent):
    def build_phase(self):
        self.driver    = SpikeDriver.create("driver", self)
        self.monitor   = SpikeMonitor.create("monitor", self)
        self.seqr      = uvm_sequencer.create("seqr", self)

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.seqr.seq_item_export)


class CamAI_SNN_Env(uvm_env):
    def build_phase(self):
        self.agent      = SpikeAgent.create("agent", self)
        self.scoreboard = SpikeScoreboard.create("scoreboard", self)
        self.coverage   = SpikeCoverage.create("coverage", self)

    def connect_phase(self):
        self.agent.monitor.ap.connect(self.scoreboard.result_export)
        self.agent.monitor.ap.connect(self.coverage)

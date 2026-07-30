"""
CamAI_SNN Scoreboard
Checks outputs against expected spike behavior
"""
from pyuvm import *
from tb.env.agent.monitor import SpikeOutputTransaction


class SpikeScoreboard(uvm_scoreboard):
    """Validates spike outputs"""

    def build_phase(self):
        self.result_fifo = uvm_tlm_analysis_fifo("result_fifo", self)
        self.result_export = self.result_fifo.analysis_export
        self.pass_count = 0
        self.fail_count = 0

    async def run_phase(self):
        while True:
            txn: SpikeOutputTransaction = await self.result_fifo.get()
            self._check(txn)

    def _check(self, txn: SpikeOutputTransaction):
        # Basic sanity: spike_out should be 2-bit (0b00 to 0b11)
        if txn.spike_out not in range(0, 4):
            self.logger.error(f"FAIL: Invalid spike_out={txn.spike_out}")
            self.fail_count += 1
        else:
            self.logger.info(f"PASS: spike_out={bin(txn.spike_out)}")
            self.pass_count += 1

    def report_phase(self):
        total = self.pass_count + self.fail_count
        self.logger.info(f"Scoreboard: {self.pass_count}/{total} passed")
        if self.fail_count:
            self.logger.error(f"{self.fail_count} FAILURES detected!")

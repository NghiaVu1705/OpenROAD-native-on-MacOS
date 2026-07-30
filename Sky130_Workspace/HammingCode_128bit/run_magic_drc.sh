#!/bin/bash
# Magic DRC wrapper for HammingCode_128bit
# Tự detect OPENROAD_HOME — không hardcode paths.
set -e

# Auto-detect (file này: OPENROAD_HOME/Sky130_Workspace/HammingCode_128bit/run_magic_drc.sh)
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENROAD_HOME="$(cd "$_SCRIPT_DIR/../.." && pwd)"

MAGIC="$OPENROAD_HOME/tools/install/magic/bin/magic"
GDS="$OPENROAD_HOME/ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.gds"
LOG="$_SCRIPT_DIR/drc_magic.log"
DESIGN=HammingCode_128bit

echo "=== Magic DRC: $DESIGN ===" | tee "$LOG"
echo "GDS: $GDS" | tee -a "$LOG"

# Note: do NOT use -rcfile sky130A.magicrc (template has quit guards before stdin)
"$MAGIC" -dnull -noconsole -T sky130A <<MAGIC_EOF 2>&1 | tee -a "$LOG"

gds read $GDS

set top_cells [cellname list top]
puts "Top cells: \$top_cells"
load $DESIGN

puts "Running DRC check..."
drc euclidean on
drc check
drc catchup

set drc_total [drc list count total]
puts ""
puts "==================================================="
puts "DRC Total Violations: \$drc_total"
puts "==================================================="

if {\$drc_total > 0} {
    set drc_list [drc listall why]
    foreach {cell reasons} \$drc_list {
        puts "Cell: \$cell"
        foreach reason \$reasons {
            puts "  \$reason"
        }
    }
} else {
    puts "CLEAN: 0 DRC violations"
}

quit
MAGIC_EOF

echo ""
echo "=== DRC Complete ==="
grep -E "DRC Total|CLEAN|violation" "$LOG" || true

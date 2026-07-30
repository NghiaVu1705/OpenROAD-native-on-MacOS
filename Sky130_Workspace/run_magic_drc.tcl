# Magic batch DRC for GCD design
# Run: magic -dnull -noconsole -T sky130A -rcfile /dev/null run_magic_drc.tcl

set GDS   /Users/vuhieunghia/Documents/OpenROAD/Sky130_Workspace/GCD_signoff/gcd_final.gds
set OUT   /Users/vuhieunghia/Documents/OpenROAD/Sky130_Workspace/GCD_signoff/drc_report.txt

puts "Loading GDS: $GDS"
gds read $GDS

# Select top cell
set topcell [lindex [cellname list top] 0]
puts "Top cell: $topcell"
load $topcell

# Flatten for DRC (optional – skip for speed)
# flatten $topcell\_flat

# Run DRC
drc on
drc catchup
set drc_count [drc list count total]
puts "DRC violations: $drc_count"

# Write report
set fp [open $OUT w]
puts $fp "=== Magic DRC Report: $topcell ==="
puts $fp "Technology: sky130A"
puts $fp "Total violations: $drc_count"
if {$drc_count > 0} {
    puts $fp "\nViolation details:"
    puts $fp [drc listall why]
}
close $fp

puts "Report written to $OUT"
quit

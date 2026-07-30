#!/usr/bin/env wish
# Magic DRC script for HammingCode_128bit
# Run: magic -dnull -noconsole -T sky130A -rcfile sky130A.magicrc -nowindow run_magic_drc.tcl

set gds_file "/Users/vuhieunghia/Documents/OpenROAD/ORFS_Source/flow/results/sky130hd/HammingCode_128bit/base/6_final.gds"
set design_name "HammingCode_128bit"

puts "=== Magic DRC for $design_name ==="
puts "Loading GDS: $gds_file"

# Read GDS
gds read $gds_file
set top [lindex [cellname list top] end]
puts "Top cell: $top"
load $design_name

# Run DRC
puts "Running DRC..."
drc on
drc check
drc catchup

# Report
set drc_count [drc list count total]
puts ""
puts "==================================================="
puts "DRC Violation Count: $drc_count"
puts "==================================================="

if {$drc_count > 0} {
    puts "DRC Errors:"
    drc listall style
} else {
    puts "CLEAN: 0 DRC violations"
}

quit

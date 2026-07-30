# Export GDS from GCD 6_final.odb using OpenROAD
set RESULTS /Users/vuhieunghia/Documents/OpenROAD/ORFS_Source/flow/results/sky130hd/gcd/base
set PLATFORM /Users/vuhieunghia/Documents/OpenROAD/ORFS_Source/flow/platforms/sky130hd
set OUTPUT /Users/vuhieunghia/Documents/OpenROAD/Sky130_Workspace/GCD_signoff

file mkdir $OUTPUT

# Read LEF
read_lef $PLATFORM/lef/sky130_fd_sc_hd_merged.lef

# Read final ODB
read_db $RESULTS/6_final.odb

# Write GDS (merge with standard cell GDS)
write_gds -merge_files $PLATFORM/gds/sky130_fd_sc_hd.gds \
          $OUTPUT/gcd_final.gds

puts "GDS written to $OUTPUT/gcd_final.gds"
exit

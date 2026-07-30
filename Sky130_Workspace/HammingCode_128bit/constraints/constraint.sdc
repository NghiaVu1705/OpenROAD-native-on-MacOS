current_design HammingCode_128bit

# 100 MHz clock (10 ns period, realistic for Sky130HD)
# XOR tree depth ~8 levels × 0.25ns ≈ 2ns combinational + routing ≈ 4-6ns total
set clk_name   core_clock
set clk_port   clk
set clk_period 10.0
set clk_io_pct 0.2

create_clock -name $clk_name -period $clk_period [get_ports $clk_port]

set non_clk_inputs [all_inputs -no_clocks]
set_input_delay  [expr $clk_period * $clk_io_pct] -clock $clk_name $non_clk_inputs
set_output_delay [expr $clk_period * $clk_io_pct] -clock $clk_name [all_outputs]

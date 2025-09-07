# Placeholder SDC file for synthesis
# Define a 100 MHz clock on the global clk port
create_clock -name clk -period 10.0 [get_ports clk]

# Input and output delays relative to the clock
set_input_delay 1.0 -clock clk [all_inputs]
set_output_delay 1.0 -clock clk [all_outputs]

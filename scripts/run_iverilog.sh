#!/bin/bash
set -euo pipefail

# Build directory
mkdir -p build

# Compile all RTL and testbench files
iverilog -g2005 -I rtl -s tb_pipeline_top -o build/sim.vvp rtl/*.v tb/tb_pipeline_top.v

# Run simulation and capture log
vvp build/sim.vvp | tee build/sim.log

# Move waveform if generated
if [ -f wave.vcd ]; then
    mv wave.vcd build/wave.vcd
fi

echo "Simulation complete; logs in build/sim.log and waveform in build/wave.vcd"

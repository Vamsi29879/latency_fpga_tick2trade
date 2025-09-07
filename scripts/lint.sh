#!/bin/bash
set -euo pipefail

# Simple lint script using Verilator if available
if ! command -v verilator >/dev/null 2>&1; then
    echo "Verilator not installed. Skipping lint."
    exit 0
fi

# Run Verilator lint on all RTL files
verilator --lint-only -Wall -I rtl rtl/*.v

echo "Lint completed successfully"

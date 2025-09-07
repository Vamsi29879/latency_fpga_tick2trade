# Latency FPGA Tick-to-Trade

This repository contains a deterministic, ultra‑low‑latency tick‑to‑trade pipeline implemented in synthesizable Verilog. The design demonstrates how to transform Top‑of‑Book (ToB) price updates directly into orders with cycle‑accurate latency measurement and built‑in risk controls.

## Features

- Branch‑free, FIFO‑free hot path for bounded latency.
- Free‑running cycle counter with timestamp capture on message ingress and egress.
- Simple momentum/imbalance‑based trading strategy with configurable thresholds and spread filter.
- Risk controls: position limit, notional limit and minimum inter‑order interval.
- Two‑word order frame with encoded latency cycles.
- Single‑cycle configuration and status register interface.
- Portable testbench using Icarus Verilog and GitHub Actions continuous integration.

## Directory structure

- `rtl/` – Verilog source files.
- `tb/` – Testbench and simulation files.
- `scripts/` – Helper scripts to build and run the simulation.
- `docs/` – Architecture and latency notes.
- `constraints/` – Placeholder timing constraints.
- `.github/workflows/` – CI workflow for simulation.

## Running the simulation

Make sure you have [Icarus Verilog](http://iverilog.icarus.com) installed.



# Architecture Overview

This document summarizes the architecture of the latency_fpga_tick2trade design.

## Pipeline top-level

The top-level module `pipeline_top` integrates all the functional blocks required to transform Top - of ‑Book (ToB) feed messages into encoded order frames with deterministic latency telemetry.

Inputs:
- `clk`: system clock driving the synchronous logic.
- `rst_n`: active-low reset.
- `valid_in`: high when a new ToB update is available.
- `tob_word0` and `tob_word1`: 2×64 -bit words encoding instrument ID, bid/ask prices and sizes.

Outputs:
- `valid_out`: indicates an order frame is ready to transmit.
- `order_word0` and `order_word1`: 2×64 -bit words encoding the order fields (instrument ID, price, quantity, side) and latency cycles.

The pipeline operates on each clock cycle without FIFOs in the hot path to maintain bounded latency.

## Module descriptions

### `tdc_timestamp`
A free running time‑to‑digital counter that provides a coarse cycle timestamp (`ts`). The counter runs continuously and is reset when `rst_n` deasserts.

### `topob_unpack`
Captures the timestamp at message completion and unpacks the incoming ToB words into structured fields: instrument identifier, bid price, bid size, ask price and ask size. Prices are represented in Q16.16 fixed point format and sizes are integers.

### `strategy_imbalance`
Implements a one‑cycle trading strategy based on simple market imbalance:
- Computes the absolute difference between bid size and ask size and compares it to `imbalance_threshold`.
- Checks that the mid‑price momentum exceeds `momentum_delta` and the current spread (ask minus bid) is less than `max_spread`.
- Optionally filters by instrument ID if `inst_filter` is non‑zero.
If conditions are satisfied, produces a BUY order at `ask_px` when ask size exceeds bid size, or a SELL order at `bid_px` otherwise. The requested quantity is the minimum of `default_qty` and the contra‑side size.

### `risk_checks`
Gates candidate orders based on:
- **Position limit**: ensures the updated long/short position does not exceed `max_position`.
- **Notional limit**: ensures the total exposure (price × quantity) remains below `max_notional`.
- **Minimum inter‑order spacing**: enforces a minimum number of cycles between orders with `min_interval_cycles`.
When all risk conditions pass, updates internal position/notional accumulators and forwards the order; otherwise suppresses the order.

### `tx_order_encoder`
Packs the selected order into two 64‑bit words. The first word contains the quantity (bits [63:48]), price (bits [47:16]) and instrument ID (bits [15:0]). The second word contains the order side (`BUY`=1, `SELL`=0) in bit 0, latency cycles (`ts_now - ts_in`) in bits [47:1], with the remaining bits reserved.

## Data flow

1. `tdc_timestamp` provides a continuously incrementing cycle count.
2. When `valid_in` is asserted, `topob_unpack` records the timestamp and splits the ToB update into fields.
3. `strategy_imbalance` evaluates the ToB message and default parameters to decide whether an order should be placed.
4. `risk_checks` evaluates the candidate order against position, notional and spacing constraints; if any check fails, the order is dropped.
5. `tx_order_encoder` calculates the latency cycles since message capture and packages the order into two 64‑bit words on `valid_out`.

By limiting each stage to a single clock cycle and avoiding buffers on the hot path, the pipeline achieves predictable end‑to‑end latency. Additional modules such as MAC/UDP feed handlers or venue‑specific order encoders can be connected at the inputs and outputs without changing this core.

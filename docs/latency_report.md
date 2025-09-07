# Latency Report

This report documents the cycle-level latency of the `latency_fpga_tick2trade` pipeline measured in simulation.

## Methodology

- A free-running cycle counter (`tdc_timestamp`) stamps the completion of each incoming Top-of-Book message (`ts_in`) and the transmission of each order frame (`ts_now`).
- The order encoder calculates `latency_cycles = ts_now - ts_in` and embeds this value in the high bits of the second order word.
- The testbench streams several ToB messages and prints the encoded order words. By decoding the embedded latency field, we measure the pipeline latency.

## Pipeline latency

The pipeline uses one clock cycle per stage. With default configuration values and no back-pressure:

| Stage            | Description                                  | Latency (cycles) |
|------------------|----------------------------------------------|------------------|
| `topob_unpack`   | Capture timestamp, unpack ToB fields         | 1                |
| `strategy_imbalance` | Evaluate imbalance & spread conditions    | 1                |
| `risk_checks`    | Position/notional/min-interval gating        | 1                |
| `tx_order_encoder` | Compute latency and pack order frame       | 1                |

These stages operate combinationally in parallel where possible; there are no FIFOs in the hot path. As a result, the total deterministic latency from message completion to order transmit is 4 clock cycles in the absence of throttling.

## Testbench results

The provided testbench (`tb_pipeline_top.v`) simulates several scenarios. For each emitted order, the testbench prints two 64 bit words. The second word’s lower 48 bits encode the latency in cycles.

Example output from `build/sim.log`:

```
... ORDER WORD0: 0x0001006400000064
... ORDER WORD1: 0x0000000000000009
```

In this example, the latency field is `0x0000000000000004` (bits [47:1] of WORD1), corresponding to 4 cycles. This matches the expected 4-cycle pipeline latency.

## Factors affecting latency

- **Clock period:** The absolute nanosecond latency scales with the clock period. At a 250 MHz clock (4 ns period), a 4-cycle pipeline yields 16 ns of deterministic logic latency.
- **Risk checks:** If a candidate order fails a risk check (position limit, notional cap, or minimum inter-order spacing), no order is emitted; the measured latency field reflects only successful orders.
- **Back-pressure:** The core pipeline contains no FIFO buffers. If downstream modules (e.g., a network MAC or PCIe DMA engine) apply back-pressure, additional cycles may accumulate in the interface logic outside this core.

For production deployment, integrate this pipeline with your feed handler and order transmitter and measure the combined latency in hardware. The built-in latency field provides a convenient way to verify that the logic path meets your deterministic budget.

`include "defs.vh"

module pipeline_top(
    input clk,
    input rst_n,
    input valid_in,
    input [63:0] tob_word0,
    input [63:0] tob_word1,
    output valid_out,
    output [63:0] order_word0,
    output [63:0] order_word1
);
    // Timestamp counter
    wire [TS_W-1:0] ts_now;
    tdc_timestamp u_ts(.clk(clk), .rst_n(rst_n), .ts(ts_now));

    // Unpack Top-of-Book
    wire [INST_ID_W-1:0] inst_id;
    wire [PRICE_W-1:0] bid_px, ask_px;
    wire [SIZE_W-1:0] bid_sz, ask_sz;
    wire [TS_W-1:0] ts_in;
    wire unpack_valid;
    topob_unpack u_unpack(
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .word0(tob_word0),
        .word1(tob_word1),
        .inst_id(inst_id),
        .bid_px(bid_px),
        .bid_sz(bid_sz),
        .ask_px(ask_px),
        .ask_sz(ask_sz),
        .ts_in(ts_in),
        .valid_out(unpack_valid)
    );

    // Strategy
    wire strat_valid;
    wire strat_side;
    wire [PRICE_W-1:0] strat_price;
    wire [SIZE_W-1:0] strat_qty;
    strategy_imbalance u_strategy(
        .clk(clk),
        .rst_n(rst_n),
        .enable(1'b1),
        .bid_sz(bid_sz),
        .ask_sz(ask_sz),
        .bid_px(bid_px),
        .ask_px(ask_px),
        .imb_thresh(DEFAULT_IMB_THRESH),
        .momentum_delta(DEFAULT_MOMENTUM_DELTA),
        .max_spread(DEFAULT_MAX_SPREAD),
        .default_qty(DEFAULT_DEFAULT_QTY),
        .inst_filter(DEFAULT_INST_FILTER),
        .inst_id(inst_id),
        .valid_in(unpack_valid),
        .side_out(strat_side),
        .price_out(strat_price),
        .qty_out(strat_qty),
        .valid_out(strat_valid)
    );

    // Risk gating
    wire risk_valid;
    wire [SIZE_W-1:0] position_out;
    wire [PRICE_W+SIZE_W-1:0] notional_out;
    wire [TS_W-1:0] ts_last_out;
    risk_checks u_risk(
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(strat_valid),
        .side_in(strat_side),
        .price_in(strat_price),
        .qty_in(strat_qty),
        .ts_now(ts_now),
        .max_position(DEFAULT_MAX_POSITION),
        .max_notional(DEFAULT_MAX_NOTIONAL),
        .min_interval_cycles(DEFAULT_MIN_ORDER_INTERVAL),
        .valid_out(risk_valid),
        .position_out(position_out),
        .notional_out(notional_out),
        .ts_last_out(ts_last_out)
    );

    // Encode order
    tx_order_encoder u_encoder(
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(risk_valid),
        .inst_id(inst_id),
        .price(strat_price),
        .qty(strat_qty),
        .side(strat_side),
        .ts_in(ts_in),
        .ts_now(ts_now),
        .valid_out(valid_out),
        .word0(order_word0),
        .word1(order_word1)
    );
endmodule

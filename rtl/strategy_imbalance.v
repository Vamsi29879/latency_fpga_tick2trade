`ifndef STRATEGY_IMBALANCE_V
`define STRATEGY_IMBALANCE_V

`include "defs.vh"

module strategy_imbalance (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [`SIZE_W-1:0] bid_sz,
    input wire [`SIZE_W-1:0] ask_sz,
    input wire [`PRICE_W-1:0] bid_px,
    input wire [`PRICE_W-1:0] ask_px,
    input wire [`INST_ID_W-1:0] inst_id,
    input wire [`SIZE_W-1:0] imb_thresh,
    input wire [`PRICE_W-1:0] max_spread,
    input wire [`PRICE_W-1:0] momentum_delta,
    input wire [`SIZE_W-1:0] default_qty,
    output reg valid,
    output reg side, // 1=buy, 0=sell
    output reg [`PRICE_W-1:0] price_out,
    output reg [`SIZE_W-1:0] qty_out,
    output reg [`INST_ID_W-1:0] inst_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid     <= 0;
            side      <= 0;
            price_out <= 0;
            qty_out   <= 0;
            inst_out  <= 0;
        end else begin
            valid     <= 0;
            if (enable) begin
                inst_out <= inst_id;
                // Check spread
                if ((bid_px >= ask_px) && ((bid_px - ask_px) <= max_spread)) begin
                    if (bid_sz > ask_sz + imb_thresh) begin
                        // Sell condition
                        valid     <= 1;
                        side      <= 0;
                        price_out <= bid_px;
                        qty_out   <= (bid_sz < default_qty) ? bid_sz : default_qty;
                    end else if (ask_sz > bid_sz + imb_thresh) begin
                        // Buy condition
                        valid     <= 1;
                        side      <= 1;
                        price_out <= ask_px;
                        qty_out   <= (ask_sz < default_qty) ? ask_sz : default_qty;
                    end
                end
            end
        end
    end
endmodule

`endif // STRATEGY_IMBALANCE_V

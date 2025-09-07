`include "defs.vh"

module risk_checks(
    input clk,
    input rst_n,
    input valid_in,
    input side_in,
    input [PRICE_W-1:0] price_in,
    input [SIZE_W-1:0] qty_in,
    input [TS_W-1:0] ts_now,
    input [SIZE_W-1:0] max_position,
    input [PRICE_W+SIZE_W-1:0] max_notional,
    input [TS_W-1:0] min_interval_cycles,
    output reg valid_out,
    output reg [SIZE_W-1:0] position_out,
    output reg [PRICE_W+SIZE_W-1:0] notional_out,
    output reg [TS_W-1:0] ts_last_out
);

// Internal state registers for position, notional, and last order timestamp.
reg [SIZE_W-1:0] position;
reg [PRICE_W+SIZE_W-1:0] notional;
reg [TS_W-1:0] ts_last;

// Compute the order value (price * qty).
wire [PRICE_W+SIZE_W-1:0] order_value = price_in * qty_in;

// Compute candidate next position depending on side.
// We treat position as an unsigned quantity for simplicity.
wire [SIZE_W-1:0] position_inc = position + qty_in;
wire [SIZE_W-1:0] position_dec = (position >= qty_in) ? (position - qty_in) : 0;
wire [SIZE_W-1:0] position_new = side_in ? position_inc : position_dec;

// Compute candidate next notional.
// For this example we accumulate absolute order values regardless of side.
wire [PRICE_W+SIZE_W-1:0] notional_new = notional + order_value;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // reset state
        position <= {SIZE_W{1'b0}};
        notional <= {(PRICE_W+SIZE_W){1'b0}};
        ts_last <= {TS_W{1'b0}};
        valid_out <= 1'b0;
        position_out <= {SIZE_W{1'b0}};
        notional_out <= {(PRICE_W+SIZE_W){1'b0}};
        ts_last_out <= {TS_W{1'b0}};
    end else begin
        // Default outputs replicate current state and no order allowed.
        valid_out <= 1'b0;
        position_out <= position;
        notional_out <= notional;
        ts_last_out <= ts_last;

        if (valid_in) begin
            // Check risk limits and minimum spacing between orders.
            if ((position_new <= max_position) &&
                (notional_new <= max_notional) &&
                ((ts_now - ts_last) >= min_interval_cycles)) begin
                // Order passes risk checks; allow it and update state.
                valid_out <= 1'b1;
                position <= position_new;
                notional <= notional_new;
                ts_last <= ts_now;
                position_out <= position_new;
                notional_out <= notional_new;
                ts_last_out <= ts_now;
            end
        end
    end
end

endmodule

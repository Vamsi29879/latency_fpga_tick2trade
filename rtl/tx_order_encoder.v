`include "defs.vh"

module tx_order_encoder(
    input clk,
    input rst_n,
    input valid_in,
    input [INST_ID_W-1:0] inst_id,
    input [PRICE_W-1:0] price,
    input [SIZE_W-1:0] qty,
    input side,
    input [TS_W-1:0] ts_in,
    input [TS_W-1:0] ts_now,
    output reg valid_out,
    output reg [63:0] word0,
    output reg [63:0] word1
);
    // Compute latency between message timestamp and now
    wire [TS_W-1:0] latency_cycles = ts_now - ts_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            word0 <= 64'd0;
            word1 <= 64'd0;
        end else begin
            // Default outputs disabled
            valid_out <= 1'b0;
            if (valid_in) begin
                // Emit packed order frame
                valid_out <= 1'b1;
                // Word0: {qty[15:0], price[31:0], inst_id[15:0]}
                word0 <= {qty, price, inst_id};
                // Word1: {reserved[63:49], latency_cycles[48:1], side[0]}
                word1 <= {15'd0, latency_cycles, side};
            end
        end
    end
endmodule

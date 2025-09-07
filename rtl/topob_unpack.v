`ifndef TOBOB_UNPACK_V
`define TOBOB_UNPACK_V

`include "defs.vh"

module topob_unpack (
    input wire clk,
    input wire rst_n,
    input wire [63:0] word0,
    input wire [63:0] word1,
    input wire [`TS_W-1:0] ts_now,
    output reg [`INST_ID_W-1:0] inst_id,
    output reg [`SIZE_W-1:0]  bid_sz,
    output reg [`PRICE_W-1:0] bid_px,
    output reg [`SIZE_W-1:0]  ask_sz,
    output reg [`PRICE_W-1:0] ask_px,
    output reg [`TS_W-1:0] ts_in
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inst_id <= 0;
            bid_sz  <= 0;
            bid_px  <= 0;
            ask_sz  <= 0;
            ask_px  <= 0;
            ts_in   <= 0;
        end else begin
            inst_id <= word0[15:0];
            bid_px  <= word0[47:16];
            bid_sz  <= word0[63:48];
            ask_px  <= word1[31:0];
            ask_sz  <= word1[47:32];
            ts_in   <= ts_now;
        end
    end
endmodule

`endif // TOBOB_UNPACK_V

`ifndef TDC_TIMESTAMP_V
`define TDC_TIMESTAMP_V

`include "defs.vh"

module tdc_timestamp (
    input wire clk,
    input wire rst_n,
    output reg [`TS_W-1:0] ts
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ts <= 0;
        else
            ts <= ts + 1;
    end
endmodule

`endif // TDC_TIMESTAMP_V

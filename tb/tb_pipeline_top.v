`include "defs.vh"

module tb_pipeline_top;
    reg clk;
    reg rst_n;
    reg valid_in;
    reg [63:0] tob_word0, tob_word1;
    wire valid_out;
    wire [63:0] order_word0, order_word1;

    // Instantiate the design under test
    pipeline_top dut(
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .tob_word0(tob_word0),
        .tob_word1(tob_word1),
        .valid_out(valid_out),
        .order_word0(order_word0),
        .order_word1(order_word1)
    );

    // Clock generation: 100 MHz (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus
    initial begin
        // Reset
        rst_n = 0;
        valid_in = 0;
        tob_word0 = 64'd0;
        tob_word1 = 64'd0;
        #20;
        rst_n = 1;
        #20;

        // Test case 1: positive imbalance, expect BUY
        send_tob(16'h0001, 32'h00010000, 16'd20, 32'h00010010, 16'd5);
        #40;

        // Test case 2: negative imbalance, expect SELL
        send_tob(16'h0001, 32'h00010020, 16'd5, 32'h00010000, 16'd20);
        #40;

        // Test case 3: too wide spread, no trade
        send_tob(16'h0001, 32'h00010000, 16'd15, 32'h00010200, 16'd15);
        #40;

        // Finish simulation
        #100;
        $finish;
    end

    // Task to send a Top-of-Book message
    task send_tob(
        input [INST_ID_W-1:0] inst_id,
        input [PRICE_W-1:0] bid_px,
        input [SIZE_W-1:0] bid_sz,
        input [PRICE_W-1:0] ask_px,
        input [SIZE_W-1:0] ask_sz
    );
        begin
            tob_word0 = {bid_sz, bid_px, inst_id};
            tob_word1 = {16'd0, ask_sz, ask_px};
            valid_in = 1'b1;
            #10;
            valid_in = 1'b0;
            tob_word0 = 64'd0;
            tob_word1 = 64'd0;
        end
    endtask

    // Monitor emitted orders
    always @(posedge clk) begin
        if (valid_out) begin
            $display("ORDER WORD0: %h", order_word0);
            $display("ORDER WORD1: %h", order_word1);
        end
    end
endmodule

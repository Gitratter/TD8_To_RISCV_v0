`timescale 1ns/1ps
`default_nettype none

module tb_v1_board;
    reg clk;
    reg reset;
    reg [7:0] in;
    reg clksel;
    wire [7:0] out;
    wire [3:0] clk_ind;
    wire [6:0] seg;
    wire [3:0] an;
    integer errors;

    TD4_TOP #(.CLOCK_HZ(10)) dut (
        .clk(clk),
        .reset(reset),
        .in(in),
        .clksel(clksel),
        .out(out),
        .clk_ind(clk_ind),
        .seg(seg),
        .an(an)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        in = 8'h05;
        clksel = 1'b1; // fast enable: every clock when CLOCK_HZ=10
        errors = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;
        repeat (14) @(posedge clk);
        #1;

        if (out !== 8'h06) begin
            $display("ERROR: board out=%h expected=06", out);
            errors = errors + 1;
        end
        if (seg !== 7'b0000010) begin
            $display("ERROR: SEG7=%b expected encoding for 6", seg);
            errors = errors + 1;
        end
        if (an !== 4'b1110) begin
            $display("ERROR: an=%b expected=1110", an);
            errors = errors + 1;
        end
        if (clk_ind === 4'd0) begin
            $display("ERROR: clk_ind did not advance");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: tb_v1_board");
        else
            $fatal(1, "FAIL: tb_v1_board errors=%0d", errors);
        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "TIMEOUT: tb_v1_board");
    end
endmodule

`default_nettype wire

// Board-facing top module. Its ports intentionally match the TD8 design so the
// existing switches, LEDs, seven-segment display, and XDC pin assignments remain
// usable during the migration.
module TD8_RAM_TO_RISCV_V1_TOP #(
    parameter integer CLOCK_HZ = 100_000_000
) (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] in,
    input  wire       clksel,
    output wire [7:0] out,
    output reg  [3:0] clk_ind,
    output wire [6:0] seg,
    output wire [3:0] an
);
    wire enable_1hz;
    wire enable_10hz;
    wire enable_cpu;
    wire [31:0] unused_pc;
    wire [31:0] unused_instruction;
    wire [31:0] unused_reg_data;
    wire [31:0] unused_mem_word0;
    wire core_fault;

    ClockEnableV1 #(.DIVISOR(CLOCK_HZ / 1)) enable_slow (
        .clk(clk),
        .reset(reset),
        .enable_pulse(enable_1hz)
    );

    ClockEnableV1 #(.DIVISOR(CLOCK_HZ / 10)) enable_fast (
        .clk(clk),
        .reset(reset),
        .enable_pulse(enable_10hz)
    );

    assign enable_cpu = clksel ? enable_10hz : enable_1hz;
    assign an = 4'b1110;

    TD8_RISCV_V1_Core #(.INIT_DEMO(1)) cpu (
        .clk(clk),
        .reset(reset),
        .cpu_enable(enable_cpu),
        .input_port(in),
        .debug_reg_addr(5'd3),
        .output_port(out),
        .debug_pc(unused_pc),
        .debug_instruction(unused_instruction),
        .debug_reg_data(unused_reg_data),
        .debug_mem_word0(unused_mem_word0),
        .fault(core_fault)
    );

    SEG7V1 seven_segment (
        .data(out[3:0]),
        .seg(seg)
    );

    always @(posedge clk or posedge reset) begin
        if (reset)
            clk_ind <= 4'd0;
        else if (enable_cpu && !core_fault)
            clk_ind <= clk_ind + 4'd1;
    end
endmodule

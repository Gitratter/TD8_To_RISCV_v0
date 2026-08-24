`timescale 1ns/1ps
`default_nettype none

// Synthesizable integration harness used by the Yosys SAT smoke proof.
module yosys_v1_harness (
    input wire clk,
    input wire reset,
    output wire [7:0] output_port,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_mem_word0,
    output wire fault
);
    wire [31:0] debug_instruction;
    wire [31:0] debug_reg_data;

    TD8_RISCV_V1_Core #(.INIT_DEMO(1)) dut (
        .clk(clk),
        .reset(reset),
        .cpu_enable(1'b1),
        .input_port(8'h2A),
        .debug_reg_addr(5'd0),
        .output_port(output_port),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_reg_data(debug_reg_data),
        .debug_mem_word0(debug_mem_word0),
        .fault(fault)
    );

endmodule

`default_nettype wire

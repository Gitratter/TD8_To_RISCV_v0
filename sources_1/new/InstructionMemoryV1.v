`timescale 1ns/1ps
`default_nettype none

// 64-word Harvard instruction ROM. Unused and out-of-range locations read as
// ADDI x0,x0,0 (the canonical RV32I NOP).
module InstructionMemoryV1 #(
    parameter integer INIT_DEMO = 1
) (
    input  wire [31:0] address,
    output wire [31:0] instruction
);
    localparam [31:0] NOP = 32'h0000_0013;

    reg [31:0] memory [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1)
            memory[i] = NOP;

        if (INIT_DEMO != 0) begin
            // TD8-style visible demo, expressed only with the v1 RV32I subset.
            // x1 = IO_IN (0x100), x2 = IO_OUT (0x104)
            memory[0]  = 32'h1000_0093; // addi x1, x0, 0x100
            memory[1]  = 32'h1040_0113; // addi x2, x0, 0x104
            memory[2]  = 32'h0000_A183; // lw   x3, 0(x1)
            memory[3]  = 32'h0011_8193; // addi x3, x3, 1
            memory[4]  = 32'h0FF1_F193; // andi x3, x3, 0xff
            memory[5]  = 32'h0030_2023; // sw   x3, 0(x0)
            memory[6]  = 32'h0000_2203; // lw   x4, 0(x0)
            memory[7]  = 32'h0041_8463; // beq  x3, x4, +8
            memory[8]  = 32'h0EE0_0193; // addi x3, x0, 0xee (failure sentinel)
            memory[9]  = 32'h0031_2023; // sw   x3, 0(x2)
            memory[10] = 32'hFE00_00E3; // beq  x0, x0, -32 (back to lw)
        end
    end

    assign instruction = (address[31:8] == 24'd0)
                       ? memory[address[7:2]]
                       : NOP;
endmodule

`default_nettype wire

`timescale 1ns/1ps
`default_nettype none

module MainDecoderV1 (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg        alu_src,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        branch,
    output reg  [1:0] alu_op,
    output reg        illegal
);
    always @(*) begin
        reg_write = 1'b0;
        alu_src   = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        branch    = 1'b0;
        alu_op    = 2'b00;
        illegal   = 1'b0;

        case (opcode)
            7'b0110011: begin // R type
                reg_write = 1'b1;
                alu_op    = 2'b10;
            end
            7'b0010011: begin // I type arithmetic
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            7'b0000011: begin // LW (funct3 checked in the core)
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00;
            end
            7'b0100011: begin // SW (funct3 checked in the core)
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b00;
            end
            7'b1100011: begin // BEQ (funct3 checked in the core)
                branch = 1'b1;
                alu_op = 2'b01;
            end
            default: illegal = 1'b1;
        endcase
    end
endmodule

`default_nettype wire

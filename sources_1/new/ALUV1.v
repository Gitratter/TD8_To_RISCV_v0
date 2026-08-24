`timescale 1ns/1ps
`default_nettype none

module ALUV1 (
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [3:0]  control,
    output reg  [31:0] result,
    output wire        zero
);
    localparam [3:0] ALU_AND = 4'd0;
    localparam [3:0] ALU_OR  = 4'd1;
    localparam [3:0] ALU_ADD = 4'd2;
    localparam [3:0] ALU_SUB = 4'd3;
    localparam [3:0] ALU_SLT = 4'd4;

    assign zero = (result == 32'd0);

    always @(*) begin
        case (control)
            ALU_AND: result = operand_a & operand_b;
            ALU_OR:  result = operand_a | operand_b;
            ALU_ADD: result = operand_a + operand_b;
            ALU_SUB: result = operand_a - operand_b;
            ALU_SLT: result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
            default: result = 32'd0;
        endcase
    end
endmodule

`default_nettype wire

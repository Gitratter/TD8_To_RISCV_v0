`timescale 1ns/1ps
`default_nettype none

module ALUDecoderV1 (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] alu_control,
    output reg        illegal
);
    localparam [3:0] ALU_AND = 4'd0;
    localparam [3:0] ALU_OR  = 4'd1;
    localparam [3:0] ALU_ADD = 4'd2;
    localparam [3:0] ALU_SUB = 4'd3;
    localparam [3:0] ALU_SLT = 4'd4;

    always @(*) begin
        alu_control = ALU_ADD;
        illegal     = 1'b0;

        case (alu_op)
            2'b00: alu_control = ALU_ADD; // LW/SW address calculation
            2'b01: alu_control = ALU_SUB; // BEQ comparison
            2'b10: begin                  // R type
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000)
                            alu_control = ALU_ADD;
                        else if (funct7 == 7'b0100000)
                            alu_control = ALU_SUB;
                        else
                            illegal = 1'b1;
                    end
                    3'b111: begin
                        alu_control = ALU_AND;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    3'b110: begin
                        alu_control = ALU_OR;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    3'b010: begin
                        alu_control = ALU_SLT;
                        if (funct7 != 7'b0000000) illegal = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end
            2'b11: begin                  // I type arithmetic
                case (funct3)
                    3'b000: alu_control = ALU_ADD; // ADDI
                    3'b111: alu_control = ALU_AND; // ANDI
                    3'b110: alu_control = ALU_OR;  // ORI
                    3'b010: alu_control = ALU_SLT; // SLTI
                    default: illegal = 1'b1;
                endcase
            end
            default: illegal = 1'b1;
        endcase
    end
endmodule

`default_nettype wire

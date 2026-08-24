module ProgramCounterV1 (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 32'd0;
        else if (enable)
            pc <= next_pc;
    end
endmodule


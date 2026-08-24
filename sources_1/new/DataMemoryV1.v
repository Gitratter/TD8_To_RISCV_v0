// TD8-derived 256-byte memory, organized as four 8-bit banks so the RV32I
// subset can perform one aligned 32-bit LW/SW per enabled CPU step.
module DataMemoryV1 (
    input  wire        clk,
    input  wire        enable,
    input  wire        write_enable,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data,
    output wire [31:0] debug_word0
);
    reg [7:0] byte0 [0:63];
    reg [7:0] byte1 [0:63];
    reg [7:0] byte2 [0:63];
    reg [7:0] byte3 [0:63];
    wire [5:0] word_index = address[7:2];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            byte0[i] = 8'd0;
            byte1[i] = 8'd0;
            byte2[i] = 8'd0;
            byte3[i] = 8'd0;
        end
    end

    assign read_data   = {byte3[word_index], byte2[word_index], byte1[word_index], byte0[word_index]};
    assign debug_word0 = {byte3[0], byte2[0], byte1[0], byte0[0]};

    always @(posedge clk) begin
        if (enable && write_enable) begin
            byte0[word_index] <= write_data[7:0];
            byte1[word_index] <= write_data[15:8];
            byte2[word_index] <= write_data[23:16];
            byte3[word_index] <= write_data[31:24];
        end
    end
endmodule

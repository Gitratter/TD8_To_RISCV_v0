module RegisterFileV1 (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire        write_enable,
    input  wire [4:0]  read_addr1,
    input  wire [4:0]  read_addr2,
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data,
    input  wire [4:0]  debug_addr,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2,
    output wire [31:0] debug_data
);
    reg [31:0] registers [0:31];
    integer i;

    assign read_data1 = (read_addr1 == 5'd0) ? 32'd0 : registers[read_addr1];
    assign read_data2 = (read_addr2 == 5'd0) ? 32'd0 : registers[read_addr2];
    assign debug_data = (debug_addr == 5'd0) ? 32'd0 : registers[debug_addr];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end else if (enable && write_enable && (write_addr != 5'd0)) begin
            registers[write_addr] <= write_data;
        end
    end
endmodule

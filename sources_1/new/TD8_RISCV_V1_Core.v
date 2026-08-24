// v1 transition core:
// - TD8-like non-pipelined, one instruction per enable pulse
// - strict RV32I subset: ADD/SUB/AND/OR/SLT, ADDI/ANDI/ORI/SLTI,
//   aligned LW/SW, and BEQ
// - Harvard ROM/RAM and TD8-derived byte-bank data memory
module TD8_RISCV_V1_Core #(
    parameter integer INIT_DEMO = 1
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        cpu_enable,
    input  wire [7:0]  input_port,
    input  wire [4:0]  debug_reg_addr,
    output reg  [7:0]  output_port,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instruction,
    output wire [31:0] debug_reg_data,
    output wire [31:0] debug_mem_word0,
    output wire        fault
);
    localparam [31:0] IO_IN_ADDR  = 32'h0000_0100;
    localparam [31:0] IO_OUT_ADDR = 32'h0000_0104;
    localparam [31:0] IMEM_BYTES  = 32'd256;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire [31:0] immediate;
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] alu_operand_b;
    wire [31:0] alu_result;
    wire [31:0] ram_read_data;
    wire [31:0] load_data;
    wire [31:0] write_back_data;
    wire [31:0] pc_plus_four;
    wire [31:0] branch_target;
    wire [31:0] next_pc;
    wire        alu_zero;

    wire        reg_write;
    wire        alu_src;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire        branch;
    wire [1:0]  alu_op;
    wire [3:0]  alu_control;
    wire        main_illegal;
    wire        alu_illegal;
    wire        format_illegal;
    wire        illegal_instruction;
    wire        memory_fault;
    wire        branch_taken;
    wire        fetch_fault;
    wire        taken_target_fault;

    wire is_ram_address = (alu_result < IO_IN_ADDR);
    wire is_input_address = (alu_result == IO_IN_ADDR);
    wire is_output_address = (alu_result == IO_OUT_ADDR);
    wire aligned_address = (alu_result[1:0] == 2'b00);
    wire valid_load_address = is_ram_address | is_input_address | is_output_address;
    wire valid_store_address = is_ram_address | is_output_address;

    assign format_illegal = (mem_read  && (instruction[14:12] != 3'b010)) ||
                            (mem_write && (instruction[14:12] != 3'b010)) ||
                            (branch    && (instruction[14:12] != 3'b000));
    assign illegal_instruction = main_illegal | alu_illegal | format_illegal;
    assign memory_fault = (mem_read  && (!aligned_address || !valid_load_address)) ||
                          (mem_write && (!aligned_address || !valid_store_address));
    assign pc_plus_four = pc + 32'd4;
    assign branch_target = pc + immediate;
    assign branch_taken = branch && alu_zero && !illegal_instruction;
    assign fetch_fault = (pc[1:0] != 2'b00) || (pc >= IMEM_BYTES);
    assign taken_target_fault = branch_taken &&
                                ((branch_target[1:0] != 2'b00) ||
                                 (branch_target >= IMEM_BYTES));
    assign fault = illegal_instruction | memory_fault |
                   fetch_fault | taken_target_fault;
    assign next_pc = branch_taken ? branch_target : pc_plus_four;

    ProgramCounterV1 pc_register (
        .clk(clk),
        .reset(reset),
        .enable(cpu_enable && !fault),
        .next_pc(next_pc),
        .pc(pc)
    );

    InstructionMemoryV1 #(.INIT_DEMO(INIT_DEMO)) imem (
        .address(pc),
        .instruction(instruction)
    );

    MainDecoderV1 main_decoder (
        .opcode(instruction[6:0]),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .alu_op(alu_op),
        .illegal(main_illegal)
    );

    ALUDecoderV1 alu_decoder (
        .alu_op(alu_op),
        .funct3(instruction[14:12]),
        .funct7(instruction[31:25]),
        .alu_control(alu_control),
        .illegal(alu_illegal)
    );

    ImmGenV1 immediate_generator (
        .instruction(instruction),
        .immediate(immediate)
    );

    RegisterFileV1 register_file (
        .clk(clk),
        .reset(reset),
        .enable(cpu_enable),
        .write_enable(reg_write && !fault),
        .read_addr1(instruction[19:15]),
        .read_addr2(instruction[24:20]),
        .write_addr(instruction[11:7]),
        .write_data(write_back_data),
        .debug_addr(debug_reg_addr),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .debug_data(debug_reg_data)
    );

    assign alu_operand_b = alu_src ? immediate : read_data2;

    ALUV1 alu (
        .operand_a(read_data1),
        .operand_b(alu_operand_b),
        .control(alu_control),
        .result(alu_result),
        .zero(alu_zero)
    );

    DataMemoryV1 data_memory (
        .clk(clk),
        .enable(cpu_enable),
        .write_enable(mem_write && !fault && is_ram_address),
        .address(alu_result),
        .write_data(read_data2),
        .read_data(ram_read_data),
        .debug_word0(debug_mem_word0)
    );

    assign load_data = is_input_address  ? {24'd0, input_port} :
                       is_output_address ? {24'd0, output_port} :
                       is_ram_address    ? ram_read_data :
                                           32'd0;
    assign write_back_data = mem_to_reg ? load_data : alu_result;

    always @(posedge clk or posedge reset) begin
        if (reset)
            output_port <= 8'd0;
        else if (cpu_enable && mem_write && !fault && is_output_address)
            output_port <= read_data2[7:0];
    end

    assign debug_pc          = pc;
    assign debug_instruction = instruction;
endmodule

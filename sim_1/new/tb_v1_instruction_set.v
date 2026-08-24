`timescale 1ns/1ps
`default_nettype none

module tb_v1_instruction_set;
    reg clk;
    reg reset;
    reg cpu_enable;
    reg [4:0] debug_reg_addr;
    wire [7:0] output_port;
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_reg_data;
    wire [31:0] debug_mem_word0;
    wire fault;
    integer errors;
    integer i;

    TD8_RISCV_V1_Core #(.INIT_DEMO(0)) dut (
        .clk(clk),
        .reset(reset),
        .cpu_enable(cpu_enable),
        .input_port(8'd0),
        .debug_reg_addr(debug_reg_addr),
        .output_port(output_port),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_reg_data(debug_reg_data),
        .debug_mem_word0(debug_mem_word0),
        .fault(fault)
    );

    always #5 clk = ~clk;

    task step_cpu;
        begin
            @(negedge clk);
            if (fault !== 1'b0) begin
                $display("ERROR: fault at pc=%h instr=%h", debug_pc, debug_instruction);
                errors = errors + 1;
            end
            cpu_enable = 1'b1;
            @(posedge clk);
            #1;
            cpu_enable = 1'b0;
        end
    endtask

    task check_reg;
        input [4:0] address;
        input [31:0] expected;
        begin
            debug_reg_addr = address;
            #1;
            if (debug_reg_data !== expected) begin
                $display("ERROR: x%0d=%h expected=%h", address, debug_reg_data, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        cpu_enable = 1'b0;
        debug_reg_addr = 5'd0;
        errors = 0;

        // Program covers all 12 v1 instructions, BEQ taken/not-taken, and a
        // negative I-type immediate. Load while reset is still asserted.
        #1;
        dut.imem.memory[0]  = 32'h0050_0093; // addi x1,x0,5
        dut.imem.memory[1]  = 32'h0070_0113; // addi x2,x0,7
        dut.imem.memory[2]  = 32'h0020_81B3; // add  x3,x1,x2
        dut.imem.memory[3]  = 32'h4011_8233; // sub  x4,x3,x1
        dut.imem.memory[4]  = 32'h0041_F2B3; // and  x5,x3,x4
        dut.imem.memory[5]  = 32'h0020_E333; // or   x6,x1,x2
        dut.imem.memory[6]  = 32'h0020_A3B3; // slt  x7,x1,x2
        dut.imem.memory[7]  = 32'h0061_F513; // andi x10,x3,6
        dut.imem.memory[8]  = 32'h0080_E593; // ori  x11,x1,8
        dut.imem.memory[9]  = 32'h0060_A613; // slti x12,x1,6
        dut.imem.memory[10] = 32'hFFF1_2693; // slti x13,x2,-1
        dut.imem.memory[11] = 32'h0030_2023; // sw   x3,0(x0)
        dut.imem.memory[12] = 32'h0000_2403; // lw   x8,0(x0)
        dut.imem.memory[13] = 32'h0034_0463; // beq  x8,x3,+8 (taken)
        dut.imem.memory[14] = 32'h0010_0493; // addi x9,x0,1 (skipped)
        dut.imem.memory[15] = 32'h0020_8463; // beq  x1,x2,+8 (not taken)
        dut.imem.memory[16] = 32'h0020_0493; // addi x9,x0,2
        dut.imem.memory[17] = 32'hFFF0_0713; // addi x14,x0,-1
        dut.imem.memory[18] = 32'h0000_0063; // beq  x0,x0,0

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        for (i = 0; i < 18; i = i + 1)
            step_cpu();

        check_reg(5'd0,  32'd0);
        check_reg(5'd1,  32'd5);
        check_reg(5'd2,  32'd7);
        check_reg(5'd3,  32'd12);
        check_reg(5'd4,  32'd7);
        check_reg(5'd5,  32'd4);
        check_reg(5'd6,  32'd7);
        check_reg(5'd7,  32'd1);
        check_reg(5'd8,  32'd12);
        check_reg(5'd9,  32'd2);
        check_reg(5'd10, 32'd4);
        check_reg(5'd11, 32'd13);
        check_reg(5'd12, 32'd1);
        check_reg(5'd13, 32'd0);
        check_reg(5'd14, 32'hFFFF_FFFF);

        if (debug_mem_word0 !== 32'd12) begin
            $display("ERROR: RAM[0]=%h expected=0000000C", debug_mem_word0);
            errors = errors + 1;
        end
        if (debug_pc !== 32'h0000_0048) begin
            $display("ERROR: final pc=%h expected=00000048", debug_pc);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: tb_v1_instruction_set");
        else
            $fatal(1, "FAIL: tb_v1_instruction_set errors=%0d", errors);
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "TIMEOUT: tb_v1_instruction_set");
    end
endmodule

`default_nettype wire

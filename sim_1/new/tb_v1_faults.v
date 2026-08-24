`timescale 1ns/1ps
`default_nettype none

module tb_v1_faults;
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
    reg [31:0] ram_before;

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

    task reset_core;
        begin
            cpu_enable = 1'b0;
            reset = 1'b1;
            repeat (2) @(posedge clk);
            @(negedge clk);
            reset = 1'b0;
        end
    endtask

    task step_expect_fault;
        input expected_fault;
        begin
            @(negedge clk);
            #1;
            if (fault !== expected_fault) begin
                $display("ERROR: pc=%h instr=%h fault=%b expected=%b",
                         debug_pc, debug_instruction, fault, expected_fault);
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
                $display("ERROR: x%0d=%h expected=%h",
                         address, debug_reg_data, expected);
                errors = errors + 1;
            end
        end
    endtask

    task check_pc;
        input [31:0] expected;
        begin
            if (debug_pc !== expected) begin
                $display("ERROR: pc=%h expected=%h", debug_pc, expected);
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

        #1;

        // Unsupported instruction: PC and registers remain unchanged.
        dut.imem.memory[0] = 32'h0010_0093; // addi x1,x0,1
        dut.imem.memory[1] = 32'h0010_C133; // xor x2,x1,x1
        reset_core;
        step_expect_fault(1'b0);
        step_expect_fault(1'b1);
        step_expect_fault(1'b1);
        check_pc(32'd4);
        check_reg(5'd1, 32'd1);
        check_reg(5'd2, 32'd0);

        // Misaligned LW does not write its destination register.
        dut.imem.memory[0] = 32'h0020_2183; // lw x3,2(x0)
        reset_core;
        step_expect_fault(1'b1);
        step_expect_fault(1'b1);
        check_pc(32'd0);
        check_reg(5'd3, 32'd0);

        // Misaligned SW does not change Data RAM.
        dut.imem.memory[0] = 32'h0010_0093; // addi x1,x0,1
        dut.imem.memory[1] = 32'h0010_2123; // sw x1,2(x0)
        reset_core;
        ram_before = debug_mem_word0;
        step_expect_fault(1'b0);
        step_expect_fault(1'b1);
        step_expect_fault(1'b1);
        check_pc(32'd4);
        if (debug_mem_word0 !== ram_before) begin
            $display("ERROR: misaligned store changed RAM[0]=%h",
                     debug_mem_word0);
            errors = errors + 1;
        end

        // A taken +2 branch is illegal without the compressed extension.
        dut.imem.memory[0] = 32'h0000_0163; // beq x0,x0,+2
        reset_core;
        step_expect_fault(1'b1);
        step_expect_fault(1'b1);
        check_pc(32'd0);

        // The same target encoding is harmless when the branch is not taken.
        dut.imem.memory[0] = 32'h0010_0093; // addi x1,x0,1
        dut.imem.memory[1] = 32'h0000_8163; // beq x1,x0,+2
        dut.imem.memory[2] = 32'h0020_0113; // addi x2,x0,2
        reset_core;
        step_expect_fault(1'b0);
        step_expect_fault(1'b0);
        check_pc(32'd8);
        step_expect_fault(1'b0);
        check_reg(5'd2, 32'd2);

        // A taken branch outside the 64-word instruction ROM must stop.
        dut.imem.memory[0] = 32'h1000_0063; // beq x0,x0,+256
        reset_core;
        step_expect_fault(1'b1);
        step_expect_fault(1'b1);
        check_pc(32'd0);

        // An invalid store cannot overwrite a previously valid I/O value.
        dut.imem.memory[0] = 32'h1040_0093; // addi x1,x0,0x104
        dut.imem.memory[1] = 32'h05A0_0113; // addi x2,x0,0x5a
        dut.imem.memory[2] = 32'h0020_A023; // sw x2,0(x1)
        dut.imem.memory[3] = 32'h0020_A123; // sw x2,2(x1)
        reset_core;
        step_expect_fault(1'b0);
        step_expect_fault(1'b0);
        step_expect_fault(1'b0);
        if (output_port !== 8'h5A) begin
            $display("ERROR: valid I/O store produced %h expected=5a",
                     output_port);
            errors = errors + 1;
        end
        step_expect_fault(1'b1);
        step_expect_fault(1'b1);
        check_pc(32'd12);
        if (output_port !== 8'h5A) begin
            $display("ERROR: faulting I/O store changed output=%h",
                     output_port);
            errors = errors + 1;
        end

        // An unmapped load must not write back.
        dut.imem.memory[0] = 32'h1080_0093; // addi x1,x0,0x108
        dut.imem.memory[1] = 32'h0000_A103; // lw x2,0(x1)
        reset_core;
        step_expect_fault(1'b0);
        step_expect_fault(1'b1);
        step_expect_fault(1'b1);
        check_pc(32'd4);
        check_reg(5'd2, 32'd0);

        // LB has a supported load opcode but an unsupported funct3.
        dut.imem.memory[0] = 32'h0000_0103; // lb x2,0(x0)
        reset_core;
        step_expect_fault(1'b1);
        step_expect_fault(1'b1);
        check_pc(32'd0);
        check_reg(5'd2, 32'd0);

        if (errors == 0)
            $display("PASS: tb_v1_faults");
        else
            $fatal(1, "FAIL: tb_v1_faults errors=%0d", errors);
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "TIMEOUT: tb_v1_faults");
    end
endmodule

`default_nettype wire

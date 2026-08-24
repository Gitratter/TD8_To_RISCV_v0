`timescale 1ns/1ps
`default_nettype none

module tb_v1_io;
    reg clk;
    reg reset;
    reg cpu_enable;
    reg [7:0] input_port;
    reg [4:0] debug_reg_addr;
    wire [7:0] output_port;
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_reg_data;
    wire [31:0] debug_mem_word0;
    wire fault;
    integer errors;
    integer i;

    TD8_RISCV_V1_Core #(.INIT_DEMO(1)) dut (
        .clk(clk),
        .reset(reset),
        .cpu_enable(cpu_enable),
        .input_port(input_port),
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
                $display("ERROR: unexpected fault at pc=%h instr=%h", debug_pc, debug_instruction);
                errors = errors + 1;
            end
            cpu_enable = 1'b1;
            @(posedge clk);
            #1;
            cpu_enable = 1'b0;
            if (debug_pc[1:0] !== 2'b00) begin
                $display("ERROR: PC is not word aligned: %h", debug_pc);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        cpu_enable = 1'b0;
        input_port = 8'h2A;
        debug_reg_addr = 5'd0;
        errors = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // First pass: output must become input+1 after RAM round-trip.
        for (i = 0; i < 9; i = i + 1)
            step_cpu();

        if (output_port !== 8'h2B) begin
            $display("ERROR: output=%h expected=2B", output_port);
            errors = errors + 1;
        end
        if (debug_mem_word0 !== 32'h0000_002B) begin
            $display("ERROR: RAM[0]=%h expected=0000002B", debug_mem_word0);
            errors = errors + 1;
        end

        // Execute the backward branch, then test 8-bit wrap at 0xFF + 1.
        step_cpu();
        if (debug_pc !== 32'h0000_0008) begin
            $display("ERROR: loop target pc=%h expected=00000008", debug_pc);
            errors = errors + 1;
        end

        input_port = 8'hFF;
        for (i = 0; i < 7; i = i + 1)
            step_cpu();

        if (output_port !== 8'h00) begin
            $display("ERROR: wrapped output=%h expected=00", output_port);
            errors = errors + 1;
        end
        if (debug_mem_word0 !== 32'h0000_0000) begin
            $display("ERROR: wrapped RAM[0]=%h expected=00000000", debug_mem_word0);
            errors = errors + 1;
        end

        debug_reg_addr = 5'd0;
        #1;
        if (debug_reg_data !== 32'd0) begin
            $display("ERROR: x0 changed to %h", debug_reg_data);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: tb_v1_io");
        else
            $fatal(1, "FAIL: tb_v1_io errors=%0d", errors);
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "TIMEOUT: tb_v1_io");
    end
endmodule

`default_nettype wire

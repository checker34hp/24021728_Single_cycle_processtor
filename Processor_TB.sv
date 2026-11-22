
`timescale 1ns / 1ps

module Processor_TB;
    logic clk;
    logic reset;
    logic [2:0] stage;
    int err_count;

    Processtor dut (
        .clk(clk),
        .reset(reset)
    );

    // Tạo xung clock chu kỳ 10ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Đánh dấu giai đoạn để dễ quan sát trên Waveform
    always_comb begin
        if (reset)
            stage = 3'd0; // Reset
        else if (dut.pc_value <= 32'h20)
            stage = 3'd1; // 1. Data Processing
        else if (dut.pc_value <= 32'h40)
            stage = 3'd2; // 2. Single Data Transfer
        else if (dut.pc_value <= 32'h5C)
            stage = 3'd3; // 3. Branch
        else
            stage = 3'd4; // 4. Conditional Execution
    end

    task automatic step_cycles(input int n);
        for (int i = 0; i < n; i++) begin
            @(posedge clk);
            #1;
            $display("t=%0t | stage=%0d | PC=0x%02h | instr=0x%08h | cond_pass=%b | NZCV=%b",
                     $time, stage, dut.pc_value, dut.instruction,
                     dut.cond_pass, dut.cpsr_flags);
        end
    endtask

    task automatic check_eq(input string name, input logic [31:0] actual, input logic [31:0] expected);
        if (actual !== expected) begin
            $display("  [FAIL] %s: got 0x%08h, expected 0x%08h", name, actual, expected);
            err_count++;
        end
        else begin
            $display("  [PASS] %s = 0x%08h", name, actual);
        end
    endtask

    initial begin
        err_count = 0;
        reset = 1'b1;

        // Giữ reset qua 1 cạnh lên của clock, nhả reset ở cạnh xuống
        @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // ------------------------------------------------------------
        // 1. Kiểm tra Data Processing (9 chu kỳ: 0x00 -> 0x20)
        // ------------------------------------------------------------
        $display("\n=== [1] DATA PROCESSING ===");
        step_cycles(9);
        check_eq("PC after DP",        dut.pc_value,                    32'h00000024);
        check_eq("R0 (MOV #10)",       dut.u_regfile.registerfile[0],   32'd10);
        check_eq("R1 (MOV #3)",        dut.u_regfile.registerfile[1],   32'd3);
        check_eq("R2 (ADD)",           dut.u_regfile.registerfile[2],   32'd13);
        check_eq("R3 (SUB)",           dut.u_regfile.registerfile[3],   32'd7);
        check_eq("R4 (ADD LSL #1)",    dut.u_regfile.registerfile[4],   32'd16);
        check_eq("R5 (AND)",           dut.u_regfile.registerfile[5],   32'd2);
        check_eq("R6 (ORR)",           dut.u_regfile.registerfile[6],   32'd11);
        check_eq("R7 (BIC)",           dut.u_regfile.registerfile[7],   32'd8);
        check_eq("R8 (MOV rot imm)",   dut.u_regfile.registerfile[8],   32'h00001200);

        // ------------------------------------------------------------
        // 2. Kiểm tra Single Data Transfer (8 chu kỳ: 0x24 -> 0x40)
        // ------------------------------------------------------------
        $display("\n=== [2] SINGLE DATA TRANSFER ===");
        step_cycles(8);
        check_eq("PC after MEM",       dut.pc_value,                    32'h00000044);
        check_eq("Mem[0x0C] (STR -4)", dut.u_dmem.memory[3],            32'd13);
        check_eq("Mem[0x10] (STR/B)",  dut.u_dmem.memory[4],            32'h00AB1200);
        check_eq("R9  (LDR)",          dut.u_regfile.registerfile[9],   32'h00001200);
        check_eq("R11 (LDRB)",         dut.u_regfile.registerfile[11],  32'h000000AB);
        check_eq("R12 (LDR reg off)",  dut.u_regfile.registerfile[12],  32'd13);
        check_eq("R13 (LDR updated)",  dut.u_regfile.registerfile[13],  32'h00AB1200);

        // ------------------------------------------------------------
        // 3. Kiểm tra Branch (5 chu kỳ: 0x44 -> 0x4C -> 0x58 -> 0x5C -> 0x50)
        // ------------------------------------------------------------
        $display("\n=== [3] BRANCH (B / BL) ===");
        step_cycles(5);
        check_eq("PC after Branch",    dut.pc_value,                    32'h00000060);
        check_eq("R14/LR (BL ret)",    dut.u_regfile.registerfile[14],  32'h00000050);
        check_eq("R2 (subroutine)",    dut.u_regfile.registerfile[2],   32'd14);

        // ------------------------------------------------------------
        // 4. Kiểm tra Conditional Execution (7 chu kỳ: 0x60 -> 0x78)
        // ------------------------------------------------------------
        $display("\n=== [4] CONDITIONAL EXECUTION ===");
        step_cycles(7);
        check_eq("PC after Cond",      dut.pc_value,                    32'h0000007C);
        check_eq("R2 (EQ skip, GT ok)",dut.u_regfile.registerfile[2],   32'd20);
        check_eq("R3 (SUBS -7)",       dut.u_regfile.registerfile[3],   32'hFFFFFFF9);
        check_eq("R5 (MI ok)",         dut.u_regfile.registerfile[5],   32'h00000055);
        check_eq("R6 (CS skip)",       dut.u_regfile.registerfile[6],   32'd11);
        check_eq("CPSR NZCV",          {28'b0, dut.cpsr_flags},         32'h00000008);

        // Chạy thêm 2 chu kỳ để xác nhận vòng lặp dừng tại 0x7C
        step_cycles(2);
        check_eq("PC halted at 0x7C",  dut.pc_value,                    32'h0000007C);

        $display("\n========================================");
        if (err_count == 0)
            $display("ALL TESTS PASSED (0 errors)");
        else
            $display("TEST FAILED (%0d errors)", err_count);
        $display("========================================");
        $finish;
    end
endmodule
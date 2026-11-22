`timescale 1ns / 1ps

module Processtor(
    input logic clk,
    input logic reset
);
    logic [31:0] pc_value, pc_plus4, pc_plus8;
    logic [31:0] branch_offset, branch_target;
    logic [31:0] pc_after_branch, next_pc;
    logic [31:0] pc_write_data;

    logic [31:0] instruction;
    logic [31:0] rdata1, rdata2, rdata3;
    logic [31:0] alu_A, alu_B, alu_result;
    logic [31:0] dp_imm, mem_offset;
    logic [31:0] shifted_operand, mem_rdata, wdata;
    logic [31:0] cpsr_value;

    logic [3:0] alu_op, cond, cpsr_flags, alu_flags;
    logic [2:0] mask;
    logic [1:0] wb_sel;

    logic reg_wr, rd_en, wr_en;
    logic sel_A, sel_B;
    logic branch, br_taken;
    logic flag_wr, operand2_imm, offset_reg;
    logic link, valid, cond_pass;
    logic pc_write_en;

    logic flag_N, flag_Z, flag_C, flag_V;
    logic dp_imm_carry, shifter_carry_out, alu_shifter_carry;
    logic is_memory;
    logic [3:0] rf_waddr;

    assign pc_plus8 = pc_value + 32'd8;
    assign branch_target = pc_plus8 + branch_offset;
    assign is_memory = (instruction[27:26] == 2'b01);
    assign rf_waddr = link ? 4'd14 : instruction[15:12];
    assign alu_flags = {flag_N, flag_Z, flag_C, flag_V};

    assign alu_shifter_carry =
        (is_memory || !operand2_imm) ? shifter_carry_out : dp_imm_carry;

    PC u_pc(
        .clk(clk), .reset(reset), .B(next_pc), .A(pc_value)
    );

    Add4 u_add4(
        .A(pc_value), .B(pc_plus4)
    );

    Mux2 u_branch_mux(
        .A(pc_plus4), .B(branch_target),
        .sel(br_taken), .C(pc_after_branch)
    );

    Mux2 u_pc_write_mux(
        .A(pc_after_branch), .B(pc_write_data),
        .sel(pc_write_en), .C(next_pc)
    );

    InstructionMemory u_imem(
        .addr(pc_value), .instruction(instruction)
    );

    RegisterFile u_regfile(
        .clk(clk), .reset(reset), .reg_wr(reg_wr),
        .raddr1(instruction[19:16]),
        .raddr2(instruction[3:0]),
        .raddr3(instruction[15:12]),
        .waddr(rf_waddr), .wdata(wdata),
        .pc_read_value(pc_plus8),
        .rdata1(rdata1), .rdata2(rdata2), .rdata3(rdata3),
        .pc_write_en(pc_write_en), .pc_write_data(pc_write_data)
    );

    ImmediateGenerator u_immgen(
        .instruction(instruction),
        .carry_in(cpsr_flags[1]),
        .dp_imm(dp_imm),
        .dp_imm_carry(dp_imm_carry),
        .mem_offset(mem_offset),
        .branch_offset(branch_offset)
    );

    BarrelShifter u_shifter(
        .instruction(instruction),
        .rm_value(rdata2),
        .carry_in(cpsr_flags[1]),
        .shifted_operand(shifted_operand),
        .shifter_carry_out(shifter_carry_out)
    );

    Mux2 u_alu_a_mux(
        .A(pc_plus8), .B(rdata1),
        .sel(sel_A), .C(alu_A)
    );

    always_comb begin
        if (is_memory) begin
            if (offset_reg)
                alu_B = shifted_operand;
            else
                alu_B = mem_offset;
        end
        else if (operand2_imm) begin
            alu_B = dp_imm;
        end
        else begin
            alu_B = shifted_operand;
        end
    end

    BranchCondition u_branch_condition(
        .instruction(instruction),
        .cpsr_flags(cpsr_flags),
        .cond_pass(cond_pass),
        .br_taken(br_taken)
    );

    Controller u_controller(
        .instruction(instruction), .cond_pass(cond_pass),
        .alu_op(alu_op), .mask(mask), .cond(cond),
        .reg_wr(reg_wr), .sel_A(sel_A), .sel_B(sel_B),
        .rd_en(rd_en), .wr_en(wr_en), .wb_sel(wb_sel),
        .branch(branch), .flag_wr(flag_wr),
        .operand2_imm(operand2_imm), .offset_reg(offset_reg),
        .link(link), .valid(valid)
    );

    ALU u_alu(
        .A(alu_A), .B(alu_B), .alu_op(alu_op),
        .carry_in(cpsr_flags[1]),
        .shifter_carry(alu_shifter_carry),
        .old_V(cpsr_flags[0]),
        .C(alu_result),
        .flag_N(flag_N), .flag_Z(flag_Z),
        .flag_C(flag_C), .flag_V(flag_V)
    );

    CPSR u_cpsr(
        .clk(clk), .reset(reset),
        .flags_we(flag_wr), .flags_in(alu_flags),
        .cpsr_flags(cpsr_flags), .cpsr_value(cpsr_value)
    );

    DataMemory u_dmem(
        .addr(alu_result), .wdata(rdata3), .mask(mask),
        .wr_en(wr_en && !reset), .rd_en(rd_en && !reset), .clk(clk),
        .rdata(mem_rdata)
    );

    WriteBack u_writeback(
        .alu_result(alu_result),
        .mem_rdata(mem_rdata),
        .link_addr(pc_plus4),
        .wb_sel(wb_sel),
        .wdata(wdata)
    );
endmodule



module Controller(
    input logic [31:0] instruction,
    input logic cond_pass,
    output logic [3:0] alu_op,
    output logic [2:0] mask,
    output logic [3:0] cond,
    output logic reg_wr,
    output logic sel_A, sel_B,
    output logic rd_en, wr_en,
    output logic [1:0] wb_sel,
    output logic branch,
    output logic flag_wr,
    output logic operand2_imm,
    output logic offset_reg,
    output logic link,
    output logic valid
);
    logic [3:0] opcode;
    logic is_dp_imm, is_dp_reg, is_dp;
    logic is_test, uses_rn;

    always_comb begin
        cond = instruction[31:28];
        opcode = instruction[24:21];

        is_dp_imm = (instruction[27:25] == 3'b001);
        is_dp_reg = (instruction[27:25] == 3'b000) &&  (instruction[4] == 1'b0);
        is_dp = is_dp_imm || is_dp_reg;

        is_test = (opcode == 4'h8) || (opcode == 4'h9) ||
                  (opcode == 4'hA) || (opcode == 4'hB);
        uses_rn = (opcode != 4'hD) && (opcode != 4'hF);

        alu_op = 4'b0000;
        mask = 3'b010;
        reg_wr = 1'b0;
        sel_A = 1'b0;
        sel_B = 1'b0;
        rd_en = 1'b0;
        wr_en = 1'b0;
        wb_sel = 2'b00;
        branch = 1'b0;
        flag_wr = 1'b0;
        operand2_imm = 1'b0;
        offset_reg = 1'b0;
        link = 1'b0;
        valid = 1'b0;

        if (is_dp) begin
            if (is_test) begin
                if (instruction[20] && instruction[15:12] == 4'd0) begin
                    valid = 1'b1;
                    alu_op = opcode;
                    sel_A = 1'b1;
                    sel_B = 1'b1;
                    operand2_imm = instruction[25];
                    flag_wr = 1'b1;
                end
            end
            else if (instruction[15:12] != 4'd15 &&
                     (!uses_rn || instruction[19:16] != 4'd15)) begin
                valid = 1'b1;
                alu_op = opcode;
                reg_wr = 1'b1;
                sel_A = 1'b1;
                sel_B = 1'b1;
                operand2_imm = instruction[25];
                flag_wr = instruction[20];
                wb_sel = 2'b00;
            end
        end
        else if (instruction[27:26] == 2'b01) begin
            if (instruction[24] && !instruction[21] &&
                instruction[15:12] != 4'd15 &&
                (!instruction[25] || !instruction[4])) begin
                valid = 1'b1;
                sel_A = 1'b1;
                sel_B = 1'b1;
                alu_op = instruction[23] ? 4'h4 : 4'h2;
                offset_reg = instruction[25];
                mask = instruction[22] ? 3'b000 : 3'b010;

                if (instruction[20]) begin
                    rd_en = 1'b1;
                    reg_wr = 1'b1;
                    wb_sel = 2'b01;
                end
                else begin
                    wr_en = 1'b1;
                end
            end
        end
        else if (instruction[27:25] == 3'b101) begin
            valid = 1'b1;
            branch = 1'b1;
            if (instruction[24]) begin
                link = 1'b1;
                reg_wr = 1'b1;
                wb_sel = 2'b10;
            end
        end

        if (!valid || !cond_pass) begin
            reg_wr = 1'b0;
            rd_en = 1'b0;
            wr_en = 1'b0;
            flag_wr = 1'b0;
            link = 1'b0;
        end

        if (!cond_pass)
            branch = 1'b0;
    end
endmodule

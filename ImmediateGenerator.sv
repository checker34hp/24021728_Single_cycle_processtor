	
module ImmediateGenerator(
    input logic [31:0] instruction,
    input logic carry_in,
    output logic [31:0] dp_imm,
    output logic dp_imm_carry,
    output logic [31:0] mem_offset,
    output logic [31:0] branch_offset
);
    logic [31:0] imm_value;
    integer rotate_amount;

    always_comb begin
        dp_imm = 32'b0;
        dp_imm_carry = carry_in;
        mem_offset = 32'b0;
        branch_offset = 32'b0;

        imm_value = {24'b0, instruction[7:0]};
        rotate_amount = 2 * instruction[11:8];

        if (instruction[27:25] == 3'b001) begin
            if (rotate_amount == 0) begin
                dp_imm = imm_value;
                dp_imm_carry = carry_in;
            end
            else begin
                dp_imm = (imm_value >> rotate_amount) |
                         (imm_value << (32 - rotate_amount));
                dp_imm_carry = dp_imm[31];
            end
        end

        if (instruction[27:26] == 2'b01 && instruction[25] == 1'b0)
            mem_offset = {20'b0, instruction[11:0]};

        if (instruction[27:25] == 3'b101)
            branch_offset = {{6{instruction[23]}}, instruction[23:0], 2'b00};
    end
endmodule

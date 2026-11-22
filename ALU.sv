
module ALU(
    input logic [31:0] A, B,
    input logic [3:0] alu_op,
    input logic carry_in,
    input logic shifter_carry,
    input logic old_V,
    output logic [31:0] C,
    output logic flag_N, flag_Z, flag_C, flag_V
);
    logic [31:0] operand_A, operand_B;
    logic [32:0] extended_result;
    logic arithmetic_cin;
    logic is_sub;
    logic do_arithmetic;

    always_comb begin
        C = 32'b0;
        operand_A = A;
        operand_B = B;
        extended_result = 33'b0;
        arithmetic_cin = 1'b0;
        is_sub = 1'b0;
        do_arithmetic = 1'b0;

        flag_C = shifter_carry;
        flag_V = old_V;

        case (alu_op)
            4'h0: C = A & B;
            4'h1: C = A ^ B;

            4'h2: begin
                arithmetic_cin = 1'b1;
                is_sub = 1'b1;
                do_arithmetic = 1'b1;
            end

            4'h3: begin
                operand_A = B;
                operand_B = A;
                arithmetic_cin = 1'b1;
                is_sub = 1'b1;
                do_arithmetic = 1'b1;
            end

            4'h4: begin
                do_arithmetic = 1'b1;
            end

            4'h5: begin
                arithmetic_cin = carry_in;
                do_arithmetic = 1'b1;
            end

            4'h6: begin
                arithmetic_cin = carry_in;
                is_sub = 1'b1;
                do_arithmetic = 1'b1;
            end

            4'h7: begin
                operand_A = B;
                operand_B = A;
                arithmetic_cin = carry_in;
                is_sub = 1'b1;
                do_arithmetic = 1'b1;
            end

            4'h8: C = A & B;
            4'h9: C = A ^ B;

            4'hA: begin
                arithmetic_cin = 1'b1;
                is_sub = 1'b1;
                do_arithmetic = 1'b1;
            end

            4'hB: begin
                do_arithmetic = 1'b1;
            end

            4'hC: C = A | B;
            4'hD: C = B;
            4'hE: C = A & ~B;
            4'hF: C = ~B;
            default: C = 32'b0;
        endcase

        if (do_arithmetic) begin
            if (is_sub)
                extended_result = {1'b0, operand_A} + {1'b0, ~operand_B} + arithmetic_cin;
            else
                extended_result = {1'b0, operand_A} + {1'b0, operand_B} + arithmetic_cin;

            C = extended_result[31:0];
            flag_C = extended_result[32];

            if (is_sub)
                flag_V = (operand_A[31] ^ operand_B[31]) &
                         (C[31] ^ operand_A[31]);
            else
                flag_V = ~(operand_A[31] ^ operand_B[31]) &
                         (C[31] ^ operand_A[31]);
        end

        flag_N = C[31];
        flag_Z = (C == 32'b0);
    end
endmodule

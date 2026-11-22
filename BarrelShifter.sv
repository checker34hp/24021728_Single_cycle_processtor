
module BarrelShifter(
    input logic [31:0] instruction,
    input logic [31:0] rm_value,
    input logic carry_in,
    output logic [31:0] shifted_operand,
    output logic shifter_carry_out
);
    logic [1:0] shift_type;
    integer amount;
    integer rotate_amount;

    always_comb begin
        shifted_operand = rm_value;
        shifter_carry_out = carry_in;
        shift_type = instruction[6:5];
        amount = instruction[11:7];
        rotate_amount = 0;

        case (shift_type)
            2'b00: begin
                if (amount == 0) begin
                    shifted_operand = rm_value;
                    shifter_carry_out = carry_in;
                end
                else begin
                    shifted_operand = rm_value << amount;
                    shifter_carry_out = rm_value[32-amount];
                end
            end

            2'b01: begin
                if (amount == 0) begin
                    shifted_operand = 32'b0;
                    shifter_carry_out = rm_value[31];
                end
                else begin
                    shifted_operand = rm_value >> amount;
                    shifter_carry_out = rm_value[amount-1];
                end
            end

            2'b10: begin
                if (amount == 0) begin
                    shifted_operand = {32{rm_value[31]}};
                    shifter_carry_out = rm_value[31];
                end
                else begin
                    shifted_operand = $signed(rm_value) >>> amount;
                    shifter_carry_out = rm_value[amount-1];
                end
            end

            2'b11: begin
                if (amount == 0) begin
                    shifted_operand = {carry_in, rm_value[31:1]};
                    shifter_carry_out = rm_value[0];
                end
                else begin
                    rotate_amount = amount;
                    shifted_operand = (rm_value >> rotate_amount) |
                                      (rm_value << (32-rotate_amount));
                    shifter_carry_out = shifted_operand[31];
                end
            end

            default: begin
                shifted_operand = rm_value;
                shifter_carry_out = carry_in;
            end
        endcase
    end
endmodule

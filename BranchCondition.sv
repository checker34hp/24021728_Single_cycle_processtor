
module BranchCondition(
    input logic [31:0] instruction,
    input logic [3:0] cpsr_flags,
    output logic cond_pass,
    output logic br_taken
);
    logic N, Z, C, V;
    logic is_branch;

    assign {N, Z, C, V} = cpsr_flags;
    assign is_branch = (instruction[27:25] == 3'b101);

    always_comb begin
        case (instruction[31:28])
            4'b0000: cond_pass = Z;
            4'b0001: cond_pass = ~Z;
            4'b0010: cond_pass = C;
            4'b0011: cond_pass = ~C;
            4'b0100: cond_pass = N;
            4'b0101: cond_pass = ~N;
            4'b0110: cond_pass = V;
            4'b0111: cond_pass = ~V;
            4'b1000: cond_pass = C & ~Z;
            4'b1001: cond_pass = ~C | Z;
            4'b1010: cond_pass = (N == V);
            4'b1011: cond_pass = (N != V);
            4'b1100: cond_pass = ~Z & (N == V);
            4'b1101: cond_pass = Z | (N != V);
            4'b1110: cond_pass = 1'b1;
            default: cond_pass = 1'b0;
        endcase
    end

    assign br_taken = is_branch && cond_pass;
endmodule

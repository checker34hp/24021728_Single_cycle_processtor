
module CPSR #(
    parameter logic [31:0] RESET_VALUE = 32'h00000010
)(
    input logic clk, reset,
    input logic flags_we,
    input logic [3:0] flags_in,
    output logic [3:0] cpsr_flags,
    output logic [31:0] cpsr_value
);
    logic [31:0] cpsr_reg;

    always_ff @(posedge clk) begin
        if (reset)
            cpsr_reg <= RESET_VALUE;
        else if (flags_we)
            cpsr_reg[31:28] <= flags_in;
    end

    assign cpsr_flags = cpsr_reg[31:28];
    assign cpsr_value = cpsr_reg;
endmodule

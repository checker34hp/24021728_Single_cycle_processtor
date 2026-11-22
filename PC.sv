module PC(
    input logic clk,
    input logic reset,
    input logic [31:0] B,
    output logic [31:0] A
);
    always_ff @(posedge clk) begin
        if (reset)
            A <= 32'b0;
        else
            A <= B;
    end
endmodule

module Add4(
    input logic [31:0] A,
    output logic [31:0] B
);
    assign B = A + 32'd4;
endmodule

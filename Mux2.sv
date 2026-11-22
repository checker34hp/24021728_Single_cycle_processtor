module Mux2(
    input logic [31:0] A, B,
    input logic sel,
    output logic [31:0] C
);
    assign C = sel ? B : A;
endmodule

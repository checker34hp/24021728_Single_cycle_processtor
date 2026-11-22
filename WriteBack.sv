
module WriteBack(
    input logic [31:0] alu_result,
    input logic [31:0] mem_rdata,
    input logic [31:0] link_addr,
    input logic [1:0] wb_sel,
    output logic [31:0] wdata
);
    always_comb begin
        case (wb_sel)
            2'b00: wdata = alu_result;
            2'b01: wdata = mem_rdata;
            2'b10: wdata = link_addr;
            default: wdata = 32'b0;
        endcase
    end
endmodule

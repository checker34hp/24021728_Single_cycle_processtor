

module RegisterFile(
    input logic clk, reset, reg_wr,
    input logic [3:0] raddr1, raddr2, raddr3, waddr,
    input logic [31:0] wdata,
    input logic [31:0] pc_read_value,
    output logic [31:0] rdata1, rdata2, rdata3,
    output logic pc_write_en,
    output logic [31:0] pc_write_data
);
    logic [31:0] registerfile [0:14];
    integer i;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 15; i = i + 1)
                registerfile[i] <= 32'b0;
        end
        else if (reg_wr && waddr != 4'd15) begin
            registerfile[waddr] <= wdata;
        end
    end

    always_comb begin
        rdata1 = (raddr1 == 4'd15) ? pc_read_value : registerfile[raddr1];
        rdata2 = (raddr2 == 4'd15) ? pc_read_value : registerfile[raddr2];
        rdata3 = (raddr3 == 4'd15) ? pc_read_value : registerfile[raddr3];

        pc_write_en = !reset && reg_wr && (waddr == 4'd15);
        pc_write_data = pc_write_en ? wdata : 32'b0;
    end
endmodule

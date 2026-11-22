
module DataMemory(
    input logic [31:0] addr, wdata,
    input logic [2:0] mask,
    input logic wr_en, rd_en, clk,
    output logic [31:0] rdata
);
    logic [31:0] memory [0:255];
    logic [31:0] read_word;
    logic [7:0] read_byte;
    logic [15:0] read_half;
    logic addr_valid;

    assign addr_valid = (addr[31:10] == 22'b0);

    always_comb begin
        read_word = 32'b0;
        read_byte = 8'b0;
        read_half = 16'b0;
        rdata = 32'b0;

        if (rd_en && addr_valid) begin
            read_word = memory[addr[9:2]];
            read_byte = read_word[8*addr[1:0] +: 8];
            read_half = addr[1] ? read_word[31:16] : read_word[15:0];

            case (mask)
                3'b000: rdata = {24'b0, read_byte};
                3'b001: if (!addr[0]) rdata = {16'b0, read_half};
                3'b010: if (addr[1:0] == 2'b00) rdata = read_word;
                3'b100: rdata = {{24{read_byte[7]}}, read_byte};
                3'b101: if (!addr[0]) rdata = {{16{read_half[15]}}, read_half};
                default: rdata = 32'b0;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (wr_en && addr_valid) begin
            case (mask)
                3'b000: memory[addr[9:2]][8*addr[1:0] +: 8] <= wdata[7:0];
                3'b001: begin
                    if (!addr[0]) begin
                        if (addr[1])
                            memory[addr[9:2]][31:16] <= wdata[15:0];
                        else
                            memory[addr[9:2]][15:0] <= wdata[15:0];
                    end
                end
                3'b010: begin
                    if (addr[1:0] == 2'b00)
                        memory[addr[9:2]] <= wdata;
                end
                default: begin
                end
            endcase
        end
    end
endmodule

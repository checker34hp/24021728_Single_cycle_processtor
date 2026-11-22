module InstructionMemory #(
    parameter int WORDS = 32,
    parameter MEM_FILE = "code.mem"
)(
    input logic [31:0] addr,
    output logic [31:0] instruction
);
    logic [31:0] instruction_memory [0:WORDS-1];

    initial begin
        $readmemh(MEM_FILE, instruction_memory);
    end

    always_comb begin
        instruction = 32'b0;
        if (addr[1:0] == 2'b00 && addr[31:7] == '0 &&
            addr[6:2] < WORDS)
            instruction = instruction_memory[addr[6:2]];
    end
endmodule

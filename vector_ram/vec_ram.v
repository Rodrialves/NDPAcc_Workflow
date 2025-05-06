`include "constants.vh"

module vec_ram (
    input                        clk_i,
    input                        en_i,
    input       [`BE_STRB_W-1 :0] we_i,   // 8-bit write enable (1 bit per byte)
    input       [`BE_ADDR_W-1 :0] addr_i, // 24-bit address, only lower 15 bits used
    input       [`BE_DATA_W-1 :0] d_i,    // 64-bit input data (8 bytes)
    output reg  [`BE_DATA_W-1 :0] d_o     // 64-bit output data (8 bytes)
);

    // Memory: 32768 bytes total
    reg [`BE_STRB_W-1 :0] mem [0:32767]; 

    wire [14:0] byte_addr = addr_i[14:0]; // Use lower 15 bits for addressing

    integer i;

    always @(posedge clk_i) begin
        if (en_i) begin
            // Write operation
            for (i = 0; i < 8; i = i + 1) begin
                if (we_i[7 - i]) 
                    mem[byte_addr + i] <= d_i[((8-i)*8-1) -: 8];
            end
            // Read operation
            d_o <= {mem[byte_addr+0], mem[byte_addr+1], mem[byte_addr+2], mem[byte_addr+3],
                    mem[byte_addr+4], mem[byte_addr+5], mem[byte_addr+6], mem[byte_addr+7]};
        end
    end

endmodule


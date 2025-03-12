module vec_ram (
    input  clk_i,
    input  en_i,
    input  [31:0] we_i,    // 32-bit write enable (1 bit per byte)
    input  [23:0] addr_i,   // 1024 locations (2^10 = 1024)
    input  [255:0] d_i,    // 256-bit input data
    output reg [255:0] d_o // 256-bit output data
);

    // 256-bit wide, 1024-depth memory (32 KB total)
    reg [255:0] mem [1023:0]; 

    integer i;

    always @(posedge clk_i) begin
        if (en_i) begin
            // Write operation (if any bit in we_i is high)
            for (i = 0; i < 32; i = i + 1) begin
                if (we_i[i]) 
                    mem[addr_i][(i*8) +: 8] <= d_i[(i*8) +: 8]; // Byte-wise write
            end

            // Read operation
            d_o <= mem[addr_i];
        end
    end

endmodule


`timescale 1ns/1ps

module tb_native_ram;

    // Parameters
    reg clk_i;
    reg en_i;
    reg [31:0] we_i;     // 32-bit write enable
    reg [23:0] addr_i;    // 10-bit address (1024 locations)
    reg [255:0] d_i;     // 256-bit input data
    wire [255:0] d_o;    // 256-bit output data

    // Instantiate RAM
    vec_ram uut (
        .clk_i(clk_i),
        .en_i(en_i),
        .we_i(we_i),
        .addr_i(addr_i),
        .d_i(d_i),
        .d_o(d_o)
    );

    // Clock generation
    always #5 clk_i = ~clk_i; // 10ns clock period (100MHz)

    // Test procedure
    initial begin
        // Initialize signals
        clk_i = 0;
        en_i  = 0;
        we_i  = 0;
        addr_i = 0;
        d_i = 0;

        #10; // Wait some cycles

        // Enable memory operations
        en_i = 1;

        // Test Case 1: Full-word write
        addr_i = 24'h000001;  // Write to address 1
        d_i = 256'hDEADBEEFCAFEBABE112233445566778899AABBCCDDEEFF0011223344556677;
        we_i = 32'hFFFFFFFF; // Enable all 32 bytes
        #10;

        // Test Case 2: Read back full-word
        we_i = 32'h00000000; // Disable writing
        #10;
        $display("Read Full Word: %h", d_o);
        if (d_o !== 256'hDEADBEEFCAFEBABE112233445566778899AABBCCDDEEFF0011223344556677)
            $display("ERROR: Full word read mismatch!");

        // Test Case 3: Partial write (Modify only lower 8 bytes)
        addr_i = 24'h000002;  // Write to address 2
        d_i = 256'h00000000000000000000000000000000_0000000000000000_1122334455667788;
        we_i = 32'h000000FF; // Enable only lower 8 bytes
        #10;

        // Read back and verify
        we_i = 32'h00000000; // Disable writing
        #10;
        $display("Read Partial Word: %h", d_o);
        if (d_o[63:0] !== 64'h1122334455667788)
            $display("ERROR: Partial write mismatch!");

        // Test Case 4: Another full-word write
        addr_i = 24'h000003;
        d_i = 256'hAABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899;
        we_i = 32'hFFFFFFFF; // Full-word write
        #10;

        // Read back
        we_i = 32'h00000000;
        #10;
        $display("Read Full Word 2: %h", d_o);
        if (d_o !== 256'hAABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899)
            $display("ERROR: Full word read mismatch!");

        $display("Test completed successfully.");
        $stop;
    end

endmodule


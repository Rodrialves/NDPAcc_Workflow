`timescale 1ns/1ps

`include "constants.vh"

module tb_native_ram;

    // Signals
    reg clk_i;
    reg en_i;
    reg [`BE_STRB_W-1 :0] we_i;     // 8-bit write enable
    reg [`BE_ADDR_W-1 :0] addr_i;  // 24-bit address
    reg [`BE_DATA_W-1 :0] d_i;     // 64-bit input data
    wire [`BE_DATA_W-1 :0] d_o;    // 64-bit output data

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
        $dumpfile("wave_ram.vcd"); // Set the VCD file name
        $dumpvars(0, tb_native_ram); // Dump all signals in the testbench

        // Initialize signals
        clk_i = 0;
        en_i  = 0;
        we_i  = 0;
        addr_i = 0;
        d_i = 0;

        #10; // Wait some cycles

        // Enable memory operations
        en_i = 1;

        // Test Case 1: Full-word write to address 0
        addr_i = 24'h000000;
        d_i = 64'h1122334455667788;
        we_i = 8'hFF; // Enable all 8 bytes
        #10;
        we_i = 8'h00;
        #10;
        $display("Read from addr 0: %h", d_o);
        if (d_o !== 64'h1122334455667788)
            $display("ERROR: Full word read mismatch at addr 0");

        // Test Case 2: Partial write to address 4
        addr_i = 24'h000004;
        d_i = 64'hAABBCCDDEEFF0011;
        we_i = 8'h0F; // Enable lower 4 bytes
        #10;
        we_i = 8'h00;
        #10;
        $display("Read from addr 4: %h", d_o);
        if (d_o[31:0] !== 32'hEEFF0011)
            $display("ERROR: Partial write mismatch at addr 4");

        // Test Case 3: Full-word write to address 8
        addr_i = 24'h000008;
        d_i = 64'h2233445566778899;
        we_i = 8'hFF;
        #10;
        we_i = 8'h00;
        #10;
        $display("Read from addr 8: %h", d_o);
        if (d_o !== 64'h2233445566778899)
            $display("ERROR: Full word read mismatch at addr 8");

        // Test Case 4: Overlapping read from address 2
        addr_i = 24'h000002;
        #10;
        $display("Read from addr 2: %h", d_o);
        if (d_o !== 64'h8899EEFF00115566)
            $display("ERROR: Overlapping read mismatch at addr 2");

        $display("Test completed successfully.");
        $finish;
    end

endmodule


`timescale 1ns/1ps

module tb_memory_wrapper;

    // Clock and Reset
    reg clk_i;
    reg arst_i;

    // Front-end Interface (IOb native slave)
    reg iob_valid_i;
    reg [18:0] iob_addr_i;
    reg [255:0] iob_wdata_i;
    reg [31:0] iob_wstrb_i;
    wire [255:0] iob_rdata_o;
    wire iob_rvalid_o;
    wire iob_ready_o;

    // Cache invalidate and write-through buffer IO chain
    reg invalidate_i;
    wire invalidate_o;
    reg wtb_empty_i;
    wire wtb_empty_o;

    // Instantiate DUT (Device Under Test)
    memory_wrapper uut (
        .clk_i(clk_i),
        .arst_i(arst_i),
        .iob_valid_i(iob_valid_i),
        .iob_addr_i(iob_addr_i),
        .iob_wdata_i(iob_wdata_i),
        .iob_wstrb_i(iob_wstrb_i),
        .iob_rdata_o(iob_rdata_o),
        .iob_rvalid_o(iob_rvalid_o),
        .iob_ready_o(iob_ready_o),
        .invalidate_i(invalidate_i),
        .invalidate_o(invalidate_o),
        .wtb_empty_i(wtb_empty_i),
        .wtb_empty_o(wtb_empty_o)
    );

    // Clock Generation (100MHz)
    always #10 clk_i = ~clk_i;

    initial begin
        $dumpfile("memory_wrapper.vcd"); // Set the VCD file name
        $dumpvars(0, tb_memory_wrapper); // Dump all signals in the testbench
    end

    // Test Procedure
    initial begin
        // Initialize signals
        clk_i = 0;
        arst_i = 1;
        iob_valid_i = 0;
        iob_addr_i = 0;
        iob_wdata_i = 0;
        iob_wstrb_i = 0;
        invalidate_i = 0;
        wtb_empty_i = 1;

        repeat (5) @(posedge clk_i);
        arst_i = 0;
        #10;

        // Test Case 1: Write a full 256-bit word
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 19'h00005;
        iob_wdata_i = 256'hDEADBEEFCAFEBABE112233445566778899AABBCCDDEEFF0011223344556677;
        iob_wstrb_i = 32'hFFFFFFFF;
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) iob_valid_i = 0;

        // Read back the full word
        #80 @(posedge clk_i);
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 19'h00005;
        iob_wstrb_i = 32'h00000000;
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read Data: %h", iob_rdata_o);
        if (iob_rdata_o !== 256'hDEADBEEFCAFEBABE112233445566778899AABBCCDDEEFF0011223344556677)
            $display("ERROR: Data mismatch!");

        // Test Case 2: Write and read different data
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 19'h00006;
        iob_wdata_i = 256'hABCDEF0123456789FEDCBA9876543210AABBCCDDEEFF112233445566778899AA;
        iob_wstrb_i = 32'hFFFFFFFF;
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) iob_valid_i = 0;

        #80 @(posedge clk_i);
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 19'h00006;
        iob_wstrb_i = 32'h00000000;
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read Data: %h", iob_rdata_o);
        if (iob_rdata_o !== 256'hABCDEF0123456789FEDCBA9876543210AABBCCDDEEFF112233445566778899AA)
            $display("ERROR: Data mismatch!");

        // Test Case 3: Write and read another different data
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 19'h00007;
        iob_wdata_i = 256'h112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00;
        iob_wstrb_i = 32'hFFFFFFFF;
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) iob_valid_i = 0;

        #80 @(posedge clk_i);
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 19'h00007;
        iob_wstrb_i = 32'h00000000;
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read Data: %h", iob_rdata_o);
        if (iob_rdata_o !== 256'h112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00)
            $display("ERROR: Data mismatch!");

        $display("Test completed successfully.");
        $finish;
    end

endmodule




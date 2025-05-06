`timescale 1ns/1ps

`include "constants.vh"

module tb_memory_wrapper;

    // Clock and Reset
    reg clk_i;
    reg arst_i;

    // Front-end Interface
    reg iob_valid_i;
    reg [`FE_ADDR_W-1:0] iob_addr_i;
    reg [`FE_DATA_W-1:0] iob_wdata_i;
    reg [`FE_STRB_W-1:0] iob_wstrb_i;
    wire [`FE_DATA_W-1:0] iob_rdata_o;
    wire iob_rvalid_o;
    wire iob_ready_o;

    // Cache invalidate and write-through buffer IO chain
    reg invalidate_i;
    wire invalidate_o;
    reg wtb_empty_i;
    wire wtb_empty_o;

    // Instantiate DUT
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

    // Clock Generation (50 MHz, 20 ns period)
    always #10 clk_i = ~clk_i;

    // Dump variables for waveform
    initial begin
        $dumpfile("wave_mem.vcd");
        $dumpvars(0, tb_memory_wrapper);
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

        // Reset
        repeat (5) @(posedge clk_i);
        arst_i = 0;
        #10;

        // Test Case 1: Full Write and Read
        $display("Test Case 1: Full Write and Read at 0x000000");
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000000;
        iob_wdata_i = 32'hDEADBEEF;
        iob_wstrb_i = 4'hF; // All bytes enabled
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) iob_valid_i = 0;

        #80 @(posedge clk_i); // Wait for write to complete
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000000;
        iob_wstrb_i = 4'h0; // Read operation
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read Data from 0x%h: %h", iob_addr_i, iob_rdata_o);
        if (iob_rdata_o !== 32'hDEADBEEF)
            $display("ERROR: Expected 32'hDEADBEEF, got %h", iob_rdata_o);

        // Test Case 2: Partial Write and Read
        $display("Test Case 2: Partial Write and Read at 0x000004");
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000004;
        iob_wdata_i = 32'hAABBCCDD;
        iob_wstrb_i = 4'b1100; // Upper two bytes (bits [31:16])
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) iob_valid_i = 0;

        #80 @(posedge clk_i);
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000004;
        iob_wstrb_i = 4'h0;
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read Data from 0x%h: %h", iob_addr_i, iob_rdata_o);
        if (iob_rdata_o !== 32'hAABB0000)
            $display("ERROR: Expected 32'hAABB0000, got %h", iob_rdata_o);

        // Test Case 3: Full Write and Read
        $display("Test Case 3: Full Write and Read at 0x000008");
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000008;
        iob_wdata_i = 32'h12345678;
        iob_wstrb_i = 4'hF;
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) iob_valid_i = 0;

        #80 @(posedge clk_i);
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000008;
        iob_wstrb_i = 4'h0;
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read Data from 0x%h: %h", iob_addr_i, iob_rdata_o);
        if (iob_rdata_o !== 32'h12345678)
            $display("ERROR: Expected 32'h12345678, got %h", iob_rdata_o);

        // End simulation
        $display("Test completed.");
        $finish;
    end

endmodule




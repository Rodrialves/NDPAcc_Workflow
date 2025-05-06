`timescale 1ns/1ps

`include "constants.vh"

module tb_memory_wrapper_loaded;

    // Clock and Reset
    reg clk_i;
    reg arst_i;

    // Front-end Interface (IOb native slave)
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

    // Clock Generation (50MHz, period = 20ns)
    always #10 clk_i = ~clk_i;

    // Memory array for comparison (32767 locations of 8-bit words)
    reg [`DATA_W-1:0] mem_check [0:32767];

    initial begin
        $dumpfile("wave_loaded_mem.vcd"); // Set the VCD file name
        $dumpvars(0, tb_memory_wrapper_loaded); // Dump all signals in the testbench

        // Preload memory with $readmemh
        //$readmemh("ram_init.mem", mem_check);       // Load into reference array
        $readmemh("ram_init.mem", uut.ram.vec_ram.mem); // Load into DUT's RAM
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

        repeat (5) @(posedge clk_i); // Wait for a few cycles
        arst_i = 0;                  // Deassert reset
        #10;

        // Test Case 1: Read preloaded value from address 0x000000
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000000; // Byte address 0
        iob_wstrb_i = 4'h0;      // Read operation
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read Addr 0x%h: %h (Expected: %h)", iob_addr_i, iob_rdata_o, mem_check[0]);
        if (iob_rdata_o !== mem_check[0])
            $display("ERROR: Preloaded value mismatch at address 0x000000!");

        // Test Case 2: Read preloaded value from address 0x000004
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000002; // Byte address 4
        iob_wstrb_i = 4'h0;      // Read operation
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read Addr 0x%h: %h (Expected: %h)", iob_addr_i, iob_rdata_o, mem_check[1]);
        if (iob_rdata_o !== mem_check[1])
            $display("ERROR: Preloaded value mismatch at address 0x000004!");

        // Test Case 3: Write new value and read back at address 0x000008
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000008; // Byte address 8
        iob_wdata_i = 32'hAABBCCDD;
        iob_wstrb_i = 4'hF;      // Full-word write
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) iob_valid_i = 0;

        #80 @(posedge clk_i); // Wait for write to propagate
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h000008;
        iob_wstrb_i = 4'h0;      // Read operation
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read After Write Addr 0x%h: %h", iob_addr_i, iob_rdata_o);
        if (iob_rdata_o !== 32'hAABBCCDD)
            $display("ERROR: Write/Read mismatch at address 0x000008!");

        // Test Case 4: Read preloaded value from address 0x00000C to ensure unchanged
        @(posedge clk_i) #1 iob_valid_i = 1;
        iob_addr_i = 22'h00000C; // Byte address 12
        iob_wstrb_i = 4'h0;      // Read operation
        #1 while (!iob_ready_o) #1;
        @(posedge clk_i) #1 iob_valid_i = 0;
        while (!iob_rvalid_o) #1;
        #10;
        $display("Read Addr 0x%h: %h (Expected: %h)", iob_addr_i, iob_rdata_o, mem_check[3]);
        if (iob_rdata_o !== mem_check[3])
            $display("ERROR: Preloaded value mismatch at address 0x00000C!");

        $display("Test completed.");
        $finish;
    end

endmodule
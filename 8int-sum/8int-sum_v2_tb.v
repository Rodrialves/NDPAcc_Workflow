`include "constants.vh"

module tb_wallace_tree_sum;

    // Clock and reset
    reg clk;
    reg rst_n;

    // Interface to bus_controller
    wire acc_valid;
    wire [`FE_ADDR_W-1:0] acc_addr;        // Address bus (byte addresses for 32-bit words)
    wire [`FE_DATA_W-1:0] acc_wdata;       // Write data
    wire [`FE_STRB_W-1:0] acc_wstrb;       // Write strobe (byte enables)
    reg  [`FE_DATA_W-1:0] acc_rdata;       // Read data
    reg  acc_rvalid;                       // Read valid
    reg  acc_ready;                        // Bus ready

    // Control signals
    reg  start;
    reg  [`FE_ADDR_W-1:0] input_addr;      // Starting byte address for input data
    reg  [`FE_ADDR_W-1:0] output_addr;     // Starting byte address for output data
    reg  [31:0] N;                         // Number of blocks to process
    wire done;                             // Completion signal

    // Memory model (32-bit wide, 1024 locations = 4 KB)
    reg  [31:0] memory [0:1023];

    // Instantiate the accelerator
    int_sum_v2 dut (
        .clk(clk),
        .rst_n(rst_n),
        .acc_valid(acc_valid),
        .acc_addr(acc_addr),
        .acc_wdata(acc_wdata),
        .acc_wstrb(acc_wstrb),
        .acc_rdata(acc_rdata),
        .acc_rvalid(acc_rvalid),
        .acc_ready(acc_ready),
        .start(start),
        .input_addr(input_addr),
        .output_addr(output_addr),
        .N(N),
        .done(done)
    );

    initial begin
        $dumpfile("wave_out_acc.vcd"); // Set the VCD file name
        $dumpvars(0, tb_wallace_tree_sum); // Dump all signals in the testbench
    end

    // Clock generation: 10ns period (5ns high, 5ns low)
    always #5 clk = ~clk;

    // Memory controller logic
    reg [`FE_ADDR_W-1:0] read_addr;        // Stores address of pending read
    reg read_pending;                      // Indicates a read is in progress
    reg [1:0] read_delay;                  // Delay counter for read response

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_ready <= 0;
            acc_rvalid <= 0;
            acc_rdata <= 0;
            read_pending <= 0;
            read_delay <= 0;
        end else begin
            // Default values
            acc_ready <= 0;
            acc_rvalid <= 0;

            // Handle read requests
            if (acc_valid && acc_wstrb == 0 && !read_pending) begin
                acc_ready <= 1;            // Accept the read request
                read_addr <= acc_addr;     // Store the requested byte address
                read_pending <= 1;         // Mark read as pending
                read_delay <= 2;           // Set 2-cycle delay for response
            end

            // Handle read response
            if (read_pending) begin
                if (read_delay == 0) begin
                    acc_rdata <= memory[read_addr >> 2]; // Read 32-bit word (byte addr / 4)
                    acc_rvalid <= 1;                     // Signal valid data
                    read_pending <= 0;                   // Clear pending flag
                end else begin
                    read_delay <= read_delay - 1;        // Decrement delay
                end
            end

            // Handle write requests
            if (acc_valid && acc_wstrb != 0) begin
                acc_ready <= 1;            // Accept the write immediately
                if (acc_wstrb == 4'hF) begin
                    memory[acc_addr >> 2] <= acc_wdata; // Write full 32-bit word
                end else begin
                    // Byte-wise write based on strobe
                    if (acc_wstrb[0]) memory[acc_addr >> 2][7:0]   <= acc_wdata[7:0];
                    if (acc_wstrb[1]) memory[acc_addr >> 2][15:8]  <= acc_wdata[15:8];
                    if (acc_wstrb[2]) memory[acc_addr >> 2][23:16] <= acc_wdata[23:16];
                    if (acc_wstrb[3]) memory[acc_addr >> 2][31:24] <= acc_wdata[31:24];
                end
            end
        end
    end

    // Test procedure
    initial begin
        // Initialize memory with test data (2 blocks of 8 32-bit integers each)
        memory[0]  = 32'h00000000; // Block 1: 0
        memory[1]  = 32'h00000001; // 1
        memory[2]  = 32'h00000002; // 2
        memory[3]  = 32'h00000003; // 3
        memory[4]  = 32'h00000004; // 4
        memory[5]  = 32'h00000005; // 5
        memory[6]  = 32'h00000006; // 6
        memory[7]  = 32'h00000007; // 7
        memory[8]  = 32'h00000008; // Block 2: 8
        memory[9]  = 32'h00000009; // 9
        memory[10] = 32'h0000000A; // 10
        memory[11] = 32'h0000000B; // 11
        memory[12] = 32'h0000000C; // 12
        memory[13] = 32'h0000000D; // 13
        memory[14] = 32'h0000000E; // 14
        memory[15] = 32'h0000000F; // 15
        memory[64] = 32'h00000000; // Output location 1 (byte addr 0x100)
        memory[65] = 32'h00000000; // Output location 2 (byte addr 0x104)

        // Initialize signals
        clk = 0;
        rst_n = 0;
        start = 0;
        input_addr = 22'h000000;  // Input starts at byte address 0x000000
        output_addr = 22'h000100; // Output starts at byte address 0x000100 (word addr 64)
        N = 32'd2;                // Process 2 blocks

        // Apply reset
        #10 rst_n = 1;

        // Start the accelerator
        #10 start = 1;
        #10 start = 0;            // Pulse start for one cycle

        // Wait for completion
        wait(done == 1);
        #10;                      // Allow time for final writes

        // Verify results
        if (memory[64] == 32'd28 && memory[65] == 32'd92) begin
            $display("Test passed!");
        end else begin
            $display("Test failed!");
            $display("memory[64] = %h, expected 0000001C", memory[64]);
            $display("memory[65] = %h, expected 0000005C", memory[65]);
        end

        $finish;                  // End simulation
    end

    // Debugging output
    always @(posedge clk) begin
        if (acc_valid && acc_ready) begin
            if (acc_wstrb == 0) begin
                $display("Time %t: Read request issued, addr=%h", $time, acc_addr);
            end else begin
                $display("Time %t: Write request issued, addr=%h, data=%h, wstrb=%h", 
                         $time, acc_addr, acc_wdata, acc_wstrb);
            end
        end
        if (acc_rvalid) begin
            $display("Time %t: Read response provided, data=%h", $time, acc_rdata);
        end
    end

endmodule
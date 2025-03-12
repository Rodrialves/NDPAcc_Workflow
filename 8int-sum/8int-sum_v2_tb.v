module tb_wallace_tree_sum;

    // Clock and reset
    reg clk;
    reg rst_n;

    // Interface to bus_controller
    wire acc_valid;
    wire [18:0] acc_addr;        // Address bus (word addresses for 256-bit words)
    wire [255:0] acc_wdata;      // Write data
    wire [31:0] acc_wstrb;       // Write strobe (byte enables)
    reg [255:0] acc_rdata;       // Read data
    reg acc_rvalid;              // Read valid
    reg acc_ready;               // Bus ready

    // Control signals
    reg start;
    reg [18:0] input_addr;       // Starting address for input data
    reg [18:0] output_addr;      // Starting address for output data
    reg [31:0] N;                // Number of blocks to process
    wire done;                   // Completion signal

    // Memory model (256-bit wide)
    reg [255:0] memory [0:31];

    // Instantiate the accelerator
    int_sum_v2 #(
        .DATA_WIDTH(256),        // Input data width
        .OUTPUT_WIDTH(32),       // Output sum width
        .NUM(8)                  // Number of 32-bit integers per block
    ) dut (
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
        $dumpfile("memory_wrapper.vcd"); // Set the VCD file name
        $dumpvars(0, tb_wallace_tree_sum); // Dump all signals in the testbench
    end

    // Clock generation: 10ns period (5ns high, 5ns low)
    always #5 clk = ~clk;

    // Memory controller logic
    reg [18:0] read_addr;        // Stores address of pending read
    reg read_pending;            // Indicates a read is in progress
    reg [1:0] read_delay;        // Delay counter for read response

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
                read_addr <= acc_addr;     // Store the requested address
                read_pending <= 1;         // Mark read as pending
                read_delay <= 2;           // Set 2-cycle delay for response
            end

            // Handle read response
            if (read_pending) begin
                if (read_delay == 0) begin
                    acc_rdata <= memory[read_addr]; // Provide data
                    acc_rvalid <= 1;                // Signal valid data
                    read_pending <= 0;              // Clear pending flag
                end else begin
                    read_delay <= read_delay - 1;   // Decrement delay
                end
            end

            // Handle write requests
            if (acc_valid && acc_wstrb != 0) begin
                acc_ready <= 1;            // Accept the write immediately
                // Update memory (only lower 32 bits, as acc_wstrb = 32'hF)
                if (acc_wstrb[3:0] == 4'hF) begin
                    memory[acc_addr][31:0] <= acc_wdata[31:0];
                end
            end
        end
    end

    // Test procedure
    initial begin
        // Initialize memory with test data
        memory[0] = 256'h00000007_00000006_00000005_00000004_00000003_00000002_00000001_00000000;
        memory[1] = 256'h0000000F_0000000E_0000000D_0000000C_0000000B_0000000A_00000009_00000008;
        memory[16] = 256'h0;  // Output location 1
        memory[17] = 256'h0;  // Output location 2

        // Initialize signals
        clk = 0;
        rst_n = 0;
        start = 0;
        input_addr = 19'h0;    // Input starts at address 0
        output_addr = 19'h10;  // Output starts at address 16 (word address)
        N = 32'd2;             // Process 2 blocks

        // Apply reset
        #10 rst_n = 1;

        // Start the accelerator
        #10 start = 1;
        #10 start = 0;         // Pulse start for one cycle

        // Wait for completion
        wait(done == 1);
        #10;                   // Allow time for final writes

        // Verify results
        if (memory[16][31:0] == 32'd28 && memory[17][31:0] == 32'd92) begin
            $display("Test passed!");
        end else begin
            $display("Test failed!");
            $display("memory[16][31:0] = %h, expected 0000001C", memory[16][31:0]);
            $display("memory[17][31:0] = %h, expected 0000005C", memory[17][31:0]);
        end

        $finish;               // End simulation
    end

    // Debugging output
    always @(posedge clk) begin
        if (acc_valid && acc_ready) begin
            if (acc_wstrb == 0) begin
                $display("Time %t: Read request issued, addr=%h", $time, acc_addr);
            end else begin
                $display("Time %t: Write request issued, addr=%h, data=%h, wstrb=%h", 
                         $time, acc_addr, acc_wdata[31:0], acc_wstrb);
            end
        end
        if (acc_rvalid) begin
            $display("Time %t: Read response provided, data=%h", $time, acc_rdata);
        end
    end

endmodule
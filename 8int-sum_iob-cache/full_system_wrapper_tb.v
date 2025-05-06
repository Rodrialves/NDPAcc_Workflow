`timescale 1ns/1ps

`include "constants.vh"

module tb_system_wrapper;

    // Signals
    reg              clk = 0;
    reg              reset = 1;
    reg              cpu_valid = 0;
    reg  [`FE_ADDR_W-1:0] cpu_addr = 0;
    reg  [`FE_DATA_W-1:0] cpu_wdata = 0;
    reg  [`FE_STRB_W-1:0] cpu_wstrb = 0;
    wire [`FE_DATA_W-1:0] cpu_rdata;
    wire             cpu_rvalid;
    wire             cpu_ready;
    reg              start = 0;
    reg  [`FE_ADDR_W-1:0] input_addr = 0;
    reg  [`FE_ADDR_W-1:0] output_addr = 0;
    reg  [31:0]      N = 0;
    wire             done;
    wire             error_flag;

    // Variables for result checking
    reg  [`FE_DATA_W-1:0] sum1, sum2;

    // Instantiate the system_wrapper
    fs_wrapper uut (
        .clk(clk),
        .reset(reset),
        .cpu_valid(cpu_valid),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_wstrb(cpu_wstrb),
        .cpu_rdata(cpu_rdata),
        .cpu_rvalid(cpu_rvalid),
        .cpu_ready(cpu_ready),
        .start(start),
        .input_addr(input_addr),
        .output_addr(output_addr),
        .N(N),
        .done(done),
        .error_flag(error_flag)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave_fs.vcd");
        $dumpvars(0, tb_system_wrapper);
    end

    // Test sequence
    initial begin
        // Initialize
        reset = 1;
        #20;                // Hold reset for 20ns
        reset = 0;
        #10;                // Wait after reset deassertion

        // Step 1: Write test data to memory via CPU interface
        // Write two 256-bit blocks, each with eight 32-bit integers
        cpu_write(19'h0, 256'h00000007_00000006_00000005_00000004_00000003_00000002_00000001_00000000, {`FE_STRB_W{1'b1}});
        cpu_write(19'h1, 256'h0000000F_0000000E_0000000D_0000000C_0000000B_0000000A_00000009_00000008, {`FE_STRB_W{1'b1}});

        // Step 2: Configure accelerator
        input_addr = 19'h0;    // Start of input data
        output_addr = 19'h10;  // Start of output data (address 16)
        N = 32'd2;             // Process 2 blocks
        #10;

        // Step 3: Start the accelerator
        start = 1;
        #10;
        start = 0;

        // Step 4: Wait for accelerator to complete
        wait(done == 1);
        #10;  // Small delay to ensure outputs settle

        // Step 5: Read results from memory
        cpu_read(19'h10, sum1);
        $display("Sum 1: %h", sum1[31:0]);
        cpu_read(19'h11, sum2);
        $display("Sum 2: %h", sum2[31:0]);

        // Step 6: Verify results
        // Expected: sum1 = 0+1+2+3+4+5+6+7 = 28, sum2 = 8+9+10+11+12+13+14+15 = 92
        if (sum1[31:0] == 32'd28 && sum2[31:0] == 32'd92) begin
            $display("Test passed!");
        end else begin
            $display("Test failed! Expected sum1=28, sum2=92; Got sum1=%d, sum2=%d", sum1[31:0], sum2[31:0]);
        end

        #20;
        $finish;
    end

    // Task: CPU Write Operation
    task cpu_write;
        input [`FE_ADDR_W-1:0] addr;
        input [`FE_DATA_W-1:0] data;
        input [`FE_STRB_W-1:0] strb;
        begin
            @(posedge clk);
            cpu_valid <= 1'b1;
            cpu_addr  <= addr;
            cpu_wdata <= data;
            cpu_wstrb <= strb;
            while (!cpu_ready) @(posedge clk);
            @(posedge clk);
            cpu_valid <= 1'b0;
            cpu_wstrb <= {`FE_STRB_W{1'b0}};
        end
    endtask

    // Task: CPU Read Operation
    task cpu_read;
        input  [`FE_ADDR_W-1:0] addr;
        output [`FE_DATA_W-1:0] rdata;
        begin
            @(posedge clk);
            cpu_valid <= 1'b1;
            cpu_addr  <= addr;
            cpu_wstrb <= {`FE_STRB_W{1'b0}};  // Read operation (no write strobes)
            while (!cpu_ready) @(posedge clk);
            @(posedge clk);
            cpu_valid <= 1'b0;
            while (!cpu_rvalid) @(posedge clk);  // Wait for read data
            rdata = cpu_rdata;
        end
    endtask

endmodule
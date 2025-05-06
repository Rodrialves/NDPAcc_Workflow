`timescale 1ns/1ps

`include "constants.vh"

module fs_wrapper (
    // Clock and reset
    input  wire              clk,
    input  wire              reset,      // Active-high asynchronous reset for bus and memory. (Active-low for accelerator internally)
    // CPU-like interface (to be driven by testbench)
    input  wire              cpu_valid,
    input  wire [`FE_ADDR_W-1:0] cpu_addr,
    input  wire [`FE_DATA_W-1:0] cpu_wdata,
    input  wire [`FE_STRB_W-1:0] cpu_wstrb,
    output wire [`FE_DATA_W-1:0] cpu_rdata,
    output wire              cpu_rvalid,
    output wire              cpu_ready,
    // Accelerator control signals
    input  wire              start,
    input  wire [`FE_ADDR_W-1:0] input_addr,
    input  wire [`FE_ADDR_W-1:0] output_addr,
    input  wire [31:0]       N,
    output wire              done,
    // Debug/status outputs
    output reg               error_flag
);

    // Internal wires to connect between modules
    // Bus controller <-> Accelerator (acc side)
    wire              acc_valid;
    wire [`FE_ADDR_W-1:0] acc_addr;
    wire [`FE_DATA_W-1:0] acc_wdata;
    wire [`FE_STRB_W-1:0] acc_wstrb;
    wire [`FE_DATA_W-1:0] acc_rdata;
    wire              acc_rvalid;
    wire              acc_ready;

    // Bus controller <-> Memory wrapper (cache side)
    wire              cache_valid;
    wire [`FE_ADDR_W-1:0] cache_addr;
    wire [`FE_DATA_W-1:0] cache_wdata;
    wire [`FE_STRB_W-1:0] cache_wstrb;
    wire [`FE_DATA_W-1:0] cache_rdata;
    wire              cache_rvalid;
    wire              cache_ready;

    // Invert reset for accelerator (convert active-high reset to active-low)
    wire arst_i = reset;       // async reset for bus controller and memory (active high)
    wire rst_n  = ~reset;      // synchronous reset for accelerator (active low)

    // Instantiate the Bus Controller (arbiter between CPU and Accelerator)
    bus_controller u_bus_ctrl (
        // CPU side
        .cpu_valid   (cpu_valid),
        .cpu_addr    (cpu_addr),
        .cpu_wdata   (cpu_wdata),
        .cpu_wstrb   (cpu_wstrb),
        .cpu_rdata   (cpu_rdata),
        .cpu_rvalid  (cpu_rvalid),
        .cpu_ready   (cpu_ready),
        // Accelerator side
        .acc_valid   (acc_valid),
        .acc_addr    (acc_addr),
        .acc_wdata   (acc_wdata),
        .acc_wstrb   (acc_wstrb),
        .acc_rdata   (acc_rdata),
        .acc_rvalid  (acc_rvalid),
        .acc_ready   (acc_ready),
        // Memory (cache) side
        .cache_valid (cache_valid),
        .cache_addr  (cache_addr),
        .cache_wdata (cache_wdata),
        .cache_wstrb (cache_wstrb),
        .cache_rdata (cache_rdata),
        .cache_rvalid(cache_rvalid),
        .cache_ready (cache_ready),
        // Clock and reset
        .clk_i       (clk),
        .arst_i      (arst_i)
    );

    // Instantiate the Memory Wrapper (includes cache + RAM)
    memory_wrapper u_mem_wrap (
        // Front-end IOb bus interface (connected to bus controller's cache side)
        .iob_valid_i (cache_valid),
        .iob_addr_i  (cache_addr),
        .iob_wdata_i (cache_wdata),
        .iob_wstrb_i (cache_wstrb),
        .iob_rdata_o (cache_rdata),
        .iob_rvalid_o(cache_rvalid),
        .iob_ready_o (cache_ready),
        // Cache invalidate chain (not used in this test, tie inputs to safe values)
        .invalidate_i(1'b0),         // no external invalidate
        .invalidate_o(/* unconnected */),
        .wtb_empty_i (1'b1),         // assume write buffer is empty (base of chain)
        .wtb_empty_o (/* unconnected */),
        // Clock and reset
        .clk_i       (clk),
        .arst_i      (arst_i)
    );

    // Instantiate the Accelerator module
    int_sum_v2 u_accel (
        .clk         (clk),
        .rst_n       (rst_n),
        // Interface to bus_controller (memory requests)
        .acc_valid   (acc_valid),
        .acc_addr    (acc_addr),
        .acc_wdata   (acc_wdata),
        .acc_wstrb   (acc_wstrb),
        .acc_rdata   (acc_rdata),
        .acc_rvalid  (acc_rvalid),
        .acc_ready   (acc_ready),
        // Control signals
        .start       (start),
        .input_addr  (input_addr),
        .output_addr (output_addr),
        .N           (N),
        .done        (done)
    );

    // =============================================================
    // Debugging/Monitoring Logic (Simulation-only constructs)
    // =============================================================
    // Monitor important signals continuously
    initial begin
        $monitor("[@%0t] CPU: valid=%b ready=%b rvalid=%b addr=%h wstrb=%h ACC: valid=%b ready=%b rvalid=%b addr=%h wstrb=%h ] done=%b",
                $time, cpu_valid, cpu_ready, cpu_rvalid, cpu_addr, cpu_wstrb,
                acc_valid, acc_ready, acc_rvalid, acc_addr, acc_wstrb, done);
    end

    // Track outstanding read requests for error detection
    integer outstanding_reads;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            outstanding_reads <= 0;
            error_flag <= 0;
        end else begin
            // If a read request is accepted (valid & ready with no write strobes)
            if (cache_valid && cache_ready && cache_wstrb == {`FE_STRB_W{1'b0}}) begin
                outstanding_reads <= outstanding_reads + 1;
            end
            // If a read response is valid (memory returning data)
            if (cache_rvalid) begin
                if (outstanding_reads > 0)
                    outstanding_reads <= outstanding_reads - 1;
            end
            // Check for error conditions:
            // 1. Too many outstanding reads (overflow)
            if (outstanding_reads > 4) begin
                $display("ERROR: Outstanding read requests overflow at time %0t", $time);
                error_flag <= 1'b1;
            end
            // 2. Read response with no request (underflow)
            if (cache_rvalid && outstanding_reads == 0) begin
                $display("ERROR: Read response with no pending request at time %0t", $time);
                error_flag <= 1'b1;
            end
        end
    end

    // // Log memory transactions for clarity
    // always @(posedge clk) begin
    //     // Log CPU transactions
    //     if (cpu_valid && cpu_ready) begin
    //         if (cpu_wstrb !== {`FE_STRB_W{1'b0}}) begin  // write operation
    //             $display("CPU WRITE: addr=%h data=%h (strobe %h) at time %0t",
    //                      cpu_addr, cpu_wdata, cpu_wstrb, $time);
    //         end else begin  // read operation
    //             $display("CPU READ REQUEST: addr=%h at time %0t", cpu_addr, $time);
    //         end
    //     end
    //     if (cpu_rvalid) begin
    //         $display("CPU READ RESPONSE: data=%h at time %0t", cpu_rdata, $time);
    //     end
    //     // Log Accelerator transactions
    //     if (acc_valid && acc_ready) begin
    //         if (acc_wstrb !== {`FE_STRB_W{1'b0}}) begin  // write
    //             $display("ACC WRITE: addr=%h data=%h (strobe %h) at time %0t",
    //                      acc_addr, acc_wdata, acc_wstrb, $time);
    //         end else begin  // read
    //             $display("ACC READ REQUEST: addr=%h at time %0t", acc_addr, $time);
    //         end
    //     end
    //     if (acc_rvalid) begin
    //         $display("ACC READ RESPONSE: data=%h at time %0t", acc_rdata, $time);
    //     end
    //     // Log accelerator completion
    //     if (done) begin
    //         $display("ACCELERATOR DONE asserted at time %0t (computation complete)", $time);
    //     end
    // end

endmodule

`include "constants.vh"

module int_sum_v2
    (
        // Clock and reset
        input clk,
        input rst_n,

        // Interface to bus_controller
        output reg acc_valid,              // Request valid
        output reg [`FE_ADDR_W-1 :0] acc_addr,        // Address for read/write
        output reg [`FE_DATA_W-1 :0] acc_wdata,      // Write data
        output reg [`FE_STRB_W-1 :0] acc_wstrb,       // Write strobe
        input wire [`FE_DATA_W-1 :0] acc_rdata,      // Read data
        input wire acc_rvalid,             // Read data valid
        input wire acc_ready,              // Request accepted

        // Control signals (memory-mapped registers)
        input wire start,                  // Start computation
        input wire [`FE_ADDR_W-1 :0] input_addr,      // Input data starting address
        input wire [`FE_ADDR_W-1 :0] output_addr,     // Output data starting address
        input wire [31:0] N,               // Number of 256-bit blocks
        output reg done                    // Computation complete
    );

    // Internal registers
    reg [`FE_DATA_W-1 :0] input_buffer [0:3];        // Buffer for input data
    reg [31:0] output_buffer [0:3];        // Buffer for output sums
    reg [1:0] input_head, input_tail;      // Buffer pointers
    reg [1:0] output_head, output_tail;
    reg [31:0] count;                      // Processed block counter
    reg [`FE_ADDR_W-1 :0] current_input_addr;         // Current read address
    reg [`FE_ADDR_W-1 :0] current_output_addr;        // Current write address

    // Pipeline registers
    reg [OUTPUT_WIDTH-1:0] sum_stage1 [3:0]; // Stage 1: 8 -> 4
    reg v_stage1;
    reg [OUTPUT_WIDTH-1:0] sum_stage2 [1:0]; // Stage 2: 4 -> 2
    reg v_stage2;
    reg [OUTPUT_WIDTH-1:0] final_sum;        // Stage 3: 2 -> 1
    reg v_final;

    // State machine
    reg [2:0] state;
    localparam IDLE = 0,
               READ_REQUEST = 1,
               WAIT_FOR_DATA = 2,
               PROCESS = 3,
               WRITE_REQUEST = 4,
               WAIT_FOR_WRITE = 5,
               DONE = 6;

    // Main FSM and logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            acc_valid <= 0;
            done <= 0;
            count <= 0;
            input_head <= 0;
            input_tail <= 0;
            output_head <= 0;
            output_tail <= 0;
            current_input_addr <= 0;
            current_output_addr <= 0;
            v_stage1 <= 0;
            v_stage2 <= 0;
            v_final <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= READ_REQUEST;
                        current_input_addr <= input_addr;
                        current_output_addr <= output_addr;
                        count <= 0;
                    end
                end

                READ_REQUEST: begin
                    // Request data if buffer not full and more data needed
                    if (count < N && (input_head - input_tail) < 4) begin
                        acc_valid <= 1;
                        acc_addr <= current_input_addr;
                        acc_wstrb <= 32'h0; // Read request (no write)
                        if (acc_ready) begin
                            acc_valid <= 0;
                            current_input_addr <= current_input_addr + 1;
                            state <= WAIT_FOR_DATA;
                        end
                    end else begin
                        state <= PROCESS;
                    end
                end

                WAIT_FOR_DATA: begin
                    if (acc_rvalid) begin
                        input_buffer[input_tail] <= acc_rdata;
                        input_tail <= input_tail + 1;
                        state <= READ_REQUEST;
                    end
                end

                PROCESS: begin
                    // Issue write request if output buffer has data and no request is pending
                    if (output_head != output_tail && !acc_valid) begin
                        acc_valid <= 1;
                        acc_addr <= current_output_addr;
                        acc_wdata <= {224'b0, output_buffer[output_head]}; // 32-bit result, padded to 256 bits
                        acc_wstrb <= 32'h0000000F; // Write 32 bits
                    end
                    // Issue read request if input buffer has space, more data needed, and no request pending
                    else if ((input_head - input_tail) < 4 && count < N && !acc_valid) begin
                        acc_valid <= 1;
                        acc_addr <= current_input_addr;
                        acc_wstrb <= 32'h00000000; // Read request
                    end

                    // Handle request acceptance
                    if (acc_valid && acc_ready) begin
                        acc_valid <= 0;
                        if (acc_wstrb != 0) begin // Write accepted
                            output_head <= output_head + 1;
                            current_output_addr <= current_output_addr + 1;
                        end else begin // Read accepted
                            current_input_addr <= current_input_addr + 1;
                        end
                    end

                    // Store incoming read data
                    if (acc_rvalid) begin
                        input_buffer[input_tail] <= acc_rdata;
                        input_tail <= input_tail + 1;
                    end

                    // Feed pipeline if data available
                    if (input_head != input_tail) begin
                        sum_stage1[0] <= input_buffer[input_head][31:0] + input_buffer[input_head][63:32];
                        sum_stage1[1] <= input_buffer[input_head][95:64] + input_buffer[input_head][127:96];
                        sum_stage1[2] <= input_buffer[input_head][159:128] + input_buffer[input_head][191:160];
                        sum_stage1[3] <= input_buffer[input_head][223:192] + input_buffer[input_head][255:224];
                        v_stage1 <= 1;
                        input_head <= input_head + 1;
                    end else begin
                        v_stage1 <= 0;
                    end

                    // Pipeline stage 2
                    if (v_stage1) begin
                        sum_stage2[0] <= sum_stage1[0] + sum_stage1[1];
                        sum_stage2[1] <= sum_stage1[2] + sum_stage1[3];
                        v_stage2 <= 1;
                    end else begin
                        v_stage2 <= 0;
                    end

                    // Pipeline stage 3
                    if (v_stage2) begin
                        final_sum <= sum_stage2[0] + sum_stage2[1];
                        v_final <= 1;
                    end else begin
                        v_final <= 0;
                    end

                    // Store result in output buffer
                    if (v_final) begin
                        output_buffer[output_tail] <= final_sum;
                        output_tail <= output_tail + 1;
                        count <= count + 1;
                    end

                    // Transition to DONE when complete
                    if (count == N && output_head == output_tail) begin
                        state <= DONE;
                    end
                end

                WAIT_FOR_WRITE: begin
                    // Optional state if write latency needs handling
                    state <= PROCESS;
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

    // Pipeline Stage 2 (unchanged logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage2[0] <= 0;
            sum_stage2[1] <= 0;
            v_stage2 <= 0;
        end else if (v_stage1) begin
            sum_stage2[0] <= sum_stage1[0] + sum_stage1[1];
            sum_stage2[1] <= sum_stage1[2] + sum_stage1[3];
            v_stage2 <= 1;
        end else begin
            v_stage2 <= 0;
        end
    end

    // Remove original output assignments since sum_out is now buffered
    // Debugging statements (optional)
    always @(posedge clk) begin
        //$display("State: %d, Count: %d", state, count);
        // $display("Stage 1: %d %d %d %d", sum_stage1[0], sum_stage1[1], sum_stage1[2], sum_stage1[3]);
        // $display("Stage 2: %d %d", sum_stage2[0], sum_stage2[1]);
        // $display("Final Sum: %d", final_sum);
    end

endmodule
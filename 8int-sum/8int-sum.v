module wallace_tree_sum
   #(	parameter DATA_WIDTH = 256,
	parameter OUTPUT_WIDTH = 32,
	parameter NUM = 8)
   (input                            clk,
    input                            rst_n,
    input                            valid_in,
    input           [DATA_WIDTH-1:0] data_in, // 8 integers * 32-bit each
    output reg                       valid_out,
    output reg    [OUTPUT_WIDTH-1:0] sum_out  // Output sum (extra bits for overflow)
);

    // Stage 1: Pairwise sums (reducing 8 inputs to 4)
    reg [OUTPUT_WIDTH-1:0] sum_stage1 [3:0]; // Array of registers
    reg v_stage1;

    // Stage 2: Pairwise sums (reducing 4 inputs to 2)
    reg [OUTPUT_WIDTH-1:0] sum_stage2 [1:0];
    reg v_stage2;

    // Stage 3: Final sum (reducing 2 inputs to 1)
    reg [OUTPUT_WIDTH-1:0] final_sum;
    reg v_final;

    // Stage 1: Add 8 integers into 4 partial sums
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_stage1[0] <= 0;
            sum_stage1[1] <= 0;
            sum_stage1[2] <= 0;
            sum_stage1[3] <= 0;
            v_stage1 <= 0;
        end else if (valid_in) begin
            sum_stage1[0] <= data_in[ 31:  0] + data_in[ 63: 32];
            sum_stage1[1] <= data_in[ 95: 64] + data_in[127: 96];
            sum_stage1[2] <= data_in[159:128] + data_in[191:160];
            sum_stage1[3] <= data_in[223:192] + data_in[255:224];
            v_stage1 <= 1;
        end else begin
            v_stage1 <= 0;
        end
    end

    // Stage 2: Add 4 partial sums into 2 sums
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

    // Stage 3: Final sum (reducing 2 numbers to 1)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_sum <= 0;
            v_final <= 0;
        end else if (v_stage2) begin
            final_sum <= sum_stage2[0] + sum_stage2[1];
            v_final <= 1;
        end else begin
            v_final <= 0;
        end
    end

    // Output assignments
    always @(posedge clk) begin
        valid_out <= v_final;
        sum_out <= final_sum;
    end

    always @(posedge clk) begin
    	$display("Stage 1: %d %d %d %d", sum_stage1[0], sum_stage1[1], sum_stage1[2], sum_stage1[3]);
    	$display("Stage 2: %d %d", sum_stage2[0], sum_stage2[1]);
    	$display("Final Sum: %d", final_sum);
    end


endmodule


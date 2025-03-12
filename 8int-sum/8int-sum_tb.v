`timescale 1ns/1ps

module wallace_tree_sum_tb;

    reg clk;
    reg rst_n;
    reg valid_in;
    reg [255:0] data_in;
    wire valid_out;
    wire [31:0] sum_out;

    // Instantiate the DUT (Device Under Test)
    wallace_tree_sum uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .sum_out(sum_out)
    );

    // Generate clock
    always #5 clk = ~clk;  // 10 ns period

    // Test sequence
    initial begin
        $dumpfile("wave.vcd");  // Generate VCD file for waveform analysis
        $dumpvars(0, wallace_tree_sum_tb);
	$dumpvars(1, uut);

        clk = 0;
        rst_n = 0;
        valid_in = 0;
        data_in = 0;

        // Reset
        #10 rst_n = 1;

        // Apply test vector
        #10 valid_in = 1;
            data_in = {32'h00000001, 32'h00000002, 32'h00000003, 32'h00000004, 
                       32'h00000005, 32'h00000006, 32'h00000007, 32'h00000008}; // Expected sum = 36

        #10 valid_in = 0; // Wait for result

        #50 $finish;
    end

endmodule


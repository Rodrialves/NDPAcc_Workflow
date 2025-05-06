`include "constants.vh" 

module bus_controller (
    // CPU interface
    input  wire                cpu_valid,
    input  wire [`FE_ADDR_W-1 :0] cpu_addr,
    input  wire [`FE_DATA_W-1 :0] cpu_wdata,
    input  wire [`FE_STRB_W-1 :0] cpu_wstrb,
    output reg  [`FE_DATA_W-1 :0] cpu_rdata,
    output reg                 cpu_rvalid,
    output wire                cpu_ready,

    // Accelerator interface
    input  wire                acc_valid,
    input  wire [`FE_ADDR_W-1 :0] acc_addr,
    input  wire [`FE_DATA_W-1 :0] acc_wdata,
    input  wire [`FE_STRB_W-1 :0] acc_wstrb,
    output reg  [`FE_DATA_W-1 :0] acc_rdata,
    output reg                 acc_rvalid,
    output wire                acc_ready,

    // Cache interface
    output wire                cache_valid,
    output wire [`FE_ADDR_W-1 :0] cache_addr,
    output wire [`FE_DATA_W-1 :0] cache_wdata,
    output wire [`FE_STRB_W-1 :0] cache_wstrb,
    input  wire [`FE_DATA_W-1 :0] cache_rdata,
    input  wire                cache_rvalid,
    input  wire                cache_ready,

    // Clock and reset
    input  wire        clk_i,
    input  wire        arst_i
);

    // Round-robin arbitration
    reg last_served; // 0: CPU, 1: accelerator
    reg [1:0] select; // Changed from wire to reg
    always @* begin
        if (last_served == 0) begin // Last served was CPU, prefer accelerator
            if (acc_valid) select = 1;
            else if (cpu_valid) select = 0;
            else select = 2;
        end else begin // Last served was accelerator, prefer CPU
            if (cpu_valid) select = 0;
            else if (acc_valid) select = 1;
            else select = 2;
        end
    end

    // Drive cache inputs based on selected requester
    assign cache_valid = (select == 0) ? cpu_valid : (select == 1) ? acc_valid : 1'b0;
    assign cache_addr  = (select == 0) ? cpu_addr  : (select == 1) ? acc_addr  : `FE_ADDR_W-1'b0;
    assign cache_wdata = (select == 0) ? cpu_wdata : (select == 1) ? acc_wdata : `FE_DATA_W-1'b0;
    assign cache_wstrb = (select == 0) ? cpu_wstrb : (select == 1) ? acc_wstrb : `FE_STRB_W-1'b0;

    // Ready signals back to requesters
    assign cpu_ready = (select == 0) && cache_ready;
    assign acc_ready = (select == 1) && cache_ready;

    // Update last_served when a request is accepted
    always @(posedge clk_i or posedge arst_i) begin
        if (arst_i) begin
            last_served <= 0; // Reset to prefer CPU initially
        end else if (cache_valid && cache_ready) begin
            last_served <= select;
        end
    end

    // Read FIFO to track outstanding read requests
    reg [1:0] read_requester [0:3]; // Requester IDs (0: CPU, 1: accelerator)
    reg [1:0] read_head, read_tail; // 2-bit pointers for depth 4
    reg [2:0] read_count;           // Number of entries (0 to 4)

    // Push requester ID into FIFO for read requests
    always @(posedge clk_i or posedge arst_i) begin
        if (arst_i) begin
            read_head  <= 2'd0;
            read_tail  <= 2'd0;
            read_count <= 3'd0;
        end else if (cache_valid && cache_ready && (cache_wstrb == 32'b0)) begin
            // Read request accepted
            read_requester[read_tail] <= select;
            read_tail <= read_tail + 1; // Wraps naturally modulo 4
            read_count <= read_count + 1;
        end
    end

    // Pop FIFO and route read responses
    always @(posedge clk_i or posedge arst_i) begin
        if (arst_i) begin
            cpu_rvalid <= 1'b0;
            acc_rvalid <= 1'b0;
        end else begin
            cpu_rvalid <= 1'b0;
            acc_rvalid <= 1'b0;
            if (cache_rvalid && read_count > 0) begin
                case (read_requester[read_head])
                    2'd0: begin
                        cpu_rdata  <= cache_rdata;
                        cpu_rvalid <= 1'b1;
                    end
                    2'd1: begin
                        acc_rdata  <= cache_rdata;
                        acc_rvalid <= 1'b1;
                    end
                endcase
                read_head <= read_head + 1; // Wraps naturally modulo 4
                read_count <= read_count - 1;
            end
        end
    end

endmodule
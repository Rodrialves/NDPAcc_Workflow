`timescale 1ns / 1ps

`include "constants.vh"

module memory_wrapper (
    // Front-end interface (IOb native slave)
    input  [                             1-1:0] iob_valid_i,
    input  [                    `FE_ADDR_W-1:0] iob_addr_i,
    input  [                    `FE_DATA_W-1:0] iob_wdata_i,
    input  [                    `FE_STRB_W-1:0] iob_wstrb_i,
    output [                    `FE_DATA_W-1:0] iob_rdata_o,
    output [                             1-1:0] iob_rvalid_o,
    output [                             1-1:0] iob_ready_o,

    // Cache invalidate and write-trough buffer IO chain
    input  [1-1:0] invalidate_i,
    output [1-1:0] invalidate_o,
    input  [1-1:0] wtb_empty_i,
    output [1-1:0] wtb_empty_o,

    //General Interface Signals
    input [1-1:0] clk_i,
    input [1-1:0] arst_i
);

    wire                     be_valid;
    wire [   `BE_ADDR_W-1:0] be_addr;
    wire [   `BE_DATA_W-1:0] be_wdata;
    wire [   `BE_STRB_W-1:0] be_wstrb;
    wire [   `BE_DATA_W-1:0] be_rdata;
    wire                     be_rvalid;
    wire                     be_ready;
    wire cke_i;
    
    assign cke_i = 1'b1;


    // Instantiate IOb-Cache Wrapper
    iob_cache_iob cache (
        //front-end
        .iob_valid_i (iob_valid_i),
        .iob_addr_i  (iob_addr_i),
        .iob_wdata_i (iob_wdata_i),
        .iob_wstrb_i (iob_wstrb_i),
        .iob_rvalid_o(iob_rvalid_o),
        .iob_rdata_o (iob_rdata_o),
        .iob_ready_o (iob_ready_o),
        //invalidate / wtb empty
        .invalidate_i(1'b0),
        .invalidate_o(invalidate_o),
        .wtb_empty_i (1'b1),
        .wtb_empty_o (wtb_empty_o),
        //back-end
        .be_valid_o (be_valid),
        .be_addr_o  (be_addr),
        .be_wdata_o (be_wdata),
        .be_wstrb_o (be_wstrb),
        .be_rdata_i (be_rdata),
        .be_rvalid_i(be_rvalid),
        .be_ready_i (be_ready),

        .clk_i (clk_i),
        .cke_i (cke_i),
        .arst_i(arst_i)
    );

    vec_ram ram (
        .clk_i (clk_i),
        .en_i  (be_valid),
        .we_i  (be_wstrb),
        .addr_i(be_addr),
        .d_o   (be_rdata),
        .d_i   (be_wdata)
    );

    assign be_ready = 1'b1;
    iob_reg_re #(
      .DATA_W (1),
      .RST_VAL(0)
    ) iob_reg_rvalid (
        .clk_i (clk_i),
        .arst_i(arst_i),
        .cke_i (cke_i),
        .rst_i (1'b0),
        .en_i  (1'b1),
        .data_i(be_valid & (~(|be_wstrb))),
        .data_o(be_rvalid)
    );

endmodule




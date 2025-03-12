// SPDX-FileCopyrightText: 2024 IObundle
//
// SPDX-License-Identifier: MIT

`timescale 1ns / 1ps

`include "iob_cache_csrs_def.vh"
`include "iob_cache_conf.vh"

module iob_cache_sim_wrapper #(
   parameter                ADDR_W        = `IOB_CACHE_ADDR_W,
   parameter                DATA_W        = `IOB_CACHE_DATA_W,
   parameter                FE_ADDR_W     = `IOB_CACHE_FE_ADDR_W,
   parameter                FE_DATA_W     = `IOB_CACHE_FE_DATA_W,
   parameter                FE_NBYTES     = FE_DATA_W / 8,
   parameter                FE_NBYTES_W   = $clog2(FE_NBYTES),
   parameter                BE_ADDR_W     = `IOB_CACHE_BE_ADDR_W,
   parameter                BE_DATA_W     = `IOB_CACHE_BE_DATA_W,
   parameter                BE_NBYTES     = BE_DATA_W / 8,
   parameter                BE_NBYTES_W   = $clog2(BE_NBYTES),
   parameter                NWAYS_W       = `IOB_CACHE_NWAYS_W,
   parameter                NLINES_W      = `IOB_CACHE_NLINES_W,
   parameter                WORD_OFFSET_W = `IOB_CACHE_WORD_OFFSET_W,
   parameter                WTBUF_DEPTH_W = `IOB_CACHE_WTBUF_DEPTH_W,
   parameter                REP_POLICY    = `IOB_CACHE_REP_POLICY,
   parameter                WRITE_POL     = `IOB_CACHE_WRITE_THROUGH,
`ifdef IOB_CACHE_AXI
   parameter                AXI_ID_W      = `IOB_CACHE_AXI_ID_W,
   parameter [AXI_ID_W-1:0] AXI_ID        = `IOB_CACHE_AXI_ID,
   parameter                AXI_LEN_W     = `IOB_CACHE_AXI_LEN_W,
   parameter                AXI_ADDR_W    = BE_ADDR_W,
   parameter                AXI_DATA_W    = BE_DATA_W,
`endif
   parameter                USE_CTRL      = `IOB_CACHE_USE_CTRL,
   parameter                USE_CTRL_CNT  = `IOB_CACHE_USE_CTRL_CNT
) (
   // Front-end interface (IOb native slave)
   input  [                             1-1:0] iob_valid_i,
   input  [USE_CTRL+FE_ADDR_W-FE_NBYTES_W-1:0] iob_addr_i,
   input  [                        DATA_W-1:0] iob_wdata_i,
   input  [                     FE_NBYTES-1:0] iob_wstrb_i,
   output [                        DATA_W-1:0] iob_rdata_o,
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

   wire cke_i;
   assign cke_i = 1'b1;

`ifdef IOB_CACHE_AXI
   wire [  AXI_ADDR_W-1:0] axi_araddr;
   wire [           3-1:0] axi_arprot;
   wire [           1-1:0] axi_arvalid;
   wire [           1-1:0] axi_arready;
   wire [  AXI_DATA_W-1:0] axi_rdata;
   wire [           2-1:0] axi_rresp;
   wire [           1-1:0] axi_rvalid;
   wire [           1-1:0] axi_rready;
   wire [    AXI_ID_W-1:0] axi_arid;
   wire [   AXI_LEN_W-1:0] axi_arlen;
   wire [           3-1:0] axi_arsize;
   wire [           2-1:0] axi_arburst;
   wire [           2-1:0] axi_arlock;
   wire [           4-1:0] axi_arcache;
   wire [           4-1:0] axi_arqos;
   wire [    AXI_ID_W-1:0] axi_rid;
   wire [           1-1:0] axi_rlast;
   wire [  AXI_ADDR_W-1:0] axi_awaddr;
   wire [           3-1:0] axi_awprot;
   wire [           1-1:0] axi_awvalid;
   wire [           1-1:0] axi_awready;
   wire [  AXI_DATA_W-1:0] axi_wdata;
   wire [AXI_DATA_W/8-1:0] axi_wstrb;
   wire [           1-1:0] axi_wvalid;
   wire [           1-1:0] axi_wready;
   wire [           2-1:0] axi_bresp;
   wire [           1-1:0] axi_bvalid;
   wire [           1-1:0] axi_bready;
   wire [    AXI_ID_W-1:0] axi_awid;
   wire [   AXI_LEN_W-1:0] axi_awlen;
   wire [           3-1:0] axi_awsize;
   wire [           2-1:0] axi_awburst;
   wire [           2-1:0] axi_awlock;
   wire [           4-1:0] axi_awcache;
   wire [           4-1:0] axi_awqos;
   wire [           1-1:0] axi_wlast;
   wire [    AXI_ID_W-1:0] axi_bid;

   iob_cache_axi cache (
      //front-end
      .iob_valid_i  (iob_valid_i),
      .iob_addr_i   (iob_addr_i),
      .iob_wdata_i  (iob_wdata_i),
      .iob_wstrb_i  (iob_wstrb_i),
      .iob_rvalid_o (iob_rvalid_o),
      .iob_rdata_o  (iob_rdata_o),
      .iob_ready_o  (iob_ready_o),
      //invalidate / wtb empty
      .invalidate_i (1'b0),
      .invalidate_o (invalidate_o),
      .wtb_empty_i  (1'b1),
      .wtb_empty_o  (wtb_empty_o),
      .axi_araddr_o (axi_araddr),
      .axi_arprot_o (axi_arprot),
      .axi_arvalid_o(axi_arvalid),
      .axi_arready_i(axi_arready),
      .axi_rdata_i  (axi_rdata),
      .axi_rresp_i  (axi_rresp),
      .axi_rvalid_i (axi_rvalid),
      .axi_rready_o (axi_rready),
      .axi_arid_o   (axi_arid),
      .axi_arlen_o  (axi_arlen),
      .axi_arsize_o (axi_arsize),
      .axi_arburst_o(axi_arburst),
      .axi_arlock_o (axi_arlock),
      .axi_arcache_o(axi_arcache),
      .axi_arqos_o  (axi_arqos),
      .axi_rid_i    (axi_rid),
      .axi_rlast_i  (axi_rlast),
      .axi_awaddr_o (axi_awaddr),
      .axi_awprot_o (axi_awprot),
      .axi_awvalid_o(axi_awvalid),
      .axi_awready_i(axi_awready),
      .axi_wdata_o  (axi_wdata),
      .axi_wstrb_o  (axi_wstrb),
      .axi_wvalid_o (axi_wvalid),
      .axi_wready_i (axi_wready),
      .axi_bresp_i  (axi_bresp),
      .axi_bvalid_i (axi_bvalid),
      .axi_bready_o (axi_bready),
      .axi_awid_o   (axi_awid),
      .axi_awlen_o  (axi_awlen),
      .axi_awsize_o (axi_awsize),
      .axi_awburst_o(axi_awburst),
      .axi_awlock_o (axi_awlock),
      .axi_awcache_o(axi_awcache),
      .axi_awqos_o  (axi_awqos),
      .axi_wlast_o  (axi_wlast),
      .axi_bid_i    (axi_bid),
      .clk_i        (clk_i),
      .cke_i        (cke_i),
      .arst_i       (arst_i)
   );
`else
   wire                   be_valid;
   wire [  BE_ADDR_W-1:0] be_addr;
   wire [  BE_DATA_W-1:0] be_wdata;
   wire [BE_DATA_W/8-1:0] be_wstrb;
   wire [  BE_DATA_W-1:0] be_rdata;
   wire                   be_rvalid;
   wire                   be_ready;

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
`endif

`ifdef IOB_CACHE_AXI
   iob_axi_ram #(
      .ID_WIDTH  (AXI_ID_W),
      .LEN_WIDTH (AXI_LEN_W),
      .DATA_WIDTH(BE_DATA_W),
      .ADDR_WIDTH(BE_ADDR_W)
   ) axi_ram (
      .axi_araddr_i (axi_araddr),
      .axi_arprot_i (axi_arprot),
      .axi_arvalid_i(axi_arvalid),
      .axi_arready_o(axi_arready),
      .axi_rdata_o  (axi_rdata),
      .axi_rresp_o  (axi_rresp),
      .axi_rvalid_o (axi_rvalid),
      .axi_rready_i (axi_rready),
      .axi_arid_i   (axi_arid),
      .axi_arlen_i  (axi_arlen),
      .axi_arsize_i (axi_arsize),
      .axi_arburst_i(axi_arburst),
      .axi_arlock_i (axi_arlock),
      .axi_arcache_i(axi_arcache),
      .axi_arqos_i  (axi_arqos),
      .axi_rid_o    (axi_rid),
      .axi_rlast_o  (axi_rlast),
      .axi_awaddr_i (axi_awaddr),
      .axi_awprot_i (axi_awprot),
      .axi_awvalid_i(axi_awvalid),
      .axi_awready_o(axi_awready),
      .axi_wdata_i  (axi_wdata),
      .axi_wstrb_i  (axi_wstrb),
      .axi_wvalid_i (axi_wvalid),
      .axi_wready_o (axi_wready),
      .axi_bresp_o  (axi_bresp),
      .axi_bvalid_o (axi_bvalid),
      .axi_bready_i (axi_bready),
      .axi_awid_i   (axi_awid),
      .axi_awlen_i  (axi_awlen),
      .axi_awsize_i (axi_awsize),
      .axi_awburst_i(axi_awburst),
      .axi_awlock_i (axi_awlock),
      .axi_awcache_i(axi_awcache),
      .axi_awqos_i  (axi_awqos),
      .axi_wlast_i  (axi_wlast),
      .axi_bid_o    (axi_bid),
      .clk_i        (clk_i),
      .rst_i        (arst_i)
   );
`else
   iob_ram_sp_be #(
      .DATA_W(BE_DATA_W),
      .ADDR_W(BE_ADDR_W)
   ) native_ram (
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
`endif

endmodule

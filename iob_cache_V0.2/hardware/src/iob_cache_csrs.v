`timescale 1ns / 1ps
`include "iob_bsp.vh"
`include "iob_cache_csrs_conf.vh"

module iob_cache_csrs #(
   parameter ADDR_W        = `IOB_CACHE_CSRS_ADDR_W,
   parameter DATA_W        = `IOB_CACHE_CSRS_DATA_W,
   parameter FE_ADDR_W     = `IOB_CACHE_CSRS_FE_ADDR_W,
   parameter FE_DATA_W     = `IOB_CACHE_CSRS_FE_DATA_W,
   parameter BE_ADDR_W     = `IOB_CACHE_CSRS_BE_ADDR_W,
   parameter BE_DATA_W     = `IOB_CACHE_CSRS_BE_DATA_W,
   parameter NWAYS_W       = `IOB_CACHE_CSRS_NWAYS_W,
   parameter NLINES_W      = `IOB_CACHE_CSRS_NLINES_W,
   parameter WORD_OFFSET_W = `IOB_CACHE_CSRS_WORD_OFFSET_W,
   parameter WTBUF_DEPTH_W = `IOB_CACHE_CSRS_WTBUF_DEPTH_W,
   parameter REP_POLICY    = `IOB_CACHE_CSRS_REP_POLICY,
   parameter WRITE_POL     = `IOB_CACHE_CSRS_WRITE_POL,
   parameter USE_CTRL      = `IOB_CACHE_CSRS_USE_CTRL,
   parameter USE_CTRL_CNT  = `IOB_CACHE_CSRS_USE_CTRL_CNT
) (
   // clk_en_rst_s
   input                   clk_i,
   input                   cke_i,
   input                   arst_i,
   // control_if_s
   input                   iob_valid_i,
   input  [ADDR_W - 2-1:0] iob_addr_i,
   input  [    DATA_W-1:0] iob_wdata_i,
   input  [  DATA_W/8-1:0] iob_wstrb_i,
   output                  iob_rvalid_o,
   output [    DATA_W-1:0] iob_rdata_o,
   output                  iob_ready_o,
   // WTB_EMPTY_io
   input                   WTB_EMPTY_rdata_i,
   input                   WTB_EMPTY_rvalid_i,
   output                  WTB_EMPTY_ren_o,
   input                   WTB_EMPTY_rready_i,
   // WTB_FULL_io
   input                   WTB_FULL_rdata_i,
   input                   WTB_FULL_rvalid_i,
   output                  WTB_FULL_ren_o,
   input                   WTB_FULL_rready_i,
   // RW_HIT_io
   input  [        32-1:0] RW_HIT_rdata_i,
   input                   RW_HIT_rvalid_i,
   output                  RW_HIT_ren_o,
   input                   RW_HIT_rready_i,
   // RW_MISS_io
   input  [        32-1:0] RW_MISS_rdata_i,
   input                   RW_MISS_rvalid_i,
   output                  RW_MISS_ren_o,
   input                   RW_MISS_rready_i,
   // READ_HIT_io
   input  [        32-1:0] READ_HIT_rdata_i,
   input                   READ_HIT_rvalid_i,
   output                  READ_HIT_ren_o,
   input                   READ_HIT_rready_i,
   // READ_MISS_io
   input  [        32-1:0] READ_MISS_rdata_i,
   input                   READ_MISS_rvalid_i,
   output                  READ_MISS_ren_o,
   input                   READ_MISS_rready_i,
   // WRITE_HIT_io
   input  [        32-1:0] WRITE_HIT_rdata_i,
   input                   WRITE_HIT_rvalid_i,
   output                  WRITE_HIT_ren_o,
   input                   WRITE_HIT_rready_i,
   // WRITE_MISS_io
   input  [        32-1:0] WRITE_MISS_rdata_i,
   input                   WRITE_MISS_rvalid_i,
   output                  WRITE_MISS_ren_o,
   input                   WRITE_MISS_rready_i,
   // RST_CNTRS_io
   output                  RST_CNTRS_wdata_o,
   output                  RST_CNTRS_wen_o,
   input                   RST_CNTRS_wready_i,
   // INVALIDATE_io
   output                  INVALIDATE_wdata_o,
   output                  INVALIDATE_wen_o,
   input                   INVALIDATE_wready_i
);
   // internal_iob
   wire                internal_iob_valid;
   wire [  ADDR_W-1:0] internal_iob_addr;
   wire [  DATA_W-1:0] internal_iob_wdata;
   wire [DATA_W/8-1:0] internal_iob_wstrb;
   wire                internal_iob_rvalid;
   wire [  DATA_W-1:0] internal_iob_rdata;
   wire                internal_iob_ready;
   // state
   wire                state;
   // state_nxt
   reg                 state_nxt;
   // internal_iob_addr_stable
   wire [  ADDR_W-1:0] internal_iob_addr_stable;
   // internal_iob_addr_reg
   wire [  ADDR_W-1:0] internal_iob_addr_reg;
   // internal_iob_addr_reg_en
   wire                internal_iob_addr_reg_en;
   // RST_CNTRS_wdata
   wire                RST_CNTRS_wdata;
   // INVALIDATE_wdata
   wire                INVALIDATE_wdata;
   // rvalid
   wire                rvalid;
   // rvalid_nxt
   reg                 rvalid_nxt;
   // rdata
   wire [      32-1:0] rdata;
   // rdata_nxt
   reg  [      32-1:0] rdata_nxt;
   // ready
   wire                ready;
   // ready_nxt
   reg                 ready_nxt;
   // rvalid_int
   reg                 rvalid_int;
   // wready_int
   reg                 wready_int;
   // rready_int
   reg                 rready_int;
   // iob_addr_i_0_0
   reg                 iob_addr_i_0_0;
   // iob_addr_i_0_8
   reg                 iob_addr_i_0_8;
   // iob_addr_i_4_0
   reg                 iob_addr_i_4_0;
   // iob_addr_i_8_0
   reg                 iob_addr_i_8_0;
   // iob_addr_i_12_0
   reg                 iob_addr_i_12_0;
   // iob_addr_i_16_0
   reg                 iob_addr_i_16_0;
   // iob_addr_i_20_0
   reg                 iob_addr_i_20_0;
   // iob_addr_i_24_0
   reg                 iob_addr_i_24_0;
   // iob_addr_i_28_16
   reg                 iob_addr_i_28_16;


   // store iob addr
   iob_reg_e #(
      .DATA_W (ADDR_W),
      .RST_VAL('b0)
   ) internal_addr_reg (
      // clk_en_rst_s port
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // en_i port
      .en_i  (internal_iob_addr_reg_en),
      // data_i port
      .data_i(internal_iob_addr),
      // data_o port
      .data_o(internal_iob_addr_reg)
   );

   // state register
   iob_reg #(
      .DATA_W (1),
      .RST_VAL(1'b0)
   ) state_reg (
      // clk_en_rst_s port
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port
      .data_i(state_nxt),
      // data_o port
      .data_o(state)
   );

   // rvalid register
   iob_reg #(
      .DATA_W (1),
      .RST_VAL(1'b0)
   ) rvalid_reg (
      // clk_en_rst_s port
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port
      .data_i(rvalid_nxt),
      // data_o port
      .data_o(rvalid)
   );

   // rdata register
   iob_reg #(
      .DATA_W (32),
      .RST_VAL(1'b0)
   ) rdata_reg (
      // clk_en_rst_s port
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port
      .data_i(rdata_nxt),
      // data_o port
      .data_o(rdata)
   );

   // ready register
   iob_reg #(
      .DATA_W (1),
      .RST_VAL(1'b0)
   ) ready_reg (
      // clk_en_rst_s port
      .clk_i (clk_i),
      .cke_i (cke_i),
      .arst_i(arst_i),
      // data_i port
      .data_i(ready_nxt),
      // data_o port
      .data_o(ready)
   );




   `define IOB_NBYTES (DATA_W/8)
   `define IOB_NBYTES_W $clog2(`IOB_NBYTES)
   `define IOB_WORD_ADDR(ADDR) ((ADDR>>`IOB_NBYTES_W)<<`IOB_NBYTES_W)


   localparam WSTRB_W = DATA_W / 8;

   //FSM states
   localparam WAIT_REQ = 1'd0;
   localparam WAIT_RVALID = 1'd1;

   assign internal_iob_addr_reg_en = (state == WAIT_REQ);
   assign internal_iob_addr_stable = (state == WAIT_RVALID) ? internal_iob_addr_reg : internal_iob_addr;

   assign internal_iob_valid = iob_valid_i;
   assign internal_iob_addr = {iob_addr_i, 2'b0};
   assign internal_iob_wdata = iob_wdata_i;
   assign internal_iob_wstrb = iob_wstrb_i;
   assign iob_rvalid_o = internal_iob_rvalid;
   assign iob_rdata_o = internal_iob_rdata;
   assign iob_ready_o = internal_iob_ready;

   //write address
   wire [($clog2(WSTRB_W)+1)-1:0] byte_offset;
   iob_ctls #(
      .W     (WSTRB_W),
      .MODE  (0),
      .SYMBOL(0)
   ) bo_inst (
      .data_i (internal_iob_wstrb),
      .count_o(byte_offset)
   );
   wire [ADDR_W-1:0] waddr;
   assign waddr           = `IOB_WORD_ADDR(internal_iob_addr_stable) + byte_offset;


   //NAME: RST_CNTRS;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 28; SPACE (bytes): 1 (max); AUTO: False

   assign RST_CNTRS_wdata = internal_iob_wdata[0+:1];
   wire RST_CNTRS_addressed_w;
   assign RST_CNTRS_addressed_w = (waddr >= 28) && (waddr < 29);
   assign RST_CNTRS_wen_o = (RST_CNTRS_addressed_w & (internal_iob_valid & internal_iob_ready))? |internal_iob_wstrb: 1'b0;
   assign RST_CNTRS_wdata_o = RST_CNTRS_wdata;


   //NAME: INVALIDATE;
   //TYPE: W; WIDTH: 1; RST_VAL: 0; ADDR: 29; SPACE (bytes): 1 (max); AUTO: False

   assign INVALIDATE_wdata = internal_iob_wdata[8+:1];
   wire INVALIDATE_addressed_w;
   assign INVALIDATE_addressed_w = (waddr >= 29) && (waddr < 30);
   assign INVALIDATE_wen_o = (INVALIDATE_addressed_w & (internal_iob_valid & internal_iob_ready))? |internal_iob_wstrb: 1'b0;
   assign INVALIDATE_wdata_o = INVALIDATE_wdata;


   //NAME: WTB_EMPTY;
   //TYPE: R; WIDTH: 1; RST_VAL: 0; ADDR: 0; SPACE (bytes): 1 (max); AUTO: False

   wire WTB_EMPTY_addressed_r;
   assign WTB_EMPTY_addressed_r = (internal_iob_addr_stable >= 0) && (internal_iob_addr_stable < (0+(2**(0))));
   assign WTB_EMPTY_ren_o = WTB_EMPTY_addressed_r & (internal_iob_valid & internal_iob_ready) & (~|internal_iob_wstrb);


   //NAME: WTB_FULL;
   //TYPE: R; WIDTH: 1; RST_VAL: 0; ADDR: 1; SPACE (bytes): 1 (max); AUTO: False

   wire WTB_FULL_addressed_r;
   assign WTB_FULL_addressed_r = (internal_iob_addr_stable >= 1) && (internal_iob_addr_stable < (1+(2**(0))));
   assign WTB_FULL_ren_o = WTB_FULL_addressed_r & (internal_iob_valid & internal_iob_ready) & (~|internal_iob_wstrb);


   //NAME: RW_HIT;
   //TYPE: R; WIDTH: 32; RST_VAL: 0; ADDR: 4; SPACE (bytes): 4 (max); AUTO: False

   wire RW_HIT_addressed_r;
   assign RW_HIT_addressed_r = (internal_iob_addr_stable >= 4) && (internal_iob_addr_stable < (4+(2**(2))));
   assign RW_HIT_ren_o = RW_HIT_addressed_r & (internal_iob_valid & internal_iob_ready) & (~|internal_iob_wstrb);


   //NAME: RW_MISS;
   //TYPE: R; WIDTH: 32; RST_VAL: 0; ADDR: 8; SPACE (bytes): 4 (max); AUTO: False

   wire RW_MISS_addressed_r;
   assign RW_MISS_addressed_r = (internal_iob_addr_stable >= 8) && (internal_iob_addr_stable < (8+(2**(2))));
   assign RW_MISS_ren_o = RW_MISS_addressed_r & (internal_iob_valid & internal_iob_ready) & (~|internal_iob_wstrb);


   //NAME: READ_HIT;
   //TYPE: R; WIDTH: 32; RST_VAL: 0; ADDR: 12; SPACE (bytes): 4 (max); AUTO: False

   wire READ_HIT_addressed_r;
   assign READ_HIT_addressed_r = (internal_iob_addr_stable >= 12) && (internal_iob_addr_stable < (12+(2**(2))));
   assign READ_HIT_ren_o = READ_HIT_addressed_r & (internal_iob_valid & internal_iob_ready) & (~|internal_iob_wstrb);


   //NAME: READ_MISS;
   //TYPE: R; WIDTH: 32; RST_VAL: 0; ADDR: 16; SPACE (bytes): 4 (max); AUTO: False

   wire READ_MISS_addressed_r;
   assign READ_MISS_addressed_r = (internal_iob_addr_stable >= 16) && (internal_iob_addr_stable < (16+(2**(2))));
   assign READ_MISS_ren_o = READ_MISS_addressed_r & (internal_iob_valid & internal_iob_ready) & (~|internal_iob_wstrb);


   //NAME: WRITE_HIT;
   //TYPE: R; WIDTH: 32; RST_VAL: 0; ADDR: 20; SPACE (bytes): 4 (max); AUTO: False

   wire WRITE_HIT_addressed_r;
   assign WRITE_HIT_addressed_r = (internal_iob_addr_stable >= 20) && (internal_iob_addr_stable < (20+(2**(2))));
   assign WRITE_HIT_ren_o = WRITE_HIT_addressed_r & (internal_iob_valid & internal_iob_ready) & (~|internal_iob_wstrb);


   //NAME: WRITE_MISS;
   //TYPE: R; WIDTH: 32; RST_VAL: 0; ADDR: 24; SPACE (bytes): 4 (max); AUTO: False

   wire WRITE_MISS_addressed_r;
   assign WRITE_MISS_addressed_r = (internal_iob_addr_stable >= 24) && (internal_iob_addr_stable < (24+(2**(2))));
   assign WRITE_MISS_ren_o = WRITE_MISS_addressed_r & (internal_iob_valid & internal_iob_ready) & (~|internal_iob_wstrb);


   //NAME: version;
   //TYPE: R; WIDTH: 16; RST_VAL: 0002; ADDR: 30; SPACE (bytes): 2 (max); AUTO: True



   //RESPONSE SWITCH


   assign internal_iob_rvalid = rvalid;
   assign internal_iob_rdata = rdata;
   assign internal_iob_ready = ready;


   always @* begin
      rdata_nxt      = 32'd0;
      rvalid_int     = (internal_iob_valid & internal_iob_ready) & (~(|internal_iob_wstrb));
      rready_int     = 1'b1;
      wready_int     = 1'b1;

      iob_addr_i_0_0 = (`IOB_WORD_ADDR(internal_iob_addr_stable) == 0);
      if (iob_addr_i_0_0) begin

         rdata_nxt[0+:8] = WTB_EMPTY_rdata_i | 8'd0;
         rvalid_int      = WTB_EMPTY_rvalid_i;
         rready_int      = WTB_EMPTY_rready_i;
      end

      iob_addr_i_0_8 = (`IOB_WORD_ADDR(internal_iob_addr_stable) == 0);
      if (iob_addr_i_0_8) begin

         rdata_nxt[8+:8] = WTB_FULL_rdata_i | 8'd0;
         rvalid_int      = WTB_FULL_rvalid_i;
         rready_int      = WTB_FULL_rready_i;
      end

      iob_addr_i_4_0 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 4) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 8));
      if (iob_addr_i_4_0) begin

         rdata_nxt[0+:32] = RW_HIT_rdata_i | 32'd0;
         rvalid_int       = RW_HIT_rvalid_i;
         rready_int       = RW_HIT_rready_i;
      end

      iob_addr_i_8_0 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 8) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 12));
      if (iob_addr_i_8_0) begin

         rdata_nxt[0+:32] = RW_MISS_rdata_i | 32'd0;
         rvalid_int       = RW_MISS_rvalid_i;
         rready_int       = RW_MISS_rready_i;
      end

      iob_addr_i_12_0 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 12) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 16));
      if (iob_addr_i_12_0) begin

         rdata_nxt[0+:32] = READ_HIT_rdata_i | 32'd0;
         rvalid_int       = READ_HIT_rvalid_i;
         rready_int       = READ_HIT_rready_i;
      end

      iob_addr_i_16_0 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 16) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 20));
      if (iob_addr_i_16_0) begin

         rdata_nxt[0+:32] = READ_MISS_rdata_i | 32'd0;
         rvalid_int       = READ_MISS_rvalid_i;
         rready_int       = READ_MISS_rready_i;
      end

      iob_addr_i_20_0 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 20) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 24));
      if (iob_addr_i_20_0) begin

         rdata_nxt[0+:32] = WRITE_HIT_rdata_i | 32'd0;
         rvalid_int       = WRITE_HIT_rvalid_i;
         rready_int       = WRITE_HIT_rready_i;
      end

      iob_addr_i_24_0 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 24) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 28));
      if (iob_addr_i_24_0) begin

         rdata_nxt[0+:32] = WRITE_MISS_rdata_i | 32'd0;
         rvalid_int       = WRITE_MISS_rvalid_i;
         rready_int       = WRITE_MISS_rready_i;
      end

      iob_addr_i_28_16 = ((
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      >= 28) && (
      `IOB_WORD_ADDR(internal_iob_addr_stable)
      < 32));
      if (iob_addr_i_28_16) begin
         rdata_nxt[16+:16] = 16'h0002 | 16'd0;
      end

      if ((waddr >= 28) && (waddr < 29)) begin
         wready_int = RST_CNTRS_wready_i;
      end
      if ((waddr >= 29) && (waddr < 30)) begin
         wready_int = INVALIDATE_wready_i;
      end


      // ######  FSM  #############

      //FSM default values
      ready_nxt  = 1'b0;
      rvalid_nxt = 1'b0;
      state_nxt  = state;

      //FSM state machine
      case (state)
         WAIT_REQ: begin
            if (internal_iob_valid & (!internal_iob_ready)) begin  // Wait for a valid request
               ready_nxt = |internal_iob_wstrb ? wready_int : rready_int;
               // If is read and ready, go to WAIT_RVALID
               if (ready_nxt && (!(|internal_iob_wstrb))) begin
                  state_nxt = WAIT_RVALID;
               end
            end
         end

         default: begin  // WAIT_RVALID
            if (rvalid_int) begin
               rvalid_nxt = 1'b1;
               state_nxt  = WAIT_REQ;
            end
         end
      endcase

   end  //always @*





endmodule

`include "iob_cache_csrs_conf.vh"
//These macros may be dependent on instance parameters
//address macros
//addresses
`define IOB_CACHE_WTB_EMPTY_ADDR 0
`define IOB_CACHE_WTB_EMPTY_W 1

`define IOB_CACHE_WTB_FULL_ADDR 1
`define IOB_CACHE_WTB_FULL_W 1

`define IOB_CACHE_RW_HIT_ADDR 4
`define IOB_CACHE_RW_HIT_W 32

`define IOB_CACHE_RW_MISS_ADDR 8
`define IOB_CACHE_RW_MISS_W 32

`define IOB_CACHE_READ_HIT_ADDR 12
`define IOB_CACHE_READ_HIT_W 32

`define IOB_CACHE_READ_MISS_ADDR 16
`define IOB_CACHE_READ_MISS_W 32

`define IOB_CACHE_WRITE_HIT_ADDR 20
`define IOB_CACHE_WRITE_HIT_W 32

`define IOB_CACHE_WRITE_MISS_ADDR 24
`define IOB_CACHE_WRITE_MISS_W 32

`define IOB_CACHE_RST_CNTRS_ADDR 28
`define IOB_CACHE_RST_CNTRS_W 1

`define IOB_CACHE_INVALIDATE_ADDR 29
`define IOB_CACHE_INVALIDATE_W 1

`define IOB_CACHE_VERSION_ADDR 30
`define IOB_CACHE_VERSION_W 16


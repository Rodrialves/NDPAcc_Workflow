#ifndef H_IOB_CACHE_CSRS_VERILATOR_H
#define H_IOB_CACHE_CSRS_VERILATOR_H

#include <stdint.h>

#include "iob_tasks.h"

// used address space width
#define IOB_CACHE_CSRS_ADDR_W 5

// used address space width
#define IOB_CACHE_CSRS_ADDR_W 5

// Addresses
#define IOB_CACHE_WTB_EMPTY_ADDR 0
#define IOB_CACHE_WTB_FULL_ADDR 1
#define IOB_CACHE_RW_HIT_ADDR 4
#define IOB_CACHE_RW_MISS_ADDR 8
#define IOB_CACHE_READ_HIT_ADDR 12
#define IOB_CACHE_READ_MISS_ADDR 16
#define IOB_CACHE_WRITE_HIT_ADDR 20
#define IOB_CACHE_WRITE_MISS_ADDR 24
#define IOB_CACHE_RST_CNTRS_ADDR 28
#define IOB_CACHE_INVALIDATE_ADDR 29
#define IOB_CACHE_VERSION_ADDR 30

// Data widths (bit)
#define IOB_CACHE_WTB_EMPTY_W 8
#define IOB_CACHE_WTB_FULL_W 8
#define IOB_CACHE_RW_HIT_W 32
#define IOB_CACHE_RW_MISS_W 32
#define IOB_CACHE_READ_HIT_W 32
#define IOB_CACHE_READ_MISS_W 32
#define IOB_CACHE_WRITE_HIT_W 32
#define IOB_CACHE_WRITE_MISS_W 32
#define IOB_CACHE_RST_CNTRS_W 8
#define IOB_CACHE_INVALIDATE_W 8
#define IOB_CACHE_VERSION_W 16

// Core Setters and Getters
uint8_t IOB_CACHE_GET_WTB_EMPTY(iob_native_t *native_if);
uint8_t IOB_CACHE_GET_WTB_FULL(iob_native_t *native_if);
uint32_t IOB_CACHE_GET_RW_HIT(iob_native_t *native_if);
uint32_t IOB_CACHE_GET_RW_MISS(iob_native_t *native_if);
uint32_t IOB_CACHE_GET_READ_HIT(iob_native_t *native_if);
uint32_t IOB_CACHE_GET_READ_MISS(iob_native_t *native_if);
uint32_t IOB_CACHE_GET_WRITE_HIT(iob_native_t *native_if);
uint32_t IOB_CACHE_GET_WRITE_MISS(iob_native_t *native_if);
void IOB_CACHE_SET_RST_CNTRS(uint8_t value, iob_native_t *native_if);
void IOB_CACHE_SET_INVALIDATE(uint8_t value, iob_native_t *native_if);
uint16_t IOB_CACHE_GET_VERSION(iob_native_t *native_if);

#endif // H_IOB_CACHE__CSRS_VERILATOR_H

#include "iob_cache_csrs_verilator.h"

// Core Setters and Getters
uint8_t IOB_CACHE_GET_WTB_EMPTY(iob_native_t *native_if) {
  return (uint8_t)iob_read((IOB_CACHE_WTB_EMPTY_ADDR), native_if);
}

uint8_t IOB_CACHE_GET_WTB_FULL(iob_native_t *native_if) {
  return (uint8_t)iob_read((IOB_CACHE_WTB_FULL_ADDR), native_if);
}

uint32_t IOB_CACHE_GET_RW_HIT(iob_native_t *native_if) {
  return (uint32_t)iob_read((IOB_CACHE_RW_HIT_ADDR), native_if);
}

uint32_t IOB_CACHE_GET_RW_MISS(iob_native_t *native_if) {
  return (uint32_t)iob_read((IOB_CACHE_RW_MISS_ADDR), native_if);
}

uint32_t IOB_CACHE_GET_READ_HIT(iob_native_t *native_if) {
  return (uint32_t)iob_read((IOB_CACHE_READ_HIT_ADDR), native_if);
}

uint32_t IOB_CACHE_GET_READ_MISS(iob_native_t *native_if) {
  return (uint32_t)iob_read((IOB_CACHE_READ_MISS_ADDR), native_if);
}

uint32_t IOB_CACHE_GET_WRITE_HIT(iob_native_t *native_if) {
  return (uint32_t)iob_read((IOB_CACHE_WRITE_HIT_ADDR), native_if);
}

uint32_t IOB_CACHE_GET_WRITE_MISS(iob_native_t *native_if) {
  return (uint32_t)iob_read((IOB_CACHE_WRITE_MISS_ADDR), native_if);
}

void IOB_CACHE_SET_RST_CNTRS(uint8_t value, iob_native_t *native_if) {
  iob_write((IOB_CACHE_RST_CNTRS_ADDR), value, IOB_CACHE_RST_CNTRS_W,
            native_if);
}

void IOB_CACHE_SET_INVALIDATE(uint8_t value, iob_native_t *native_if) {
  iob_write((IOB_CACHE_INVALIDATE_ADDR), value, IOB_CACHE_INVALIDATE_W,
            native_if);
}

uint16_t IOB_CACHE_GET_VERSION(iob_native_t *native_if) {
  return (uint16_t)iob_read((IOB_CACHE_VERSION_ADDR), native_if);
}

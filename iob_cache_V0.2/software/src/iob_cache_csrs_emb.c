#include "iob_cache_csrs.h"

// Base Address
static int base;
void IOB_CACHE_INIT_BASEADDR(uint32_t addr) { base = addr; }

// Core Setters and Getters
uint8_t IOB_CACHE_GET_WTB_EMPTY() {
  return (*((volatile uint8_t *)((base) + (IOB_CACHE_WTB_EMPTY_ADDR))));
}

uint8_t IOB_CACHE_GET_WTB_FULL() {
  return (*((volatile uint8_t *)((base) + (IOB_CACHE_WTB_FULL_ADDR))));
}

uint32_t IOB_CACHE_GET_RW_HIT() {
  return (*((volatile uint32_t *)((base) + (IOB_CACHE_RW_HIT_ADDR))));
}

uint32_t IOB_CACHE_GET_RW_MISS() {
  return (*((volatile uint32_t *)((base) + (IOB_CACHE_RW_MISS_ADDR))));
}

uint32_t IOB_CACHE_GET_READ_HIT() {
  return (*((volatile uint32_t *)((base) + (IOB_CACHE_READ_HIT_ADDR))));
}

uint32_t IOB_CACHE_GET_READ_MISS() {
  return (*((volatile uint32_t *)((base) + (IOB_CACHE_READ_MISS_ADDR))));
}

uint32_t IOB_CACHE_GET_WRITE_HIT() {
  return (*((volatile uint32_t *)((base) + (IOB_CACHE_WRITE_HIT_ADDR))));
}

uint32_t IOB_CACHE_GET_WRITE_MISS() {
  return (*((volatile uint32_t *)((base) + (IOB_CACHE_WRITE_MISS_ADDR))));
}

void IOB_CACHE_SET_RST_CNTRS(uint8_t value) {
  (*((volatile uint8_t *)((base) + (IOB_CACHE_RST_CNTRS_ADDR))) = (value));
}

void IOB_CACHE_SET_INVALIDATE(uint8_t value) {
  (*((volatile uint8_t *)((base) + (IOB_CACHE_INVALIDATE_ADDR))) = (value));
}

uint16_t IOB_CACHE_GET_VERSION() {
  return (*((volatile uint16_t *)((base) + (IOB_CACHE_VERSION_ADDR))));
}

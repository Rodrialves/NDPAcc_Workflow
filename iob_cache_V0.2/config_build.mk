NAME=iob_cache
CSR_IF ?=iob
BUILD_DIR_NAME=iob_cache_V0.2
IS_FPGA=0

CONFIG_BUILD_DIR = $(dir $(lastword $(MAKEFILE_LIST)))
ifneq ($(wildcard $(CONFIG_BUILD_DIR)/custom_config_build.mk),)
include $(CONFIG_BUILD_DIR)/custom_config_build.mk
endif

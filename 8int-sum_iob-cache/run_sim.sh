#!/bin/bash

# Define simulation version (update this manually for each iteration)
VERSION="v0.1"  # Change this for each new version (e.g., v2, v3, ...)

# Define filenames with versioning
SIM_OUT="full_system_tb_${VERSION}.out"
WAVE_FILE="wave_${VERSION}.vcd"
LOG_FILE="simout_${VERSION}.log"

#IOb-cache source folder
CACHE_LOCATION="../iob_cache_V0.2/"
SUM_LOCATION="../8int-sum/"
SIM_LOCATION="../iob_cache_V0.2/hardware/simulation/src/"
SRC_LOCATION="../iob_cache_V0.2/hardware/src/"


# Define source files
SRC_FILES="full_system_wrapper_tb.v full_system_wrapper.v ${SIM_LOCATION}iob_cache_sim_wrapper.v ${SUM_LOCATION}8int-sum.v ${SRC_LOCATION}iob_cache_iob.v ${SRC_LOCATION}iob_ram_sp_be.v ${SRC_LOCATION}iob_reg_re.v ${SRC_LOCATION}iob_cache_back_end.v ${SRC_LOCATION}iob_cache_front_end.v ${SRC_LOCATION}iob_cache_memory.v ${SRC_LOCATION}iob_reg_r.v ${SRC_LOCATION}iob_cache_onehot_to_bin.v ${SRC_LOCATION}iob_cache_read_channel.v ${SRC_LOCATION}iob_cache_replacement_policy.v ${SRC_LOCATION}iob_cache_write_channel.v ${SRC_LOCATION}iob_fifo_sync.v ${SRC_LOCATION}iob_ram_sp.v ${SRC_LOCATION}iob_ram_t2p.v ${SRC_LOCATION}iob_reg.v ${SRC_LOCATION}iob_asym_converter.v ${SRC_LOCATION}iob_counter.v ${SRC_LOCATION}iob_regfile_sp.v"

# Step 1: Compile the Verilog Files
echo "Compiling Verilog files..."
iverilog -I $SRC_LOCATION -I $SIM_LOCATION -o $SIM_OUT $SRC_FILES
if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

# Step 2: Run the Simulation and Append Output to Versioned Log
echo "Running simulation..."
echo "----------------------------" >> $LOG_FILE
echo "Simulation Run on $(date) - Version: $VERSION" >> $LOG_FILE
echo "----------------------------" >> $LOG_FILE
vvp $SIM_OUT | tee -a $LOG_FILE  # Append output instead of overwriting

# Step 3: Check if expected result (0x24) appears in the log
EXPECTED_RESULT="00000024"
if grep -q "$EXPECTED_RESULT" "$LOG_FILE"; then
    echo "✅ Test Passed: Expected sum ($EXPECTED_RESULT) found!" | tee -a $LOG_FILE
else
    echo "❌ Test Failed: Expected sum ($EXPECTED_RESULT) NOT found!" | tee -a $LOG_FILE
fi

# Step 4: Open GTKWave for visualization
echo "Opening GTKWave..."
gtkwave $WAVE_FILE &


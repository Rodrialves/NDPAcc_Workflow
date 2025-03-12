import yaml
import subprocess
import datetime
import sys
import os

# Load configuration from YAML file
CONFIG_FILE = "files.yaml"

try:
    with open(CONFIG_FILE, "r") as file:
        config = yaml.safe_load(file)
except FileNotFoundError:
    print(f"Error: {CONFIG_FILE} not found.")
    sys.exit(1)

# Extract variables
version = config["version"]
sim = config["sim_out"]
wave = config["wave_out"]
log = config["log_out"]
sim_out = f"{sim}_{version}.out"
wave_file = f"{wave}_{version}.vcd"
log_file = f"{log}_{version}.log"

cache_location = config["cache_location"]
sum_location = config["sum_location"]
sim_location = config["sim_location"]
src_location = config["src_location"]

src_files = " ".join(config["src_files"])  # Convert list to space-separated string

# Step 1: Compile the Verilog Files
print("Compiling Verilog files...")
compile_command = f"iverilog -I {src_location} -I {sim_location} -o {sim_out} {src_files}"
compilation = subprocess.run(compile_command, shell=True)

if compilation.returncode != 0:
    print("Compilation failed!")
    sys.exit(1)

# Step 2: Run the Simulation
print("Running simulation...")
timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
with open(log_file, "a") as log:
    log.write("----------------------------\n")
    log.write(f"Simulation Run on {timestamp} - Version: {version}\n")
    log.write("----------------------------\n")

with open(log_file, "a") as log:
    process = subprocess.Popen(f"vvp {sim_out}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    for line in iter(process.stdout.readline, b""):
        decoded_line = line.decode().strip()
        print(decoded_line)
        log.write(decoded_line + "\n")
    process.stdout.close()
    process.wait()

# Step 3: Check if expected result is found in the log
expected_result = "00000024"

with open(log_file, "r") as log:
    log_contents = log.read()

if expected_result in log_contents:
    print(f"✅ Test Passed: Expected sum ({expected_result}) found!")
    with open(log_file, "a") as log:
        log.write(f"✅ Test Passed: Expected sum ({expected_result}) found!\n")
else:
    print(f"❌ Test Failed: Expected sum ({expected_result}) NOT found!")
    with open(log_file, "a") as log:
        log.write(f"❌ Test Failed: Expected sum ({expected_result}) NOT found!\n")

# Step 4: Open GTKWave for visualization
print("Opening GTKWave...")
subprocess.Popen(f"gtkwave {wave_file}", shell=True)

import os
import subprocess
import shutil
import yaml
import argparse


# Configuration
YAML_FILE = "config.yaml"  # Name of the YAML configuration file
IVERILOG_CMD = "iverilog"  # Icarus Verilog compiler
VVP_CMD = "vvp"            # Icarus Verilog runtime
GTKWAVE_CMD = "gtkwave"    # GTKWave viewer

def check_tools():
    """Check if required tools (iverilog, vvp, gtkwave) are installed."""
    for tool in [IVERILOG_CMD, VVP_CMD, GTKWAVE_CMD]:
        if shutil.which(tool) is None:
            print(f"Error: {tool} is not installed or not in PATH.")
            exit(1)

def load_yaml_config(yaml_file):
    """Load the YAML configuration file."""
    with open(yaml_file, 'r') as file:
        config = yaml.safe_load(file)
    return config

def compile_verilog(src_files, sim_out, sim_location, src_location):
    """Compile the Verilog files into an executable using iverilog."""
    cmd = ["iverilog", "-I", sim_location, "-I", src_location, "-o", sim_out] + src_files.split()
    print(f"Compiling with command: {' '.join(cmd)}")
    try:
        subprocess.run(cmd, check=True)
        print(f"Compilation successful. Generated: {sim_out}")
    except subprocess.CalledProcessError as e:
        print(f"Compilation failed: {e}")
        exit(1)

def run_simulation(sim_out):
    """Run the simulation using vvp to generate the waveform file."""
    cmd = [VVP_CMD, sim_out]
    try:
        subprocess.run(cmd, check=True)
        print("Simulation completed.")
    except subprocess.CalledProcessError as e:
        print(f"Simulation failed: {e}")
        exit(1)

def open_gtkwave(wave_out):
    """Open GTKWave to view the waveform file."""
    waveform_file = f"{wave_out}.vcd"
    if os.path.exists(waveform_file):
        cmd = [GTKWAVE_CMD, waveform_file]
        try:
            subprocess.Popen(cmd)
            print(f"Opened GTKWave with {waveform_file}")
        except Exception as e:
            print(f"Failed to open GTKWave: {e}")
    else:
        print(f"Error: Waveform file {waveform_file} not found.")

def main():
    """Main function to orchestrate the simulation process."""
    parser = argparse.ArgumentParser(description="Run Verilog simulation with configurable source files.")
    parser.add_argument(
        "--source-set",
        nargs="+",
        choices=["fs_tb", "mem_tb", "loaded_mem_tb", "acc_tb", "ram_tb"],
        default=["fs_tb"],
        help="Choose which simulation to run (default: fs_tb)."
    )
    args = parser.parse_args()

    check_tools()
    config = load_yaml_config(YAML_FILE)
    sim_location = config['sim_location']
    src_location = config['src_location']

    # Combine source files from the selected sets
    if "fs_tb" in args.source_set:
        print("\n------------------------\nRunning full system testbench.\n------------------------\n")
        src_files = config['tb_files_top_module'] + config['IoB_files'] + config['ram_files'] + config['acc_files'] + config['ctrl_files']
        wave_out = config['wave_out_top_module']
        sim_out = config['sim_out_top_module']
    elif "mem_tb" in args.source_set:
        print("\n------------------------\nRunning memory testbench.\n------------------------\n")
        src_files = config['tb_files_mem_module'] + config['IoB_files'] + config['ram_files'] + config['acc_files']
        wave_out = config['wave_out_mem_module']
        sim_out = config['sim_out_mem_module']
    elif "loaded_mem_tb" in args.source_set:
        print("\n------------------------\nRunning loaded memory testbench.\n------------------------\n")
        src_files = config['tb_files_mem_loaded_module'] + config['ram_files'] + config['acc_files'] + config['IoB_files']
        wave_out = config['wave_out_mem_loaded_module']
        sim_out = config['sim_out_mem_loaded_module']
    elif "acc_tb" in args.source_set:
        print("\n------------------------\nRunning accelerator testbench.\n------------------------\n")
        src_files = config['tb_files_acc_module'] + config['acc_files']
        wave_out = config['wave_out_acc_module']
        sim_out = config['sim_out_acc_module']
    elif "ram_tb" in args.source_set:
        print("\n------------------------\nRunning RAM testbench.\n------------------------\n")
        src_files = config['tb_files_ram_module'] + config['ram_files']
        wave_out = config['wave_out_ram_module']
        sim_out = config['sim_out_ram_module']

    # Join all source files into a single string
    src_files_str = " ".join(src_files)

    compile_verilog(src_files_str, sim_out, sim_location, src_location)
    run_simulation(sim_out)
    open_gtkwave(wave_out)

if __name__ == "__main__":
    main()
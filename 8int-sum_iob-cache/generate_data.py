import random

# Seed for reproducibility (optional, remove for different values each run)
random.seed(42)

# Generate ram_init.mem with 1024 lines of random 256-bit values
with open("ram_init.mem", "w") as f:
    for _ in range(32768):  # 1024 locations
        # Generate a 256-bit (64 hex digit) random value
        # Each hex digit is 4 bits, so 64 digits = 256 bits
        random_value = ''.join(random.choices('0123456789abcdef', k=2))
        f.write(random_value + "\n")
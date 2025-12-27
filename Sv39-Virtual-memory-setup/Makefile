# Configuration
CC           = riscv64-unknown-elf-gcc
OBJDUMP      = riscv64-unknown-elf-objdump
CFLAGS       = -march=rv64g -mabi=lp64 -mcmodel=medany -nostdlib
LDFLAGS      = -T link.ld
SPIKE_FLAGS  = -m8796093022208 --isa=rv64gc -l --log-commits
SAIL_CONFIG  = config.json

# Files
SOURCE       = test.S
ELF_FILE     = test.elf
DISASM_FILE  = test.disass
# Default target
all: compile disasm

# Compile the test
compile: $(ELF_FILE)

$(ELF_FILE): $(SOURCE) link.ld
	@echo "Compiling $(SOURCE)..."
	$(CC) $(CFLAGS) $(LDFLAGS) $(SOURCE) -o $(ELF_FILE)
	@echo "✓ Build complete: $(ELF_FILE)"

# Generate disassembly
disasm: $(DISASM_FILE)

$(DISASM_FILE): $(ELF_FILE)
	@echo "Generating disassembly..."
	$(OBJDUMP) -D $(ELF_FILE) > $(DISASM_FILE)
	@echo "✓ Disassembly complete: $(DISASM_FILE)"

# Run with Spike simulator
run-spike: $(ELF_FILE)
	@echo "Running test with Spike..."
	spike $(SPIKE_FLAGS) $(ELF_FILE) 1>spike.out 2>spike.log
	@echo "✓ Spike execution complete (check spike.log)"

# Run with SAIL simulator
run-sail: $(ELF_FILE)
	@echo "Running test with SAIL..."
	riscv_sim_rv64d -c $(SAIL_CONFIG) --trace $(ELF_FILE) 1>sail.log 2>sail.out
	@echo "✓ SAIL execution complete (check sail.log)"

# Run complete test suite
test: compile disasm run-spike run-sail
	@echo "✓ All tests completed"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -f $(ELF_FILE) $(DISASM_FILE) *.log *.out
	@echo "✓ Clean complete"

# Show help
help:
	@echo "Available targets:"
	@echo "  all       - Compile and generate disassembly (default)"
	@echo "  compile   - Compile the test"
	@echo "  disasm    - Generate disassembly"
	@echo "  run-spike - Run test with Spike simulator"
	@echo "  run-sail  - Run test with SAIL simulator"
	@echo "  test      - Run complete test suite"
	@echo "  clean     - Remove build artifacts"
	@echo "  help      - Show this help message"

.PHONY: all compile disasm run-spike run-sail test clean help

.PHONY: clean

ASFLAGS = -march=rv32i -mabi=ilp32

all: source_O0.elf source_O1.elf source_O2.elf source_O3.elf source_Os.elf source_Ofast.elf

source_O0.elf:
	riscv-none-elf-gcc $(LDFLAGS) -O0 source.c -o $@

source_O1.elf:
	riscv-none-elf-gcc $(LDFLAGS) -O1 source.c -o $@

source_O2.elf:
	riscv-none-elf-gcc $(LDFLAGS) -O2 source.c -o $@

source_O3.elf:
	riscv-none-elf-gcc $(LDFLAGS) -O3 source.c -o $@

source_Os.elf:
	riscv-none-elf-gcc $(LDFLAGS) -Os source.c -o $@

source_Ofast.elf:
	riscv-none-elf-gcc $(LDFLAGS) -Ofast source.c -o $@

clean:
	rm *.elf
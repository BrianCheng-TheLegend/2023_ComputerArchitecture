.PHONY: clean

CROSS_COMPILE = riscv-none-elf-gcc 
ASFLAGS = -march=rv32i -mabi=ilp32

all: source_O0.elf source_O1.elf source_O2.elf source_O3.elf source_Os.elf source_Ofast.elf

source_O0.elf:
	$(CROSS_COMPILE) $(LDFLAGS) -O0 source.c -o $@

source_O1.elf:
	$(CROSS_COMPILE) $(LDFLAGS) -O1 source.c -o $@

source_O2.elf:
	$(CROSS_COMPILE) $(LDFLAGS) -O2 source.c -o $@

source_O3.elf:
	$(CROSS_COMPILE) $(LDFLAGS) -O3 source.c -o $@

source_Os.elf:
	$(CROSS_COMPILE) $(LDFLAGS) -Os source.c -o $@

source_Ofast.elf:
	$(CROSS_COMPILE) $(LDFLAGS) -Ofast source.c -o $@

clean:
	rm *.elf
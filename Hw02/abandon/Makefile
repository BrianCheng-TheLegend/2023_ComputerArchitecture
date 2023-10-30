.PHONY: clean

include ./toolchain.mk

ASFLAGS = -march=rv32i -mabi=ilp32
LDFLAGS = --oformat=elf32-littleriscv

%.o: %.c
	$(CROSS_COMPILE)as -R $(ASFLAGS) -o $@ $<

all: source.elf


source.elf: source.o
	 $(CROSS_COMPILE)ld -o $@ -T link.ld $(LDFLAGS) $<

clean:
	$(RM) source.elf source.o
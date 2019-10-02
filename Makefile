DEBUG ?= 1
ifeq ($(DEBUG), 1)
  ASMFLAGS = -F dwarf -g
endif

fibonacci: fibonacci.asm
	nasm -f elf64 $(ASMFLAGS) -o $@.o $<
	ld -nostdlib -nostartfiles $@.o -o $@
							
.phony: clean
clean:
	rm -f fibonacci *.o *.bin 

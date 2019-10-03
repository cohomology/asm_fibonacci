DEBUG ?= 1
ifeq ($(DEBUG), 1)
  ASMFLAGS = -F dwarf -g
endif

fibonacci: fibonacci.o add.o
	ld -nostdlib -nostartfiles $^ -o $@

fibonacci.o: fibonacci.asm
	nasm -f elf64 $(ASMFLAGS) -o $@ $<

add.o: add.asm
	nasm -f elf64 $(ASMFLAGS) -o $@ $<
							
.phony: clean
clean:
	rm -f fibonacci *.o *.bin 

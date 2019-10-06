DEBUG ?= 1
ifeq ($(DEBUG), 1)
  ASMFLAGS = -F dwarf -g
endif

fibonacci: fibonacci.o add.o memmove.o realloc.o
	ld -nostdlib -nostartfiles $^ -o $@

fibonacci.o: fibonacci.asm
	nasm -f elf64 $(ASMFLAGS) -o $@ $<

add.o: add.asm
	nasm -f elf64 $(ASMFLAGS) -o $@ $<

memmove.o: memmove.asm
	nasm -f elf64 $(ASMFLAGS) -o $@ $<

realloc.o: realloc.asm
	nasm -f elf64 $(ASMFLAGS) -o $@ $<

							
.phony: clean
clean:
	rm -f fibonacci *.o *.bin 

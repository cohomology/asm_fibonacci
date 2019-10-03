;; Prints all fibonacci numbers on the console, as long as 
;; process memory is available.
;; Design goals: - Follow x86_64/amd64 Linux ABI
;;               - No external libs, no c library calls
bits 64                                                                ; enable 64 bit mode

extern _add;

struc number
  .address: resq 1          ; address of number in memory (8 byte)
                            ; this points 1 byte after the _end_ of number
  .length: resd 1           ; length of number in memory
  .unused: resd 1
endstruc


section .bss

  initial_break:  resq 1
  current_break:  resq 1
  old_break:      resq 1
  divider_address:resq 1
  align 16
  number1:       resb number_size
  align 16
  number2:       resb number_size

section .data                                                          ; data section

  newline: db `\n`
  no_memory_text: db "No more memory, quit."
  no_memory_text_ln: equ $-no_memory_text
  block_size: equ 16
  number_max_size: dd (block_size / 2)
  number_old_max_size: dd 0

section	.text                                                          ; text (=code) section

global _start  ; expose _start as entry point for the linker
_start:   ;; get end of data segment into %rax 
          mov eax, 0xc 
          xor edi, edi 
          syscall         ; brk(0)
          mov rdi, rax
          call algn16_brk ; rax = aligned address
          mov [qword initial_break], rax
          ;; allocate initial memory 
          mov rdi, rax
          add rdi, block_size
          mov eax, 0xc
          syscall 
          cmp rax, rdi
          jne no_mem
          ;; write start values 
          mov [current_break], rax 
          mov [number2 + number.address], rax
          dec rax
          mov cl, '1'
          mov [byte rax], cl 
          mov rax, [initial_break]
          mov edx, dword [number_max_size]
          add rax, rdx 
          mov [number1 + number.address], rax
          mov [divider_address], rax
          dec rax
          mov cl, '0'
          mov [byte rax], cl
          mov ecx, 1
          mov [number1 + number.length], ecx
          mov [number2 + number.length], ecx
          call print

loop:     ; add both numbers 
          mov rdi, qword [number1 + number.address]
          mov esi, dword [number1 + number.length]
          mov rdx, qword [number2 + number.address]
          mov ecx, dword [number2 + number.length]
          call _add
          mov dword [number1 + number.length], eax
          ; print number
          call print
          ; check for reallocation
          mov eax, [number1 + number.length]
          mov ecx, dword [number_max_size]
          sub ecx, 1
          cmp ecx, eax
          je realloc
          ;; exchange number1 and number2
continue: movdqa xmm0, oword [number1]
          movdqa xmm1, oword [number2] 
          movdqa oword [number1], xmm1
          movdqa oword [number2], xmm0
          jmp loop

realloc:  ;; increase the mem_size by the block size 
          mov eax, 0xc
          mov rdi, [current_break]
          add rdi, block_size
          syscall                   ; brk(current_break + block_size)
          cmp rax, rdi              ; error handling, in case we got no memory
          jne no_mem                
          
          ;; recompute all global variables
          mov rdi, [current_break]  ; old_break := new_break
          mov [old_break], rdi      ; new_break := pointer to newly allocated memory 
          mov [current_break], rax
          
          mov esi, [number_max_size]      ; number_old_max_size = number_max_size
          mov [number_old_max_size], esi  ; number_max_size = (current_break - intial_break) / 2
          mov rcx, rax
          sub rcx, [initial_break] 
          shr ecx, 1
          mov [number_max_size], ecx

          mov rdx, rax 
          call memmove16           ; copy upper portion

          mov rdx, [initial_break]       ; set rdx to the end of the new "smaller" number
          mov esi, [number_max_size]
          add rdx, rsi
          mov [divider_address], rdx  

          mov rdi, [initial_break]       ; set rdx to end of of the "old" smaller number
          mov esi, [number_old_max_size] ; and esi to the old maximum size
          add rdi, rsi 
          
          call memmove16             ; copy lower portion

          mov rdi, [old_break]
          mov rsi, [current_break]
          cmp rdi, [number1+number.address] 
          ; cmove [number1+number.address], [current_break] 
          ; cmove [number2+number.address], 
          ; cmovne [number2+number.address], [current_break]

exit:     mov eax, 0x3c              ; exit syscall  
          xor edi, edi               ; return value 0
          syscall                    ; exit(0);

no_mem:   mov rax, 1
          mov rdi, 1
          mov rsi, no_memory_text
          mov rdx, no_memory_text_ln
          syscall
          jmp exit

print:  mov rax, 1
        mov rdi, 1
        mov rsi, [number1 + number.address]
        mov rdx, [number1 + number.length]
        sub rsi, rdx
        syscall
        mov rax, 1
        mov rdi, 1
        mov rsi, newline
        mov rdx, 1 
        syscall
        ret
     
;; Given an address returned by the brk() syscall, this
;; function aligns this address to a 16 byte boundary
;; and call brk() again.
;; \in  rdi = address
;; \out rax = aligned address
algn16_brk:  mov rax, rdi
             and rdi, 0xf
             test edi, edi
             je algn16_end
             xor rax, rdi
             add rax, 0x10
             mov rdi, 0xc
             xchg rax, rdi
             syscall
algn16_end:  ret

;; Moves a portion of memory _downwards_ in 16 byte steps
;; \in rdi = start address (i.e. 1 byte after end of memory) 
;; \in rsi = length (must be divisible by 16)
;; \in rdx = destination address (i.e. 1 byte after end of destination)
memmove16: sub rdi, 0x10
           sub rsi, 0x10
           sub rdx, 0x10 
           movdqa xmm0, [rdi]
           movdqa [rdx], xmm0 
           test ecx, ecx
           jne memmove16 
           ret

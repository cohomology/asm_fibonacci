;; Simple fibonacci number generator with arbitrary precision.
;; Design goals: - Follow x86_64/amd64 Linux ABI
;;               - Try to be efficient, but stay sane  
;;               - No external libs, no c library calls

bits 64                                                                ; enable 64 bit mode

struc number
  .address: resq 1          ; address of number in memory (8 byte)
                            ; this points 1 byte after the _end_ of number
  .length: resd 1           ; length of number in memory
  .unused: resd 1
endstruc

section .bss

  initial_break: resq 1
  current_break: resq 1
  align 16
  number1:       resb number_size
  align 16
  number2:       resb number_size

section .data                                                          ; data section

  newline: db `\n`
  no_memory_text: db "No more memory, quit."
  no_memory_text_ln: equ $-no_memory_text
  block_size: equ 256
  number_max_size: dd (block_size / 2)

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
          call add
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
          movdqa xmm0, oword [number1]
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

;; The add routine adds two decimal numbers a and b, i.e. computes
;;                    a = a + b 
;; The numbers are stored in ASCII form in memory and the addition
;; happens from right to left, i.e. additional bytes are added to the
;; front(!) of a, by the schoolbook method.
;; Preconditions: 
;;           - We assume a <= b
;;           - a has enough space on the left to hold digits(b)+1 bytes 
;; rdi = pointer to one byte after the end of "a" 
;; rsi = length of "a" in bytes 
;; rdx = pointer to one bytes afte the end of "b"
;; rcx = length of "b" in bytes
;; Return value: rax = new length of a in bytes
add:      xor r8d, r8d                 ;; r8d = 1 (overflow) = 0 (no overflow)
          mov r9d, ecx                 ;; save length of b to compute return value 
add_loop: dec rdi                      ;; decrease both pointers
          dec rdx 
          sub ecx, 1                   ;; decrease length of larger number
          jc add_last                  ;; length = 0 => quit and handle last carry
          mov r10b, [byte rdx]         ;; r10b = current byte of larger number 
          sub esi, 1                   ;; decrease length of smaller number
          jc add_ze 
          mov al, [byte rdi]
          sub al, '0'
add_comp: sub r10b, '0'
          add al, r10b
          add al, r8b
          cmp al, 10
          jb add_clr
          sub al, 10
          mov r8b, 1
          jmp add_str
add_clr:  xor r8w, r8w
add_str:  add al, '0' 
          mov [byte rdi], al
          jmp add_loop
add_last: test r8b, r8b 
          mov eax, r9d
          je add_end 
          inc eax
          mov cl, '1'
          mov [byte rdi], cl  
add_end:  ret
add_ze:   xor al, al 
          jmp add_comp 
     
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
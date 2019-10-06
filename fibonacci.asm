;; (c) by cohomology, 2019. 
;; Prints all fibonacci numbers on the console, as long as 
;; process memory is available.
;; Design goals: - Follow x86_64/amd64 Linux ABI
;;               - No external libs, no c library calls
bits 64                                                                ; enable 64 bit mode

extern _add, _realloc
global _start, _no_mem 
global number1, number2, initial_break, current_break, old_break
global number_max_size, number_old_max_size, block_size
global divider_address, old_divider_address

%include "number.inc"

section .bss

  initial_break:       resq 1
  current_break:       resq 1
  old_break:           resq 1
  divider_address:     resq 1
  old_divider_address: resq 1

  alignb 16
  number1:          resb number_size

  alignb 16
  number2:          resb number_size

section .data                                                          ; data section

  newline: db `\n`
  no_memory_text: db "No more memory, quit."
  no_memory_text_ln: equ $-no_memory_text
  block_size: dd 32
  number_max_size: dd 16
  number_old_max_size: dd 0

section	.text                                                          ; text (=code) section

_start:   ;; get end of data segment into [initial_break]
          mov eax, 0xc               ; system call brk(), increase size of data segment
          xor edi, edi               ; invalid address 0
          syscall                    ; brk(0)
          inc rax                    ; $rax points to end of data segment, increase by 1 byte
          mov rdi, rax
          call algn16_brk            ; align to 16 bytes by calling brk() again 
          mov [qword initial_break], rax
          ;; allocate initial memory block of [block_size] bytes 
          mov rdi, rax
          mov esi, dword [block_size]
          add rdi, rsi
          mov eax, 0xc
          syscall                   ; brk([initial break] + [block_size])
          cmp rax, rdi
          jne _no_mem
          ;; initialize [number1] and [number2]
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
          ;; print smaller number
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

realloc:  call _realloc
          jmp continue

exit:     mov eax, 0x3c              ; exit syscall  
          xor edi, edi               ; return value 0
          syscall                    ; exit(0);

_no_mem:  mov rax, 1
          mov rdi, 1
          mov rsi, no_memory_text
          mov rdx, no_memory_text_ln
          syscall
          jmp exit

print:    mov rax, 1
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
             cmp rax, rdi
             jne _no_mem 
algn16_end:  ret

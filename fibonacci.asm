;; Simple fibonacci number generator with arbitrary precision.
;; Design goals: - Follow x86_64/amd64 Linux ABI
;;               - Try to be efficient, but stay sane  
;;               - No external libs, no c library calls

bits 64                                                                ; enable 64 bit mode
global _start                                                          ; expose _start as entry point for the linker

section .data                                                          ; data section
zero     db '0'
align 32
number1_start:
db '00000000000000000000000000000919'
number1_end: 
align 32
number2_start:
db '00000000000000000000000000009979'
number2_end: 

section	.text                                                          ; text (=code) section

_start: mov rdi, number1_end
        mov esi, 3
        mov rdx, number2_end
        mov ecx, 4
        call add
        mov eax, 0x01
        mov edi, 0x01
        mov rsi, number1_start
        mov rdx, 32 
        syscall
        mov eax, 0x3c                                                  ; exit syscall  
        xor edi, edi                                                   ; return value 0
        syscall                                                        ; exit(0);

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
     
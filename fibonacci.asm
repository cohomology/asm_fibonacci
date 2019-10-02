;; Simple fibonacci number generator with arbitrary precision.
;; Design goals: - Follow x86_64/amd64 Linux ABI
;;               - Try to be efficient, but stay sane  

bits 64                                                                ; enable 64 bit mode
global _start                                                          ; expose _start as entry point for the linker

section .data                                                          ; data section
zero     db '0'
align 32
number1_start:
db '00000000000000000000000000000009'
number1_end: 
align 32
number2_start:
db '00000000000000000000000000000002'
number2_end: 

section	.text                                                          ; text (=code) section

_start: mov rdi, number1_end
        mov rsi, 1
        mov rdx, number2_end
        mov rcx, 1
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
;; The numbers are stored in ASCII form in memory. 
;; It is assumed that a <= b. It is also assumed that the 
;; numbers are multiple of 32 bytes long, possible filled with 
;; '0' on the left. 
;; rdi = pointer to one byte after the end of "a" 
;; rsi = length of "a" in 32-byte chunks 
;; rdx = pointer to one byte afte the end of "b"
;; rcx = length of "b" in 32 byte chunks
;; Return value: none
add:     mov eax, 0x30                ; broadcast '0' to all bytes of xmm0
         movd xmm6, eax               ; mov '0' to zero'th byte of xmm0
         pxor xmm0, xmm1              ; sets all bytes of xmm1 to 0 => shuffle mask 
         pshufb xmm6, xmm0            ; broadcast with mask xmm1
         mov eax, 0x39
         movd xmm7, eax
         pshufb xmm7, xmm0
         mov xmm8, xmm7
         sub rdi, 0x10             
         sub rdx, 0x10
         dec rsi
         dec rcx
         movdqa xmm0, oword [rdi]     ; move memory portion of "a" to xmm1
         movdqa xmm1, oword [rdx]     ; move memory portion of "b" to xmm2
         psubb xmm0, xmm6
         psubb xmm1, xmm6
         paddb xmm0, xmm1 
         paddb xmm0, xmm6
         pmaxub xmm7, xmm0
         psubb xmm7, xmm8
         movdqa oword [rdi], xmm0
add_end: ret
     
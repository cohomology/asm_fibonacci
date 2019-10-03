bits 64

global _realloc
extern _memmove16, _no_mem
extern number1, number2, initial_break, current_break, old_break
extern number_max_size, number_old_max_size, block_size
extern divider_address, old_divider_address

%include "number.inc"

;; ---------------------------------------------------------------;;
;;                   FUNCTION realloc_brk                         ;;
;; Given the memory area [initial_break, current_break]           ;;
;; this allocates new memory [initial_break, new_break] and sets  ;;
;; old_break := current_break                                     ;;
;; current_break := old_break                                     ;;
;; Here new_break := old_break + block_size                       ;;
;; This function also computes a distance "number_max_size"       ;;
;; such that number_max_size = (new_break - initial_break)/2      ;;
;; It stores the previous number_max_size value in the global     ;;
;; variable "number_old_max_size". The same happens with the      ;;
;; old and new divider address, which is                          ;;
;; initial_break+number_max_size                                  ;;
;; Parameters and return value: None (works with global vars)     ;;
;; ---------------------------------------------------------------;;
realloc_brk: mov eax, 0xc              ; syscall brk()
             mov rdi, [current_break]  ; new_break := old_break + block_size
             add rdi, block_size
             syscall                   ; brk(current_break + block_size)
             cmp rax, rdi              ; if new_break != expected_new_break
             jne _no_mem               ;   goto error 

             mov rdi, [divider_address]    ; old_divider_address := divider_address
             mov [old_divider_address], rdi

             mov rdi, [current_break]  ; old_break := new_break
             mov [old_break], rdi      ; new_break := pointer to newly allocated memory 
             mov [current_break], rax

             mov esi, [number_max_size]      ; number_old_max_size = number_max_size
             mov [number_old_max_size], esi  ; number_max_size = (current_break - intial_break) / 2
             mov rcx, rax
             sub rcx, [initial_break] 
             shr ecx, 1
             mov [number_max_size], ecx
             add rcx, [initial_break]
             mov [divider_address], rcx 
             ret

;; ---------------------------------------------------------------;;
;;                  FUNCTION update_num                           ;;
;; Updates the addressed inside the structure "number" of the     ;;
;; variables "number1" and "number2" to match the newly allocated ;;
;; memory.                                                        ;;
;; Parameters and return value: None (works with global vars)     ;;
;; ---------------------------------------------------------------;;
update_num:  mov rsi, [current_break]   ;; save both places at which 
             mov rcx, [divider_address] ;; the newly allocated numbers may be
                                        ;; in rsi and rcx 

             mov rdi, [old_break]              ;; check if number1 was in the higher
             cmp rdi, [number1+number.address] ;; address before

             cmove  r8, rsi
             cmove  r9, rcx
             cmovne r8, rcx
             cmovne r9, rsi

             mov [number1+number.address], r8
             mov [number2+number.address], r9

             ret

;; ---------------------------------------------------------------;;
;;                   FUNCTION _realloc                            ;;
;; This function allocates new memory to enlarge the size of the  ;;
;; numbers and copies the old numbers to the new numbers.         ;;
;; Also some global variables for bookkeeping are set. See in the ;;
;; above function realloc_brk for a detailled description.        ;;
;; Parameters and return value: None (works with global vars)     ;;
;; ---------------------------------------------------------------;;
_realloc:    call realloc_brk               ;; enlarge memory and set global vars

             mov rdi, [old_break]           ;; copy the number with the larger address
             mov rsi, [number_old_max_size]
             mov rdx, [current_break]
             call _memmove16
             
             mov rdi, [old_divider_address] ;; copy the number with the smaller address
             mov rsi, [number_old_max_size]
             mov rdx, [divider_address]
             call _memmove16

             call update_num                ;; update the addressed inside "number1"
                                            ;; and "number2"
             ret
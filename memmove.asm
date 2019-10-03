global _memmove16

;; Moves a portion of memory _downwards_ in 16 byte steps
;; \in rdi = start address (i.e. 1 byte after end of memory) 
;; \in rsi = length (must be divisible by 16)
;; \in rdx = destination address (i.e. 1 byte after end of destination)
_memmove16: sub rdi, 0x10
            sub rsi, 0x10
            sub rdx, 0x10 
            movdqa xmm0, [rdi]
            movdqa [rdx], xmm0 
            test esi, esi
            jne _memmove16 
            ret
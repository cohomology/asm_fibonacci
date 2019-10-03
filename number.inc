struc number
  .address: resq 1          ; address of number in memory (8 byte)
                            ; this points 1 byte after the _end_ of number
  .length: resd 1           ; length of number in memory
  .unused: resd 1
endstruc

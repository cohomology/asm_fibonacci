# Fibonacci

This is just a little personal project to write a non trivial Linux assembly program for amd64/x86_64. 

It infinitely prints all fibonacci numbers (arbitrary precision, i.e. can do > 64 bits) without using any additional libraries (e.g. without libc, gmp, etc.), just using Linux syscalls. 

It uses a self implemented decimal addition algorithm via the schoolbook method and constantly reallocates memory when memory runs out. Due to using the Linux syscall `brk` (and the data section limit of 30MB), the design is limited to numbers up to 16MB or 16 millions of decimal digits. 

Design goals: 

               - be amd64 Linux ABI compliant
               - no external libs
        

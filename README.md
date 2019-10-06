# Fibonacci

This is just a little personal project to write a non trivial Linux assembly program for amd64/x86_64. 
It infinitely prints all fibonacci numbers (arbitrary precision, i.e. can do > 64 bits) without using any additional libraries (e.g. without libc, gmp, etc.), just using Linux syscalls. It uses a self implemented decimal addition algorithm via the schoolbook method and constantly reallocates memory, when memory runs out.

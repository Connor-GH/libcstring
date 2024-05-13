# libcstring


Library written in D for handling C strings.


This library is mainly made to interface with C libraries or to use strings in
a C-like manner without the mental burden of making sure strings fit, etc.


This library is:
- @safe
- @nogc
- nothrow
- meant for baremetal
- compatible with OpenD
- compatible with BetterC (unittests are not)
- based on Meta's Folly fbstring library

This library is NOT:
- faster than native D GC strings always -- more below
- smaller than native D GC strings -- 16 bytes vs 32 bytes
- a drop-in replacement for anything

This library should really only be used in embedded or baremetal environments
where programmers are worried about C string semantics (as they use C linkage)
but want to have a string that is basically equivalent to what they would
have written, albeit more correct. No longer do you need to struggle with
strcat or strncat in C; you can create an object and use .cat()! It may also
be faster depending on how your C string was allocated, as this library
allocates memory eagerly, meaning most times there is no need for a
reallocation when concatenating two strings. If you have the memory to spare,
this is an excellent and easy-to-use string library for C strings.



(Micro-)Benchmarks:
# gdc:
library: 0.001486
native (GC): 0.001453

Difference: +2% (slower)

# ldc2:
library: 0.001622
native (GC): 0.001136

Difference: +42% (slower)


# ldc2:
library: 0.001622
native (GC): 0.001556

Difference: +4% (slower)

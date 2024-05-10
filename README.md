# libcstring


Library written in D for handling C strings.


This library is mainly made to interface with C libraries or to use strings in
a C-like manner without the mental burden of making sure strings fit, etc.


This library is:
- @safe
- @nogc
- nothrow
- compatible with OpenD
- based on Meta's Folly fbstring library

This library is NOT:
- faster than native D GC strings (yet?) -- about 30% slower
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

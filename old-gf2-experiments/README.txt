This dir contains a mix of experiments designed to arrive at a good
implementation of maths operations (particularly multiplication) in
various Galois fields.

Older files looked at different multiplication algorithms using
as many techniques as I could come up with, for 8, 16 and 32-bit
operands. There's also a fallback of working with arbitrary-precision
values/polynomials.

I don't have a proper Makefile here. The fast_gf2.h file may need
changes for your platform (word sizes and endianness). There's a
script fast_gf2_method_chooser.pl that is supposed to simplify the
choice of choosing between various GF multiplication methods.

There's also a version of the maths routines implemented in Perl
with Inline C. That got replaced with a much more practical version
using XS in Math::FastGF2.

The rabin-ida program later evolved into rabin-ida-helper, which is
in amongst the files in the PS3 implementation. It just does the
basic IDA split/combine transforms and leaves other details such as
reading/writing sharefile headers or generating matrices to a
calling program.

Finally, I have a version of the 8-bit GF multiplication routine
implemented as efficiently as I think is possible using the SIMD 
instructions available on the Raspberry Pi. It's able to work on
four multiplications at once due to having only 32 bit wide SIMD
there. When operating on 4 pairs of operands, it's marginally slower
than the fastest method of multiplication, which uses optimised
log and exponent table lookups. As a result, it's not really useful
for 8-bit multiplies, but it's possible that it might be better for 
16-bit values.


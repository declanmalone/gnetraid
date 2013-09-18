// implements fast XOR operation
//

// We use sizeof(void *) to determine the largest fundamental unsigned
// integer type that this platform supports, and use this type for our
// xor loop.  Obviously, this assumes that (void *) has the same size
// as the largest usable register type. This may not be true in all
// cases, but it should be OK for most platforms.

// Note that we can't use sizeof() within an #if statement because the
// preprocessor knows nothing about data types/sizes. Thus, the file
// below has to be generated by running a separate test program. It
// includes just one definition:
//
// native_register_t: a typedef to an unsigned int of appropriate size
// (such as unsigned long or uint_32 where available)
//
// The native register size in bytes can be calculated by using sizeof
// on the above type.

#include "this_machine.h"

// The simplest implementation operates on bytes
void bytewise_xor (unsigned char *dest, unsigned char *src, 
		   unsigned long bytes) {
  while (bytes--) {
    *dest++ ^= *src++;
  }
}

// This more complex implementation employs three separate
// optimisations:
//
// 1. Use native_register_t instead of char *
// 2. Memory access are aligned to native_register_t
// 3. Use "Duff's Device" to do loop-unrolling 
//
// The second optimisation may not be useful on all platforms, but
// there are still quite a few platforms where it is useful. It may
// not be possible to align accesses to both the source and
// destination memory spaces if they have differing alignments. We
// concentrate on aligning memory accesses in the dest array since we
// need to do both a read and a write on it.
//
// 
void aligned_word_xor(unsigned char *dest, unsigned char *src, 
		      unsigned long bytes) {

  unsigned long leading_bytes;

  register native_register_t *dword, *sword;
  register unsigned long words;

  // bitmask to help with alignment:
  // 128-bit alignment => 16 byte/word => mask 0b00...01111
  // 64-bit  alignment => 8  byte/word => mask 0b00...0111
  // 32-bit  alignment => 4  byte/word => mask 0b00...011
  // 16-bit  alignment => 2  byte/word => mask 0b00...01
  // 8-bit   alignment => 1  byte/word => mask 0b00...0
  register native_register_t mask = sizeof(native_register_t) - 1;

  // do byte-wise xor until dest is word-aligned
  while ((((native_register_t) dest) & mask) && bytes) {
    *dest++ ^= *src++;
    --bytes;
  }

  dword = (native_register_t*) dest;
  sword = (native_register_t*) src;

  // the division below could be replaced by repeated shift, but we'd
  // need to add code to calculate log_2(sizeof(native_register_t)).
  words  = (bytes) / sizeof(native_register_t);
  bytes -= words * sizeof(native_register_t);
  dest  += words * sizeof(native_register_t);
  src   += words * sizeof(native_register_t);

  // since Duff's device always xors some data, we check beforehand
  // whether it's appropriate to go into it to avoid going past the
  // end of the arrays.
  if (words) {
    register count = (words + 7) >> 3;
    switch (words & 0x07) {	// 0x07 => loop unrolled 8 times
    case 0: do {    *dword++ ^= *sword++;
    case 7:         *dword++ ^= *sword++;
    case 6:         *dword++ ^= *sword++;
    case 5:         *dword++ ^= *sword++;
    case 4:         *dword++ ^= *sword++;
    case 3:         *dword++ ^= *sword++;
    case 2:         *dword++ ^= *sword++;
    case 1:         *dword++ ^= *sword++;
            } while (--count);
    }
  }

  // finally, use byte-wise xor for any remaining bytes
  while (bytes--) {
    *dest++ ^= *src++;
  }
}

/* Use gcc's x86 simd intrinsics to multiply vectors of GF(2^8) values */

// it seems that we need to explicitly include intrinsic-related headers
#include <emmintrin.h>
#include <smmintrin.h>

#include <stdio.h>

// Make up some shorter names for vector types
// (Do these automatically imply the correct alignment attribute?)
// (assembler output seems to say "yes")
typedef unsigned char vchar __attribute__((vector_size (16)));

vchar a;

// irreducible polynomial with 0x100 bit stripped off
vchar poly = { 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b,
	       0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b, 0x1b };

#if 0
// try implementing product without using builtin macros
// See https://gcc.gnu.org/onlinedocs/gcc/Vector-Extensions.html
vchar gf2_vp_vector(vchar a, vchar b, vchar poly) {

  vchar mask, temp_result, result;
  int bit = 7;

  result ^= result;

  // try doing immediate shift
  mask = (b << 7) & 0x80;

  do {

    mask = (b << bit) & 0x80;


    /* Both ways of expressing a condition below (if or ?:) fail with

       ``error: used vector type where scalar is required''

      if (mask) result ^= a;

      // this works if we use g++ instead of gcc, though:
      a = (a & 0x80) ? ((a << 1) ^ poly) : (a << 1);

    */

  } while (bit--);

  return result;
}
#endif

vchar gf2_vp_intrinsics(register vchar a, register vchar b, register vchar poly) {

  register vchar mask, temp_result, result;
  register int bit = 7;

  // two ways of doing XOR
  result ^= result;
  result=(vchar) _mm_xor_si128((__m128i) result,(__m128i) result);
  
  do {

    //  if (b & (1 << bit)) { result ^= a; }
    
    // there are various logical left shift intrinsics, but it doesn't
    // make any difference which sized one we use
    mask = (vchar) _mm_slli_epi16 ((__m128i) b, bit);
    temp_result = result ^ a;

    result = (vchar) _mm_blendv_epi8((__m128i) result, (__m128i) temp_result,
				     (__m128i) mask);

    // if (a & 0x80) { a = (a << 1) ^ poly; } else { a <<= 1; }

    // When doing a <<= 1, it turns out that there isn't a
    // _mm_slli_epi8 instruction for doing logical left shift on
    // packed bytes :( This means that we have to use a bigger data
    // type and mask out the bits that should have been zero-extended.
    // OR: just say a += a
    
    mask = a;
    a += a;
    temp_result = (vchar) _mm_xor_si128((__m128i) a, (__m128i) poly);

    a = (vchar) _mm_blendv_epi8((__m128i) a, (__m128i) temp_result,
				(__m128i) mask);

  } while (bit--);

  return result;
}

/* With these gcc options:

   gcc  -O1 -mfpmath=sse -mmmx -msse -msse2 -msse3 -mavx -msse4 -c -S 

   The generated code looked like (gcc version 4.9.2 (Debian 4.9.2-10)):

        vmovdqa %xmm0, %xmm3
        vpxor   %xmm0, %xmm0, %xmm0
        movl    $7, %eax
.L2:
        movl    %eax, -12(%rsp)
        vmovd   -12(%rsp), %xmm6
        vpsllw  %xmm6, %xmm1, %xmm5
        vpxor   %xmm3, %xmm0, %xmm4
        vpblendvb       %xmm5, %xmm4, %xmm0, %xmm0
        vpaddb  %xmm3, %xmm3, %xmm4
        vpxor   %xmm2, %xmm4, %xmm5
        vpblendvb       %xmm3, %xmm5, %xmm4, %xmm3
        subl    $1, %eax
        cmpl    $-1, %eax
        jne     .L2
        rep ret

  That's actually a pretty decent rendering. The only thing I dislike
  about it is how it splats the 'bit' variable across xmm6 (including
  writing it to memory). That's not important, though, because after
  testing I will write an unrolled version that eliminates the loop
  variable completely. This version should have 6 instructions per bit
  for a total of 47 instructions (the last vpsllw can be eliminated)
  instructions to do 16 multiplies in parallel.

*/

// take a function pointer for the test routine so that we can test
// both the looping and unrolled versions
void test_gf2_vp_intrinsics(vchar (*func)(register vchar a, register vchar b,
					  register vchar poly)) {

  // very basic test: 0x53 and 0xca are multiplicative inverses mod 0x11b
  vchar a = { 0x53, 0xca, 0x53, 0xca, 0x53, 0xca, 0x53, 0xca,
	      0x53, 0xca, 0x53, 0xca, 0x53, 0xca, 0x53, 0xca };
  vchar b = { 0xca, 0x53, 0xca, 0x53, 0xca, 0x53, 0xca, 0x53,
	      0xca, 0x53, 0xca, 0x53, 0xca, 0x53, 0xca, 0x53 };
  union {			/* union makes for easier casting */
    unsigned char array[16];
    vchar v;
  } result;

  int i, byte, ok;

  result.v = (func)(a, b, poly);

  ok = 1;
  for (i = 0; i < 16; ++i) {
    byte = result.array[i];
    if (byte != 1) ok = 0;
  }

  printf ("Basic test %s\n", (ok? "ok" : "not ok"));
}

// Basic test passed, so unroll loop

#define SHIFT_BIT(BIT) (mask = (vchar) _mm_slli_epi16 ((__m128i) b, BIT))
#define NO_SHIFT (mask=b)

#define UNROLL_INNER(SHIFT)	\
    SHIFT; \
    temp_result = result ^ a; \
    result = (vchar) _mm_blendv_epi8((__m128i) result, \
				     (__m128i) temp_result, \
				     (__m128i) mask); \
    mask = a; \
    a += a; \
    temp_result = (vchar) _mm_xor_si128((__m128i) a, (__m128i) poly); \
    a = (vchar) _mm_blendv_epi8((__m128i) a, (__m128i) temp_result, \
				(__m128i) mask)

vchar gf2_vp_intrinsics_unrolled (register vchar a, register vchar b,
				  register vchar poly) {

  register vchar mask, temp_result, result;

  result ^= result;

  UNROLL_INNER(SHIFT_BIT(7));
  UNROLL_INNER(SHIFT_BIT(6));
  UNROLL_INNER(SHIFT_BIT(5));
  UNROLL_INNER(SHIFT_BIT(4));
  UNROLL_INNER(SHIFT_BIT(3));
  UNROLL_INNER(SHIFT_BIT(2));
  UNROLL_INNER(SHIFT_BIT(1));
  // gcc with -O1 also manages to eliminate the last few instructions
  // of the next part since they can't affect the returned result
  // variable
  UNROLL_INNER(NO_SHIFT);

  return result;
}

int main(int ac, char *av[]) {
  test_gf2_vp_intrinsics(gf2_vp_intrinsics);
  test_gf2_vp_intrinsics(gf2_vp_intrinsics_unrolled);
}

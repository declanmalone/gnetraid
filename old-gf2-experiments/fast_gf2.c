/* GF(2) arithmetic */

/*
 * There are routines here which are optimised for 8, 16 and 32-bit
 * word sizes, and also arbitrary-precision versions versions. Besides
 * optimising for particular word sizes, the routines can create and
 * use lookup tables for specific (user-supplied) polynomials in
 * GF(2^8), GF(2^16) and GF(2^32).
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "fast_gf2.h"

/* utility routines for swapping byte order */
gf2_u16 gf2_swab_u16(gf2_u16 word) {
  return (word >> 8) | (word << 8);
}
gf2_u32 gf2_swab_u32(gf2_u32 word) {
  return (word >> 24) |
    ((word >> 8) & 0x0000ff00)|
    ((word << 8) & 0x00ff0000)|
    (word << 24);
}

/*
  Define a macro to do the "standard" long multiply modulo a
  polynomial. This just defines a function of the appropriate type; it
  doesn't create any inline code.
*/
#define GF2_LONG_MOD_MULTIPLY(TYPE) \
gf2_##TYPE \
gf2_long_mod_multiply_##TYPE (gf2_##TYPE a, gf2_##TYPE b, gf2_##TYPE poly) { \
  gf2_##TYPE result = (b & 1) ? a : 0; \
  gf2_##TYPE bit    = 2; \
  do { \
    if (a & HIGH_BIT_gf2_##TYPE)  { \
      a = (a << 1) ^ poly;	    \
    } else { \
      a <<= 1; \
    } \
    if (b & bit) { \
      result ^= a; /* & ALL_BITS_gf2_##TYPE */  \
    }; \
    bit <<= 1; \
  } while (bit); \
  return result; \
}

/* 
  Even though I've defined the standard way of multiplying for
  variable types above (which should be fairly fast), we can still do
  a little bit better by unrolling the loop. This gets rid of the loop
  counter as well as the loop itself. The choice of whether to unroll
  or not is left as a compile-time option.
*/

#ifndef GF2_UNROLL_LOOPS
GF2_LONG_MOD_MULTIPLY(u8);
GF2_LONG_MOD_MULTIPLY(u16);
GF2_LONG_MOD_MULTIPLY(u32);
#else
/* define unrolled forms */
gf2_u8
gf2_long_mod_multiply_u8 (gf2_u8 a, gf2_u8 b, gf2_u8 poly) {
  gf2_u8 result = (b & 1) ? a : 0;

  if (a & HIGH_BIT_gf2_u8)  { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 2)                { result ^= a; }
  if (a & HIGH_BIT_gf2_u8)  { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 4)                { result ^= a; }
  if (a & HIGH_BIT_gf2_u8)  { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 8)                { result ^= a; }
  if (a & HIGH_BIT_gf2_u8)  { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 16)               { result ^= a; }
  if (a & HIGH_BIT_gf2_u8)  { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 32)               { result ^= a; }
  if (a & HIGH_BIT_gf2_u8)  { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 64)               { result ^= a; }

  /*
    for the final bit, we can re-order the tests to avoid doing the
    shift/mod operations on a if its value isn't going to be used.
  */
  if (b & 128) {
    result ^= ((a & HIGH_BIT_gf2_u8) ? (a << 1) ^ poly :  a << 1);
  }

  return result;
}

gf2_u16
gf2_long_mod_multiply_u16 (gf2_u16 a, gf2_u16 b, gf2_u16 poly) {
  gf2_u16 result = (b & 1) ? a : 0;

  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 2)                { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 4)                { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 8)                { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 16)               { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 32)               { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 64)               { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 128)              { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 256)              { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 512)              { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 1024)             { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 2048)             { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 4096)             { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 8192)             { result ^= a; }
  if (a & HIGH_BIT_gf2_u16) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 16384)            { result ^= a; }

  /* see above function for explanation of last-bit optimisation */
  if (b & 32768) {
    result ^= ((a & HIGH_BIT_gf2_u16) ? (a << 1) ^ poly :  a << 1);
  }

  return result;
}

gf2_u32
gf2_long_mod_multiply_u32 (gf2_u32 a, gf2_u32 b,
			   gf2_u32 poly) {
  gf2_u32 result = (b & 1) ? a : 0;

  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 2)                { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 4)                { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 8)                { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 16)               { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 32)               { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 64)               { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 128)              { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 256)              { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 512)              { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 1024)             { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 2048)             { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 4096)             { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 8192)             { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 16384)            { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 32768)            { result ^= a; }

  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x010000)         { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x020000)         { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x040000)         { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x080000)         { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x100000)         { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x200000)         { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x400000)         { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x800000)         { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x01000000)       { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x02000000)       { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x04000000)       { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x08000000)       { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x10000000)       { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x20000000)       { result ^= a; }
  if (a & HIGH_BIT_gf2_u32) { a = (a << 1) ^ poly; } else { a <<= 1; }
  if (b & 0x40000000)       { result ^= a; }

  if (b & 0x80000000) {
    result ^= ((a & HIGH_BIT_gf2_u32) ? (a << 1) ^ poly :  a << 1);
  }

  return result;
}

#endif


/*
  Define a macro to do the standard "straight" (not modulo a
  polynomial) long multiply. BIG_TYPE should be twice the width of
  SMALL_TYPE. Created functions are named after SMALL_TYPE.
  "Straight" multiplication isn't that useful for normal applications,
  but there are some optimisations in GF(2^16) and GF(2^32) that can
  get a speed benefit from using straight multiplications over modulo
  multiplications.
*/
#define GF2_LONG_STRAIGHT_MULTIPLY(SMALL_TYPE,BIG_TYPE) \
gf2_##BIG_TYPE \
gf2_long_straight_multiply_##SMALL_TYPE ( \
  gf2_##SMALL_TYPE a, gf2_##SMALL_TYPE b) \
{ \
  gf2_##BIG_TYPE   aa     = (gf2_##BIG_TYPE) (a);		\
  gf2_##BIG_TYPE   result = (gf2_##BIG_TYPE) ((b & 1) ? a : 0); \
  gf2_##SMALL_TYPE bit    = 2; \
  do { \
    aa <<= 1; \
    if (b & bit) { result ^= aa; }; \
    bit <<= 1; \
  } while (bit); \
  return result; \
}

GF2_LONG_STRAIGHT_MULTIPLY(u8,u16);
GF2_LONG_STRAIGHT_MULTIPLY(u16,u32);

/*
  For calculating inverses, we need to know what the order of the
  polynomials being operated on are. The size_in_bits_* functions use
  this lookup table to quickly find the order of the value stored in
  the highest non-zero byte.
*/

static unsigned char size_of_byte[256]= {
  0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4, /*   0 -  15 */
  5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5, /*  16 -  31 */
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6, /*  32 -  47 */
  6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6, /*  48 -  63 */
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, /*  63 -  79 */
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, /*  80 -  95 */
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, /*  96 - 111 */
  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, /* 112 - 127 */
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*           */
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*     :     */
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*           */
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*     :     */
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*           */
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*     :     */
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*           */
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /* 240 - 255 */
};

int size_in_bits_u8 (gf2_u8 byte) {
  return size_of_byte[byte];
}

int size_in_bits_u16 (gf2_u16 word) {
  if (word & 0xff00) {
    return 8 + size_of_byte[word >> 8];
  } else {
    return size_of_byte[word];
  }
}

int size_in_bits_u32 (gf2_u32 word) {
  if (word & 0xff000000l) {
    return 24 + size_of_byte[word >> 24];
  } else if (word & 0xff0000) {
    return 16 + size_of_byte[word >> 16];
  } else if (word & 0xff00) {
    return 8  + size_of_byte[word >> 8 ];
  } else {
    return size_of_byte[word];
  }
}

/*
  Finding the multiplicative inverse uses a version of the extended
  Euclidean algorithm for calculating the greatest common divisor of
  two values. Note that unlike other gcd algorithms, this one goes
  into an infinite loop if gcd(x,poly) is not equal to 1 (ie, x and
  poly are not relatively prime). So don't pass in a poly that isn't
  actually an irreducible polynomial.
*/
#define GF2_LONG_MOD_INVERSE(TYPE) \
gf2_##TYPE \
gf2_long_mod_inverse_##TYPE (gf2_##TYPE x, gf2_##TYPE poly) { \
\
  gf2_##TYPE  u,v,z,g,t; \
  int   i; \
\
  if (x < 2) return x;		/* inverse for 0, 1 */ \
\
  u = poly;  v = x;  z = 0;  g = 1; \
\
  /* unroll first loop iteration */ \
  i=ORDER_##TYPE + 1 - size_in_bits_##TYPE(v); \
  u^=(v<<i);  z^=(g<<i); \
\
  while (u != 1) { \
    i=size_in_bits_##TYPE(u) - size_in_bits_##TYPE(v); \
    if (i < 0) { \
      t=u; u=v; v=t; \
      t=z; z=g; g=t; \
      i=-i; \
    } \
    u ^= (v << i); z ^= (g << i); \
  } \
  return z; \
}

/* no unrolled versions of these */
GF2_LONG_MOD_INVERSE(u8);
GF2_LONG_MOD_INVERSE(u16);
GF2_LONG_MOD_INVERSE(u32);

/* 
  Raise a polynomial x to a power y, modulo a polynomial p. This uses
  the fairly well-known trick of converting exponentiation to a large
  power into an equivalent expression involving only multiplication by
  x and squaring. Both arguments are restricted to being no larger
  than can be accommodated in the particular type.
*/
#define GF2_LONG_MOD_POWER(TYPE) \
gf2_##TYPE \
gf2_long_mod_power_##TYPE (gf2_##TYPE x, gf2_##TYPE y, gf2_##TYPE p) \
{\
\
  gf2_##TYPE z = x; \
  gf2_##TYPE mask = HIGH_BIT_gf2_##TYPE; \
\
  if ((y == 0) || (y == ALL_BITS_gf2_##TYPE))   return 1; \
  /* removed the next line, as it improves overall performance if we
     don't check for (relatively rare) special cases */ \
  /* if (x  < 2)                                   return x; */ \
\
  mask >>= (ORDER_##TYPE - size_in_bits_##TYPE(y)); \
  while (mask>>=1) { \
    z=gf2_long_mod_multiply_##TYPE(z,z,p); \
    if (y & mask) { \
      z=gf2_long_mod_multiply_##TYPE(x,z,p); \
    } \
  } \
  return z; \
}

GF2_LONG_MOD_POWER(u8);
GF2_LONG_MOD_POWER(u16);
GF2_LONG_MOD_POWER(u32);


/* 
  I don't have any division routine yet, mostly because I don't need
  much division for my purposes. For now, if you need it, to calculate
  a/b, use a * inv(b). Or just test the optimised routines. Some of
  them might provide pretty good performance on division.
*/

/* 
   Accelerated routines.

   I apologise in advance for the profusion of function names and
   calling conventions. If you want optimised, then you can't really
   complain if there isn't a nice, unified calling convention. Feel
   free to make wrappers that hide the underlying implementation, but
   don't come complaining to me if you find that your function
   dereferencing/structure lookup is causing performance to drop.

   At least I've picked a standard naming for all the functions to
   make things slightly easier for you. These functions are of the form:

   gf2_fast_{type}_{function}_{method}

   type:     u8, u16 and u32 (for gf2_u8, gf2_u16 and gf2_u32)
   function: mul, inv, div, pow, etc.
   method:   1, 2, 3, etc.

   If they exist, macros (suitable for inline execution) will have
   _mac appended to the function name. See the header file for
   details.
*/

/* accelerated GF(2^8) routines */

/* method 1: full multiplication and inverse lookups */
int  /* 0 = OK, -1 = error (probably malloc-related) */
gf2_fast_u8_init_m1(gf2_u8 poly, gf2_u8 **mul_table, gf2_u8 **inv_table) {
  gf2_u16  i,j;
  gf2_u8   k;

  (*mul_table)=malloc(65536);
  (*inv_table)=malloc(256);

  if (((*mul_table)==NULL) || ((*inv_table)==NULL)) {
    if ((*mul_table)!=NULL) free (*mul_table);
    if ((*inv_table)!=NULL) free (*inv_table);
    return -1;
  }

  /* a * 0 == 0 */
  (*mul_table)[0]=0;
  for (i=1; i < 256; ++i) {
    (*mul_table)[i]=0;
    (*mul_table)[i<<8]=0;
  }

  /* a * 1 == a */
  (*mul_table)[257]=1;
  for (i=2; i < 256; ++i) {
    (*mul_table)[i      + 256]=i;
    (*mul_table)[(i<<8) + 1  ]=i;
  }

  (*inv_table)[0]=0;		/* not perfect, but it'll do */
  (*inv_table)[1]=1;
  for (i=2; i<256; ++i) {
    for (j=2; j <= i; ++j) {
      /* 
	we do an extra 254 assignments during this loop for diagonal
	elements where i==j, but it's hardly worth optimising them
	out.
      */
      
      k=gf2_long_mod_multiply_u8((gf2_u8) i,(gf2_u8) j,poly);

      (*mul_table)[(i << 8) + j]=k;
      (*mul_table)[i + (j << 8)]=k;

      /* save multiplicative inverses */
      if (k==1) {
	(*inv_table)[i]=j;
	(*inv_table)[j]=i;
      }
    }
  }

  return 0;
}
/*
  provide a de-initialisation routine since some methods might have
  more complex free() code.
*/
void gf2_fast_u8_deinit_m1(gf2_u8 *mul_table, gf2_u8 *inv_table) {
  free(mul_table);
  free(inv_table);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u8 gf2_fast_u8_mul_m1(gf2_u8 *mul_table, gf2_u8 a, gf2_u8 b) {
  return mul_table[(((gf2_u16) a) << 8) + b];
}

gf2_u8 gf2_fast_u8_inv_m1(gf2_u8 *inv_table, gf2_u8 a) {
  return inv_table[a];
}

gf2_u8 gf2_fast_u8_div_m1(gf2_u8 *mul_table, gf2_u8 *inv_table,
			  gf2_u8 a, gf2_u8 b) {
  return mul_table[(((gf2_u16) a) << 8) + inv_table[b]];
}

/*
  Dot product (vector product) routines. The basic form (dpc, for "dot
  product, contiguous") assumes that elements of the input vectors (a
  and b) are contiguous in their respective storage areas (ie, both
  are simple arrays). If elements to be operated on aren't contiguous,
  then the extended form (dpd, for "dot product, with delta") allows
  you to specify the deltas to be applied to pointers after each
  element has been processed. The "with deltas" form is particularly
  useful when the vectors being multiplied are rows or columns of a
  matrix, where it's not always possible or desirable to make vector
  elements contiguous in memory.
*/

gf2_u8
gf2_fast_u8_dpc_m1(gf2_u8 *mul_table,
		   gf2_u8 *a,
		   gf2_u8 *b,
		   int len)
{
  gf2_u8 total=mul_table[((gf2_u16)*a) << 8 + *b];

  if (len == 0) return 0;

  while (--len) {
    total^=mul_table[((gf2_u16)*++a) << 8 + *++b];
  }

  return total;
}

gf2_u8 gf2_fast_u8_dpd_m1(gf2_u8 *mul_table,
			  gf2_u8 *a, int da,
			  gf2_u8 *b, int db,
			  int len)
{
  gf2_u8 total=mul_table[((gf2_u16)*a) << 8 + *b];

  if (len == 0) return 0;

  while (--len) {
    total^=mul_table[((gf2_u16)*(a+=da)) << 8 + *(b+=db)];
  }

  return total;
}

/* method 2: unoptimised log/exp (minimal lookup table size, slower
   than method 2, and slightly slower than method 3) */
int  /* 0 = OK, other = error (args or malloc-related) */
gf2_fast_u8_init_m2(gf2_u8 poly, gf2_u8 g, 
		    gf2_u8 **log_table, gf2_u8 **exp_table) {
  gf2_u8  i,p;

  if ((g == 0) || (poly == 0))  return -1;

  (*log_table)=malloc(256);
  (*exp_table)=malloc(256);

  if (((*log_table)==NULL) || ((*exp_table)==NULL)) {
    if ((*log_table)!=NULL) free (*log_table);
    if ((*exp_table)!=NULL) free (*exp_table);
    return -1;
  }

  (*exp_table)[0]=1;
  (*log_table)[0]=0;		/* not perfect, but it'll do */
  (*exp_table)[1]=g;  (*log_table)[g]=1;

  p=g;				/* product = generator */
  i=2;				/* next value to store is g^2  */
  do {
    /* 
      since the generator and poly to be used are user-supplied, it's
      possible that they don't actually form a proper field. The
      requirement is that the cycle length of the sequence of repeated
      powers of g mod p is maximal, which can be easily checked by
      making sure that the product is only 1 for values of g^0 and
      g^255. Since g^0 is outside the loop, and g^255 is the final
      loop iteration, we can avoid actually having to compare whether
      i==0 or i==255--simply testing that the product != 1 will
      suffice. Handily, this also catches the case where g or p is 1.
    */
    if (p == 1) {
      fprintf(stderr,
	      "Bad poly/generator: got product==1 (g was %u, i is %u)", 
	      (unsigned) p, (unsigned) i);
      free (*log_table);
      free (*exp_table);
      return -i;
    }
      
    p=gf2_long_mod_multiply_u8(p,g,poly);

    (*exp_table)[i]=p;
    (*log_table)[p]=i;

  } while (++i);		/* relies on overflow: max + 1 = 0 */

  return 0;
}
void gf2_fast_u8_deinit_m2(gf2_u8 *log_table, gf2_u8 *exp_table) {
  free (log_table);
  free (exp_table);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u8 gf2_fast_u8_mul_m2(gf2_u8 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b) {
  gf2_u16 sum;			/* u16, since sum of logs can overflow u8 */
  if ((!a) || (!b)) return 0;
  sum = log_table[a] + log_table[b];
  sum = (sum & 255) + ( sum >> 8);
  return exp_table[sum];
}

gf2_u8 gf2_fast_u8_inv_m2(gf2_u8 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a) {
  return exp_table[255-log_table[a]];
}

gf2_u8 gf2_fast_u8_div_m2(gf2_u8 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b) {
  gf2_u8 log_a = log_table[a];
  gf2_u8 log_b = log_table[b];
  if (log_a >= log_b) {
    return exp_table[log_a - log_b];
  } else {
    return exp_table[255 + log_a - log_b];
  }
}

/*
  method 3: optimised log/exp (exchanges larger tables (5 times
  larger, between doubling the width of the log table to store signed
  16-bit numbers and quadrupling the size of the exp table) than
  method 2 for even faster lookups with no need to check for
  multiplication by zero or for making log[a] + log[b] be in the range
  0,255). The idea behind the first optimisation is to let log[0] be a
  large enough negative number that the sum of log[0] and
  log[(1..255)] is always a negative number. The exp table is expanded
  in the negative direction to account for possible negative sums of
  log[a] + log[b]. The second optimisation is to extend the exp table
  in the positive direction (doubling its size in this direction) to
  avoid having to bring log[a] + log[b] down to a number in the range
  (0,255).
*/
int  /* 0 = OK, other = error (args or malloc-related) */
gf2_fast_u8_init_m3(gf2_u8 poly, gf2_u8 g, 
		    gf2_s16 **log_table, gf2_u8 **exp_table) {
  gf2_s16 i;
  gf2_u8  p;

  if ((g == 0) || (poly == 0))  return -1;

  (*log_table)=malloc(256 * sizeof(gf2_s16));
  (*exp_table)=malloc(1024);

  if ((*log_table)==NULL || (*exp_table)==NULL) {
    if ((*log_table)!=NULL) free (*log_table);
    if ((*exp_table)!=NULL) free (*exp_table);
    return -1;
  }

  /*
    we include negative indexes in the array, so move the pointer
    forward so that it points to the proper zeroth element. Remember
    to subtract 512 from the address before freeing it!
  */
  (*exp_table) += 512;
  for (i=-512; i; ++i) {
    (*exp_table)[i]=0; 
  }

  (*log_table)[0]=-256;  (*exp_table)[0]=1;
  (*log_table)[g]=1;     (*exp_table)[1]=g;
  (*exp_table)[255]=1;   (*exp_table)[256]=g;

  /* this next one is to make inv(0)=0 work ok */
  (*exp_table)[255+256]=0;

  p=g;				/* product = generator */
  i=2;				/* next value to store is g^2  */
  do {
    /* check for bad (poly,generator) pair, as in method 2 */
    if (p == 1) {
      fprintf(stderr,
	      "Bad poly/generator: got product==1 (g was %u, i is %u)", 
	      (unsigned) p, (unsigned) i);
      free (*log_table);
      free (*exp_table - 512);
      return -i;
    }

    p=gf2_long_mod_multiply_u8(p,g,poly);

    (*exp_table)[i]     = p;
    (*exp_table)[i+255] = p;
    (*log_table)[p]     = i;

  } while (++i < 256);

  return 0;
}

void gf2_fast_u8_deinit_m3(gf2_s16 *log_table, gf2_u8 *exp_table) {
  free (log_table);
  free (exp_table - 512);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u8 gf2_fast_u8_mul_m3(gf2_s16 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b) {
  return exp_table[log_table[a] + log_table[b]];
}

gf2_u8 gf2_fast_u8_inv_m3(gf2_s16 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a) {
  
  return exp_table[255-log_table[a]];
}

gf2_u8 gf2_fast_u8_div_m3(gf2_s16 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b) {
  return exp_table[255 + log_table[a] - log_table[b]];
}

gf2_u8 gf2_fast_u8_pow_m3(gf2_s16 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b) {
  return exp_table[(log_table[a] * b) % 255];
}

/* accelerated GF(2^16) routines */
/* 
  A full multiplication table for GF(2^16) would be 8Gb, so there's no
  point in attempting to implement it. The next best options are:

  1. Unoptimised log/exp tables (256 Kbytes)

  2. Use of l-r tables. Break one operand into two 8-bit values, and
     store 64 Mb (2 tables of 256 * 64K * 16 bits) of precomputed
     results.

  3. Decomposition of both operands into 2 8-bit blocks, for 4
     sub-products and some shifting/xoring to combine them. We can use
     straight multiplies for the subcalculations, in which case we
     have to make sure the shifts are done modulo the poly, or we can
     use 4 separate multiplication lookup tables which take account of
     the relative positions of the 8-bit operands. The first option
     takes up 128Kbytes, while the second takes up 4 times that, at
     512 Kbytes. For the first option, we could use a second lookup
     table for shifting a partial sum by 8 bits, modulo the
     polynomial. This would be a futher 128Kbytes in size, for a total
     of 256Kbytes.

  4. Decomposition of each operand into 4-bit blocks. This would
     achieve the smallest lookup table size at the cost of calculating
     16 sub-products as well as the need to manually shift the running
     totals by 4 bits at a time. As with the above scheme, we have two
     options for speeding up the shift part of the operations. Either
     we use 16 separate multiply tables (each only 512 bytes) to take
     care of the modulo operation before adding sub-products, or we do
     all multiplies of sub-products as straight multiplies, and use a
     table to look up shifts of 4 bits on full 16-bit numbers, for a
     total size of 128Kbytes.

  5. Use lookup tables for multiplcation by x, x^2, ... , x^15. Each
     table would have to be 128Kbytes in size, so although this method
     should be very fast, it would take up 7.5 times as much as the
     plain log/exp method (assuming we use the zeroth table for an
     inverse lookup table).

  6. Decomposition of one operand into 2 8-bit values, the other into
     4 4-bit values. This has half the number of sub-products as
     option 4 and hence half the number of multiplcation tables. The
     tradeoff is that all tables must now be 8 Kbytes in size. So the
     total memory requirement is 64 Kbytes.

  7. Decomposition into a series of squares? It seems to me that
     there's probably a quick method of multiplication that
     recursively breaks calculations up into a square and a residue
     mod that square. It would probably look very like option 3 above,
     since the square root of a 16-bit polynomial will be 8 bits (or
     less). Or it could be like the l-r table method (assuming we only
     apply the square root operation to one operand).

  The most attractive implementation above would appear to be option 1
  for the best possible speed with a fairly feasible memory footprint.
  Using log/exp lookups allows the full range of arithmetic, so no
  extra tables would be required for inverses or division. Options 2, 3,
  4 and 6 are all variations on the same theme. It seems best to
  create multiplication tables which take account of the position of
  blocks within the operands, rather than using a large (16-bit)
  table for looking up shifts after the fact. Of course, there's
  always the possiblity of calculating shifts manually, which would
  allow us to use a single straight multiply table (with double the
  width, to prevent numeric overflow). 

  Where the options involving breaking multiplications down into
  chunks fall down, however, is that they can't be used to do inverses
  or divisions. I haven't really considered division until now, and I
  suspect that there might be some problems with attempting to break
  divisions up into blocks in the same way as these multiplication
  algorithms. Blocks with zero divisors will obviously be a
  problem.

  Perhaps there is a solution to both the inverse and division problem
  in option 7? Unfortunately, I'm only guessing here... Another guess
  I have about using square roots is that it might be possible to
  compress the log/exp tables. I can't remember the identity involved
  off hand, but it's probably something like this:

   2x
  a      = exp ( log a * 2x ) 

         = exp ( log a * (exp 2 + exp x)

         = exp ( exp 2 * log a + log a * exp x)

         = ???

  I suppose where this is leading is that optimisations of the log
  table have to take account of the base which the logs are calculated
  for. If I were to look up log tables on paper, and the number I
  wanted to look up wasn't there, I'd have to divide my number by the
  base squared until I got a small enough value that I could look up
  int the table. I'd add 1 to the exponent for each time I divided by
  the base squared. At least that's kind of how I remember it...

  Unfortunately, that doesn't really help me understand how this
  should work for a field. Firstly, I don't have an exponent as such,
  since there are no "fractions" (mantissa). Secondly, if the
  technique works, it's dependent on the base used and I won't have a
  nice easy base like 2. It'll probably be 3 at best, and I have a
  feeling that any powers of 2 will not work as generators for any
  field polynomial. I don't know if using a primitive polynomial would
  help there, either.

  Anyway, I'm digressing... most of this will go into lossage anyway,
  so it doesn't matter too much... I will come back to the
  idea of using square roots, though. I'm certain that any number is
  representable in terms of whole numbers and square roots
  (as an orthonormal basis?) so there *should* be a method of
  effectively shrinking the log/exp tables by a quarter, at the cost
  of a few more operations. One of these extra operations will
  undoubtedly be a square root operation...

  But getting back to the main point... I should definitely implement
  a full log/exp method. I should also look at implementing some of
  the blockwise multiplication strategies. 

  I just thought of another optimisation for doing shifts on partial
  products... since we only need to look up shifts which we know will
  overflow (the rest being handled by the << operator), we can omit
  any table entries for which the top bits are zero. If we were
  chunking a 16-bit value into two 8-bit values, and we're doing 8-bit
  shifts, then we save only 256 words. If we were chunking it into
  four 4-bit values, we'd save 2^12 words out of 2^16. That still only
  saves 4096 words, though... I guess that goes to show that you don't
  get good returns for dealing with low numbers specially.

  Other optimisations of the shift operation might be possible if the
  polynomial was sparse and had most of its co-efficients clustered in
  the lower bits. Some number of higher bits could be shifted using
  the standard << operator, with a lookup table taking account of the
  high bits (which are being shifted out, and may cause xors on the
  lower bits) and the low bits. Or it can simply take account of the
  high bits being shifted out to create a mask to xor with the low
  bits to correct them for any modulus operations triggered.

  This last optimisation is a bit tricky because the width of the
  table may not be aligned to bytes, or even nibbles. It is also
  ineffective if the chosen polynomial has any high co-efficients, at
  which point it just degrades to being a more-or-less full shift
  lookup table, with added complexity to account for the new method.

  The question of optimising shifts isn't totally irrelevant. If we
  had an efficient method for it, then we could use straight
  multiplies in our lookups. That would have two consequences.
  Firstly, straight multiplies are faster than mod multiplies, and
  secondly, we'd only need one multiply lookup table. We can't use
  straight multiplies for the l-r table version (because we're
  multiplying a 16-bit number with an 8-bit one, which would need 24
  bits of output, although we could still use an 8-bit shift lookup to
  mask the low bits, then discard the top bits and storing the result
  as a mod multiply result). Well, we could, (see previous
  parenthetical comment), but I think the best results would be in the
  version which breaks both numbers in to 8-bit chunks or the 8:4
  version. The 4:4 version probably wouldn't benefit too much because,
  even though it has more shifts than the other versions, the shifts
  are only 4 bits each, and they're very simple operations in and of
  themselves. Also, since the 4:4 version uses very small multiply
  tables (256 words apiece), we can certainly afford to use several of
  them (16, to be precise) without become concerned about memory
  usage. We also still have the option of using straight long
  multiplies for 6/16 of the tables (since these are the cases which
  won't overflow).

  I won't completely rule out using shift lookup tables, though
  perhaps it's best to leave that particular optimisation until I come
  to working with GF(2^32). I note that the poly I'm using for that
  field has bit 7 as its top bit (besides bit 32, obviously, which
  we're not storing). That puts it just within the first byte, so a
  256-word lookup would be perfect.

  As for the poly I've got for GF(2^16), bit 5 is set, so it is just a
  shade too big for a nibble. That means that either it'll be best to
  only use it for the shift-8 versions, or to add a little bit more
  code to explicitly handle that bit. I could go two ways with this. I
  could look for a smaller primitive polynomial to use. Or I could
  just make a runtime check for routines that make use of accelerated
  shifts to disallow any poly whose second-highest co-efficient is too
  large. I should probably go with the second approach, but make sure
  that I provide an alternative implementation that doesn't rely on
  fast shift lookups.

*/

/* 
  GF(2^16) Method 1: log/exp tables
*/

int  /* 0 = OK, other = error (args or malloc-related) */
gf2_fast_u16_init_m1(gf2_u16 poly, gf2_u16 g, 
		     gf2_u16 **log_table, gf2_u16 **exp_table) {
  gf2_u16  i,p;

  if ((g == 0) || (poly == 0))  return -1;

  (*log_table)=malloc(65536 * sizeof(gf2_u16));
  (*exp_table)=malloc(65536 * sizeof(gf2_u16));
  
  if ((*log_table)==NULL || (*exp_table)==NULL) {
    if ((*log_table)!=NULL) free (*log_table);
    if ((*exp_table)!=NULL) free (*exp_table);
    return -1;
  }
  
  (*exp_table)[0]=1;
  (*log_table)[0]=0;		/* not perfect, but it'll do */
  (*exp_table)[1]=g;  (*log_table)[g]=1;

  p=g;				/* product = generator */
  i=2;				/* next value to store is g^2  */
  do {
    /* 
       See previous log/exp implementation for details of this check.
    */
    if (p == 1) {
      fprintf(stderr,
	      "Bad poly/generator: got product==1 (g was %u, i is %u)", 
	      (unsigned) p, (unsigned) i);
      free (*log_table);
      free (*exp_table);
      return -i;
    }
      
    p=gf2_long_mod_multiply_u16(p,g,poly);
    (*exp_table)[i]=p;
    (*log_table)[p]=i;

  } while (++i);		/* relies on overflow: max + 1 = 0 */

  return 0;
}
void gf2_fast_u16_deinit_m1(gf2_u16 *log_table, gf2_u16 *exp_table) {
  free(log_table);
  free(exp_table);
}

/* 
  some of these might have inline/macro versions; see header file for
  details
 */
gf2_u16 gf2_fast_u16_mul_m1(gf2_u16 *log_table, gf2_u16 *exp_table,
			  gf2_u16 a, gf2_u16 b) {
  gf2_u32 sum;          /* u32, since sum of logs can overflow u16 */
  if ((!a) || (!b)) return 0;
  sum=log_table[a] + log_table[b];
  /* if (sum > 65535) sum -= 65535; */
  sum=(sum & 0xffff) + (sum >> 16);
  return exp_table[sum];
}

gf2_u16 gf2_fast_u16_inv_m1(gf2_u16 *log_table, gf2_u16 *exp_table,
			    gf2_u16 a) {
  return exp_table[65535-log_table[a]];
}

gf2_u16 gf2_fast_u16_div_m1(gf2_u16 *log_table, gf2_u16 *exp_table,
			    gf2_u16 a, gf2_u16 b) {
  gf2_u16 log_a=log_table[a];
  gf2_u16 log_b=log_table[b];
  if (log_a >= log_b) {
    return exp_table[log_a - log_b];
  } else {
    return exp_table[65535 + log_a - log_b];
  }
}

/* 
  GF(2^16) Method 2: l-r tables
  32Mb for each (of 2) multiplication table, 128 Kbytes for inverses
*/
int
gf2_fast_u16_init_m2(gf2_u16 poly, gf2_u16 g, 
		     gf2_u16 **lmul_table,
		     gf2_u16 **rmul_table,
		     gf2_u16 **inv_table) {
  gf2_u32  i,j;
  gf2_u16  k,p;

  (*lmul_table)=malloc(65536 * 256 * sizeof(gf2_u16));
  (*rmul_table)=malloc(65536 * 256 * sizeof(gf2_u16));
  (*inv_table) =malloc(65536 * sizeof(gf2_u16));

  if (((*lmul_table)==NULL) || ((*rmul_table)==NULL)  ||
      ((*inv_table)==NULL)) {
    if ((*lmul_table)!=NULL) free (*lmul_table);
    if ((*rmul_table)!=NULL) free (*rmul_table);
    if ((*inv_table)!=NULL)  free (*inv_table);
    return -1;
  }

  /*
    Since we're allocating so much space, we can use the x0 and x1
    columns of one of the multiplication tables to store log and exp
    tables for the duration of the initialisation routine (using
    columns from the same table rather than just using the zero column
    from two tables should improve locality of reference, and hence
    result in fewer page faults/cpu cache misses; I'll also organise
    the table so that the log/exp table values are contiguous in
    memory). While it might be useful to keep the log/exp tables after
    initialisation, it would mean complicating (slowing down) our
    lookups. If you really wanted the log/exp tables, then you should
    probably just be using them and not be setting up l-r tables at
    all. The only reason I'm using them here is to reduce
    initialisation time. Note that in order to produce the log/exp
    tables, we need to be passed a generator. If the value of the
    generator (g) is 0, or if it turns out not to work, we will go
    back to using the slower long multiply. If the value of g provided
    doesn't work, an error message will be printed, but this will not
    cause the routine to fail since we have our fallback strategy.
  */
  if (g) {
    gf2_u16 *log_table=(*rmul_table);
    gf2_u16 *exp_table=(*rmul_table)+65536;
    gf2_u32 sum;

    /* set up log tables */
    log_table[0]=0;    exp_table[0]=1;
    log_table[g]=1;    exp_table[1]=g;
    p=g;  i=2;
    do {
      if (p == 1) {
	fprintf(stderr,
		"Warning: Bad poly/generator. Using fallback multiply.");
	g=0; break;		/* fall back to long multiply */
      }
      p=gf2_long_mod_multiply_u16(p,g,poly);
      exp_table[i]=p;
      log_table[p]=i;
    } while (++i < 65536);


    /* 
      If that went OK, use log/exp tables to populate the multiply
      tables, then set the x0 and x1 columns to their proper values.
    */
    if (g) {
      for (i=2; i < 256; ++i) {
	(*lmul_table)[ i<<16 ] = 0;
	(*rmul_table)[ i<<16 ] = 0;
	for (j=2; j < 65536; ++j) {
	  sum=log_table[(i<<8)] + log_table[j];
	  if (sum > 65535) sum-=65535;
	  (*lmul_table)[(i<<16) | j ]=exp_table[sum];
	  sum=log_table[i] + log_table[j];
	  if (sum > 65535) sum-=65535;
	  (*rmul_table)[(i<<16) | j ]=exp_table[sum];
	}
      }

      for (j=0; j < 65536; ++j) {
	sum=log_table[(1<<8)] + log_table[j];
	if (sum > 65535) sum-=65535;
	(*lmul_table)[65536 | j]=exp_table[sum];
      }

      memset(*lmul_table,0,65536 * sizeof(gf2_u16));
      memset(*rmul_table,0,65536 * sizeof(gf2_u16));

      for (j=0; j < 65536; ++j) {
	(*rmul_table)[65536 | j]=j;
      }

    }
  }

  /* 
    if we didn't get a generator, or it didn't work, use long
    multiply
  */
  if (g == 0) {
    printf("No valid generator; using long multiply\n");
    /* 
      Since we're only looking up partial products, we won't be able
      to calculate inverses directly from the multiplication
      tables. So we have to call the long version of the inverse
      routine.
      */
    (*inv_table)[0]=0;
    for (i=0; i<256; ++i) {
      (*lmul_table)[ i<<16 ] = 0;
      (*rmul_table)[ i<<16 ] = 0;
    }
    for (j=1; j<65536; ++j) {
      (*inv_table) [ j ] = gf2_long_mod_inverse_u16(j,poly);
      (*lmul_table)[ j ] = 0;
      (*rmul_table)[ j ] = 0;
    }
    for (i=1; i<256; ++i) {
      for (j=1; j<65536; ++j) {
	(*lmul_table)[ (i<<16) | j ] = 
	  gf2_long_mod_multiply_u16((gf2_u16) (i<<8),(gf2_u16) j,poly);
	(*rmul_table)[ (i<<16) | j ] = 
	  gf2_long_mod_multiply_u16((gf2_u16) i,(gf2_u16) j,poly);
      }
    }
  }

  return 0;

}
void gf2_fast_u16_deinit_m2(gf2_u16 *lmul_table, 
			    gf2_u16 *rmul_table, 
			    gf2_u16 *inv_table) {
  free(lmul_table);
  free(rmul_table);
  free(inv_table);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u16 gf2_fast_u16_mul_m2(gf2_u16 *lmul_table,
			    gf2_u16 *rmul_table, 
			    gf2_u16 a, gf2_u16 b) {
  return 
    lmul_table[(((gf2_u32) a & 0xff00) << 8) | b] ^
    rmul_table[(((gf2_u32) a & 0xff ) << 16) | b];
}

gf2_u16 gf2_fast_u16_inv_m2(gf2_u16 *inv_table, gf2_u16 a) {
  return inv_table[a];
}

gf2_u16 gf2_fast_u16_div_m2(gf2_u16 *lmul_table,
			    gf2_u16 *rmul_table, 
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b) {
  gf2_u16 inv=inv_table[b];
  return 
    lmul_table[(((gf2_u32) a & 0xff00) << 8) | inv] ^
    rmul_table[(((gf2_u32) a & 0xff ) << 16) | inv];
}

/*****************************************************************
  Method 3: Optimised log/exp tables
*****************************************************************/
int  /* 0 = OK, other = error (args or malloc-related) */
gf2_fast_u16_init_m3(gf2_u16 poly, gf2_u16 g, 
		     gf2_s32 **log_table, gf2_u16 **exp_table) {
  gf2_s32 i;
  gf2_u16  p;

  if ((g == 0) || (poly == 0))  return -1;

  (*log_table)=malloc(65536 * sizeof(gf2_s32));
  (*exp_table)=malloc(65536 * 4 * sizeof(gf2_u16));

  if ((*log_table)==NULL || (*exp_table)==NULL) {
    if ((*log_table)!=NULL) free (*log_table);
    if ((*exp_table)!=NULL) free (*exp_table);
    return -1;
  }

  /*
     See gf2_u8 version for details
  */
  (*exp_table) += 131072;
  for (i=-131072; i; ++i) {
    (*exp_table)[i]=0; 
  }

  (*log_table)[0]=-65536;  (*exp_table)[0]=1;
  (*log_table)[g]=1;       (*exp_table)[1]=g;
  (*exp_table)[65535]=1;   (*exp_table)[65536]=g;

  /* this next one is to make inv(0)=0 work ok */
  (*exp_table)[65535+65536]=0;

  p=g;				/* product = generator */
  i=2;				/* next value to store is g^2  */
  do {
    if (p == 1) {
      fprintf(stderr,
	      "Bad poly/generator: got product==1 (g was %u, i is %u)", 
	      (unsigned) p, (unsigned) i);
      free (*log_table);
      free (*exp_table - 131072);
      return -i;
    }

    p=gf2_long_mod_multiply_u16(p,g,poly);

    (*exp_table)[i]       = p;
    (*exp_table)[i+65535] = p;
    (*log_table)[p]       = i;

  } while (++i < 65536);

  return 0;
}

void gf2_fast_u16_deinit_m3(gf2_s32 *log_table, gf2_u16 *exp_table) {
  free (log_table);
  free (exp_table - 131072);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u16 gf2_fast_u16_mul_m3(gf2_s32 *log_table, gf2_u16 *exp_table,
			  gf2_u16 a, gf2_u16 b) {
  return exp_table[log_table[a] + log_table[b]];
}

gf2_u16 gf2_fast_u16_inv_m3(gf2_s32 *log_table, gf2_u16 *exp_table,
			  gf2_u16 a) {
  return exp_table[65535-log_table[a]];
}

gf2_u16 gf2_fast_u16_div_m3(gf2_s32 *log_table, gf2_u16 *exp_table,
			  gf2_u16 a, gf2_u16 b) {
  return exp_table[65535 + log_table[a] - log_table[b]];
}

gf2_u16 gf2_fast_u16_pow_m3(gf2_s32 *log_table, gf2_u16 *exp_table,
			  gf2_u16 a, gf2_u16 b) {
  return exp_table[(log_table[a] * b) % 65535];
}


/*****************************************************************
  Method 4: 8-bit x 8-bit chunks
*****************************************************************/
int  /* 0 = OK, other = error (args or malloc-related) */
gf2_fast_u16_init_m4(gf2_u16 poly, 
		     gf2_u16 **mul_table, gf2_u16 **inv_table) {

  int  i,j,k;

  (*mul_table) = malloc(256 * 256 * 4 * sizeof(gf2_u16));
  (*inv_table) = malloc(65536 * sizeof(gf2_u16));

  if (((*mul_table)==NULL)  || ((*inv_table)==NULL)) {
    if ((*mul_table)!=NULL) free (*mul_table);
    if ((*inv_table)!=NULL) free (*inv_table);
    return -1;
  }

  (*inv_table)[0]=0;
  memset((*mul_table),0, 4 * sizeof(gf2_u16));
  for (i=1; i<256; ++i) {
    (*inv_table) [ i ] = gf2_long_mod_inverse_u16(i,poly);
    memset((*mul_table)+ (i<<2), 0, 4 * sizeof(gf2_u16));
    memset((*mul_table)+ (i<<10), 0, 4 * sizeof(gf2_u16));
  }
  for (i=1; i<256; ++i) {
    for (j=1; j<256; ++j) {
      (*mul_table)[ (i<<10) | (j<<2) ] = 
	gf2_long_straight_multiply_u8((gf2_u8) i,(gf2_u8) j);
      (*mul_table)[ (i<<10) | (j<<2) | 1 ] = 
	gf2_long_mod_multiply_u16((gf2_u16) (i<<8) ,(gf2_u16) j,poly);
      (*mul_table)[ (i<<10) | (j<<2) | 2 ] = 
	gf2_long_mod_multiply_u16((gf2_u16) i, (gf2_u16) (j<<8),poly);
      (*mul_table)[ (i<<10) | (j<<2) | 3 ] = 
	gf2_long_mod_multiply_u16((gf2_u16) (i<<8) ,(gf2_u16) (j<<8),poly);
    }
  }

  return 0;

}

void gf2_fast_u16_deinit_m4(gf2_u16 *mul_table, gf2_u16 *inv_table) {
  free(mul_table);
  free(inv_table);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u16 gf2_fast_u16_mul_m4(gf2_u16 *mul_table, 
			    gf2_u16 a, gf2_u16 b) {

  register gf2_u32 a_lo=(((gf2_u32) a & 0xff)<<10);
  register gf2_u32 a_hi=(((gf2_u32) a & 0xff00)<<2);
  register gf2_u32 b_lo=((b & 0xff)<<2);
  register gf2_u32 b_hi=((b & 0xff00)>>6);

  return 
    mul_table [ a_lo  | b_lo    ] ^
    mul_table [ a_hi  | b_lo | 1] ^
    mul_table [ a_lo  | b_hi | 2] ^
    mul_table [ a_hi  | b_hi | 3]
    ;
}

gf2_u16 gf2_fast_u16_inv_m4(gf2_u16 *inv_table, gf2_u16 a) {
  return inv_table[a];
}

gf2_u16 gf2_fast_u16_div_m4(gf2_u16 *mul_table, 
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b) {
  gf2_u16 inv=inv_table[b];
  return gf2_fast_u16_mul_m4(mul_table,a,inv);
}



/*****************************************************************
  Method 5: 8-bit x 8-bit chunks
*****************************************************************/
int  /* 0 = OK, other = error (args or malloc-related) */
gf2_fast_u16_init_m5(gf2_u16 poly, 
		     gf2_u16 **m1_tab,
		     gf2_u16 **m2_tab,
		     gf2_u16 **m3_tab,
		     gf2_u16 **m4_tab,
		     gf2_u16 **inv_table) {

  int  i,j,k;

  (*m1_tab) = malloc(256 * 256 * 4 * sizeof(gf2_u16));
  (*inv_table) = malloc(65536 * sizeof(gf2_u16));

  if (((*m1_tab)==NULL)  || ((*inv_table)==NULL)) {
    if ((*m1_tab)!=NULL)    free (*m1_tab);
    if ((*inv_table)!=NULL) free (*inv_table);
    return -1;
  }

  (*m2_tab)=(*m1_tab) + 65536;
  (*m3_tab)=(*m2_tab) + 65536;
  (*m4_tab)=(*m3_tab) + 65536;

  (*inv_table)[0]=0;
  (*m1_tab)[0]=0;
  (*m2_tab)[0]=0;
  (*m3_tab)[0]=0;
  (*m4_tab)[0]=0;

  for (i=1; i<256; ++i) {
    (*inv_table) [ i ] = gf2_long_mod_inverse_u16(i,poly);
    (*m1_tab) [ i      ] = 0;
    (*m1_tab) [ i<<8   ] = 0;
    (*m2_tab) [ i      ] = 0;
    (*m2_tab) [ (i<<8) ] = 0;
    (*m3_tab) [ i      ] = 0;
    (*m3_tab) [ (i<<8) ] = 0;
    (*m4_tab) [ i      ] = 0;
    (*m4_tab) [ (i<<8) ] = 0;
  }

  for (i=1; i<256; ++i) {
    for (j=1; j<256; ++j) {
      (*m1_tab) [ (i<<8) + (j) ] = 
	gf2_long_straight_multiply_u8((gf2_u8) i,(gf2_u8) j);
       (*m2_tab) [ (i<<8) + (j) ] = 
	gf2_long_mod_multiply_u16((gf2_u16) (i<<8) ,(gf2_u16) j,poly);
      (*m3_tab) [ (i<<8) + (j) ] = 
	gf2_long_mod_multiply_u16((gf2_u16) i, (gf2_u16) (j<<8),poly);
      (*m4_tab) [ (i<<8) + (j) ] = 
	gf2_long_mod_multiply_u16((gf2_u16) (i<<8) ,(gf2_u16) (j<<8),poly);
    }
  }

  return 0;

}

void gf2_fast_u16_deinit_m5(gf2_u16 *m1_tab, gf2_u16 *inv_table) {
  free(m1_tab);
  free(inv_table);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u16 gf2_fast_u16_mul_m5(gf2_u16 *m1_tab,
			    gf2_u16 *m2_tab,
			    gf2_u16 *m3_tab,
			    gf2_u16 *m4_tab, 
			    gf2_u16 a, gf2_u16 b) {
  register gf2_u16 a_lo=a << 8;
  register gf2_u16 a_hi=a & 0xff00;
  register gf2_u16 b_lo=b & 0xff;
  register gf2_u16 b_hi=b >> 8;

  return m1_tab [ a_lo | b_lo ] ^ m2_tab [ a_hi | b_lo ] ^
         m3_tab [ a_lo | b_hi ] ^ m4_tab [ a_hi | b_hi ];
}

gf2_u16 gf2_fast_u16_inv_m5(gf2_u16 *inv_table, gf2_u16 a) {
  return inv_table[a];
}

gf2_u16 gf2_fast_u16_div_m5(gf2_u16 *m1_tab,
			    gf2_u16 *m2_tab,
			    gf2_u16 *m3_tab,
			    gf2_u16 *m4_tab,
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b) {
  return gf2_fast_u16_mul_m5(m1_tab,m2_tab,m3_tab,m4_tab,a,inv_table[b]);
}

/********************************************************************
 Method 6: 8-bit x 8-bit straight multiply, with manual shift
********************************************************************/

int  /* 0 = OK, other = error (args or malloc-related) */
gf2_fast_u16_init_m6(gf2_u16 poly, 
		     gf2_u16 **mul_table, gf2_u16 **inv_table) {

  int  i,j,k;

  (*mul_table) = malloc(256 * 256 * sizeof(gf2_u16));
  (*inv_table) = malloc(65536 * sizeof(gf2_u16));

  if (((*mul_table)==NULL)  || ((*inv_table)==NULL)) {
    if ((*mul_table)!=NULL) free (*mul_table);
    if ((*inv_table)!=NULL) free (*inv_table);
    return -1;
  }

  (*inv_table)[0]=0;
  (*mul_table)[0]=0;
  for (i=1; i<256; ++i) {
    (*inv_table) [ i ]    = gf2_long_mod_inverse_u16(i,poly);
    (*mul_table) [ i    ] = 0;
    (*mul_table) [ i<<8 ] = 0;
  }
  for (i=1; i<256; ++i) {
    (*inv_table) [ i<<8 ] = gf2_long_mod_inverse_u16(i<<8,poly);
    for (j=1; j<256; ++j) {
      (*mul_table)[ (i<<8) | (j) ] = 
	gf2_long_straight_multiply_u8((gf2_u8) i,(gf2_u8) j);
      (*inv_table) [ (i<<8) | j ] = gf2_long_mod_inverse_u16((i<<8) | j,poly);
    }
  }

  return 0;

}

void gf2_fast_u16_deinit_m6(gf2_u16 *mul_table, gf2_u16 *inv_table) {
  free(mul_table);
  free(inv_table);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u16 gf2_fast_u16_mul_m6(gf2_u16 *mul_table, 
			    gf2_u16 a, gf2_u16 b, gf2_u16 poly) {

  gf2_u16 c = mul_table[(a & 0xff00) | (b >> 8)];

  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }

  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }

  c ^= mul_table[ (a & 0xff00) | (b & 0xff)];
  c ^= mul_table[ ((a << 8) & 0xffff) | (b >> 8) ];

  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }

  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }
  if (c & HIGH_BIT_gf2_u16) { c = (c << 1) ^ poly; } else { c <<= 1; }

  return c ^ mul_table[((a << 8) & 0xffff) | (b & 0xff)];
}

gf2_u16 gf2_fast_u16_inv_m6(gf2_u16 *inv_table, gf2_u16 a) {
  return inv_table[a];
}

gf2_u16 gf2_fast_u16_div_m6(gf2_u16 *mul_table, 
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b, gf2_u16 poly) {
  gf2_u16 inv=inv_table[b];
  return gf2_fast_u16_mul_m6(mul_table,a,inv,poly);
}

/********************************************************************
 Method 7: 8-bit x 8-bit straight multiply, with accelerated shift
********************************************************************/

int  /* 0 = OK, other = error (args or malloc-related) */
gf2_fast_u16_init_m7(gf2_u16 poly, 
		     gf2_u16 **mul_table, gf2_u16 **inv_table,
		     gf2_u16 **shift_tab) {

  int     i,j;
  gf2_u16 k,mask;

  (*mul_table) = malloc(65536 * sizeof(gf2_u16));
  (*inv_table) = malloc(65536 * sizeof(gf2_u16));
  (*shift_tab) = malloc(256 * sizeof(gf2_u16));

  if (((*mul_table)==NULL)  || ((*inv_table)==NULL) ||
      ((*shift_tab)==NULL)) {
    if ((*mul_table)!=NULL) free (*mul_table);
    if ((*shift_tab)!=NULL) free (*shift_tab);
    if ((*inv_table)!=NULL) free (*inv_table);
    return -1;
  }

  (*inv_table)[0] = 0;
  (*mul_table)[0] = 0;
  (*shift_tab)[0] = 0;
  for (i=1; i<256; ++i) {
    (*inv_table) [ i ] = gf2_long_mod_inverse_u16(i,poly);
    (*mul_table) [ i      ] = 0;
    (*mul_table) [ i<<8   ] = 0;

    k=i<<8; 
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    (*shift_tab)[i]= k ;
  }
  for (i=1; i<256; ++i) {
    (*inv_table) [ (i<<8) ] = gf2_long_mod_inverse_u16((i<<8),poly);
    for (j=1; j<256; ++j) {
      (*mul_table)[ (i<<8) | (j) ] = 
	gf2_long_straight_multiply_u8((gf2_u8) i,(gf2_u8) j);
      (*inv_table) [ (i<<8) | j ] = gf2_long_mod_inverse_u16((i<<8)|j,poly);
    }
  }

  return 0;

}

void gf2_fast_u16_deinit_m7(gf2_u16 *mul_table, gf2_u16 *inv_table,
			    gf2_u16 *shift_tab) {
  free(mul_table);
  free(inv_table);
  free(shift_tab);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u16 gf2_fast_u16_mul_m7(gf2_u16 *mul_table, gf2_u16 *shift_tab,
			    gf2_u16 a, gf2_u16 b) {

  gf2_u16 c = mul_table[(a & 0xff00) | (b >> 8)];

  c= (c << 8) ^ shift_tab[c >> 8];

  c ^= mul_table[ (a & 0xff00) | (b & 0xff)];
  c ^= mul_table[ ((a << 8) & 0xffff) | (b >> 8) ];

  c= (c << 8) ^ shift_tab[c >> 8];

  return c ^ mul_table[((a << 8) & 0xffff) | (b & 0xff)];
}

gf2_u16 gf2_fast_u16_inv_m7(gf2_u16 *inv_table, gf2_u16 a) {
  return inv_table[a];
}

gf2_u16 gf2_fast_u16_div_m7(gf2_u16 *mul_table, 
			    gf2_u16 *inv_table,
			    gf2_u16 *shift_tab,
			    gf2_u16 a, gf2_u16 b) {
  return gf2_fast_u16_mul_m7(mul_table,shift_tab,a,inv_table[b]);
}

/********************************************************************
 Method 8: 4/2 split, using l-r tables for nibbles, fast 8-bit shifts
********************************************************************/
int gf2_fast_u16_init_m8(gf2_u16 poly, 
			 gf2_u16 **lmul_table,
			 gf2_u16 **rmul_table,
			 gf2_u16 **shift_tab,
			 gf2_u16 **inv_table) {

  gf2_u16  i,j;
  gf2_u16  k;

  (*lmul_table) = malloc(256 * 16 * sizeof(gf2_u16));
  (*rmul_table) = malloc(256 * 16 * sizeof(gf2_u16));
  (*shift_tab)  = malloc(256 * sizeof(gf2_u16));
  (*inv_table)  = malloc(65536 * sizeof(gf2_u16));

  if (((*lmul_table)==NULL)  || ((*rmul_table)==NULL)  ||
      ((*shift_tab)==NULL) || ((*inv_table)==NULL)) {
    if ((*lmul_table)!=NULL) free (*lmul_table);
    if ((*rmul_table)!=NULL) free (*rmul_table);
    if ((*shift_tab)!=NULL)  free (*shift_tab);
    if ((*inv_table)!=NULL)  free (*inv_table);
    return -1;
  }

  (*lmul_table)[0]=0;
  (*rmul_table)[0]=0;
  (*shift_tab)[0]=0;
  (*inv_table)[0]=0;
  (*inv_table)[1]=1;
  for (j=2; j; ++j) {
    (*inv_table) [ j ] = gf2_long_mod_inverse_u16(j,poly);
  }

  for (j=1; j<256; ++j) {
    (*lmul_table) [ j ] = 0;
    (*rmul_table) [ j ] = 0;
    k=j<<8; 
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u16) { k = (k << 1) ^ poly; } else { k <<= 1; }
    (*shift_tab)[j]= k ;
  }

  for (i=1; i<16 ; ++i) {
    (*lmul_table)[i << 8] = 0;
    (*rmul_table)[i << 8] = 0;
    for (j=1; j<256; ++j) {
      (*lmul_table)[ (i << 8) | (j) ] = 
	gf2_long_straight_multiply_u8((gf2_u8) (i << 4),(gf2_u8) j);
      (*rmul_table)[ (i << 8) | (j) ] = 
	gf2_long_straight_multiply_u8((gf2_u8) (i), (gf2_u8) j);
    }
  }
  return 0;
}

void gf2_fast_u16_deinit_m8(gf2_u16 *lmul_table, gf2_u16 *rmul_table, 
			    gf2_u16 *shift_tab, gf2_u16 *inv_table) {
  free(lmul_table);
  free(rmul_table);
  free(shift_tab);
  free(inv_table);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u16 gf2_fast_u16_mul_m8(gf2_u16 *lmul_table, gf2_u16 *rmul_table, 
			    gf2_u16 *shift_tab,
			    gf2_u16 a, gf2_u16 b) {

  /* break a into four nibbles, b into two 8-bit words */
  gf2_u16 a3=((a >> 4 ) & 0x0f00);
  gf2_u16 a2=((a      ) & 0x0f00);
  gf2_u16 a1=((a << 4 ) & 0x0f00);
  gf2_u16 a0=((a << 8 ) & 0x0f00);
  gf2_u16 b1=((b >> 8 ) & 0x00ff);
  gf2_u16 b0=((b      ) & 0x00ff);

  gf2_u16 c = lmul_table[a3 | b1] ^ rmul_table[a2 | b1] ;

  /* no safe shifts */
  c = (c << 8) ^ shift_tab[c >> 8];

  c ^=  lmul_table[a3 | b0] ^ rmul_table[a2 | b0];
  c ^=  lmul_table[a1 | b1] ^ rmul_table[a0 | b1];

  c = (c << 8) ^ shift_tab[c >> 8];

  return c ^ lmul_table[a1 | b0] ^ rmul_table[a0 | b0];
}

gf2_u16 gf2_fast_u16_inv_m8(gf2_u16 *inv_table, gf2_u16 a) {
  return inv_table[a];
}

gf2_u16 gf2_fast_u16_div_m8(gf2_u16 *lmul_table, 
			    gf2_u16 *rmul_table, 
			    gf2_u16 *shift_tab,
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b) {
  return gf2_fast_u16_mul_m8(lmul_table,rmul_table,shift_tab,
			     a,inv_table[b]);
}


/********************************************************************

  GF(2^32) routines

  We don't have so many techniques available to us here, mainly
  because log and exponent tables would have to be ridiculously large
  (unless you're running some serious iron, of course). There is
  basically only one routine that I would consider right now:

  * chunk all operands into 8-bit values and use the fast shifting
    method.

  The only other method that seems viable would be to chunk into
  operands into 8 and 16 bit values and to use the fast shifting
  algorithm. That will have a similar memory footprint to the 16-bit
  l-r table lookup method. Whereas the 16-bit method used two lookup
  tables to distinguish high-byte and low-byte lookups, we'd only be
  using one because we're using straight multiplies and the shift
  lookup table, but entries in the table will be twice as wide.

  Actually, now that I've written that down, it does seem like it's a
  viable method. I'll implement that first...

********************************************************************/

int gf2_fast_u32_init_m1(gf2_u32 poly, 
			 gf2_u32 **mul_table,
			 gf2_u32 **shift_tab) {

  gf2_u16  i,j;
  gf2_u32  k;

  (*mul_table) = malloc(65536 * 256 * sizeof(gf2_u32));
  (*shift_tab) = malloc(256 * sizeof(gf2_u32));

  if (((*mul_table)==NULL)  || ((*shift_tab)==NULL)) {
    if ((*mul_table)!=NULL) free (*mul_table);
    if ((*shift_tab)!=NULL) free (*shift_tab);
    return -1;
  }

  (*mul_table)[0]=0;
  (*shift_tab)[0]=0;
  for (i=1; i<256; ++i) {
    (*mul_table) [ i ] = 0;
    k=i<<24; 
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    (*shift_tab)[i]= k ;
  }
  for (i=1; i ; ++i) {
    (*mul_table)[i << 8] = 0;
    for (j=1; j<256; ++j) {
      (*mul_table)[ (i<<8) | (j) ] = 
	gf2_long_straight_multiply_u16((gf2_u16) i,(gf2_u16) j);
    }
  }
  return 0;
}

void gf2_fast_u32_deinit_m1(gf2_u32 *mul_table, gf2_u32 *shift_tab) {
  free(mul_table);
  free(shift_tab);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u32 gf2_fast_u32_mul_m1(gf2_u32 *mul_table, gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b) {

  /* break a into two 16-bit words, b into four 8-bit words */
  /* making all these the same type since it may be more efficient
     to or them together that way? */
  gf2_u32 hi=((a>>8) & 0xffff00);
  gf2_u32 lo= ((a<<8) & 0xffff00);
  gf2_u32 b3=(b >> 24);
  gf2_u32 b2=((b >> 16) & 0xff);
  gf2_u32 b1=((b >> 8) & 0xff);
  gf2_u32 b0=b & 0xff;

  gf2_u32 c = mul_table[hi | b3 ];

  /* only the first shift is safe from overflow */
  c <<= 8;
  c ^= mul_table[ hi | b2 ];
  c = (c << 8) ^ shift_tab[c >> 24];
  c ^= mul_table[ hi | b1 ];
  c ^= mul_table[ lo | b3 ];
  c = (c << 8) ^ shift_tab[c >> 24];
  c ^= mul_table[ lo | b2 ];
  c ^= mul_table[ hi | b0 ];
  c = (c << 8) ^ shift_tab[c >> 24];
  c ^= mul_table[ lo | b1 ];
  c = (c << 8) ^ shift_tab[c >> 24];

  return c ^ mul_table[ lo | b0 ];
}

gf2_u32 gf2_fast_u32_inv_m1(gf2_u32 a,gf2_u32 poly) {
  return gf2_long_mod_inverse_u32(a,poly);
}

gf2_u32 gf2_fast_u32_div_m1(gf2_u32 *mul_table, 
			    gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b,gf2_u32 poly) {
  return gf2_fast_u32_mul_m1(mul_table,shift_tab,a,
			     gf2_long_mod_inverse_u32(b, poly));
}
 
/********************************************************************
 Method 2: break each operand into 8-bit blocks, use fast shifts
********************************************************************/
int gf2_fast_u32_init_m2(gf2_u32 poly, 
			 gf2_u16 **mul_table,
			 gf2_u32 **shift_tab) {

  gf2_u16  i,j;
  gf2_u32  k;

  (*mul_table) = malloc(256 * 256 * sizeof(gf2_u16));
  (*shift_tab) = malloc(256 * sizeof(gf2_u32));

  if (((*mul_table)==NULL)  || ((*shift_tab)==NULL)) {
    if ((*mul_table)!=NULL) free (*mul_table);
    if ((*shift_tab)!=NULL) free (*shift_tab);
    return -1;
  }

  (*mul_table)[0]=0;
  (*shift_tab)[0]=0;
  for (i=1; i<256; ++i) {
    (*mul_table) [ i ] = 0;
    k=i<<24; 
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    (*shift_tab)[i]= k ;
  }
  for (i=1; i<256 ; ++i) {
    (*mul_table)[i << 8] = 0;
    for (j=1; j<256; ++j) {
      (*mul_table)[ (i<<8) | (j) ] = 
	gf2_long_straight_multiply_u8((gf2_u8) i,(gf2_u8) j);
    }
  }
  return 0;
}

void gf2_fast_u32_deinit_m2(gf2_u16 *mul_table, gf2_u32 *shift_tab) {
  free(mul_table);
  free(shift_tab);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u32 gf2_fast_u32_mul_m2(gf2_u16 *mul_table, gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b) {

  /* break both operands into four 8-bit words */
  gf2_u16 a3=((a >> 16) & 0xff00);
  gf2_u16 a2=((a >> 8 ) & 0xff00);
  gf2_u16 a1=((a      ) & 0xff00);
  gf2_u16 a0=((a << 8 ));
  gf2_u16 b3=((b >> 24) & 0xff);
  gf2_u16 b2=((b >> 16) & 0xff);
  gf2_u16 b1=((b >>  8) & 0xff);
  gf2_u16 b0=((b      ) & 0xff);

  gf2_u32 c = mul_table[a3 | b3];
  c <<= 8;  /* the first 2 shifts are safe from overflow. */

  /*
    There's an easy method of checking that these calculations are
    done in the correct order.. we've already done a3|b3, which needs
    a total of 6 shifts. Then we do any combinations that add up to 5
    shifts, ie a2|b3 or a3|b2, and so on down to a0|b0 which doesn't
    need any shifting at all.
  */
  c ^=  mul_table[a3 | b2];
  c ^=  mul_table[a2 | b3];
  c <<= 8;
  c ^=  mul_table[a3 | b1];
  c ^=  mul_table[a2 | b2];
  c ^=  mul_table[a1 | b3];
  c = (c << 8) ^ shift_tab[c >> 24];
  c ^=  mul_table[a3 | b0];
  c ^=  mul_table[a2 | b1];
  c ^=  mul_table[a1 | b2];
  c ^=  mul_table[a0 | b3];
  c = (c << 8) ^ shift_tab[c >> 24];
  c ^=  mul_table[a2 | b0];
  c ^=  mul_table[a1 | b1];
  c ^=  mul_table[a0 | b2];
  c = (c << 8) ^ shift_tab[c >> 24];
  c ^=  mul_table[a1 | b0];
  c ^=  mul_table[a0 | b1];
  c = (c << 8) ^ shift_tab[c >> 24];

  return c ^ mul_table[a0 | b0];
}

gf2_u32 gf2_fast_u32_inv_m2(gf2_u32 a, gf2_u32 poly) {
  return gf2_long_mod_inverse_u32(a,poly);
}

gf2_u32 gf2_fast_u32_div_m2(gf2_u16 *mul_table, 
			    gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b, gf2_u32 poly) {
  return gf2_fast_u32_mul_m2(mul_table,shift_tab,a,
			     gf2_long_mod_inverse_u32(b, poly));
}

/********************************************************************
 Method 3: 4/8 split, using l-r tables for nibbles, fast 8-bit shifts
********************************************************************/
int gf2_fast_u32_init_m3(gf2_u32 poly, 
			 gf2_u16 **lmul_table,
			 gf2_u16 **rmul_table,
			 gf2_u32 **shift_tab) {

  gf2_u16  i,j;
  gf2_u32  k;

  (*lmul_table) = malloc(256 * 16 * sizeof(gf2_u16));
  (*rmul_table) = malloc(256 * 16 * sizeof(gf2_u16));
  (*shift_tab)  = malloc(256 * sizeof(gf2_u32));

  if (((*lmul_table)==NULL)  || ((*rmul_table)==NULL)  || ((*shift_tab)==NULL)) {
    if ((*lmul_table)!=NULL) free (*lmul_table);
    if ((*rmul_table)!=NULL) free (*rmul_table);
    if ((*shift_tab)!=NULL)  free (*shift_tab);
    return -1;
  }

  (*lmul_table)[0]=0;
  (*rmul_table)[0]=0;
  (*shift_tab)[0]=0;
  for (j=1; j<256; ++j) {
    (*lmul_table) [ j ] = 0;
    (*rmul_table) [ j ] = 0;
    k=j<<24; 
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    if (k & HIGH_BIT_gf2_u32) { k = (k << 1) ^ poly; } else { k <<= 1; }
    (*shift_tab)[j]= k ;
  }

  for (i=1; i<16 ; ++i) {
    (*lmul_table)[i << 8] = 0;
    (*rmul_table)[i << 8] = 0;
    for (j=1; j<256; ++j) {
      (*lmul_table)[ (i << 8) | (j) ] = 
	gf2_long_straight_multiply_u8((gf2_u8) (i << 4),(gf2_u8) j);
      (*rmul_table)[ (i << 8) | (j) ] = 
	gf2_long_straight_multiply_u8((gf2_u8) (i),(gf2_u8) j);
    }
  }
  return 0;
}

void gf2_fast_u32_deinit_m3(gf2_u16 *lmul_table, gf2_u16 *rmul_table, 
			    gf2_u32 *shift_tab) {
  free(lmul_table);
  free(rmul_table);
  free(shift_tab);
}

/* some of these might have inline/macro versions; see header file for
   details */
gf2_u32 gf2_fast_u32_mul_m3(gf2_u16 *lmul_table, gf2_u16 *rmul_table, 
			    gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b) {

  /* break a into 8 nibbles, b into four 8-bit words */
  gf2_u16 a7=((a >> 20) & 0x0f00);
  gf2_u16 a6=((a >> 16) & 0x0f00);
  gf2_u16 a5=((a >> 12) & 0x0f00);
  gf2_u16 a4=((a >> 8 ) & 0x0f00);
  gf2_u16 a3=((a >> 4 ) & 0x0f00);
  gf2_u16 a2=((a      ) & 0x0f00);
  gf2_u16 a1=((a << 4 ) & 0x0f00);
  gf2_u16 a0=((a << 8 ) & 0x0f00);
  gf2_u16 b3=((b >> 24) & 0x00ff);
  gf2_u16 b2=((b >> 16) & 0x00ff);
  gf2_u16 b1=((b >>  8) & 0x00ff);
  gf2_u16 b0=((b      ) & 0x00ff);

  gf2_u32 c = lmul_table[a7 | b3] ^ rmul_table[a6 | b3] ;
  c <<= 8;  /* the first 2 shifts are safe from overflow. */
  c ^=  lmul_table[a7 | b2] ^ rmul_table[a6 | b2];
  c ^=  lmul_table[a5 | b3] ^ rmul_table[a4 | b3];
  c <<= 8;  /* the first 2 shifts are safe from overflow. */
  c ^=  lmul_table[a7 | b1] ^ rmul_table[a6 | b1];
  c ^=  lmul_table[a5 | b2] ^ rmul_table[a4 | b2];
  c ^=  lmul_table[a3 | b3] ^ rmul_table[a2 | b3];
  c = (c << 8) ^ shift_tab[c >> 24];
  c ^=  lmul_table[a7 | b0] ^ rmul_table[a6 | b0];
  c ^=  lmul_table[a5 | b1] ^ rmul_table[a4 | b1];
  c ^=  lmul_table[a3 | b2] ^ rmul_table[a2 | b2];
  c ^=  lmul_table[a1 | b3] ^ rmul_table[a0 | b3];
  c = (c << 8) ^ shift_tab[c >> 24];
  c ^=  lmul_table[a5 | b0] ^ rmul_table[a4 | b0];
  c ^=  lmul_table[a3 | b1] ^ rmul_table[a2 | b1];
  c ^=  lmul_table[a1 | b2] ^ rmul_table[a0 | b2];
  c = (c << 8) ^ shift_tab[c >> 24];
  c ^=  lmul_table[a3 | b0] ^ rmul_table[a2 | b0];
  c ^=  lmul_table[a1 | b1] ^ rmul_table[a0 | b1];
  c = (c << 8) ^ shift_tab[c >> 24];

  return c ^ lmul_table[a1 | b0] ^ rmul_table[a0 | b0];
}

gf2_u32 gf2_fast_u32_inv_m3(gf2_u32 a, gf2_u32 poly) {
  return gf2_long_mod_inverse_u32(a,poly);
}

gf2_u32 gf2_fast_u32_div_m3(gf2_u16 *lmul_table, 
			    gf2_u16 *rmul_table, 
			    gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b, gf2_u32 poly) {
  return gf2_fast_u32_mul_m3(lmul_table,rmul_table,shift_tab,a,
			     gf2_long_mod_inverse_u32(b, poly));
}


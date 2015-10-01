/* Copyright (c) Declan Malone 2009 */

/* Vector (SIMD) version of Galois Field arithmetic */
/* SPU version. Currently only does GF(2^8) multiplication; matrix
   code not implemented. Until this is complete, use spu-math.c for
   regular scalar polynomial/matrix multiply.
*/

#include "spu-vecmath.h"

vec_uchar16
gf2_vec_mod_multiply_u8( vec_uchar16 a,
			 vec_uchar16 b,
			 vec_uchar16 poly) {

  vec_uchar16 result;
  vec_uchar16 one     = spu_splats((unsigned char) 1);
  vec_uchar16 mask    = one;

  /* result = (b & 1) ? a : 0; */
  vec_uchar16 other   = spu_splats((unsigned char) 0);
  vec_uchar16 masked  = spu_and(b,mask);
  vec_uchar16 cond    = spu_cmpeq(masked,mask);

  result = spu_sel(other,a,cond);

  /* There doesn't seem to be a shift left operator that works on
     8-bit values, so use the quadword version and use and to clear
     the low bit in each byte. The mask doesn't have to be anded in
     this way because we end the routine before it can overflow */

#define GF2_UNROLL(HIGH_BIT) \
\
  /* if (a & HIGH_BIT) { a = (a << 1) ^ poly; } else { a <<= 1; } */ \
  masked = spu_and(a,HIGH_BIT); \
  cond   = spu_cmpeq(masked,HIGH_BIT); \
  a      = spu_slqw(a,1); \
  a      = spu_andc(a,one); \
  other  = spu_xor(a,poly); \
  a      = spu_sel(a,other,cond); \
 \
  /* if (b & mask) { result ^= a; } */ \
  mask   = spu_slqw(mask,1); \
  masked = spu_and(b,mask); \
  cond   = spu_cmpeq(masked,mask); \
  other  = spu_xor(result,a); \
  result = spu_sel(result,other,cond)

  GF2_UNROLL(128);		/* 2 */
  GF2_UNROLL(128);		/* 4 */
  GF2_UNROLL(128);		/* 8 */
  GF2_UNROLL(128);		/* 16 */
  GF2_UNROLL(128);		/* 32 */
  GF2_UNROLL(128);		/* 64 */

  /*
    if (b & HIGH_BIT) { 
      result ^= ((a & 128) ? (a << 1) ^ poly :  a << 1); 
    }
  */
  GF2_UNROLL(128);		/* 128 */

  return result;
}


// Although the split and combine steps are both effectively the same
// matrix multiplication algorithm, separate routines are provided
// because the organisation of the input and output matrices are
// different and so need to be optimised differently for the most
// efficient use of vector multiplication routine.
gf2_matrix_t *
gf2_ida_split_u8(gf2_matrix_t *xform, 
		 vec_uchar16 poly,
		 gf2_matrix_t *in,  
		 gf2_matrix_t *out) {

  //
  // split routine requires:
  //
  // ROWWISE transform matrix
  // COLWISE input matrix
  // ROWWISE output matrix


  


}


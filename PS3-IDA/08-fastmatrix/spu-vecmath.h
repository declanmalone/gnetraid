/* Copyright (c) Declan Malone 2009 */

#include <spu_intrinsics.h>
#include "common.h"		/* needed for matrix struct */

vec_uchar16
gf2_vec_mod_multiply_u8( vec_uchar16 a,
			 vec_uchar16 b,
			 vec_uchar16 poly);

gf2_matrix_t *
gf2_ida_split_u8(gf2_matrix_t *xform, 
		 vec_uchar16 poly,
		 gf2_matrix_t *in,  
		 gf2_matrix_t *out);


gf2_matrix_t *
gf2_ida_combine_u8(gf2_matrix_t *xform, 
		   vec_uchar16 poly,
		   gf2_matrix_t *in,  
		   gf2_matrix_t *out);

// Macros for doing "non-aligned" (ie, sub-vector size) reads.  Used
// to feed multiple values values at a time into the vector multiply
// code.
//
// Briefly, how this works is as follows. Firstly, a call to init sets
// up the passed variable to store an initial memory pointer (which
// needs to be 16-byte aligned), two mask registers (used for shufb
// operations which move the read bytes into the start of the return
// register), and a buffer register for holding any left-over
// bytes. The init call also specifies a "remainder" value. The macros
// can read two sizes of vectors: either a full 16-byte vector, or
// this "remainder" value (which is less than 16). The idea is that
// when multiplying large matrices the caller will make as many calls
// to retrieve a full vector's worth of data as possible (using the
// SPU_NARV macro), then when fewer bytes are needed (ie, when there
// are fewer than 16 bytes of data in the current row/column being
// operated on), the caller calls the SPU_NARR macro to read the
// remaining bytes.
//
// Calls to SPU_NARV and SPU_NARR can be intermingled, so that after
// reading a full matrix row (with multiple SPU_NARV calls, and at
// most one SPU_NARR call), the next call to SPU_NARR or SPU_NARV will
// read the bytes at the start of the next matrix row, assuming the
// rows are stored contiguously in memory.
//
// For brevity, the macro code doesn't contain any comments. To figure
// out how it works, it's probably best to consult the matrix multiply
// code to see it in operation. Running the code through the C
// preprocessor might also be useful.

/* All arguments except _VAL args should be variable names */
#define SPU_NARINIT(MEM, \
		    SELQ, \
		    SELR, \
		    REM_VAL, \
		    BUF \
	    ) \
{ \
  unsigned int mask; \
  vec_uchar16 vmask; \
\
  BUF=*((vec_uchar16 *) (MEM)); \
  MEM+=16; \
\
  SELQ = (vec_uchar16) { 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 }; \
\
  SELR=SELQ; \
\
  mask=(1 << (15 - REM_VAL)) -1; \
  vmask=spu_maskb(mask); \
  vmask=spu_and(vmask, 128); \
  SELR=spu_or(SELR,vmask); \
\
}

/*
  For macros that return a value, pass a variable which will store it
  as the first arg. Also note that temporary variables must also be
  passed in in order to avoid the overhead of allocating new ones each
  time the macro is called
 */
#define SPU_NARV(RETVAL, \
		  MEM, \
		  TMP_PTR, \
		  SELQ, \
		  SELR, \
		  BUF, \
		  TMP_BUF) \
{ \
  TMP_PTR  = (MEM) + 16; \
  MEM     -=  ((unsigned int)  (MEM) & 15); \
  TMP_BUF  = *((vec_uchar16 *) (MEM)); \
\
  RETVAL=spu_shuffle(BUF, TMP_BUF, SELQ); \
\
  (BUF)=TMP_BUF; \
  (MEM)=TMP_PTR; \
}

#define SPU_NARR(RETVAL, \
		  MEM, \
		  TMP_PTR, \
		  SELQ,	\
		  SELR,	\
		  REM_VAL, \
		  BUF, \
		  TMP_BUF, \
		  TMP_UCHAR, \
		  TMP_VEC_COND,	   \
		  TMP_VEC_MASK_8F, \
		  TMP_VEC_MASK_9F, \
		  TMP_VEC_ADD_REM, \
		  TMP_VEC_ADD_REM_16) \
{ \
  TMP_PTR=(MEM) + REM_VAL; \
\
  TMP_UCHAR= (((((unsigned int) (MEM)    & ~15)) == \
	       (((unsigned int) (TMP_PTR) & ~15))) * 0xff); \
  TMP_VEC_COND = (vec_uchar16) spu_splats(TMP_UCHAR); \
\
  TMP_BUF = *((vec_uchar16 *) ((unsigned) (MEM) & ~ 15)); \
  TMP_BUF = spu_sel(TMP_BUF,BUF,TMP_VEC_COND); \
\
  RETVAL = spu_shuffle(BUF, TMP_BUF, SELR); \
\
  TMP_VEC_ADD_REM=(vec_uchar16) \
    spu_add((vec_ushort8) SELQ, \
	    (unsigned short) (REM_VAL + \
			      ((unsigned short) REM_VAL << 8))); \
  TMP_VEC_ADD_REM_16 = (vec_uchar16) \
    spu_add((vec_ushort8) SELQ, (unsigned short) \
	    ((16+REM_VAL) + ((unsigned short) (16+REM_VAL) << 8))); \
  SELQ = spu_sel(TMP_VEC_ADD_REM_16,TMP_VEC_ADD_REM,TMP_VEC_COND); \
  SELQ = spu_and(SELQ, 0x9f); \
\
  TMP_VEC_MASK_8F = (vec_uchar16) \
    spu_add((vec_ushort8) SELR, (unsigned short) \
	    (REM_VAL + ((unsigned short) REM_VAL << 8))); \
  TMP_VEC_MASK_9F = TMP_VEC_MASK_8F; \
  TMP_VEC_MASK_8F = spu_and(TMP_VEC_MASK_8F, 0x8F); \
  TMP_VEC_MASK_9F = spu_and(TMP_VEC_MASK_9F, 0x9F); \
  SELR = spu_sel(TMP_VEC_MASK_8F,TMP_VEC_MASK_9F,TMP_VEC_COND); \
\
  MEM=TMP_PTR; \
  BUF=TMP_BUF; \
}


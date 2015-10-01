/* Copyright (c) Declan Malone 2009 */

#ifndef SPU_MATRIX_H
#define SPU_MATRIX_H

#ifdef __SPU__
#include <spu_intrinsics.h>
#else
#define vec_uchar16 int
#endif

#include "spu-math.h"
#include "common.h"

// new SIMD code at end

//
// Modes of operation
//
// In an ideal situation there would be just one mode of operation,
// namely just "matrix multiply". However, in practice the choice of
// the best algorithm for doing multiplication depends on the
// organisation of the input and output matrices. With the IDA
// application, input and output are more efficient if single files
// (original input or combined output) can be read/written to/from a
// matrix with a column-wise organisation. For share files, however,
// it's better to use a row-wise matrix organisation. 
//
// What is more efficient for the input/output routines does not
// necessarily match up with efficiency in actually computing the
// matrix, however. For computation, the best arrangement is to have
// the input matrix in column-wise format. Fortunately, the
// organisation of the output matrix does not matter as much, although
// the ordering of the iterating loops used will favour one
// organisation at the expense of the other. The best performance for
// multiplication will have the input matrix stored in column-wise
// format, which is the format used for the split operation.
//
// What this all boils down to is that several variations on the
// matrix multiply code are possible, and the host program will have
// to select the correct one (or the best one from among several
// correct options) to suit the organisation of the input/output
// matrices. These different options are given here. The names are
// chosen to reflect (in order) the organisation of the input matrix,
// the organisation of the output matrix, and then the particular
// implementation method for that arrangement of organisations.

enum { 
  SPE_NOTHING,
  /* generic implementations */
  SPE_ROW_COL_ROWWISE,		/* calculate output elements one */
  SPE_COL_ROW_ROWWISE,		/* row at a time */
  SPE_ROW_COL_COLWISE,		/* calculate output elements one */
  SPE_COL_ROW_COLWISE,		/* column at a time */
  /* don't multiply, just re-organise */
  SPE_ROW_COL_REORG,		/* only for 'combine' layout matrix */
  /* combine re-organisation and multiply */
  SPE_ROW_COL_REORG_ROW,	/* calc output one row at a time */
  SPE_ROW_COL_REORG_COL,	/* calc output one col at a time */
  /* list of specially-optimised modes */
  /* ... */
  /* invalid method (always the last in this list) */
  SPE_INVALID,
};

//
// Matrix type
//

// Since this has to store a pointer to the values stored in the
// matrix, and pointer types are not the same between the PPE and SPE,
// we have to store a uint64_t value instead of a true pointer
// type. This means that additional casting may be needed on both
// sides.

typedef struct {
  int rows;
  int cols;
  int width;			/* number of bytes in each element */
  //char *values;
  uint64_t values;		/* compatible across PPE, SPE */
  enum {
    UNDEFINED, ROWWISE, COLWISE,
  } organisation;
  /* 
    save some information so we know whether to call free() when we're
    finished with the object. FREE_NONE means don't call free on either
    the structure or the values array.
  */
  enum {
    FREE_NONE, FREE_VALUES, FREE_STRUCT, FREE_BOTH,
  } alloc_bits;
} gf2_matrix_t;


volatile gf2_matrix_t *
gf2_matrix_multiply(gf2_matrix_t *xform, 
		    volatile gf2_matrix_t *in,  
		    volatile gf2_matrix_t *out);

// utility function: print matrix
void dump_matrix (gf2_matrix_t * mat);


// New SIMD-based matrix multiply

#define APPORTION_SET_MASK(MASK, BYTES) \
  MASK   = ((1 << (BYTES)) -1);

#define APPORTION_SET_VEC(VECTOR,MASK)		\
  VECTOR = spu_maskb(MASK);

#define APPORTION_PRODUCT(MASK, PRODUCT, TOTAL, NEXT_TOTAL, TMP_VEC) \
  TMP_VEC    = spu_maskb(~MASK); \
  TOTAL      = spu_xor (TOTAL, spu_and(PRODUCT,TMP_VEC)); \
  TMP_VEC    = spu_maskb(MASK); \
  NEXT_TOTAL = spu_and(PRODUCT, TMP_VEC);

#define XOR_ACROSS_UCHAR16(VECTOR) \
  VECTOR = spu_xor (VECTOR, spu_rlqwbyte (VECTOR, 8)); \
  VECTOR = spu_xor (VECTOR, spu_rlqwbyte (VECTOR, 4)); \
  VECTOR = spu_xor (VECTOR, spu_rlqwbyte (VECTOR, 2)); \
  VECTOR = spu_xor (VECTOR, spu_rlqwbyte (VECTOR, 1));


void dump_vec_uchar16(char *s, vec_uchar16 v);

// "Wrap-around read" matrix multiply. Assumes that xform uses rowwise
// organisation, input colwise. Output matrix organisation can be
// either rowwise or colwise. This routine orders the evaluation of
// calculations in such a way as to optimise both memory accesses on
// the transform and input matrices and utilisation of the
// vector-based field multiplication routine. An efficient vector-wide
// xor algorithm is also used, which can xor across 16 values using
// only 4 rotate and 4 xor operations.
//
// This routine does not work on small xform matrices (n * k * w < 32)
// due to different wrap-around code being needed for such cases. For
// the moment, use the generic (non-optimised) multiply routine. I
// plan to implement a variation on the below code to handle
// wrap-around reads where the entire xform matrix can fit in 2 (or 1)
// registers later. The routine also assumes that the input and output
// matrices have n, k*w and 16 as factors (ie, cols = x.lcm(n,k*w,16),
// where x is an integer). This routine also assumes that the
// input/output matrices are sufficiently large (>32 bytes) to ensure
// the wrap-around code works correctly.

gf2_matrix_t *
warm_multiply_u8(gf2_matrix_t *xform, 
		 gf2_matrix_t *in,
		 gf2_matrix_t *out,
		 vec_uchar16   poly);



#endif

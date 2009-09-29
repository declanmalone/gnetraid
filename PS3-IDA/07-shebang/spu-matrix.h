/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#ifndef SPU_MATRIX_H
#define SPU_MATRIX_H

#ifdef __SPU__
#include <spu_intrinsics.h>
#else
#endif

#include "spu-math.h"

//
// TODO: Modes of operation
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

#endif

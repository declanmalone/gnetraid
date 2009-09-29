/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#ifndef SPU_TASK_H
#define SPU_TASK_H

#include "spu-matrix.h"

// verbose flag is now a #define to allow compiler to optimise out all
// debug statements using Dead Code Elimination feature.

#define verbose 2

// extern int verbose;


// Move away from static allocation used in previous (demo) versions

// globals corresponding to hard-coded macro values

// make old macro names continue to work
#define LS_MATRIX_COLS (opts->spe_cols)
#define N_BUFS         (opts->buf_pairs)

// globals defined in spu-task.c
extern gf2_matrix_t xform;
extern gf2_matrix_t ppe_in;
extern gf2_matrix_t ppe_out;


#endif

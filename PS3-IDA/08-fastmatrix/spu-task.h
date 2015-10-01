/* Copyright (c) Declan Malone 2009 */

#ifndef SPU_TASK_H
#define SPU_TASK_H

#include "spu-matrix.h"


#define verbose 2


// Move away from static allocation...

// globals corresponding to hard-coded macro values

// make old macro names continue to work
#define LS_MATRIX_COLS (opts->spe_cols)
#define N_BUFS         (opts->buf_pairs)

// globals defined in spu-task.c
extern gf2_matrix_t xform;
extern gf2_matrix_t ppe_in;
extern gf2_matrix_t ppe_out;

// extern int verbose;

#endif

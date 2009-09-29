/* Copyright (c) Declan Malone 2009 */

/* Stuff that both host/spu tasks need */

#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>

#include "spu-matrix.h"

//
// Size of local store matrix
//
// This code is hard-wired to use statically-allocated buffers on the
// SPE side, and it checks that the threshold system being operated on
// has (k,n) == (8,8) and w == 1. This is just done in order to keep
// things simple. In a real program, the PPE will have to calculate
// the optimum size of the local store matrix space, and the SPE will
// use malloc to reserve that much memory. In both cases, the value of
// LS_MATRIX_COLS must be a multiple of the least common multiple of
// (k,n,16), which in this specific case is 16. This is to ensure that
// each block being operated on is properly aligned for the
// vector-based matrix multiply routines.

#define LS_MATRIX_COLS  (16 * 256)


//
// Parameter block (same as in runargs demo)
//

typedef struct {

  /* parameters for this operation */
  uint32_t n;
  uint32_t k;
  uint32_t w;
  uint32_t spe_cols;            /* columns in local in/out matrices */

  /*
    Both of the following should be small values, so they can be use
    the smaller uint16_t data type. This should bring the total size
    of the structure down to 48 bytes, allowing the SPE_RUN_USER_REGS
    flag to be set when starting the program, eliminating the need to
    DMA the structure as a separate step.
  */
  uint16_t mode;                /* see spu-matrix.h */
  uint16_t buf_pairs;           /* 1=single-buffered */

  /*
    The caller doesn't pass a matrix structure for any of the
    matrices, but we need to know how many columns there are in the
    input/output matrices so that we can calculate the address of each
    row so we can do DMA transfers.
  */
  uint32_t host_cols;

  /* remaining values are taken to be addresses */

  /* addresses of the values of each matrix in host memory space */
  uint64_t xform_values;
  uint64_t in_values;
  uint64_t out_values;

  /* pad this structure to a multiple of 128 bits */
  // uint32_t pad[3];  /* not needed; struct is 48 bytes in size */

} task_setup_t;


// define a macro to print the values stored in the struct
// takes a pointer to a structure.

#define DUMP_OPTS(ptr) { \
    printf("Parameters:\nn = %d\n", ptr->n); \
    printf("k = %d\n", ptr->k); \
    printf("w = %d\n", ptr->w);			\
    printf("pairs = %d\n", ptr->buf_pairs); \
    printf("our cols = %d\n", ptr->spe_cols); \
    printf("mode = %d\n", ptr->mode); \
    printf("host cols = %d\n", ptr->host_cols); \
    printf("out_values = %lld\n", ptr->out_values); \
  }


#endif

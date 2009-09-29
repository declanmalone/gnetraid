/* Copyright (c) Declan Malone 2009 */

/* Stuff that both host/spu tasks need */

#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>

#include "spu-matrix.h"

// alignment macro; ALIGN must be a power of 2
#define align_up(X, ALIGN) (((X) & ((ALIGN) - 1)) ?		 \
			    (((X) + (ALIGN)) & ~((ALIGN) - 1)) : \
			    (X))

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
    printf("Parameters:\nn = %u\n", ptr->n); \
    printf("k = %u\n", ptr->k); \
    printf("w = %u\n", ptr->w);			\
    printf("pairs = %u\n", ptr->buf_pairs); \
    printf("our cols = %u\n", ptr->spe_cols); \
    printf("mode = %u\n", ptr->mode); \
    printf("host cols = %u\n", ptr->host_cols); \
    printf("in_values = %llu\n", ptr->in_values); \
    printf("out_values = %llu\n", ptr->out_values); \
    printf("xform_values = %llu\n", ptr->xform_values); \
  }


#endif

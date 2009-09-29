/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#include "spu-task.h"
#include "spu-matrix.h"

#include <stdio.h>

// One-size-fits-all (u8, u16, u32) matrix multiply. No optimisations
// done for matrix organisation or to exploit possible SIMD operation.
volatile gf2_matrix_t *
gf2_matrix_multiply(gf2_matrix_t *xform, 
		    volatile gf2_matrix_t *in,  
		    volatile gf2_matrix_t *out) {

  int r,c,i;
  gf2_u8 sum_u8;
  gf2_u16 sum_u16;
  gf2_u32 sum_u32;

  int bits = xform->width << 3;

  // navigate either matrix organisation
  uint32_t xform_down, xform_across;
  uint32_t in_down,    in_across;
  uint32_t out_down,   out_across;
  uint32_t xform_row,  in_col;

  if (verbose) printf("SPE: entered matrix multiply\n");

  xform_across = (xform->width);
  xform_down   = (xform->width * xform->cols);
  if (in->organisation == ROWWISE) {
    in_across = (in->width);
    in_down   = (in->width * in->cols);
  } else {
    in_across = (in->width * in->rows);
    in_down   = (in->width);
  }
  if (out->organisation == ROWWISE) {
    out_across = (out->width);
    out_down   = (out->width * out->cols);
  } else {
    out_across = (out->width * out->rows);
    out_down   = (out->width);
  }

  // same loop three times, one for each width
  switch (bits) {

  case 8:
    for (r = 0; r < out->rows; ++r) {
      for (c = 0; c < out->cols; ++c) {
	xform_row = (uint32_t) xform->values + r * xform_down;
	in_col    = (uint32_t) in->values    + c * in_across;
	sum_u8 = gf2_mul(bits, 
		      *((gf2_u8 *) xform_row),
		      *((gf2_u8 *) in_col));
	for (i = 1; i < xform->cols; ++i) {
	  in_col    += in_down;
	  xform_row += xform_across;
	  sum_u8 ^= gf2_mul(bits, 
			    *((gf2_u8 *) xform_row),
			    *((gf2_u8 *) in_col));
	}
	((gf2_u8 *) (uint32_t) out->values)
	  [r * out_down + c * out_across] = sum_u8;
      }
      if (verbose > 2)
	printf ("SPE: matrix multiply finished row %d\n", r);
    }
    break;

  case 16:
    for (r = 0; r < out->rows; ++r) {
      for (c = 0; c < out->cols; ++c) {
	xform_row = (uint32_t) xform->values + r * xform_down;
	in_col    = (uint32_t) in->values    + c * in_across;
	sum_u16 = gf2_mul(bits, 
			  *((gf2_u16 *) xform_row),
			  *((gf2_u16 *) in_col));
	for (i = 1; i < xform->cols; ++i) {
	  in_col    += in_down;
	  xform_row += xform_across;
	  sum_u16 ^= gf2_mul(bits, 
			 *((gf2_u16 *) xform_row),
			 *((gf2_u16 *) in_col));
	}
	*((gf2_u16 *) ((uint32_t) out->values +
		       r * out_down + c * out_across)) = sum_u16;
      }
    }
    break;

  case 32:
    for (r = 0; r < out->rows; ++r) {
      for (c = 0; c < out->cols; ++c) {
	xform_row = (uint32_t) xform->values + r * xform_down;
	in_col    = (uint32_t) in->values    + c * in_across;
	sum_u32 = gf2_mul(bits, 
			  *((gf2_u32 *) xform_row),
			  *((gf2_u32 *) in_col));
	for (i = 1; i < xform->cols; ++i) {
	  in_col    += in_down;
	  xform_row += xform_across;
	  sum_u32 ^= gf2_mul(bits, 
			 *((gf2_u32 *) xform_row),
			 *((gf2_u32 *) in_col));
	}
	*((gf2_u32 *) ((uint32_t) out->values +
		       r * out_down + c * out_across)) = sum_u32;
      }
    }
    break;
  default:
    printf ("WARN: unknown number of bits: %d\n", bits);
  }

  if (verbose) printf("SPE: finished matrix multiply\n");

  return out;
}

// dump matrix (useful for debugging)
void dump_matrix (gf2_matrix_t *m) {

  int r,c,b;
  int nibbles;

  // navigate either matrix organisation
  int down, across;

  if (m->organisation == ROWWISE) {
    across = (m->width);
    down   = (m->width * m->cols);
  } else {
    down   = (m->width);
    across = (m->width * m->rows);
  }

  printf ("Dumping matrix with %d rows, %d cols, width %d\n",
	  m->rows, m->cols, m->width);

  nibbles = m->width * 2;

  // assumes values stored in big-endian format (which SPE is)
  for (r=0; r < m->rows; ++r) {
    printf ("| ");
    for (c=0; c < m->cols; ++c) {
      for (b = 0; b < m->width; ++b) {
	printf ("%02x", 
		(char) (*(char*) ((uint32_t) 
				 m->values + down * r + across * c + b )));
      }
      printf (" ");
    }
    printf ("|\n");
  }
  printf ("\n");
}

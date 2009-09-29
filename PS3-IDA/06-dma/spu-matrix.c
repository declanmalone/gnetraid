/* Copyright (c) Declan Malone 2009 */

#include "spu-matrix.h"

#include <stdio.h>

gf2_matrix_t *
gf2_matrix_multiply_u8(gf2_matrix_t *xform, 
		       gf2_u8        poly,
		       gf2_matrix_t *in,  
		       gf2_matrix_t *out) {

  // one-size-fits-all (u8) matrix multiply
  int r,c,i;
  gf2_u8 sum;
  int bits = xform->width << 3;

  // navigate either matrix organisation
  uint32_t xform_down, xform_across;
  uint32_t in_down,    in_across;
  uint32_t out_down,   out_across;
  uint32_t xform_row,  in_col;

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

  for (r = 0; r < out->rows; ++r) {
    for (c = 0; c < out->cols; ++c) {
      xform_row = xform->values + r * xform_down;
      in_col    = in->values    + c * in_across;
      sum = gf2_mul(bits, 
		    *((char *) (uint32_t) xform_row),
		    *((char *) (uint32_t) in_col));
      for (i = 1; i < xform->cols; ++i) {
	in_col    += in_down;
	xform_row += xform_across;
	sum ^= gf2_mul(bits, 
		       *((char *) xform_row),
		       *((char *) in_col));
      }
      ((char *) out->values)[r * out_down + c * out_across] = sum;
    }
  }

  return out;
}

void dump_matrix (gf2_matrix_t *m) {

  int r,c;
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
      printf ("%0*x ", nibbles,
	      ((char*)(m->values))[ down * r + across * c ]);
    }
    printf ("|\n");
  }
  printf ("\n");
}

/* Copyright (c) Declan Malone 2009 */

#include <stdio.h>
#include <spu_intrinsics.h>

#include "spu-task.h"
#include "spu-matrix.h"

#define debug 0

void dump_vec_uchar16(char *s, vec_uchar16 v) {
  int i;
  printf ("%s: [",s);
  for (i=0;i < 16; ++i) 
    printf("%s%02x", (i? ", " : ""), spu_extract(v,i));
  printf ("]\n");
}

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
		 vec_uchar16   poly) {

  char *xform_ptr = (char*) (uint32_t) xform->values;
  char *in_ptr    = (char*) (uint32_t) in->values;

  int n, k, w, in_bytes;
  int r, or, ic, oc;
  int i, j;

  // use modulo addressing to determine when to handle dot-product and
  // matrix wrap-arounds
  uint32_t mod_kw_addr=0;
  uint32_t mod_nkw_addr=0;
  unsigned char rem=0;		// number of bytes to apportion to
				// next total
  unsigned char consume_bytes;


  unsigned char sum;
  uint16_t mask;
  register vec_uchar16 vec_mask;

  // starting mask (re-use later when calculating correct mask at end
  // of xform matrix)
  register vec_uchar16 smask = { 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 };

  // first level of buffering; we'll take 16 bytes from across these
  // read-ahead buffers
  register vec_uchar16 xbuf0, xbuf1;
  register vec_uchar16 ibuf0, ibuf1;

  // masks to use with shufb to extract correct vector from above
  register vec_uchar16 xmask = smask;
  register vec_uchar16 imask = smask;

  // extracted values to pass to multiply routine
  register vec_uchar16 m1,m2;

  // second level of buffering; products of two full vectors. Only a
  // single register is needed here since we will always work on 16
  // bytes of data at a time; the xform/input buffering handles any
  // alignment issues.
  register vec_uchar16 pbuf;

  // it is still useful to use a mask to selb (not shufb, as with
  // xform, input buffes) between wrapped/non-wrapped input bytes.
  register vec_uchar16 pmask;

  // third level; selected products for adding. tbuf_next is used at
  // the end of the dot product to temporarily store total to be
  // carried forward to next dot product. 
  register vec_uchar16 tbuf, tbuf_next;

  // allocate a single extra vector for temporary storage/calculations
  register vec_uchar16 tmp_vec;

  // shorter names for matrix dimensions
  n = xform -> rows;
  k = xform -> cols;
  w = xform -> width;
  in_bytes = w * k * in->cols;

  // read-ahead one vector from transform, input matrices into buffers
  xbuf0 = *(vec_uchar16 *) xform_ptr; xform_ptr += 16;
  ibuf0 = *(vec_uchar16 *) in_ptr++;  in_ptr    += 16;

  // first write to output is at (row,col) (0,0). Next is (1,1),
  // (2,2), down to (n-1,n-1). At that point, we rewind to (0,1) and
  // work diagonally down as before. This ordering is used in order to
  // achieve 100% utilisation of the vector multiply routine.
  or = 0; ic = 0; 


  // clear totals. Rather than clearing the totals at the top of each
  // dot product loop, clear it once here and then at the end of the
  // loop and any remaining values are carried forward to the next
  // loop. This helps us work on 16 bytes of products at a time,
  // regardless of memory alignment or wrap-around issues.
  tbuf = spu_xor(smask, smask);

  do {

    // we have different wrap-around code depending on whether we're
    // going from one row to the next or wrapping around to start of
    // xform matrix again. Do all row-to-row iterations in one loop,
    // then handle the last row separately.


    if (debug) printf("top of loop, (ic,or) = (%d,%d)\n", ic,or);

    // read 16 bytes each time around this loop. detect and handle
    // wrap-around on a full matrix or dot product boundaries.

    // handle wrap-around on right-hand side of input matrix. The
    // input matrix should always end on a 16-byte boundary, so we
    // don't have to worry about partial vectors while wrapping
    // around there.
    in_ptr -= in_bytes * ((uint32_t) in_ptr >= in->values + in_bytes);

    // read in next vectors
    xbuf1 = *(vec_uchar16 *) xform_ptr; xform_ptr += 16;
    ibuf1 = *(vec_uchar16 *) in_ptr;    in_ptr    += 16;

    mod_kw_addr  += 16;
    mod_nkw_addr += 16;

    m1 = spu_shuffle(xbuf0,xbuf1,xmask);
    m2 = spu_shuffle(ibuf0,ibuf1,imask);

    if (debug) {
      dump_vec_uchar16("m1", m1);
      dump_vec_uchar16("m2", m2);
      dump_vec_uchar16("xmask",xmask);
      dump_vec_uchar16("imask",imask);
    }

    // wrap around full xform matrix? This just sets up the new read
    // buffers and sets up m1, m2 to include some bytes from the old
    // stream and some bytes from the new one. The actual
    // apportionment and storage of the completed value is done in
    // the dot-product wrap-around code which follows.
    if (mod_nkw_addr >= n * k * w) {

      register uint16_t jmask;

      // handle end of matrix
      if (debug) printf ("Matrix boundary\n");

      rem = (mod_nkw_addr -= n * k * w);

      // set up read-ahead buffers for new stream.

      // wrap-around xform address
      xform_ptr  = (char *) (uint32_t) xform->values;
      xform_ptr -= (uint32_t) xform_ptr & 15;

      xbuf1 =  *(vec_uchar16 *) xform_ptr; xform_ptr += 16;

      // wrap-around input address
      j = ((ic+1) % in->cols) * w * k;
      in_ptr  = (char*) (uint32_t) in->values + j;
      in_ptr -= (uint32_t) in_ptr & 15;

      jmask = (j & 15) + rem;

      /* This if() statement can be eliminated with a bit of
	 conditional maths. It doesn't matter if ibuf0 is set and
	 the condition doesn't hold, since we'll only be interested
	 in bytes in ibuf1 with any bytes from ibuf0 being masked
	 out. */
      /*
	if (jmask >= 16) {
	// the part we want to shufb from the input register spans
	// two aligned memory locations, so read in the first part
	ibuf0 = *(vec_uchar16 *) (in_ptr);
	in_ptr += 16;
	jmask  -= 16;
	in_ptr -= in_bytes * (in_ptr >= &(in->values[in_bytes]));
	}
      */
      ibuf0 = *(vec_uchar16 *) (in_ptr);
      in_ptr += 16 * (jmask >= 16);
      jmask  -= 16 * (jmask >= 16);
      in_ptr -= in_bytes * ((uint32_t) in_ptr >= in->values + in_bytes);

      ibuf1 = *(vec_uchar16 *) (in_ptr); in_ptr += 16;

      // shufb masks for selecting bytes from new stream

      xmask = (vec_uchar16)
	spu_add((vec_ushort8) smask,
		((uint16_t) rem << 8) |
		((uint16_t) rem));
      imask = (vec_uchar16)
	spu_add((vec_ushort8) smask,
		(jmask << 8) | jmask);

      if (debug) printf ("matrix wrap-around rem is %d\n", rem);

      // we've already read in values from old streams into m1, m2,
      // so we can re-use buffer and mask variables to read from new
      // streams now.

      APPORTION_SET_MASK(mask, rem);
      APPORTION_SET_VEC(vec_mask, mask);

      if (debug) {
	dump_vec_uchar16("in vec_mask", vec_mask);
	dump_vec_uchar16("previous m2", m2);
      }

      m1 = spu_sel(m1, spu_shuffle(xbuf0, xbuf1, xmask), vec_mask);
      m2 = spu_sel(m2, spu_shuffle(ibuf0, ibuf1, imask), vec_mask);

      if (debug) {
	dump_vec_uchar16("xbuf0", xbuf0);
	dump_vec_uchar16("xbuf1", xbuf1);
	dump_vec_uchar16("xmask", xmask);
	dump_vec_uchar16("ibuf0", ibuf0);
	dump_vec_uchar16("ibuf1", ibuf1);
	dump_vec_uchar16("imask", imask);

	dump_vec_uchar16("wrapped m1", m1);
	dump_vec_uchar16("wrapped m2", m2);
      }

      // finally, it's time to multiply ... but we defer that to the
      // dot-product wrap-around code below.
    }

    // multiply next 16 bytes and store in next buffer slot
    pbuf = gf2_vec_mod_multiply_u8(m1, m2, poly);

    // dot-product boundary? (matrix boundary is also a dot-product
    // boundary, so this will also save final value in each matrix
    // block multiplication)
    if (mod_kw_addr >= k * w) {
	
      rem           = (mod_kw_addr - (k * w));
      if (rem < 16)
	consume_bytes = 16 - rem;
      else 
	consume_bytes = 16;

      if (debug) printf ("Dot product boundary\n");

      if (debug) {
	dump_vec_uchar16("pbuf",pbuf);
	dump_vec_uchar16("tbuf before apportion", tbuf);
      }

      // loop for as many times as there are ending/full dot
      // products in current pbuf
      do {

	APPORTION_SET_MASK(mask, rem);
	APPORTION_PRODUCT(mask, pbuf, tbuf, tbuf_next, vec_mask);
	if (debug) {
	  printf("dot product wrap-around rem is %d\n", rem);
	  printf ("mask is %04x\n", mask);
	  dump_vec_uchar16("tbuf after apportion", tbuf);
	  dump_vec_uchar16("tbuf_next", tbuf_next);

	  dump_vec_uchar16("pbuf after apportion", pbuf);
	}

	pbuf=spu_slqwbyte(pbuf, consume_bytes);

	if (debug)
	  dump_vec_uchar16("pbuf after shift", pbuf);

	// sum all bytes in current total and save it in output matrix
	XOR_ACROSS_UCHAR16(tbuf);

	if (debug) 
	  printf ("Inserting dp-final value %x\n", spu_extract(tbuf,3));
	// printf ("Value should equal %x\n", spu_extract(tbuf,0));

	((char*) out->values)[or * w * out->cols + 
			      (ic * w + or * w) % 
			      (w * out->cols)] = spu_extract(tbuf,3);

	// advance to next dot product. Also need to check whether
	// we've wrapped around to the top of the input matrix

	if(++or == n) {
	  // printf ("WARNING: DP wrote across matrix boundary\n");

	  or = 0; ic++;
	  if (debug)
	    dump_matrix(out);
	}

	tbuf           = spu_xor(tbuf,tbuf);
	rem            = 16 - (k * w);
	consume_bytes  = k * w;
	mod_kw_addr   -= consume_bytes;

      } while (mod_kw_addr >= consume_bytes);

      tbuf           = tbuf_next;

      if (debug) printf ("Finished dot product loop\n");

    } else {			// no wrap-around

      // haven't crossed dot product boundary yet

      if (debug) {
	dump_vec_uchar16("m1", m1);
	dump_vec_uchar16("m2", m2);
	dump_vec_uchar16("pbuf",pbuf);
      }

      // extract current vector, add it to total
      tbuf = spu_xor(tbuf, pbuf);

      if (debug) dump_vec_uchar16("tbuf",tbuf);
    }

    // advance buffers
    xbuf0 = xbuf1; ibuf0 = ibuf1;

    if (debug) 
      printf ("Finished full vector of dot product\n");

  } while (ic < out->cols);

  return out;

}


volatile gf2_matrix_t *
gf2_matrix_multiply(gf2_matrix_t *xform, 
		    volatile gf2_matrix_t *in,  
		    volatile gf2_matrix_t *out) {

  // one-size-fits-all (u8, u16, u32) matrix multiply
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

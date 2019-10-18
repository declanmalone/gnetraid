/* perpetual.c */
/* Implementation of Perptual Codes */

#include <stdio.h>

#include "perpetual.h"
#include "gf8.h"

/* Start implementing the 2015 paper, allowing for various field
   sizes:

   F_2       straight binary (bit-based XOR)
   F_2**8    8-bit words
   F_2**16   16-bit words
   F_2**32   32-bit words

   All but the first of these require full field multiplication and
   division of symbols.

   Besides the field size, the other major parameter is the alpha
   value. 

*/

void perp_init_encoder_2015(struct perp_settings_2015 *s,
			    struct perp_encoder_2015 *e) {

  
  

}

unsigned pivot_bin(struct perp_settings_2015 *s, struct perp_decoder_2015 *d) {
  return d->remain;
}

unsigned pivot_gf8(struct perp_settings_2015 *s,
		   struct perp_decoder_2015 *d,
		   unsigned i,
		   unsigned char *code,
		   unsigned char *sym)
{
  unsigned tries = 0;
  short ctz_row, ctz_code = -1, clz_code;
  unsigned char temp;
  unsigned char *cp, *bp, *rp;
  unsigned short code_size = s->code_size;
  unsigned short blocksize = s->blocksize;
  unsigned short cancelled, zero_sym;
  
  while (++tries < s->gen * 2) {

    if (d->filled[i] == 0) {
      d->filled[i] = 1;
      memcpy(d->coding + code_size * i, code, code_size);
      memcpy(d->symbol + blocksize * i, sym,  blocksize);
      return --(d->remain);
    }

    // Avoid recalculating ctz_code if we already know it
    if (ctz_code == -1) {
      for (ctz_code = 0, cp=code + code_size - 1;
	   cp >= code;
	   --cp ) {
	if (*cp != 0) break;
	++ctz_code;
      }
    }

    // We could also memoise ctz_row, but for now I'll just calculate it
    bp = d->coding + i * code_size;
    for (ctz_row = 0, cp = bp + code_size - 1;
	 cp >= bp;
	 --cp ) {
      if (*cp != 0) break;
      ++ctz_code;
    }

    if (ctz_code > ctz_row) {

      // swap code vectors (skipping last ctz_row zeroes, which are equal)
      cp = code + code_size - 1 - ctz_row;
      rp = d->coding + ((i+1) * code_size) - 1 - ctz_row;
      while (cp >= code) {
	temp = *cp;
	*cp  = *rp;
	*rp  = temp;
	--cp; --rp;
      }

      // swap symbols (we could use indirect tables, allowing us to
      // swap pointers instead of memory)
      cp = sym;
      rp = d->symbol + i * blocksize;
      bp = rp + blocksize;
      while (rp < bp) {
	temp = *cp;
	*cp  = *rp;
	*rp  = temp;
	++cp; ++rp;
      }

      // update ctz_code
      ctz_code = ctz_row;

      // Actually, this optimisation won't work if the subtraction
      // below cancels out trailing elements in code, so disable it
      ctz_code = -1;
    }

    // Subtract matrix "row" from our code, symbol
    cancelled = 1;		/* incidentally, check if code became zero */
    zero_sym  = 1;		/* same for symbol (for debugging) */
    cp = code;
    rp = d->coding + i * code_size;
    bp = rp + code_size;
    while (rp < bp) {
      if (*(cp++) ^= *(rp++)) cancelled = 0;
    }
    cp = sym;
    rp = d->symbol + i * blocksize;
    bp = rp + blocksize;
    while (rp < bp) {
      if (*(cp++) ^= *(rp++)) zero_sym = 0;
    }

    if (cancelled) {
      if (zero_sym) return d->remain;
      fprintf(stderr,  "failed: zero code vector => zero symbol (i=$d)\n", i);
      exit(1);
    }

    // count leading zeros to find new i value
    clz_code = 0;
    cp = code; bp = code + code_size;
    while (cp < bp) {
      if (*cp) break;
      ++clz_code;
      ++cp;
    }
    // cp now points to first non-zero value
    temp = gf256_inv_elem(*cp);
    ++cp;			// skip past implicit 1
    gf256_vec_mul(cp,  temp, code_size - clz_code - 1);
    gf256_vec_mul(sym, temp, blocksize);

    // shift left
    rp = code;
    while (cp < bp) { *(rp++) = *(cp++); }
    while (rp < bp) { *(rp++) = 0; }

    // update i value
    i = (i + clz_code + 1) % s->gen;
  }
  fprintf(stderr, "Bailing after 2 * gen attempts to pivot\n");
}
 
int solve_gf8(struct perp_settings_2015 *s,
	      struct perp_decoder_2015  *d) {

  // I could try implementing a more complicated scheme for doing
  // matrix operations in-place (on d->coding) as much as possible,
  // but I don't think that it's worth it.

  signed   short i, j, k;
  unsigned char *cp, *rp, *bp;
  unsigned short alpha     = s->alpha;
  unsigned short gen       = s->gen;
  unsigned short code_size = s->code_size;
  unsigned int   blocksize = s->blocksize;
  unsigned char *mat_rows  = d->mat_rows;
  unsigned short diag, swap_row, down_row;
  unsigned char temp;

  // rp -> destination (j'th row of mat_rows)
  rp = mat_rows;
  j = 0;
  do {
    // cp -> start of code being upgraded
    cp = d->coding + (gen - alpha + j) * code_size;
    // bp -> -j'th byte of the code vector
    bp = cp + code_size - ++j;

    // Layout of the new row:
    //
    // (end)      (zeros)          (1)   (start)
    //  (j)  + (gen - alpha - 1) + (1) (alpha - j) = gen

    for (i=1;  i <= j;            ++i)   *(rp++) = *(bp++);
    for (i=1;  i <  gen - alpha;  ++i)   *(rp++) = 0;
                                         *(rp++) = 1;
    for (i=1;  i <= alpha - j;    ++i)   *(rp++) = *(cp++);
  } while (j != alpha);

  // forward propagation
  for (diag = 0; diag < gen - alpha; ++diag) {
    rp = mat_rows + diag;	// work down the diag'th column
    for (j = 0; j < alpha; ++j, rp += gen) {
      k = *rp;
      if (k == 0) continue;

      // coding vector (fma would clear non-zero at *rp if 1 above was explicit)
      *rp = 0;
      gf256_vec_fma(rp + 1, d->coding + diag * alpha, k, alpha);
      // symbol
      gf256_vec_fma(d->symbol + (gen - alpha + j) * blocksize,
		    d->symbol + (diag)            * blocksize,
		    k, blocksize);
    }
  }

  // Step 2: get 0's, 1's in lower-left corner of lower-right side

  // Arithmetic is easier if we convert to an alpha * alpha submatrix
  rp = mat_rows;
  cp = rp + gen - alpha;
  for (i = 0; i < alpha; ++i) {
    for (j = 0; j < alpha; ++j) *(rp++) = *(cp++);
    cp += gen - alpha;
  }

  for (diag = 0; diag < alpha; ++diag) {

    // somehow deal with zero on diagonal 
    swap_row = diag;
    if ((k = mat_rows[diag * alpha + diag]) == 0) {
      for (i = diag + 1; i < alpha; ++i) {
	if (mat_rows[i * alpha + diag] == 0) continue;
	swap_row = i;
	break;
      }
    }

    if (swap_row == diag) {

      // My Perl code currently has '...' (unimplemented) at the top
      // of this branch, but it seems like I have actually implemented
      // it below that.


      // looks like it was a copy/paste of the f2 code, so I'll just
      // die for now
      fprintf(stderr, "Dealing with zero column not implemented yet...\n");
      exit(1);
      
      continue;
    } else {

      // We found a row to swap with.

      // There's scratchpad space after the alpha * alpha matrix, even
      // in the worst case that alpha == gen - 1 (which would give us
      // exactly alpha bytes)
      memcpy(mat_rows + alpha * alpha, mat_rows + swap_row * alpha, alpha);
      memcpy(mat_rows + swap_row * alpha, mat_rows + diag * alpha, alpha);
      memcpy(mat_rows + diag * alpha, mat_rows + alpha * alpha, alpha);

      // We don't have scratch space for the symbol, though.
      cp = d->symbol + (gen - alpha + diag) * blocksize;
      bp = cp + blocksize;
      rp = d->symbol + (gen - alpha + swap_row) * blocksize;
      while (cp < bp) {
	temp    = *cp;
	*(cp++) = *rp;
	*(rp++) = temp;
      }

      k = mat_rows[diag * alpha + diag];
    }

    // Normalise the diagonal
    if (k != 1) {
      k = gf256_inv_elem(k);
      gf256_vec_mul(mat_rows + diag * alpha, k, alpha);
      gf256_vec_mul(d->symbol + (gen - alpha + diag) * blocksize, k, blocksize);
    }

    // Propagate down from diagonal to clear non-zeros underneath
    for (i = swap_row + 1; i < alpha; ++i) {
      k = mat_rows[i * alpha + diag];
      if (k == 0) continue;

      gf256_vec_fma(mat_rows + i * alpha, mat_rows + diag * alpha, k, alpha);
      gf256_vec_fma(d->symbol + (gen - alpha + i)    * blocksize,
		    d->symbol + (gen - alpha + diag) * blocksize,
		    k, blocksize);
    }

    // Step 3a: convert coding sub-matrix back to original form
    cp = d->coding + (gen - alpha) * code_size;
    rp = mat_rows + 1;
    for (i = 1; i <= alpha; ++i) {
      for (j = 0; j < alpha - i; ++j)  *(cp++) = *(rp++);
      for (j = j; j < alpha;     ++j)  *(cp++) = 0;
      rp += i + 1;
    }

    // Step 3b: back-substitution

  }    
}

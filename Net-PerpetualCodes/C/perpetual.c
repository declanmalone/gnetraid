/* perpetual.c */
/* Implementation of Perptual Codes */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "gf_types.h"
#include "perpetual.h"
#include "gf8.h"
#include "gf16_32.h"

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

static void _check_common_settings(struct perp_settings_2015 *s) {
  unsigned       blocksize = s->blocksize;
  unsigned       gen       = s->gen;
  unsigned short alpha     = s->alpha;
  unsigned short qbits     = s->qbits; /* field size (number of bits) */
  unsigned short q         = s->q; /* field size (number of elements) */

  switch(qbits) {
  case 0:
    fprintf (stderr, "q/qbits not set (required).\n");
    exit(1);
  case 1:
    fprintf (stderr, "Binary field not implemented yet.\n");
    exit(1);
  case 4:
    fprintf (stderr, "GF(2**4) not implemented yet.\n");
    exit(1);
  case 8:
  case 16:
  case 32:
    break;
  default:
    fprintf (stderr, "Unknown qbits value %d.\n",qbits);
    exit(1);
  }
  if (alpha == 0) {
    fprintf (stderr, "Invalid alpha value %d (must be > 0)\n", alpha);
    exit(1);
  }

  if (gen == 0) {
    fprintf (stderr, "Invalid gen value %d (must be > 0)\n", gen);
    exit(1);
  }

  if (blocksize == 0) {
    fprintf (stderr, "Invalid blocksize value %d (must be > 0)\n", blocksize);
    exit(1);
  }

  if (blocksize % (qbits >> 3)) {
    fprintf (stderr, "Blocksize %d not a multiple of field size\n", blocksize);
    exit(1);
  } else {
    s->blocksyms = blocksize / (qbits >> 3);
  }

  if (alpha >= gen) {
    fprintf (stderr, "Invalid alpha value %d (must be < gen %d)\n", alpha, gen);
    exit(1);
  }

  s->code_size = alpha * (qbits >> 3);

}

void perp_init_encoder_2015(struct perp_settings_2015 *s,
			    struct perp_encoder_2015 *e) {

  unsigned       blocksize = s->blocksize;
  unsigned       gen       = s->gen;
  unsigned short alpha     = s->alpha;
  unsigned short qbits     = s->qbits; /* field size (number of bits) */
  unsigned short q         = s->q; /* field size (number of elements) */

  _check_common_settings(s);

  if (e->deterministic) {
    srand(1);
  } else if (e->seed) {
    srand(e->seed);
  } else {
    srand(time(0));
  }
}

void perp_init_decoder_2015(struct perp_settings_2015 *s,
			    struct perp_decoder_2015 *d) {
  unsigned       blocksize = s->blocksize;
  unsigned       gen       = s->gen;
  unsigned short alpha     = s->alpha;
  unsigned short qbits     = s->qbits; /* field size (number of bits) */
  unsigned short q         = s->q; /* field size (number of elements) */

  _check_common_settings(s);

  if (0 == (d->filled = (gf8_t *) malloc(gen))) {
    fprintf (stderr, "Failed to alloc %d bytes for gen\n", gen);
    exit(1);
  } else {
    memset(d->filled, 0, gen);
  }

  if (0 == (d->coding = (gf8_t *) malloc(gen * (s->code_size)))) {
    fprintf (stderr, "Failed to alloc %d bytes for coding\n", gen * alpha);
    exit(1);
  }

  if (0 == (d->symbol = (gf8_t *) malloc(gen * blocksize))) {
    fprintf (stderr, "Failed to alloc %d bytes for symbol\n", gen * blocksize);
    exit(1);
  }

  d->remain = gen;

  d->repivot = 0;
  d->queue = malloc(alpha * sizeof(struct perp_repivot_queue));

  if (0 == (d->mat_rows = malloc((s->code_size) * gen))) {
    fprintf (stderr, "Failed to alloc %d bytes for mat_rows\n", alpha * gen);
    exit(1);
  }

};

static void hex_print(gf8_t *s, int len) {
  while (len--) 
    fprintf(stderr, "%02x", *(s++));
  fprintf(stderr, "\n");
}
unsigned pivot_bin(struct perp_settings_2015 *s, struct perp_decoder_2015 *d) {
  return d->remain;
}

#define typed_pivot(N) \
unsigned pivot_gf ## N (struct perp_settings_2015 *s, \
struct perp_decoder_2015 *d, \
		   unsigned i, \
		   gf ## N ## _t *code, \
		   gf ## N ## _t *sym) \
{ \
  unsigned tries = 0; \
  short ctz_row, ctz_code, clz_code; \
  gf ## N ## _t temp; \
  gf ## N ## _t *cp, *bp, *rp, *coding, *symbol; \
  unsigned short alpha     = s->alpha;     /* elements */ \
  unsigned short code_size = s->code_size; /* bytes */ \
  unsigned short blocksyms = s->blocksyms; /* elements */ \
  unsigned short blocksize = s->blocksize; /* bytes */ \
  unsigned short cancelled, zero_sym; \
\
  coding = d->coding; \
  symbol = d->symbol; \
  if (i >= s->gen) { \
    fprintf(stderr, "pivot_gf" # N ": i value %u out of range\n", i); \
    exit(1); \
  } \
\
  while (++tries < s->gen * 2) { \
\
    if (d->filled[i] == 0) { \
      /* fprintf(stderr,"filling hole in row %u\n", i); */	\
      d->filled[i] = 1; \
      memcpy(d->coding + code_size * i, code, code_size); \
      memcpy(d->symbol + blocksize * i, sym,  blocksize); \
      return --(d->remain); \
    } \
\
    /* fprintf(stderr,"Row %u already has data: ", i); */	\
    /* hex_print(d->coding + code_size * i, code_size);      */	\
\
    for (ctz_code = 0, cp=code + alpha - 1; \
	 cp >= code; \
	 --cp ) { \
      if (*cp != 0) break; \
      ++ctz_code; \
    } \
    /* fprintf (stderr, "ctz_code is %u\n", ctz_code); */	\
\
    /* We could memoise ctz_row, but for now I'll just calculate it */	\
    bp = coding + i * alpha;			\
    for (ctz_row = 0, cp = bp + alpha - 1; \
	 cp >= bp; \
	 --cp ) { \
      if (*cp != 0) break; \
      ++ctz_row; \
    } \
    /* fprintf (stderr, "ctz_row is %u\n", ctz_row); */	\
\
    /* Rather than doing swap as a single step, just set a flag. The */	\
    /* loops below have been rewritten to deal with it correctly. */   \
    short need_swap = 0; \
    if (ctz_code > ctz_row) need_swap=1; \
\
    /* Subtract matrix "row" from our code, symbol		  */ \
    /* fprintf(stderr, "Substituting row %u into code, sym\n", i);*/	\
    cancelled = 1;		/* incidentally, check if code became zero */ \
    cp = code; \
    rp = coding + i * alpha; \
    bp = rp + alpha; \
\
    if (need_swap) { \
      gf ## N ## _t cv, xor; \
      while (rp < bp) { \
	if (xor = (cv = *cp) ^ *rp) cancelled = 0; \
	*(rp++) = cv; \
	*(cp++) = xor; \
      } \
    } else { \
      while (rp < bp) { \
	if (*(cp++) ^= *(rp++)) cancelled = 0; \
      } \
    } \
\
    /* Defer operating on symbol so that we can do a fused operation later */\
\
    /* fprintf(stderr, "New code is: "); */	\
    /* hex_print(code, code_size); */	   \
\
    if (cancelled) { \
      /* fprintf(stderr, "Code was cancelled\n");		*/	\
      zero_sym  = 1;		/* did symbol cancel? (for debugging) */ \
      cp = sym; \
      rp = symbol + i * blocksyms; \
      bp = rp + blocksyms; \
      /* if need_swap is set, we still need to save swapped symbol! */ \
      /*  */ \
      while (rp < bp) { \
	if ((temp = *(cp++)) ^ *rp) zero_sym = 0; \
	if (need_swap) *rp = temp; \
	++rp; \
      } \
      if (zero_sym) return d->remain; \
      fprintf(stderr,  "failed: zero code vector => zero symbol (i=%d)\n", i); \
      exit(1); \
    } \
\
/* count leading zeros to find new i value */	\
    clz_code = 0; \
    cp = code; bp = code + alpha; \
    while (cp < bp) { \
      if (*cp) break; \
      ++clz_code; \
      ++cp; \
    } \
/* fprintf(stderr, "clz of new code is %u\n", clz_code); */	\
\
/* cp now points to first non-zero value */	\
    temp = gf ## N ## _inv_elem(*cp); \
    ++cp;			/* skip past implicit 1 */\
    gf ## N ## _vec_mul(cp,  temp, alpha - clz_code - 1); \
/* roll (possible) swapping, adding and multiplying into one call */	\
    gf ## N ## _vec_fam_with_swap(sym, symbol + i * blocksyms, \
				  temp, blocksyms, need_swap);		\
\
/* shift code vector left		*/	\
    rp = code; \
    while (cp < bp) { *(rp++) = *(cp++); } \
    while (rp < bp) { *(rp++) = 0; } \
\
/* update i value */		     \
    i = (i + clz_code + 1) % s->gen; \
  } \
  fprintf(stderr, "Bailing after 2 * gen attempts to pivot\n"); \
}

typed_pivot(8)
typed_pivot(16)
typed_pivot(32)



static void hex_print_mrows(gf8_t *mat, int rows, int cols) {
  while (rows--) {
    fprintf(stderr, "| ");
    hex_print(mat, cols);
    mat += cols;
    fprintf(stderr, " |\n");
  }
}

#define typed_solver(N) \
int solve_gf ## N(struct perp_settings_2015 *s, \
                  struct perp_decoder_2015  *d) { \
 \
  /* I could try implementing a more complicated scheme for doing */ \
  /* matrix operations in-place (on d->coding) as much as possible, */ \
  /* but I don't think that it's worth it. */ \
 \
  signed   short i, j; \
  unsigned short alpha     = s->alpha; \
  unsigned short code_size = s->code_size; \
  unsigned int   blocksize = s->blocksize; \
  unsigned int   blocksyms = s->blocksyms; \
  unsigned short gen       = s->gen; \
  gf ## N ## _t *cp, *rp, *bp, k, temp; \
  gf ## N ## _t *mat_rows  = d->mat_rows; \
  /* also copy coding, symbol table pointers, casting them to gf*_t * */ \
  gf ## N ## _t *coding  = d->coding; \
  gf ## N ## _t *symbol  = d->symbol; \
  unsigned short diag, swap_row, down_row; \
 \
  /* rp -> destination (j'th row of mat_rows) */ \
  rp = mat_rows; \
  j = 0; \
  do { \
    /* cp -> start of code being upgraded */ \
    cp = coding + (gen - alpha + j) * alpha; \
    /* bp -> -j'th byte of the code vector */ \
    bp = cp + alpha - ++j; \
 \
    /* Layout of the new row: */ \
     \
    /* (end)      (zeros)          (1)   (start) */ \
    /*  (j)  + (gen - alpha - 1) + (1) (alpha - j) = gen */ \
 \
    for (i=1;  i <= j;            ++i)   *(rp++) = *(bp++); \
    for (i=1;  i <  gen - alpha;  ++i)   *(rp++) = 0; \
                                         *(rp++) = 1; \
    for (i=1;  i <= alpha - j;    ++i)   *(rp++) = *(cp++); \
  } while (j != alpha); \
 \
  /* fprintf(stderr, "Solving. Last coding vectors are:\n"); */ \
  for (i = 0; i < alpha; ++i) { \
    /* hex_print(d->coding + (gen - alpha + i) * alpha, alpha); */ \
  } \
  /* hex_print_mrows(mat_rows, alpha, gen); */ \
 \
   /* forward propagation */ \
  for (diag = 0; diag < gen - alpha; ++diag) { \
    rp = mat_rows + diag;	/* work down the diag'th column */ \
    for (j = 0; j < alpha; ++j, rp += gen) { \
 \
      /* We seem to be getting too many zeros */ \
      /* fprintf(stderr, "<-"); */ \
      /* hex_print(mat_rows + j * gen, gen); */ \
 \
      k = *rp; \
      if (k == 0) continue; \
       \
      /* coding vector (fma would clear non-zero at *rp if 1 above was explicit) */ \
      *rp = 0; \
      gf ## N ## _vec_fma(rp + 1, coding + diag * alpha, k, alpha); \
      /* symbol */ \
      gf ## N ## _vec_fma(symbol + (gen - alpha + j) * blocksyms, \
		    symbol       + (diag           ) * blocksyms, \
		    k, blocksyms); \
 \
      /* fprintf(stderr, "->"); */ \
      /* hex_print(mat_rows + j * gen, gen); */ \
    } \
    /* fprintf(stderr, "<-"); */ \
    /* hex_print(mat_rows + j * gen, gen); */ \
  } \
 \
   /* fprintf(stderr, "After forward propagation. Matrix is:\n"); */ \
   /* hex_print_mrows(mat_rows, alpha, gen); */ \
 \
  /* Step 2: get 0's, 1's in lower-left corner of lower-right side */ \
 \
  /* Arithmetic is easier if we convert to an alpha * alpha submatrix */ \
  rp = mat_rows; \
  cp = rp + gen - alpha; \
  for (i = 0; i < alpha; ++i) { \
    for (j = 0; j < alpha; ++j) *(rp++) = *(cp++); \
    cp += gen - alpha; \
  } \
  /* fprintf(stderr, "Reduced matrix is:\n"); */ \
  /* hex_print_mrows(mat_rows, alpha, alpha); */ \
   \
  for (diag = 0; diag < alpha; ++diag) { \
 \
    /* somehow deal with zero on diagonal  */ \
    swap_row = diag; \
    if ((k = mat_rows[diag * alpha + diag]) == 0) { \
      for (i = diag + 1; i < alpha; ++i) { \
	if (mat_rows[i * alpha + diag] == 0) continue; \
	swap_row = i; \
	break; \
      } \
      if (swap_row == diag) { \
 \
	/* My Perl code currently has '...' (unimplemented) at the top */ \
	/* of this branch, but it seems like I have actually implemented */ \
	/* it below that. */ \
 \
 \
	/* looks like it was a copy/paste of the f2 code, so I'll just */ \
	/* die for now */ \
	fprintf(stderr, "Zero column %u not implemented yet...\n",diag); \
	exit(1); \
       \
	continue; \
      } else { \
 \
	/* We found a row to swap with. */ \
 \
	/* There's scratchpad space after the alpha * alpha matrix, even */ \
	/* in the worst case that alpha == gen - 1 (which would give us */ \
	/* exactly alpha symbols) */ \
	memcpy(mat_rows + alpha * alpha, mat_rows + swap_row * alpha, \
	       alpha * sizeof(gf ## N ## _t));				\
	memcpy(mat_rows + swap_row * alpha, mat_rows + diag * alpha, \
	       alpha * sizeof(gf ## N ## _t));				\
	memcpy(mat_rows + diag * alpha, mat_rows + alpha * alpha, \
	       alpha * sizeof(gf ## N ## _t));				\
	 \
	/* We don't have scratch space for the symbol, though. */ \
	cp = symbol + (gen - alpha + diag) * blocksyms; \
	bp = cp + blocksyms; \
	rp = symbol + (gen - alpha + swap_row) * blocksyms; \
	while (cp < bp) { \
	  temp    = *cp; \
	  *(cp++) = *rp; \
	  *(rp++) = temp; \
	} \
	 \
	k = mat_rows[diag * alpha + diag]; \
      } \
    } \
  } \
 \
   /* Normalise the diagonal */ \
  if (k != 1) { \
    k = gf ## N ## _inv_elem(k); \
    gf ## N ## _vec_mul(mat_rows + diag * alpha, k, alpha); \
    gf ## N ## _vec_mul(symbol + (gen - alpha + diag) * blocksyms, k, blocksyms); \
  } \
 \
  /* Propagate down from diagonal to clear non-zeros underneath */ \
  for (i = swap_row + 1; i < alpha; ++i) { \
    k = mat_rows[i * alpha + diag]; \
    if (k == 0) continue; \
 \
    gf ## N ##_vec_fma(mat_rows + i * alpha, mat_rows + diag * alpha, k, alpha); \
    gf ## N ##_vec_fma(symbol + (gen - alpha + i)    * blocksyms, \
		  symbol + (gen - alpha + diag) * blocksyms, \
		  k, blocksyms); \
  } \
 \
   /* Step 3a: convert coding sub-matrix back to original form */ \
  cp = coding + (gen - alpha) * alpha; \
  rp = mat_rows + 1; \
  for (i = 1; i <= alpha; ++i) { \
    for (j = 0; j < alpha - i; ++j)  *(cp++) = *(rp++); \
    for (j = j; j < alpha;     ++j)  *(cp++) = 0; \
    rp += i + 1; \
  } \
 \
  /* Step 3b: back-substitution */ \
  diag = gen - 1; \
  do { \
    j = alpha < diag ? alpha : diag; \
    if (j) { \
      i = diag - 1; \
      temp = 0; \
      do { \
	k = coding[i * alpha + temp];	\
	if (k == 0) { }  \
	else if (k == 1) { \
	  rp = symbol + i * blocksyms; \
	  bp = rp + blocksyms; \
	  cp = symbol + diag * blocksyms; \
	  while (rp < bp) { \
	    *(rp++) ^= *(cp++); \
	  }; \
	  coding[i * alpha + temp] = 0; \
	} else { \
	  gf ## N ## _vec_fma(symbol + i * blocksyms, \
			symbol + diag * blocksyms, \
			k, blocksyms); \
	  coding[i * alpha + temp] = 0; \
	} \
      } while (++temp, --i, --j); \
    } \
  } while (--diag); \
 \
  return 0;			/* success */ \
}

typed_solver(8)
typed_solver(16)
typed_solver(32)


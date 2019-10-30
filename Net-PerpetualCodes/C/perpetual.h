/* perpetual.h */

#include <stdlib.h>
#include <string.h>


// Start by implementing the 2015 paper
struct perp_settings_2015 {
  size_t   blocksize;		/* size in bytes */
  size_t   blocksyms;		/* size in symbols */
  unsigned gen;
  unsigned short alpha;	        /* size of code in symbols */
  unsigned short qbits;		/* field size (number of bits) */
  unsigned short q;		/* field size (number of elements) */
  unsigned short code_size;	/* qbits * alpha / 8 (size in bytes) */
};

// Field sizes and what they mean:
//
// q       Field               qbits
// 2       GF(2), {0,1}        1
// 16      GF(2**4), {0..f}    4
// 256     GF(2**8), {00..ff}  8
// 65536   GF(2**16)           16
// etc.

// Since I can imagine implementing the algorithm for GF(2**16) and
// GF(2**32), I'm going to suffix field-specific functions with the
// number of bits rather than the field size. I'll make an exception
// for GF(2) functions, which I'll suffix with _bin.

// 
struct perp_encoder_2015 {
  unsigned seed;
  unsigned options;
  unsigned short deterministic;
  gf8_t *message;
};

struct perp_repivot_queue {
  unsigned i;
  void *code;
  void *symbol;
};

struct perp_decoder_2015 {
  unsigned char *filled;
  void *coding;
  void *symbol;
  unsigned remain;
  unsigned repivot;
  struct perp_repivot_queue *queue;
  // I expect I can eliminate the need to allocate full matrix rows later
  void *mat_rows;
};

void
perp_init_decoder_2015(struct perp_settings_2015 *s, struct perp_decoder_2015 *d);

void
perp_init_encoder_2015(struct perp_settings_2015 *s, struct perp_encoder_2015 *e);

unsigned pivot_bin(struct perp_settings_2015 *s, struct perp_decoder_2015 *d);
unsigned pivot_gf8(struct perp_settings_2015 *s, struct perp_decoder_2015 *d,
		   unsigned i,
		   gf8_t *code,
		   gf8_t *sym
		   );
unsigned pivot_gf16(struct perp_settings_2015 *s, struct perp_decoder_2015 *d,
		   unsigned i,
		   gf16_t *code,
		   gf16_t *sym
		   );
unsigned pivot_gf32(struct perp_settings_2015 *s, struct perp_decoder_2015 *d,
		   unsigned i,
		   gf32_t *code,
		   gf32_t *sym
		   );
int solve_gf8(struct perp_settings_2015 *s, struct perp_decoder_2015  *d);
int solve_gf16(struct perp_settings_2015 *s, struct perp_decoder_2015  *d);
int solve_gf32(struct perp_settings_2015 *s, struct perp_decoder_2015  *d);

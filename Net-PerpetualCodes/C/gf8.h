
#include "gf_types.h"

gf8_t gf8_mul_elems(gf8_t a, gf8_t b);
gf8_t gf8_inv_elem(gf8_t a);
void gf8_vec_mul(gf8_t *s, gf8_t val, unsigned len);
void gf8_vec_fma(gf8_t *d, gf8_t *s, gf8_t val,
		   unsigned len );
void gf8_vec_fam_with_swap(gf8_t *d, gf8_t *s,
			     gf8_t val, unsigned len,
			     int do_swap);

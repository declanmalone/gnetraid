/* Basic GF(2**16) and GF(2**32) field operations */

#include "gf_types.h"

gf16_t gf16_mul_elems (gf16_t a, gf16_t b);
gf16_t gf16_inv_elem (gf16_t a);

gf32_t gf32_inv_elem (gf32_t a);
gf32_t gf32_mul_elems (gf32_t a, gf32_t b);

void gf16_vec_mul(gf16_t *s, gf16_t val, unsigned len);
void gf16_vec_fma(gf16_t *d, gf16_t *s, gf16_t val, unsigned len );
void gf16_vec_fam_with_swap(gf16_t *d, gf16_t *s,
			    gf16_t val, unsigned len,
			    int do_swap);

void gf32_vec_mul(gf32_t *s, gf32_t val, unsigned len);
void gf32_vec_fma(gf32_t *d, gf32_t *s, gf32_t val, unsigned len );
void gf32_vec_fam_with_swap(gf32_t *d, gf32_t *s,
			    gf32_t val, unsigned len,
			    int do_swap);


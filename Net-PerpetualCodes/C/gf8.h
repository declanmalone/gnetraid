
unsigned char gf256_mul_elems(unsigned char a, unsigned char b);
unsigned char gf256_inv_elem(unsigned char a);
void gf256_vec_mul(unsigned char *s, unsigned char val, unsigned len);
void gf256_vec_fma(unsigned char *d, unsigned char *s, unsigned char val,
		   unsigned len );
void gf256_vec_fam_with_swap(unsigned char *d, unsigned char *s,
			     unsigned char val, unsigned len,
			     int do_swap);

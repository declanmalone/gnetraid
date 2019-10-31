
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "gf16_32.h"

int main (int argc, char *argv[]) {

  gf16_t a16, b16, c16, d16, e16;
  gf16_t *va16, *vb16, *vc16, *vd16, *ve16;
  int i, j;
  int vec_size = 100;

  va16 = malloc(vec_size);	/* a operand */
  vb16 = malloc(vec_size);	/* b operand */
  vc16 = malloc(vec_size);	/* manual multiply a.e */
  vd16 = malloc(vec_size);	/* vector multiply a.e */
  ve16 = malloc(vec_size);	/* vector fma a.e + b */

  memset(va16, 0, vec_size);
  memset(vb16, 0, vec_size);
  memset(vc16, 0, vec_size);
  memset(vd16, 0, vec_size);
  memset(ve16, 0, vec_size);

  // just some random numbers to test with
  a16 = 0x8421;
  b16 = 0xfedc;
  e16 = 0xcafe;

  for (i=0; a16; a16 >>= 1, b16 <<= 1) {
    c16 = gf16_mul_elems(a16,b16);
    va16[0] = a16;
    vb16[0] = b16;
    vc16[0] = gf16_mul_elems(a16,e16);
    vd16[0] = a16;
    ve16[0] = b16;

    // Test multiplication by zero and identity (both operand positions)
    if (0 != gf16_mul_elems(0,a16))
      printf ("Failed 0 x %d\n", a16);
    if (0 != gf16_mul_elems(a16,0))
      printf ("Failed %d x 0\n", a16);
    if (a16 != gf16_mul_elems(1,a16))
      printf ("Failed 1 x %d\n", a16);
    if (a16 != gf16_mul_elems(a16,1))
      printf ("Failed %d x 1\n", a16);

    if (0 != gf16_mul_elems(0,b16))
      printf ("Failed 0 x %d\n", b16);
    if (0 != gf16_mul_elems(b16,0))
      printf ("Failed %d x 0\n", b16);
    if (b16 != gf16_mul_elems(1,b16))
      printf ("Failed 1 x %d\n", b16);
    if (b16 != gf16_mul_elems(b16,1))
      printf ("Failed %d x 1\n", b16);

    // I don't actually know what the products above are,
    // but I can still test that ab = ba
    if (c16 != gf16_mul_elems(b16,a16))
      printf ("ab != ba for a=%d, b=%d\n", a16, b16);

    // And I can test if a.b.inv(b) = a
    // (I expect this to fail if a or b is 0)
    d16 = gf16_inv_elem(a16);
    if (b16 != gf16_mul_elems(c16,d16))
      printf ("ab/a != b for a=%d, b=%d\n", a16, b16);
    d16 = gf16_inv_elem(b16);
    if (a16 != (d16 = gf16_mul_elems(c16,d16)))
      printf ("ab/b != a for a=%d, b=%d (got %d)\n", a16, b16, d16);

    // we've done multiplication, but I also want to check the fma
    // vector call.
    ve16[i] = a16 ^ gf16_mul_elems(b16,e16);
  }

  // check vector multiplication (a x constant)
  gf16_vec_mul(vd16, e16, vec_size / 2);

  if (0 != memcmp(vc16, vd16, vec_size))
    printf("gf16_vec_mul failed\n");

  // want to calculate a + b.e, which is stored in ve16
  gf16_vec_fma(va16, vb16, e16, vec_size / 2);
  if (0 != memcmp(va16, ve16, vec_size))
    printf("gf16_vec_fma failed\n");
  

}

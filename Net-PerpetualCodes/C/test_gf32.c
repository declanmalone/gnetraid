
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "gf16_32.h"

int main (int argc, char *argv[]) {

  gf32_t a32, b32, c32, d32, e32;
  gf32_t *va32, *vb32, *vc32, *vd32, *ve32;
  int i, j;
  int vec_size = 100;

  va32 = malloc(vec_size);	/* a operand */
  vb32 = malloc(vec_size);	/* b operand */
  vc32 = malloc(vec_size);	/* manual multiply a.e */
  vd32 = malloc(vec_size);	/* vector multiply a.e */
  ve32 = malloc(vec_size);	/* vector fma a.e + b */

  memset(va32, 0, vec_size);
  memset(vb32, 0, vec_size);
  memset(vc32, 0, vec_size);
  memset(vd32, 0, vec_size);
  memset(ve32, 0, vec_size);

  // just some random numbers to test with
  a32 = 0x8421;
  b32 = 0xfedc;
  e32 = 0xcafe;

  for (i=0; a32; a32 >>= 1, b32 <<= 1) {
    c32 = gf32_mul_elems(a32,b32);
    va32[0] = a32;
    vb32[0] = b32;
    vc32[0] = gf32_mul_elems(a32,e32);
    vd32[0] = a32;
    ve32[0] = b32;

    // Test multiplication by zero and identity (both operand positions)
    if (0 != gf32_mul_elems(0,a32))
      printf ("Failed 0 x %d\n", a32);
    if (0 != gf32_mul_elems(a32,0))
      printf ("Failed %d x 0\n", a32);
    if (a32 != gf32_mul_elems(1,a32))
      printf ("Failed 1 x %d\n", a32);
    if (a32 != gf32_mul_elems(a32,1))
      printf ("Failed %d x 1\n", a32);

    if (0 != gf32_mul_elems(0,b32))
      printf ("Failed 0 x %d\n", b32);
    if (0 != gf32_mul_elems(b32,0))
      printf ("Failed %d x 0\n", b32);
    if (b32 != gf32_mul_elems(1,b32))
      printf ("Failed 1 x %d\n", b32);
    if (b32 != gf32_mul_elems(b32,1))
      printf ("Failed %d x 1\n", b32);

    // I don't actually know what the products above are,
    // but I can still test that ab = ba
    if (c32 != gf32_mul_elems(b32,a32))
      printf ("ab != ba for a=%d, b=%d\n", a32, b32);

    // And I can test if a.b.inv(b) = a
    // (I expect this to fail if a or b is 0)
    d32 = gf32_inv_elem(a32);
    if (b32 != gf32_mul_elems(c32,d32))
      printf ("ab/a != b for a=%d, b=%d\n", a32, b32);
    d32 = gf32_inv_elem(b32);
    if (a32 != (d32 = gf32_mul_elems(c32,d32)))
      printf ("ab/b != a for a=%d, b=%d (got %d)\n", a32, b32, d32);

    // we've done multiplication, but I also want to check the fma
    // vector call.
    ve32[i] = a32 ^ gf32_mul_elems(b32,e32);
  }

  // check vector multiplication (a x constant)
  gf32_vec_mul(vd32, e32, vec_size / 2);

  if (0 != memcmp(vc32, vd32, vec_size))
    printf("gf32_vec_mul failed\n");

  // want to calculate a + b.e, which is stored in ve32
  gf32_vec_fma(va32, vb32, e32, vec_size / 2);
  if (0 != memcmp(va32, ve32, vec_size))
    printf("gf32_vec_fma failed\n");
  

}

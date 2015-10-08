#include <stdio.h>

#include "rabin-ida.h"
#include "fast_gf2.h"

extern gf2_u32 gf2_test_arm_simd(gf2_u32 a,gf2_u32 b);
int main (int ac, char *av[]) {

  gf2_u32 a, b, c;

  a=0x10204080l;
  b=0x10204080l;

  c = gf2_test_arm_simd(a,b);

  printf("%2x %2x %2x %2x\n", a>>24, (a>>16) & 255, (a>>8) & 255, a & 255);
  printf("%2x %2x %2x %2x\n", b>>24, (b>>16) & 255, (b>>8) & 255, b & 255);
  printf("----------- + (uadd8/sel)\n");
  printf("%2x %2x %2x %2x\n", c>>24, (c>>16) & 255, (c>>8) & 255, c & 255);


  printf("\n");
  a=0x80402010l;
  b=0x80402010l;

  c = gf2_test_arm_simd(a,b);

  printf("%2x %2x %2x %2x\n", a>>24, (a>>16) & 255, (a>>8) & 255, a & 255);
  printf("%2x %2x %2x %2x\n", b>>24, (b>>16) & 255, (b>>8) & 255, b & 255);
  printf("----------- + (uadd8/sel)\n");
  printf("%2x %2x %2x %2x\n", c>>24, (c>>16) & 255, (c>>8) & 255, c & 255);
}

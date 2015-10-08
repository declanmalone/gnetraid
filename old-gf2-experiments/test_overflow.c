#include <stdio.h>


main () {

  unsigned char x=250;
  unsigned char y=30;
  unsigned char z;

  printf("x=%u, y=%u\n", (unsigned int) x,(unsigned int) y);
  z=x+y;
  printf("x + y = %u\n", (unsigned int) (z));
  z=x-y;
  printf("x - y = %u\n", (unsigned int) (z));
  
}

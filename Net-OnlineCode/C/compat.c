// Test compatibility of Perl, C routines
//
// Primarily based on checking RNG implementations

#include <stdio.h>
#include <math.h>
#include <assert.h>

#include "rng_sha1.h"
#include "online-code.h"

const char *null_seed = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

oc_rng_sha1 rng;

int fisher_src[25];
int fisher_dst[25];

int main (int ac, char *av[]) {

  unsigned int i, j;
  double max = 0xffffffff;
  double r;
  int *list;

  oc_rng_init_seed(&rng, null_seed);

  for (i=0; i < 10000; ++i) {
    r = oc_rng_rand(&rng,i+1); // range [0,i]
    j = floor(r);
    assert(r - j < 1.0l);
    printf("%ld\n", (long) j);
  }

  // maybe add check for oc_floyd() too

}

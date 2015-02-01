#include "online-code.h"





float *oc_codec_init_probdist(oc_codec *codec) {

  int   coblocks = codec->coblocks;
  float epsilon  = codec->e;
  float f        = codec->F;	// save doing cast later

  // Calculate the sum of the sequence:
  //
  //                1 + 1/F
  // p_1  =  1  -  ---------
  //                 1 + e
  //
  //
  //             F . (1 - p_1)
  // p_i  =  ---------------------
  //          (F - 1) . (i^2 - i)
  //
  // Since the i term is the only thing that changes for each p_i, I
  // optimise the calculation by keeping a fixed term involving only p
  // and f with a variable one involving i, then dividing as
  // appropriate.

  float p1     = 1 - (1 + 1/f) / (1 + epsilon);
  float pfterm;			// calculate later to avoid potential
				// division by zero if f == 1
  float *p, p_i, sum;
  double i, iterm;

  // basic sanity checking
  assert(f <= coblocks);
  assert(p1 > 0);

  // allocate array
  p = calloc(f, sizeof(float));

  if (p == NULL) {
    return NULL;
  }

  // save pointer, but continue using local p as array iterator
  codec->p = p;

  // hard-code simple cases where f = 1 or 2
  if (f == 1) {
    p[0] = 1;
    return p;
  } else if (f == 2) {
    p[0] = p1;
    p[1] = 1;
    return p;
  }

  // calculate sum(p_i) for 2 <= i < F.
  // p_(i=F) is simply set to 1 to avoid rounding errors in the sum
  pfterm = (1-p1) * f / (f - 1);
  *(p++) = sum = p1;
  for (i=2.0l; i < f; ++i) {
    iterm = i * (i - 1);
    p_i   = pfterm / iterm;
    *(p++) = (sum += p_i);
  }
  *(p) = 1.0;

  return codec->p;

}

// use probability distribution table and rng to find degree of a
// check block
int oc_random_degree(oc_codec *codec, rng_sha1 *rng) {

  int    i = 0;
  float  r = oc_rng_rand(rng, 1.0);
  float *p = codec->p;
  // A linear scan is likely to be quick for most values of r.
  while (r > *(p++)) {	// terminates since r < p[last] (ie, 1)
    ++i;
  }
  return i + 1;
}


int *oc_checkblock_mapping(oc_codec *codec, oc_rng_sha1 *rng) {

  int degree = oc_random_degree(codec,rng);
  int *nodes = calloc(degree, sizeof(int));

  if (nodes == NULL) return NULL;

  


}

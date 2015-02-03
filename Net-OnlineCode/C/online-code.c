// "Base class methods" for Online Code algorithm

#include <math.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>

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
  // p_(i=F) is set to 1 to avoid rounding errors in the sum
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

// Fisher-Yates shuffle routine
//
// Randomly picks some combination of elements from a list
//
// If we were selecting a combination of all elements of an n-element
// array it would be possible to use an "inside-out" version of the
// Fisher-Yates shuffle algorithm that only requires one array which
// is built up on the fly. However, there's no such algorithm (that I
// can find) that only needs one array when we pick k out of n
// elements (k < n). As a result, this version requires that the
// caller sets up the source array before calling this routine. As
// this array will be copied into the "working" array at the start of
// the routine, it needs to be able to hold the full n elements.
//
// This version works by shuffling the working array so that selected
// elements are gathered at the end of it. A pointer to the start of
// this area of the working array is returned.

int *oc_fisher_yates(int *src, int *dst, int k, int n, oc_rng_sha1 *rng) {

  int i,j,tmp;

  // catch various calling errors (turn off by #defining NDEBUG)
  assert(src != NULL);
  assert(dst != NULL);
  assert(src != dst);
  assert(rng != NULL);
  assert(n > 0);
  assert(k > 0);
  assert(k <= n);

  memcpy(dst, src, n * sizeof(int));

  // algorithm gathers picks at the end of the array
  i=n;
  while (--i >= n - k) {
    j=floor(oc_rng_rand(rng,i + 1));	// range [0,i]
    // if (i==j) continue;	// not worth checking
    tmp    = dst[i];
    dst[i] = dst[j];
    dst[j] = tmp;
  }

  return &(dst[n - k]);

}

// Create the auxiliary mapping 
//
// Conceptually, this creates a 2d array of mblocks x q elements which
// encode the upwards edges from message blocks to auxiliary blocks.
// However, rather than an actual 2d array, I just use a 1d array and
// use counting rules to find the x and y coordinates. So for an array
// index i:
//
// x = i % q    counts between 0 and q-1
// y = i / q    counts between 0 and mblocks-1
//
// This is exactly the same as using array[mblocks][q] but C only lets
// you declare something like int (*array)[q] and q would have to be
// known at compile time.
//
// The encoder/decoder "subclasses" use the reverse mapping (of
// auxiliary to message blocks) in different ways so it's not stored
// here in the base class.

int *oc_auxiliary_map(oc_codec *codec, oc_rng_sha1 *rng) {

  int  q       = codec->q;
  int  mblocks = codec->mblocks;
  int  ablocks = codec->ablocks;
  int *src     = codec->shuffle_source;
  int *dst     = codec->shuffle_dest;
  int *p, i, j;

  int *map = calloc(q * mblocks, sizeof(int));

  if (map == NULL) return NULL;

  codec->auxiliary = map;

  // initialise source array for Fisher-Yates shuffle (just once)
  p=src;
  for (i=0; i < ablocks; ++i) {
    *(p++) = mblocks + i;
  }

  // attach each mblock to q ablocks
  for (i=0; i < mblocks; ++i) {
    p = oc_fisher_yates(src, dst, q, ablocks, rng);
    for (j=0; j < q; ++j) {
      *(map++) = *(p++);
    }
  }

  return codec->auxiliary;

}


// use probability distribution table and rng to find degree of a
// check block (a value between 1 and F)
int oc_random_degree(oc_codec *codec, oc_rng_sha1 *rng) {

  int    i = 0;
  float  r = oc_rng_rand(rng, 1.0);
  float *p = codec->p;
  // A linear scan is likely to be quick for most values of r.  Extra
  // speedup might be achieved by partitioning and using binary search
  // on the "flatter" part of the array but this is easier.
  while (r > *(p++)) {	// terminates since r < p[last] (ie, 1)
    ++i;
  }
  return i + 1;
}

// Factor out code to initialise shuffle_source array for use in
// generating check blocks (call once rather than doing it for every
// check block)
void oc_init_cblock_shuffle_source(oc_codec *codec) {

  int i, *p = codec->shuffle_source;
  int coblocks = codec->mblocks + codec->ablocks;

  for (i=0; i < coblocks; ++i)
    *(p++) = i;

}

// Create a new check block as a list of 'degree' downward edges.
// 'Degree' is stored in the first element of the returned list.

int *oc_checkblock_map(oc_codec *codec, int degree, oc_rng_sha1 *rng) {

  int *list     = calloc(degree + 1, sizeof(int));
  int  coblocks = codec->mblocks + codec->ablocks;
  int *src      = codec->shuffle_source;
  int *dst      = codec->shuffle_dest;
  int *p, *q;

  if (list == NULL) return NULL;

  p = list;			// temporary iterator

  // select 'degree' composite blocks ('src' array is assumed to be
  // initialised already)
  q = oc_fisher_yates(src, dst, degree, coblocks, rng);

  // save degree and list of blocks in our array
  *(p++) = degree;
  memcpy(p, q, degree * sizeof(int));

  return list;

}

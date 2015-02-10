// "Base class methods" for Online Code algorithm

#include <math.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#include "structs.h"
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

// Initialisation routines
//
// The main work done in the initialisation routine is to find a set
// of e, q and F parameters that work for a given mblocks
// parameter. The routine tries to honour the q parameter first and
// foremost, but this may involve changing the e and F parameters to
// suit. The code is split among several helper functions to aid
// clarity.

// calculate F from epsilon
int oc_max_degree(float e) {
  e /= 2;
  return ceil( (2*log(e)) / log(1-e) );
}

// count number of auxiliary blocks
int oc_count_aux(int mblocks, int q, float e) {

  // shouldn't overflow for any practical values of q, mblocks
  int aux_blocks = ceil(0.55 * q * e * mblocks);
  return (aux_blocks < q) ? q : aux_blocks;

}

// Use a binary search to find a new epsilon such that
// oc_max_degree(epsilon) <= mblocks + ablocks (ie, n')
float oc_recalculate_e(int mblocks, int q, float e) {

  float l, r, m;		// left, right, middle
  int   ablocks  = oc_count_aux(mblocks, q, e);
  int   coblocks = mblocks + ablocks;

  // set up left and right of range to search
  l = -log(1/e - 1);
  r = l + 1;

  // expand right side of search until we get F <= n'
  while (oc_eval_f(r) > coblocks) {
    r += r - l;
  }

  // binary search between left and right to find a suitable lower
  // value of epsilon still satisfying F <= n'
  while (r - l > 0.01) {
    m = (l + r) / 2;
    if (oc_eval_f(m) > coblocks) {
      l = m;
    } else {
      r = m;
    }
  }

  // return new epsilon value
  return 1/(1 + exp(-r));

}

int oc_eval_f(float t) {
  return oc_max_degree(1/(1 + exp(-t)));
}

// An aside on va_args and representation of numbers (0 and 0.0)...
//
// C's variadic arguments require the caller to tell us how many args
// they are actually sending: it can't just figure this out from the
// stack frame or whatever. As a result, I'll use the convention of
// terminating the list of args to oc_codec_init below with a null
// value. This should work fine because none of our var args should be
// zero. The only fly in the ointment is that on platforms where ints
// are smaller than floats a terminal zero (integer) may not be read
// as 0.0 (float). That's the sort of detail that I should probably
// handle in an autoconf-style script, but as a quick fix, I'll
// terminate the list with 0ll instead.
//
// The other potential problem with using an integer value of zero to
// represent 0.0 is that 0.0 may not be represented by all bits set to
// zero on some particular platform. However, this possibility seems
// extremely unlikely. In fact, C99 mandates the use of IEEE-754
// floats, so if you have a C99-compliant compiler then +0.0 /is/
// actually represented as all zero bits and there is no problem.

int oc_codec_init(oc_codec *codec, int mblocks, ...) {

  va_list ap;
  int     flags = 0;
  int     q=OC_DEFAULT_Q, new_q;
  float   e=OC_DEFAULT_E, new_e;
  int     f=OC_DEFAULT_F, new_f; // f=0 => not supplied (calculated)

  int     ablocks,coblocks;

  // extract variadic args
  va_start(ap, mblocks);
  do {				// preferable to goto?
    new_q = va_arg(ap, int);
    if (new_q == 0) break; else q=new_q;

    // not getting here for some reason...

    new_e = va_arg(ap, double); // float automatically promoted in ...
    if (new_e == 0) break; else e=new_e;

    new_f = va_arg(ap, int);
    if (new_f == 0) break; else f=new_f;

  } while(0);
  va_end(ap);

  // Sanity checking of parameters
  assert(codec != NULL);
  if ((q <= 0) || (e <= 0) || (e >= 1) || (mblocks <= 0)) {
    flags |= OC_FATAL_ERROR;
    return codec->flags = flags;
  }

  // clear structure out and fill in what we can now
  memset(codec,0,sizeof(oc_codec));
  codec->mblocks = mblocks;
  codec->q       = q;

  // how many auxiliary blocks would this scheme need?
  ablocks =  oc_count_aux(mblocks,q,e);

  // does epsilon value need updating?
  new_f = oc_max_degree(e);

  if (new_f > mblocks + ablocks) {
    flags  |= OC_E_CHANGED;
    new_e   = oc_recalculate_e(mblocks,q,e);
    new_f   = oc_max_degree(new_e);
    ablocks = oc_count_aux(mblocks,q,new_e);

    e = new_e;
  }

  if (f && (new_f != f))
    flags |= OC_F_CHANGED;
  f = new_f;

  // allocate scratch space for shuffles (F elements)
  if (NULL == (codec->shuffle_source = malloc(f * sizeof(int))))
    flags |= OC_FATAL_ERROR;
  if (NULL == (codec->shuffle_source = malloc(f * sizeof(int))))
    flags |= OC_FATAL_ERROR;

  // Fill in remaining fields
  codec->ablocks  = ablocks;
  codec->coblocks = mblocks + ablocks;
  codec->e        = e;
  codec->F        = f;
  codec->flags    = flags;
  
  // calculate the probability distribution (uses stashed values)
  if (NULL == oc_codec_init_probdist(codec))
    flags |= OC_FATAL_ERROR;

  // Auxiliary map is set up in encoder/decoder sub-class

  return flags;

}

int oc_is_message(oc_codec *codec,int m) {
  return (m < codec->mblocks);
}

int oc_is_auxiliary(oc_codec *codec,int m) {
  return ((m >= codec->mblocks) && (m < codec->coblocks));
}

int oc_is_check(oc_codec *codec,int m) {
  return (m >= codec->coblocks);
}

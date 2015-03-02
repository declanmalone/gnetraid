// "Base class methods" for Online Code algorithm

#include <math.h>
#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#include "structs.h"
#include "online-code.h"
#include "floyd.h"


double *oc_codec_init_probdist(oc_codec *codec) {

  int    coblocks = codec->coblocks;
  double epsilon  = codec->e;
  double f        = codec->F;	// save doing cast later

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

  double p1     = 1 - (1 + 1/f) / (1 + epsilon);
  double pfterm;		// calculate later to avoid potential
				// division by zero if f == 1
  double *p, p_i, sum;
  double i, iterm;

  // basic sanity checking
  assert(f <= coblocks);
  assert(p1 > 0);

  // allocate array
  p = calloc(f, sizeof(double));

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
  int *p, i, j;

  int *map = calloc(q * mblocks, sizeof(int));

  if (map == NULL) return NULL;

  codec->auxiliary = map;

  // return values in the range [0,MAX]
#define RandInt(RNG, MAX) (floor(oc_rng_rand(RNG, MAX + 1)))
  
  // Attach each mblock to q ablocks

  // The default value of q would allow us to use a more efficient
  // unrolled version of Floyd's algorithm
  if (q == 3) {
    int a, b, c;
    for (i=0; i < mblocks; ++i) {

      a = mblocks + RandInt(rng, ablocks - 3);
      *(map++) = a;
      b = mblocks + RandInt(rng, ablocks - 2);
      if (b == a)
	b = mblocks + ablocks - 2;
      *(map++) = b;
      c = mblocks + RandInt(rng, ablocks - 1);
      if ((c == a) || (c == b) )
	c = mblocks + ablocks - 1;
      *(map++) = c;
      // printf("msg block %d attaches to %d, %d, %d\n", i, a, b, c);
    }
  } else {
    SET_INIT(codec->floyd_scratch, mblocks, ablocks, q);
    for (i=0; i < mblocks; ++i) {
      p = oc_floyd(rng, mblocks, ablocks, q);
      for (j=0; j < q; ++j) {
	*(map++) = p[j];
      }
      free(p);
    }
  }

  return codec->auxiliary;

}


// use probability distribution table and rng to find degree of a
// check block (a value between 1 and F)
int oc_random_degree(oc_codec *codec, oc_rng_sha1 *rng) {

  int     i = 0;
  double  r = oc_rng_rand(rng, 1.0);
  double *p = codec->p;
  // A linear scan is likely to be quick for most values of r.  Extra
  // speedup might be achieved by partitioning and using binary search
  // on the "flatter" part of the array but this is easier.
  while (r > *(p++)) {	// terminates since r < p[last] (ie, 1)
    ++i;
  }
  return i + 1;
}

// Create a new check block as a list of 'degree' downward edges.
// 'Degree' is stored in the first element of the returned list.

int *oc_checkblock_map(oc_codec *codec, int degree, oc_rng_sha1 *rng) {

  int  coblocks = codec->mblocks + codec->ablocks;
  int *p, *q;

  p = codec->xor_scratch;

  // select 'degree' composite blocks ('src' array is assumed to be
  // initialised already)

  q = oc_floyd(rng, 0, coblocks, degree);

  // save degree and list of blocks in our array
  *(p++) = degree;
  memcpy(p, q, degree * sizeof(int));

  return codec->xor_scratch;

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
int oc_max_degree(double e) {
  e /= 2;
  return ceil( (2*log(e)) / log(1-e) );
}

// count number of auxiliary blocks
int oc_count_aux(int mblocks, int q, double e) {

  // shouldn't overflow for any practical values of q, mblocks
  int aux_blocks = ceil(0.55 * q * e * mblocks);
  return (aux_blocks < q) ? q : aux_blocks;

}

// Use a binary search to find a new epsilon such that
// oc_max_degree(epsilon) <= mblocks + ablocks (ie, n')
double oc_recalculate_e(int mblocks, int q, double e) {

  double l, r, m;		// left, right, middle
  int    ablocks  = oc_count_aux(mblocks, q, e);
  int    coblocks = mblocks + ablocks;

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

int oc_eval_f(double t) {
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
// are smaller than doubles a terminal zero (integer) may not be read
// as 0.0 (double). That's the sort of detail that I should probably
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
  double  e=OC_DEFAULT_E, new_e;
  int     f=OC_DEFAULT_F, new_f; // f=0 => not supplied (calculated)

  int     ablocks,coblocks;

  // extract variadic args
  va_start(ap, mblocks);
  do {				// preferable to goto?
    new_q = va_arg(ap, int);
    if (new_q == 0) break; else q=new_q;

    new_e = va_arg(ap, double);
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

  // allocate scratch space for creating check block mapping
  if (NULL == (codec->xor_scratch = calloc(f + 1, sizeof(int))))
    flags |= OC_FATAL_ERROR;
  if (NULL == (codec->floyd_scratch = calloc(f + 1, sizeof(int))))
    flags |= OC_FATAL_ERROR;
  SET_INIT(codec->floyd_scratch, mblocks, ablocks, q);

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

// More utility routines for dealing with "XOR list" (arrays where
// p[0] == number of elements in rest of array) and linked lists (of
// type oc_uni_block)

// print an xor list
void oc_print_xor_list(int *xp, char *terminal) {
  int count = *(xp++);
  while (count--) {
    printf("%d%s", *(xp++), (count == 0) ? "" : ", ");
  }
  printf("%s", terminal);
}

// calculate the length of a linked list
int oc_len_linked_list (oc_uni_block *list) {
  int len = 0;
  while (NULL != list) {
    ++len;
    list = list->a.next;
  }
  return len;
}

// print contents of linked list
void oc_print_linked_list(oc_uni_block *list, char *terminal) {
  while (NULL != list) {
    printf("%d%s", list->b.value, (NULL == list->a.next) ? "" : ", ");
    list = list->a.next;
  }
  printf("%s", terminal);
}

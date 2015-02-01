// Common definitions for Online Code implementation

#ifndef OC_ONLINE_CODE_H
#define OC_ONLINE_CODE_H

#include "oc_encoder.h"
#include "oc_decoder.h"

#include "rng_sha1.h"

#include "tuples.h"

// structure holding details common to encoder and decoder

typdef struct {

  int   q;			// outer block coding factor
  float e;			// epsilon
  int   F;			// max degree

  int   mblocks, ablocks;	// counts of message, auxiliary blocks
  int   coblocks;		// message blocks + auxiliary blocks

  float *p;			// probablity distribution table

  int   flags;			// error flags; see discussion of
				// oc_codec_init below

} oc_codec;

// init takes at least the number of message blocks, but also possibly
// values for q, e and F. The other parameters are derived from those
// values. The full argument list looks like:
//
// oc_codec_init (oc_codec *codec, mblocks, q=3, e=0.01, F=0);
// F=0 => calculate F based on other parameters

int oc_codec_init(oc_codec *codec, int mblocks, ...);

// init tries its best to combine the passed (or default) parameter
// values, but some combinations don't make sense. If it detects such
// a situation and has to change some parameters so that things do
// make sense, it will set one or more of the flag bits below:

#define OC_Q_CHANGED 1
#define OC_E_CHANGED 2
#define OC_F_CHANGED 4
#define OC_FLAG_ERROR 8  // supplied parameters had unfixable error

// (flags are returned, and also stored in the structure)

// init doesn't allocate memory for the probablity distribution table
// or populate it; those steps are done separately with the following
// routine. This is decoupled from init to allow the caller to tweak
// and validate the codec parameters first without engaging in
// wasteful alloc/free steps every time something changes.

// allocate and populate probablity table here (returns pointer to new
// memory or NULL if malloc fails):
float *oc_codec_init_probdist(oc_codec *codec);

// use probability distribution table and rng to find degree of a
// check block
int oc_random_degree(oc_codec *codec, rng_sha1 *rng);

// The following routines are used by init to validate and "fix" the
// parameter list. They can also be called directly.

int oc_max_degree(float e);	// calculate F from epsilon
int oc_count_aux(int mblocks, int q, float e);
int oc_check_parameters(int mblocks, int q, float e, int F);
int oc_find_new_e();
int oc_eval_f(float t);



#endif

// Common definitions for Online Code implementation

#ifndef OC_ONLINE_CODE_H
#define OC_ONLINE_CODE_H

// #include "oc_encoder.h"
// #include "oc_decoder.h"

#include "structs.h"
#include "rng_sha1.h"

// structure holding details common to encoder and decoder

typedef struct {

  int   q;			// outer block coding factor
  float e;			// epsilon
  int   F;			// max degree

  int   mblocks, ablocks;	// counts of message, auxiliary blocks
  int   coblocks;		// message blocks + auxiliary blocks

  float *p;			// probablity distribution table

  int   flags;			// error flags; see discussion of
				// oc_codec_init below

  int  *auxiliary;		// 2d array mapping message->auxiliary

  int  *shuffle_source;		// re-usable scratch space for holding
  int  *shuffle_dest;		// source/dest for Fisher-Yates shuffle

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

#define OC_E_CHANGED   1
#define OC_F_CHANGED   2
#define OC_FATAL_ERROR 4  // Fatal error (parameters/memory allocation)
//#define OC_Q_CHANGED 8  // q always constant

// (flags are returned, and also stored in the structure)

// init doesn't allocate memory for the probablity distribution table
// or populate it; those steps are done separately with the following
// routine. This is decoupled from init to allow the caller to tweak
// and validate the codec parameters first without engaging in
// wasteful alloc/free steps every time something changes.

// allocate and populate probablity table here (returns pointer to new
// memory or NULL if malloc fails):
float *oc_codec_init_probdist(oc_codec *codec);

// Fisher-Yates shuffle routine
int *oc_fisher_yates(int *src, int *dst, int k, int n, oc_rng_sha1 *rng);

// Create auxiliary map
int *oc_auxiliary_map(oc_codec *codec, oc_rng_sha1 *rng);

// use probability distribution table and rng to find degree of a
// check block
int oc_random_degree(oc_codec *codec, oc_rng_sha1 *rng);

// Create a check block map
int *oc_checkblock_map(oc_codec *codec, int degree, oc_rng_sha1 *rng);

// The following routines are used by init to validate and "fix" the
// parameter list. They can also be called directly.

int oc_max_degree(float e);	// calculate F from epsilon
int oc_count_aux(int mblocks, int q, float e);
int oc_check_parameters(int mblocks, int q, float e, int F);
float oc_recalculate_e(int mblocks, int q, float e);
int oc_eval_f(float t);

// Block "expansion": When dealing with lists of blocks, we have the
// option of expanding message, auxiliary or check blocks. In the
// encoder it only makes sense to expand auxiliary blocks (into
// message blocks), while in the decoder we can expand auxiliary or
// message blocks (into check blocks and/or auxiliary blocks, provided
// the auxiliary expansion flag isn't set)

#define OC_EXPAND_MSG 1
#define OC_EXPAND_AUX 2
#define OC_EXPAND_CHK 4



#endif

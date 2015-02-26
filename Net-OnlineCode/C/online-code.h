// Common definitions for Online Code implementation

#ifndef OC_ONLINE_CODE_H
#define OC_ONLINE_CODE_H

// Profiling with valgrind showed me that the memcpy in the
// Fisher-Yates shuffle routine was taking a lot of time. Defining the
// macro below changes the routine so that it calculates the array to
// be shuffled every time instead of using memcpy.
//
// It's quite possible that memcpy will be faster on *some* platforms
// or compiler/libc combinations. For comparison, I tested on three
// platforms (all Linux/gcc/glibc).
//
// Running mindecoder -d 100000, no OC_DEBUG or profiling options set
// and stdout directed to /dev/null:
//
// Machine                            with memcpy    without memcpy
//
// PC (AMD Athlon X2, x86_64 2.2GHz)  ~31s           ~13s
// ODROID X2 (ARMv7, 1.7GHz)          ~17s           ~15s
// Raspberry Pi B (ARMv6 700MHz)      ~128s          ~116s
//
// These benchmarks were correct at time of this commit:
//   edd970f23ed504781bd5f729a93e4b073823bb32

#define OC_AVOID_MEMCPY

// #include "oc_encoder.h"
// #include "oc_decoder.h"

#include "structs.h"
#include "rng_sha1.h"

// structure holding details common to encoder and decoder

typedef struct {

  int    q;			// outer block coding factor
  double e;			// epsilon
  int    F;			// max degree

  int    mblocks, ablocks;	// counts of message, auxiliary blocks
  int    coblocks;		// message blocks + auxiliary blocks

  double *p;			// probablity distribution table

  int    flags;			// error flags; see discussion of
				// oc_codec_init below

  int   *auxiliary;		// 2d array mapping message->auxiliary

  int   *shuffle_source;	// re-usable scratch space for holding
  int   *shuffle_dest;		// source/dest for Fisher-Yates shuffle

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
double *oc_codec_init_probdist(oc_codec *codec);

// Fisher-Yates shuffle routine
#ifdef OC_AVOID_MEMCPY
int *oc_fisher_yates(int *src, int *dst, int start, int k, int n, oc_rng_sha1 *rng);
#else
int *oc_fisher_yates(int *src, int *dst, int k, int n, oc_rng_sha1 *rng);
#endif


// Create auxiliary map
int *oc_auxiliary_map(oc_codec *codec, oc_rng_sha1 *rng);

// use probability distribution table and rng to find degree of a
// check block
int oc_random_degree(oc_codec *codec, oc_rng_sha1 *rng);

// Create a check block map
int *oc_checkblock_map(oc_codec *codec, int degree, oc_rng_sha1 *rng);

// The following routines are used by init to validate and "fix" the
// parameter list. They can also be called directly.

int oc_max_degree(double e);	// calculate F from epsilon
int oc_count_aux(int mblocks, int q, double e);
int oc_check_parameters(int mblocks, int q, double e, int F);
double oc_recalculate_e(int mblocks, int q, double e);
int oc_eval_f(double t);

// Block "expansion": When dealing with lists of blocks, we have the
// option of expanding message, auxiliary or check blocks. In the
// encoder it only makes sense to expand auxiliary blocks (into
// message blocks), while in the decoder we can expand auxiliary or
// message blocks (into check blocks and possibly auxiliary blocks,
// provided the auxiliary expansion flag isn't set).
//
// The option to expand auxiliary blocks probably isn't that useful
// (except maybe for debugging) so it might go away at some point. It
// might still be useful on machines with very little memory and very
// large block sizes, though.

#define OC_EXPAND_MSG 1
#define OC_EXPAND_AUX 2
#define OC_EXPAND_CHK 4

// The decoder's expansion routine also takes a flag to decide whether
// or not to XOR in solved message/auxiliary blocks during expansion
// (provided they're actually cached).
#define OC_XOR_CACHED_MSG 8

// The OC_XOR_CACHED_AUX option is for expanding cached aux blocks.
// This pair of options will usually be set but can be turned off if
// the caller wants to know exactly which blocks are included in an
// expansion.
#define OC_XOR_CACHED_AUX 16


// Defaults for q, e, F. Needed to keep consistency among online-code,
// encoder and decoder va_args handling (code must be duplicated due
// to shortcoming of C's ... semantics)

#define OC_DEFAULT_Q  3
#define OC_DEFAULT_E  0.01
#define OC_DEFAULT_F  0

// XOR/linked list utilities
void oc_print_xor_list(int *xp, char *terminal);
int  oc_len_linked_list  (oc_uni_block *list);
void oc_print_linked_list(oc_uni_block *list, char *terminal);


#endif

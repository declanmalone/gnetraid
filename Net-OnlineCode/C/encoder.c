// Encoder methods

#include <math.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

#include "structs.h"
#include "online-code.h"
#include "encoder.h"

// Encoder is somewhat simpler than the Decoder, but the constructor
// is almost the same.
int oc_encoder_init(oc_encoder *enc, int mblocks, oc_rng_sha1 *rng,
		    int flags, ...) { // ... q, e, f

  int    q=OC_DEFAULT_Q, new_q;
  double e=OC_DEFAULT_E, new_e;
  int    f=OC_DEFAULT_F, new_f;	// f=0 => not supplied (calculated)
  int    i, *p, coblocks;

  int    super_flag = 0;

  // extract variadic args (duplicates code in parent class)
  va_list ap;

  va_start(ap, flags);
  do {				// preferable to goto?
    new_q = va_arg(ap, int);
    if (new_q == 0) break; else q=new_q;

    new_e = va_arg(ap, double); // float automatically promoted in ...
    if (new_e == 0) break; else e=new_e;

    new_f = va_arg(ap, int);
    if (new_f == 0) break; else f=new_f;

  } while(0);
  va_end(ap);

  if (NULL == enc) {
    fprintf(stderr, "oc_encoder_init: passed NULL encoder pointer\n");
    return OC_FATAL_ERROR;
  }

  if (NULL == rng) {
    fprintf(stderr, "oc_encoder_init: passed NULL rng pointer\n");
    return OC_FATAL_ERROR;
  }
  enc->rng = rng;

  // call "super" with extracted args
  super_flag = oc_codec_init(&(enc->base), mblocks, q, e, f, 0ll);

  if (super_flag & OC_FATAL_ERROR) {
    fprintf(stderr, "oc_encoder_init: parent class returned fatal error\n");
    return super_flag;
  }

  // Only OC_EXPAND_AUX makes sense in the encoder, but I'm leaning
  // towards either removing the option or doing a fairly substantial
  // rewrite (to allow this code to explicitly manage block caching).
  // Since things are in a state of flux right now, I'm not going to
  // implement OC_EXPAND_AUX handling in the Encoder just yet. This
  // also saves me from having to implement the reverse mapping of
  // check blocks to message blocks here right now.
  if (flags & OC_EXPAND_AUX) {
    fprintf(stderr, "oc_encoder_init: OC_EXPAND_AUX not implemented yet\n");
    return super_flag & OC_FATAL_ERROR;
  }

  if (flags & OC_EXPAND_CHK) {
    fprintf(stderr, "oc_encoder_init: OC_EXPAND_CHK not valid here\n");
    return super_flag & OC_FATAL_ERROR;
  }
  if (flags & OC_EXPAND_MSG) {
    fprintf(stderr, "oc_encoder_init: OC_EXPAND_MSG not valid here\n");
    return super_flag & OC_FATAL_ERROR;
  }
  enc->flags = flags;		// our flags; parent's is just for errors

  // parent doesn't create auxiliary mapping so we do it
  if (NULL == oc_auxiliary_map(&(enc->base), rng)) { // stashed for us
    fprintf(stderr, "oc_encoder_init: failed to make auxiliary mapping\n");
    return super_flag & OC_FATAL_ERROR;
  }

  return super_flag;

}

// I'm not implementing OC_EXPAND_AUX right now, so check block
// creation is simply a matter of returning whatever the parent
// class's oc_checkblock_map() routine returns. I'll just create a
// stub routine here that calls it.

int *oc_encoder_check_block(oc_encoder *enc) {

  oc_codec *codec;
  int degree;

  assert(NULL != enc);
  assert(NULL != enc->rng);

  codec  = &(enc->base);
  degree = oc_random_degree(codec, enc->rng);
  return   oc_checkblock_map(codec, degree, enc->rng);
}


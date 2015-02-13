// Encoder-specific stuff

#ifndef OC_ENCODER_H
#define OC_ENCODER_H

typedef struct {

  oc_codec     base;
  oc_rng_sha1 *rng;
  int          flags;
} oc_encoder;


int oc_encoder_init(oc_encoder *enc, int mblocks, oc_rng_sha1 *rng,
		    int flags, ...); // ... q, e, f
  
int *oc_encoder_check_block(oc_encoder *enc);

#endif

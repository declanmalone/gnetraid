// Encoder-specific stuff

#ifndef OC_ENCODER_H
#define OC_ENCODER_H

typedef struct {

  oc_codec     base;

  
  oc_rng_sha1 *rng;

} oc_encoder;



#endif

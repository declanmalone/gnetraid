// Decoder-specific stuff

#ifndef OC_DECODER_H
#define OC_DECODER_H

#include "online-code.h"
#include "graph.h"

typedef struct {

  oc_codec base;

  oc_rng_sha1 *rng;

  oc_graph graph;

} oc_decoder;


#endif

// Decoder-specific stuff

#ifndef OC_DECODER_H
#define OC_DECODER_H

#include "online-code.h"
#include "graph.h"

typedef struct {

  oc_codec base;
  oc_graph graph;
  oc_rng_sha1 *rng;

  int flags;
} oc_decoder;


int oc_resolve(oc_decoder *decoder, oc_block_list **solved_list);


#endif

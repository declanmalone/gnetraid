// Decoder-specific stuff

#ifndef OC_DECODER_H
#define OC_DECODER_H

#include "online-code.h"
#include "graph.h"

// need to give the struct a name to allow declaration of callback
// function prototype
typedef struct oc_decoder_struct {

  oc_codec base;
  oc_graph graph;
  oc_rng_sha1 *rng;

  int flags;

  // variables used when iterating over expansion of XOR list
  // function pointer:
  void (*callback)(struct oc_decoder_struct *d, int node);
  int  count;			// use when counting
  int *dest;			// use when copying

} oc_decoder;


int oc_decoder_init(oc_decoder *dec, int mblocks, oc_rng_sha1 *rng,
		    int flags, ...); // ... fudge, q, e, f

int oc_resolve(oc_decoder *decoder, oc_block_list **solved_list);


#endif

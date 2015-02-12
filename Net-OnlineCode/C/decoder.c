// Decoder methods

#include <math.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

#include "structs.h"
#include "decoder.h"

int oc_decoder_init(oc_decoder *dec, int mblocks, oc_rng_sha1 *rng,
		    int flags, ...) { // ... fudge, q, e, f

  // Besides required parameters, we also have optional ones that are
  // the same ones that oc_codec_init takes. The end of the optional
  // list of args must be terminated with 0ll.
  //
  // The flags parameter here is composed of OC_EXPAND_MSG,
  // OC_EXPAND_AUX or a combination (logical or) of the two. I'm
  // making it a required parameter to make sure a null value isn't
  // confused with the end of the optional parameter list.

  // C doesn't let you pass va_args from here into the oc_codec_init
  // function so I'm stuck with various inelegant solutions. The least
  // bad seems to be to duplicate the va_args functionality here (and
  // in the encoder) and keep things consistent by using macros to
  // define the defaults in "online-code.h".

  float  fudge=1.2, new_fudge;	// !!new optional parameter!!
  int    q=OC_DEFAULT_Q, new_q;
  double e=OC_DEFAULT_E, new_e;
  int    f=OC_DEFAULT_F, new_f;	// f=0 => not supplied (calculated)
  int    i, *p, coblocks;

  int    super_flag;

  // extract variadic args
  va_list ap;

  va_start(ap, flags);
  do {				// preferable to goto?
    // new "fudge factor" optional parameter (float promoted in ...)
    new_fudge = va_arg(ap, double);
    if (new_fudge == 0.0) break; else fudge = new_fudge;

    new_q = va_arg(ap, int);
    if (new_q == 0) break; else q=new_q;

    new_e = va_arg(ap, double); // float automatically promoted in ...
    if (new_e == 0) break; else e=new_e;

    new_f = va_arg(ap, int);
    if (new_f == 0) break; else f=new_f;

  } while(0);
  va_end(ap);

  if (NULL == dec) {
    fprintf(stderr, "oc_decoder_init: passed NULL decoder pointer\n");
    return OC_FATAL_ERROR;
  }

  if (NULL == rng) {
    fprintf(stderr, "oc_decoder_init: passed NULL rng pointer\n");
    return OC_FATAL_ERROR;
  }
  dec->rng = rng;

  // call "super" with extracted args
  super_flag = oc_codec_init(&(dec->base), mblocks, q, e, f, 0ll);

  if (super_flag & OC_FATAL_ERROR) {
    fprintf(stderr, "oc_decoder_init: parent class returned fatal error\n");
    return super_flag;
  }

  if (flags & OC_EXPAND_CHK) {
    fprintf(stderr, "oc_decoder_init: OC_EXPAND_CHK not valid here\n");
    return super_flag & OC_FATAL_ERROR;
  }
  dec->flags = flags;		// our flags; parent's is just for errors

  // parent doesn't create auxiliary mapping so we do it
  if (NULL == oc_auxiliary_map(&(dec->base), rng)) { // stashed for us
    fprintf(stderr, "oc_decoder_init: failed to make auxiliary mapping\n");
    return super_flag & OC_FATAL_ERROR;
  }

  // set up Fisher-Yates source array for check block selection
  p = dec->base.shuffle_source;
  coblocks = dec->base.coblocks;
  for (i=0; i < coblocks; ++i) {
    *(p++) = i;
  }

  // Create graph decoder
  if (oc_graph_init(&(dec->graph), &(dec->base), fudge)) {
    fprintf(stderr, "oc_decoder_init: failed to initialise graph\n");
    return super_flag & OC_FATAL_ERROR;
  }

  return super_flag;

}


// Accept a check block (from a sender) and return zero on success
int oc_accept_check_block(oc_decoder *decoder, oc_rng_sha1 *rng) {

  int *p, f;
  oc_codec *codec;
  oc_graph *graph;

  assert(decoder != NULL);
  assert(rng != NULL);

  codec = &(decoder->base);	// could just cast decoder
  graph = &(decoder->graph);

  // call parent class methods to figure out mapping based on RNG
  f = oc_random_degree(codec, rng);
  p = oc_checkblock_map(codec, f, rng);
  if (p == NULL) {
    fprintf(stderr, "oc_accept_check_block: failed to allocate check block\n");
    return -1;
  }

  // register the new check block in the graph
  if (-1 == oc_graph_check_block(graph, p)) {
    fprintf(stderr, "oc_accept_check_block: failed to graph check block\n");
    return -1;
  }

  return 0;

}

// pass resolve calls onto graph decoder resolve method
int oc_resolve(oc_decoder *decoder, oc_block_list **solved) {

  assert(decoder != NULL);
  assert(solved  != NULL);

  return oc_graph_resolve(&(decoder->graph), solved);
}

// "Lazy" expansion routines
//
// The resolver includes block IDs of message and aux blocks rather
// than expand them into their constituent aux and/or check blocks
// since this is quicker and saves memory. As a result, if we want to
// have the xor lists that it returns only in terms of check blocks or
// check and aux blocks, they have to be expanded afterwards.
//
// My Perl implementation makes liberal use of the language's ability
// to create dynamic lists during the expansion, but this being C it
// isn't so straightforward.
//
// In this port, I'm going to implement the expansion as a set of
// functions:
//
// * a recursive part that iterates over the list and takes a callback
//   (function pointer) argument
// * one callback that scans the expansion to find its length
// * one callback that copies the expanded list
// * a high-level function that calls the recursive part twice (once
//   for each callback) to create the expanded array and then does the
//   sorting/de-duplication stages to create the final array
// 
// To cut down on the size of the stack frames I'm going to use a set
// of decoder-local variables that the callbacks will access (instead
// of passing state through the stack).
//

typedef void (*callback_t)(oc_decoder *d, int node);

// callbacks
static void count(oc_decoder *d, int node) { ++(d->count); };
static void copy(oc_decoder *d, int node)  { *((d->dest)++) = node; };

// recursive part
static void expandr(oc_decoder *d, int flags,
		    int *nodelist) { // [size, elem1, elem2, ... ]

  register int i, node, size;
  register int mblocks, coblocks;

  mblocks  = d->base.mblocks;
  coblocks = d->base.coblocks;

  assert(nodelist != NULL);
  size = *(nodelist++);

  for (i=0; i < size; ++i) {

    node = *(nodelist++);
    // TODO: implement cache-related stuff
    if (
	((flags & OC_EXPAND_MSG) && (node < mblocks)) ||
	((flags & OC_EXPAND_AUX) && (node >= mblocks) && (node <coblocks)) 
	) 
      expandr(d, flags, d->graph.xor_list[node]);
    else 
      (*(d->callback))(d, *nodelist);	// call callback on unexpanded block
  }
}

// callback for qsort
static int compare_ascending(const void *a, const void *b) {
       if ( *((int *)a) == *((int *)b))    return 0;
  else if ( *((int *)a)  > *((int *)b))    return -1;
                       else                return +1;
}

int *oc_expansion(oc_decoder *decoder, int node) {

  int ic, *p, oc, *op, pass, i, previous, runlength;

  // 1st Stage: expand into a list with duplicates
  decoder->callback = &count;
  decoder->count    = 0;
  expandr(decoder, decoder->flags, decoder->graph.xor_list[node]);

  // Allocate memory, including space for a sentinel at the end.
  if (NULL == (p = calloc(decoder->count + 2, sizeof(int))))
    return NULL;
  *p = ic = decoder->count + 1;
  p[ic] = -1;			// sentinel (not a valid block number)

  decoder->callback = &copy;
  decoder->dest     = p + 1;
  expandr(decoder, decoder->flags, decoder->graph.xor_list[node]);

  decoder->dest     = p;	// stash p for later reuse/free

  // 2nd Stage: sort the list. I will probably use heap sort later,
  // but I can use glibc's qsort for now (don't sort sentinel value)
  qsort(++p, ic - 1, sizeof(int), compare_ascending);

  // 3rd Stage: remove elements that appear an even number of times

  // I'll do this in two passes so that we can return a fixed-size
  // array to the caller. Using a sentinel at the end of the list
  // avoids duplicating a bunch of code outside the loop to deal with
  // the last run in the input.

  for (pass = oc = 0; pass < 2; ++pass ) {

    p = decoder->dest;		// restore stashed input pointer
    previous  = *(++p);		// start from p[1] (skip p[0] = length)
    runlength = 0;		// even run lengths cancel each other out
    for (i = 0; i < ic; ++i, ++p) { // scan up to and including sentinel
      if (*p == previous) {
	++runlength;
      } else {
	if (runlength &1)
	  // TODO: implement cache-related stuff
	  if (pass == 0)	// count up non-cancelling blocks first 
	    ++oc;
	  else			// copy block ID or XOR from cache later
	    *(++op) = previous;
	previous  = *p;
	runlength = 1;
      }
    }

    // create output array at end of first pass
    if (pass == 0) {
      if (NULL == (op = calloc(oc + 1, sizeof(int))))
	return NULL;
      *op = oc;
    }
  }

  free(decoder->dest);
  return op;

}


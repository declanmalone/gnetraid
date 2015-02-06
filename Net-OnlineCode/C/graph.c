// Graph decoding routines

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "online-code.h"
#include "graph.h"

int oc_graph_init(oc_graph *graph, oc_codec *codec, float fudge) {

  // Various parameters snarfed from codec. Some are copied locally.
  int  mblocks = codec->mblocks;
  int  ablocks = codec->ablocks;
  int coblocks = codec->coblocks;

  // we need e and q to calculate the expected number of check blocks
  float e = codec->e;
  int   q = codec->q;		// also needed to iterate over aux mapping

  float expected;		// expected number of check blocks
  int   check_space;		// actual space for check blocks (fudged)

  int *aux_map = codec->auxiliary;

  // iterators and temporary variables
  int msg, aux, *mp, *p, aux_temp, temp;

  // Check parameters and return non-zero value on failures
  if (mblocks < 1)
    return fprintf(stderr, "graph init: mblocks (%d) invalid\n", mblocks);

  if (ablocks < 1)
    return fprintf(stderr, "graph init: ablocks (%d) invalid\n", ablocks);

  if (NULL == aux_map)
    return fprintf(stderr, "graph init: codec has null auxiliary map\n");

  if (fudge <= 1.0)
    return fprintf(stderr, "graph init: Fudge factor (%f) <= 1.0\n", fudge);

  // calculate space to allocate for check blocks (only)
  expected = (1 + q * e) * mblocks;
  check_space = fudge * expected;

  // prepare structure
  memset(graph, 0, sizeof(oc_graph));

  // save simple variables (all others start zeroed)
  graph->mblocks    = mblocks;
  graph->ablocks    = ablocks;
  graph->coblocks   = coblocks;
  graph->nodes      = coblocks;
  graph->node_space = coblocks + check_space;
  graph->unsolved_count = mblocks;

  // Allocate "v" edges (omit message blocks)
  if (NULL == (graph->v_edges = calloc(ablocks + check_space, sizeof(int *))))
    return fprintf(stderr, "graph init: Failed to allocate 'v' edges\n");
  memset(graph->v_edges,0,(ablocks + check_space) * sizeof(int *));

  // Allocate "n" edges (omit check blocks)
  if (NULL == (graph->n_edges = calloc(coblocks, sizeof(oc_block_list *))))
    return fprintf(stderr, "graph init: Failed to allocate 'n' edges\n");
  memset(graph->n_edges,0,coblocks * sizeof(oc_block_list *));

  // allocate unsolved (downward) edge counts (omit message blocks)
  if (NULL == (graph->edge_count = calloc(ablocks + check_space, sizeof(int))))
    return fprintf(stderr, "graph init: Failed to allocate edge counts\n");
  memset(graph->v_edges,0,(ablocks + check_space) * sizeof(int));

  // allocate solved array (omit check blocks; assumed to be solved)
  if (NULL == (graph->solved = calloc(coblocks, sizeof(char))))
    return fprintf(stderr, "graph init: Failed to allocate 'solved' array\n");
  memset(graph->solved,0,coblocks * sizeof(char));

  // Allocate xor lists (omit check blocks; they are their own expansion)
  if (NULL == (graph->xor_list = calloc(coblocks, sizeof(int *))))
    return fprintf(stderr, "graph init: Failed to allocate xor lists\n");
  memset(graph->xor_list,0,coblocks * sizeof(int *));

  // Register the auxiliary mapping


  // 1st stage: allocate/store message up edges, count aux down edges

  mp = codec->auxiliary;	// start of 2d message -> aux* map
  for (msg = 0; msg < mblocks; ++msg) {

    if (NULL == (p = calloc(q + 1, sizeof(int))))
      return fprintf(stderr, "graph init: failed to malloc aux up edges\n");

    graph->n_edges[msg] = (oc_block_list *) p;
    p[0] = q;
    for (aux = 0; aux < q; ++aux) {
      aux_temp    = *(mp++);
      p[aux + 1]  = aux_temp;
      aux_temp   -= mblocks;	// relative to start of edge_count[]
      graph->edge_count[aux_temp] += 2; // +2 trick explained below
    }
  }

  // 2nd stage: allocate down edges for auxiliary nodes

  for (aux = 0; aux < ablocks; ++aux) {
    aux_temp = graph->edge_count[aux];
    aux_temp >>= 1;		// reverse +2 trick
    if (NULL == (p = calloc(1 + aux_temp, sizeof(int))))
      return fprintf(stderr, "graph init: failed to malloc aux down edges\n");

    graph->v_edges[aux] = p;
    p[0] = aux_temp;		// array size; edges stored in next pass
  }

  // 3rd stage: store down edges

  mp = codec->auxiliary;	// start of 2d message -> aux* map
  for (msg = 0; msg < mblocks; ++msg) {

    for (aux = 0; aux < q; ++aux) {
      aux_temp    = *(mp++) - mblocks;
      p = graph->v_edges[aux_temp];

      // The trick explained ...
      // * fills in array elements p[1] onwards (in reverse order)
      // * edge counts are correct after this pass (+2n - n = n)
      // * no extra array/pass to iterate over/recalculate edge counts
      temp = (graph->edge_count[aux_temp])--;
      p[temp - p[0]] = msg;
    }
  }

  return 0;
}


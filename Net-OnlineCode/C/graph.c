// Graph decoding routines

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

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

void oc_save_check_block() {

}


void oc_aux_rule(oc_graph *g, int node) {

}


// Work up from a newly-solved message or auxiliary block

void oc_cascade(oc_graph *g, int node) {


}

// Add a new node to the end of the pending list
oc_block_list *oc_push_pending(oc_ graph *g, int value) {

  oc_block_list *p;

  if (NULL == (p=malloc(sizeof(oc_block_list))))
    return NULL;

  p->next  = NULL;
  p->value = value;

  if (g->ptail != NULL)
    g->ptail->next = p;
  else
    g->phead = p;
  g->ptail = p;

  return p;
}

// Remove a node from the start of the pending list (returns a pointer
// to the node so that it can be re-used or freed later)
oc_block_list *oc_shift_pending(oc_ graph *g) {

  oc_block_list *node;

  assert(g->phead != NULL);

  node = g->phead;

  if (NULL == (g->phead = node->next))
    g->ptail = NULL;

  return node;

}

// Pushing to solved is similar to pushing to pending, but we don't
// need to allocate the new node
void oc_push_solved(oc_block_list *pnode, 
		    oc_block_list **phead,   // update caller's head
		    oc_block_list **ptail) { // and tail pointers

  pnode->next  = NULL;

  if (*ptail != NULL)
    (*ptail)->next = pnode;
  else
    *phead = pnode;
  *ptail = pnode;
}


// helper function to delete an up edge
void oc_delete_n_edge (oc_graph *g, int upper, int lower) {

  //   pp       is the address of the prior pointer
  //  *pp       is the value of the pointer itself
  // **pp       is the thing pointed at (an oc_block_list)
  // (*pp)->foo is a member of the oc_block_list

  oc_block_list **pp = &((graph->n_edges)[lower]);
  oc_block_list *p;

  while (NULL != (p = *pp)) {
    if (p->value == upper) {
      *pp = p->next;
      free(p);
      return;
    }
    pp = &(p->next);
  }

  // we shouldn't get here: up edge lower -> upper must exist
  assert (0 == 1);

}

// helper function to delete edges from a solved aux or check node
void oc_decommission_node (oc_graph *g, int node) {

  int *down, upper, lower, i;

  assert(node >= g->coblocks);

  down = g->v_edges[node];
  for (i = down[0]; i > 0; --i) {
    oc_delete_n_edge (g, node, down[i]);
  }
  free(down);
  g->v_edges[node] = NULL;	// not strictly necessary
}



// Resolve nodes by working down from check or aux blocks
// 
// Returns 0 for not done, 1 for done and -1 for error (malloc)
// If any nodes are solved, they're added to solved_list
//
int oc_resolve(oc_graph *graph, oc_block_list **solved_list) {

  int mblocks  = graph->mblocks;
  int ablocks  = graph->ablocks;
  int coblocks = graph->coblocks;

  oc_block_list *pnode;		// pending node

  // linked list for storing solved nodes (we return solved_head)
  oc_block_list *solved_head = NULL;
  oc_block_list *solved_tail = NULL;

  int from, to, count_unsolved, xor_count, i, *p, *xp, *ep;

  // Check whether our queue is empty. If it is, the caller needs to
  // add another check block
  if (NULL == graph->phead) {
    return graph->done;
  }

  // mark solved list as empty
  *solved_list = (oc_block_list *) NULL;

  // exit immediately if all message blocks are already solved
  if (0 == graph->unsolved_count)
    return graph->done = 1;

  while (NULL != graph->phead) { // while items in pending queue

    pnode = oc_shift_pending(graph);
    from  = pnode->value;

    assert(from >= mblocks);

    // my @solved_nodes = ();
    // my @unsolved_nodes;

    count_unsolved = (graph->edge_count)[from - mblocks];

    if (count_unsolved > 1)
      goto discard;

    if (count_unsolved == 0) {

      if ((from >= coblocks) || (graph->solved)[from]) {

	// The first test above matches check blocks, while the second
	// matches a previously-solved auxiliary block (the order of
	// tests is important to avoid going off the end of the solved
	// array). In either case, the node has no unsolved edges and
	// so adds no new information. We can remove it from the
	// graph.

	oc_decommission_node(graph, from);
	goto discard;
      }

      // This is an unsolved aux block. Solve it with aux rule
      oc_aux_rule(graph,from);

      oc_push_solved(pnode, &solved_head, &solved_tail);
      oc_cascade(graph,from);


    } else if (count_unsolved == 1) {

      // Discard unsolved auxiliary blocks
      if ((from < coblocks) && !(graph->solved)[from])
	goto discard;

      // Propagation rule matched (solved aux/check with 1 unsolved)

      // xor_list will be fixed-size array, so we need to count how
      // many elements will be in it.
      ep = (graph->v_edges)[from - mblocks];
      xor_count = *(ep++);	// number of v edges

      if (NULL == (p = malloc((xor_count + 1) * sizeof(int))))
	return -1;

      // store size and 'from' node in target xor list
      xp = p;
      *(xp++) = xor_count;
      *(xp++) = from;

      // iterate over v edges, adding solved ones to xor_list
      for (i = 0; i < xor_count; ++i) {
	if ((graph->solved)[*ep]) 
	  *(xp++) = *(ep++);
	else
	  to = *(ep++);		// note the unsolved one
      }

      // Set 'to' as solved
      pnode->value        = to;
      (graph->solved)[to] = 1;
      oc_push_solved(pnode, &solved_head, &solved_tail);

      // Save 'to' xor list and decommission 'from' node
      graph->xor_list[to] = p;
      oc_decommission_node(graph, from);

      // Update global structure and decide if we're done
      if (to < mblocks) {
	if (0 == (--(graph->unsolved_count))) {
	  graph->done = 1;
	  oc_flush_pending(graph);
	  break;		// finish searching
	}
      } else {
	// Solved auxiliary block, so queue it for resolving again
	oc_push_pending(graph, to);
      }

      // Cascade to potentially find more solvable blocks
      oc_cascade(graph, to);

      // If we reach this point, then pnode has been added to the
      // solved list. We continue to avoid the following free()
      continue;

  discard:
      free(pnode);

    }

  }

  *solved_list = solved_head;
  return graph->done;


}

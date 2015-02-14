// Graph decoding routines

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "online-code.h"
#include "graph.h"

#define OC_DEBUG 1

// I'm moving back to the Perl way of doing things and storing an XOR
// list for each node (not just msg/aux)
#define OC_USE_CHECK_XOR_LIST 1

// Create an up edge
oc_block_list *oc_create_n_edge(oc_graph *g, int upper, int lower) {

  oc_block_list *p;

  assert(upper > lower);

  if (NULL == (p = malloc(sizeof(oc_block_list))))
    return NULL;

  OC_DEBUG && fprintf(stdout, "Adding n edge %d -> %d\n", lower, upper);

  p->value = upper;
  p->next  = g->n_edges[lower];

  return g->n_edges[lower] = p;

}

int oc_graph_init(oc_graph *graph, oc_codec *codec, float fudge) {

  // Various parameters snarfed from codec. Some are copied locally.
  int  mblocks = codec->mblocks;
  int  ablocks = codec->ablocks;
  int coblocks = codec->coblocks;

  // we need e and q to calculate the expected number of check blocks
  double e = codec->e;
  int    q = codec->q;		// also needed to iterate over aux mapping

  float expected;		// expected number of check blocks
  int   check_space;		// actual space for check blocks (fudged)

  int *aux_map = codec->auxiliary;

  // iterators and temporary variables
  int msg, aux, *mp, *p, aux_temp, temp;

  // Check parameters and return non-zero value on failures
  if (mblocks < 1)
    return fprintf(stdout, "graph init: mblocks (%d) invalid\n", mblocks);

  if (ablocks < 1)
    return fprintf(stdout, "graph init: ablocks (%d) invalid\n", ablocks);

  if (NULL == aux_map)
    return fprintf(stdout, "graph init: codec has null auxiliary map\n");

  if (fudge <= 1.0)
    return fprintf(stdout, "graph init: Fudge factor (%f) <= 1.0\n", fudge);

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

  OC_DEBUG && fprintf(stdout, "check space is %d\n", check_space);

  // use a macro to make the following code clearer/less error-prone
#define OC_ALLOC(MEMBER, SPACE, TYPE, MESSAGE) \
  if (NULL == (graph->MEMBER = calloc(SPACE, sizeof(TYPE)))) \
    return fprintf(stdout, "graph init: Failed to allocate " \
		   MESSAGE "\n"); \
  memset(graph->MEMBER, 0, (SPACE) * sizeof(TYPE));

  // "v" edges: omit message blocks
  OC_ALLOC(v_edges, ablocks + check_space, int *,         "v edges");

  // "n" edges: omit check blocks
  OC_ALLOC(n_edges, coblocks, oc_block_list *,            "n edges");

  // unsolved (downward) edge counts: omit message blocks
  OC_ALLOC(edge_count, ablocks + check_space, int,        "unsolved v_edge counts");

  // solved array: omit check blocks; assumed to be solved
  OC_ALLOC(solved, coblocks, char,                        "solved array");

  // xor lists: omit nothing
  OC_ALLOC(xor_list, coblocks + check_space, int *,       "xor lists");


  // Register the auxiliary mapping
  // 1st stage: allocate/store message up edges, count aux down edges

  mp = codec->auxiliary;	// start of 2d message -> aux* map
  for (msg = 0; msg < mblocks; ++msg) {

    for (aux = 0; aux < q; ++aux) {
      aux_temp    = *(mp++);
      if (NULL == oc_create_n_edge(graph, aux_temp, msg))
	return fprintf(stdout, "graph init: failed to malloc aux up edge\n");
      aux_temp   -= mblocks;	// relative to start of edge_count[]
      assert (aux_temp >= 0);
      assert (aux_temp < ablocks);
      graph->edge_count[aux_temp] += 2; // +2 trick explained below
    }
  }

  // 2nd stage: allocate down edges for auxiliary nodes

  for (aux = 0; aux < ablocks; ++aux) {
    aux_temp = graph->edge_count[aux];
    aux_temp >>= 1;		// reverse +2 trick
    if (NULL == (p = calloc(1 + aux_temp, sizeof(int))))
      return fprintf(stdout, "graph init: failed to malloc aux down edges\n");

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

// Install a new check block into the graph. Called from decoder.
// Returns node number on success, -1 otherwise
int oc_graph_check_block(oc_graph *g, int *v_edges) {

  int node;
  int count, solved_count, end, i, tmp;
  int mblocks;

  int xor_length = 1, *ep, *xp;

  assert(g != NULL);
  assert(v_edges != NULL);

  node    = (g->nodes)++;
  mblocks = g->mblocks;

  OC_DEBUG && fprintf(stdout, "Graphing check node %d/%d:\n", node, g->node_space);

  // have we run out of space for new nodes?
  if (node >= g->node_space)
    return fprintf(stdout, "oc_graph_check_block: node >= node_space\n"), -1;

#if OC_USE_CHECK_XOR_LIST

  // Be like the Perl version: check blocks have an xor_list
  //
  // This will be composed of the node's ID plus any solved
  // nodes. Since we're allocating a fixed-sized list, we need two
  // passes (separated out into two loops for clarity).
  //

  solved_count = 0;
  ep    = v_edges;
  count = *(ep++);
  while (count--) {
    tmp = *(ep++);
    if (g->solved[tmp])
      ++solved_count;
  }

  // Allocate xor_list and set it up with our block ID
  if (NULL == (xp = calloc(solved_count + 2, sizeof(int))))
    return fprintf(stdout, "Failed to allocate xor_list for check block\n"), 
      -1;
  g->xor_list[node] = xp;
  *(xp++) = solved_count + 1;
  *(xp++) = node;

  // Scan edge list again. Solved nodes go to xor_list, unsolved have
  // n edges created for them.
  ep      = v_edges;
  count   = *ep;
  end     = *ep;
  *(ep++) = count - solved_count;
  while (count--) {
    tmp = *ep;
    if (g->solved[tmp]) {
      *(xp++) = tmp;
      *ep     = v_edges[end--]; // move last node and check again
      solved_count--;
    } else {
      if (NULL == oc_create_n_edge(g, node, tmp))
	return -1;
      ++ep;
    }
  }

#else

  // Edge creation (no pruning/xor_list)

  unsolved_count = count = v_edges[0];
  for (i=1; i <=count; ++i) {
    tmp = v_edges[i];
    OC_DEBUG && fprintf(stdout, "  %d -> %d\n", node, tmp);
    if (g->solved[tmp])
      --unsolved_count;
    if (NULL == oc_create_n_edge(g, node, tmp))
      return -1;
  }
  OC_DEBUG && fprintf(stdout, "\n");

#endif

  g->v_edges   [node - mblocks] = v_edges;
  g->edge_count[node - mblocks] = v_edges[0];

  printf("Check block mapping after removing solved: ");
  oc_print_xor_list(v_edges,"\n");

  printf("XOR list after adding solved: ");
  oc_print_xor_list(g->xor_list[node],"\n");

  // mark node as pending resolution
  if (NULL == oc_push_pending(g, node))
    return fprintf(stdout, "oc_graph_check_block: failed to push pending\n"),
      -1;

  // success: return index of newly created node
  return node;
}

// Aux rule triggers when an unsolved aux node has no unsolved v edges
void oc_aux_rule(oc_graph *g, int aux_node) {

  int mblocks = g->mblocks;
  int *p, i, count;

  assert(aux_node >= mblocks);
  assert(aux_node < g->coblocks);
  OC_DEBUG && fprintf(stdout, "Aux rule triggered on node %d\n", aux_node);

  g->solved[aux_node] = 1;

  // xor list becomes list of v edges
  g->xor_list[aux_node] = p = g->v_edges[aux_node - mblocks];

  // mark aux node as having no down edges
  g->v_edges[aux_node - mblocks] = (int *) NULL;

  // delete reciprocal up edges
  count = *(p++);
  for (i = 0; i < count; ++i) 
    oc_delete_n_edge(g, aux_node, *(p++));
}


// Cascade works up from a newly-solved message or auxiliary block
int oc_cascade(oc_graph *g, int node) {

  int mblocks  = g->mblocks;
  int coblocks = g->coblocks;
  oc_block_list *p;
  int to;

  assert(node < coblocks);

  OC_DEBUG && fprintf(stdout, "Cascading from node %d:\n", node);

  p = g->n_edges[node];

  // update unsolved edge count and push target to pending
  while (p != NULL) {
    to = p->value;
    if (node != to) {		// don't cascade back to where we came from
      OC_DEBUG && fprintf(stdout, "  pending link %d\n", to);
      if ((g->edge_count[to - mblocks]))
	--(g->edge_count[to - mblocks]);
      else 
	fprintf(stdout, "Unsolved edge count for %d was already zero\n", to);
      if (NULL == oc_push_pending(g, to))
	return -1;
    }
    p = p->next;
  }
  return 0;
}

// Add a new node to the end of the pending list
oc_block_list *oc_push_pending(oc_graph *g, int value) {

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
oc_block_list *oc_shift_pending(oc_graph *g) {

  oc_block_list *node;

  node = g->phead;
  assert(node != NULL);

  if (NULL == (g->phead = node->next))
    g->ptail = NULL;

  return node;

}

void oc_flush_pending(oc_graph *graph) {

  oc_block_list *tmp;

  assert(graph != NULL);

  while ((tmp = graph->phead) != NULL) {
    graph->phead = tmp->next;
    free(tmp);
  }
  graph->ptail = NULL;

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

  oc_block_list **pp, *p;
  //   pp       is the address of the prior pointer
  //  *pp       is the value of the pointer itself
  // **pp       is the thing pointed at (an oc_block_list)
  // (*pp)->foo is a member of the oc_block_list

  assert(upper > lower);
  pp = g->n_edges + lower;

  printf("Deleting n edge from %d up to %d\n", lower, upper);

  while (NULL != (p = *pp)) {
    if (p->value == upper) {
      *pp = p->next;
      free(p);
      return;
    }
    pp = &(p->next);
  }

  // we shouldn't get here
  //  assert (0 == "up edge didn't exist");

  // just turn the above into a warning for now
  fprintf(stdout, "oc_delete_n_edge: up edge %d -> %d didn't exist\n",
	  lower, upper);

}

// helper function to delete edges from a solved aux or check node
void oc_decommission_node (oc_graph *g, int node) {

  int *down, upper, lower, i;
  int mblocks = g->mblocks;

  assert(node >= mblocks);

  down = g->v_edges[node - mblocks];

  if (NULL == down) return;	// nodes may be decommissioned twice

  printf("Decommissioning node %d's v edges: ", node);
  oc_print_xor_list(down, "\n");

  for (i = down[0]; i > 0; --i) {
    oc_delete_n_edge (g, node, down[i]);
  }
  free(down);
  g->edge_count[node - mblocks] = 0;
  g->v_edges   [node - mblocks] = NULL;
}

// merge an xor list and a list of v edges into a new xor list
static int *oc_propagate_xor(int *xors, int *edges, int skip_edge) {

  int *xp, *p;
  int tmp, count, found = 0;

  assert(NULL != xors);
  assert(NULL != edges);

  tmp = xors[0] + edges[0] - 1;
  if (NULL == (p = xp = calloc(tmp + 1, sizeof(int))))
    return NULL;

  // Write size and all elements of xor array
  *(xp++) = tmp;
  count = *(xors++);
  while (count--)
    printf("Propagating XOR list element %d\n",
    *(xp++) = *(xors++)
	   )
      ;

  // Write all edges except skip_edge
  count = *(edges++);
  while (count--) {
    tmp = *(edges++);
    printf("Is node %d == skip node (%d)?\n", tmp, skip_edge);
    if (tmp == skip_edge)
      ++found;
    else
      *(xp++) = tmp;
  }

  assert (1 == found);
  return p;
}

// Resolve nodes by working down from check or aux blocks
// 
// Returns 0 for not done, 1 for done and -1 for error (malloc)
// If any nodes are solved, they're added to solved_list
//
int oc_graph_resolve(oc_graph *graph, oc_block_list **solved_list) {

  int mblocks  = graph->mblocks;
  int ablocks  = graph->ablocks;
  int coblocks = graph->coblocks;

  oc_block_list *pnode;		// pending node

  // linked list for storing solved nodes (we return solved_head)
  oc_block_list *solved_head = NULL;
  oc_block_list *solved_tail = NULL;

  int from, to, count_unsolved, xor_count, i, *p, *xp, *ep;

  // mark solved list (passed by reference) as empty
  *solved_list = (oc_block_list *) NULL;

  // Check whether our queue is empty. If it is, the caller needs to
  // add another check block
  if (NULL == graph->phead) {
    return graph->done;
  }

  // Exit immediately if all message blocks are already solved
  if (0 == graph->unsolved_count)
    return graph->done = 1;

  while (NULL != graph->phead) { // while items in pending queue

    pnode = oc_shift_pending(graph);
    from  = pnode->value;

    assert(from >= mblocks);

    OC_DEBUG && fprintf(stdout, "Resolving block %d with ", from);

    count_unsolved = graph->edge_count[from - mblocks];

    OC_DEBUG && fprintf(stdout, "%d unsolved edges\n", count_unsolved);

    if (count_unsolved > 1)
      goto discard;

    if (count_unsolved == 0) {

      if ((from >= coblocks) || graph->solved[from]) {

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
      if (-1 == oc_cascade(graph,from))
	return -1;


    } else if (count_unsolved == 1) {

      // Discard unsolved auxiliary blocks
      if ((from < coblocks) && !(graph->solved)[from])
	goto discard;

      // Propagation rule matched (solved aux/check with 1 unsolved)


      // xor_list will be fixed-size array, so we need to count how
      // many elements will be in it.
      ep = graph->v_edges[from - mblocks]; assert (ep != NULL);
      xor_count = *(ep++);	// number of v edges

      // find the single solved edge
      assert(to =  -1);
      for (i = 0; i < xor_count; ++i, ++ep)
	if (!graph->solved[*ep]) {
	  to = *ep;
	  break;
	}
      assert(to != -1);

      oc_delete_n_edge(graph, from, to);
      if (NULL ==
	  (p = oc_propagate_xor(graph->xor_list[from],
				graph->v_edges[from - mblocks],
				to)))
	return -1;

      if (OC_DEBUG || 1) {
	fprintf(stdout, "Node %d solves node %d\n", from, to);
      }

      // Set 'to' as solved
      assert (!graph->solved[to]);
      pnode->value      = to;	// update value (was 'from')
      graph->solved[to] = 1;
      oc_push_solved(pnode, &solved_head, &solved_tail);

      // Save 'to' xor list and decommission 'from' node
      assert (NULL == graph->xor_list[to]);
      graph->xor_list[to] = p;
      oc_decommission_node(graph, from);

      if (OC_DEBUG || 1) {
	fprintf(stdout, "Node %d (from) has xor list: ", from);
	if (from > coblocks)
	  fprintf(stdout, "%d\n", from);
	else
	  oc_print_xor_list(graph->xor_list[from], "\n");
	fprintf(stdout, "Node %d (to) has xor list: ", to);
	oc_print_xor_list(graph->xor_list[to], "\n");
      }

      // Update global structure and decide if we're done
      if (to < mblocks) {
	// Solved message block
	if (0 == (--(graph->unsolved_count))) {
	  graph->done = 1;
	  oc_flush_pending(graph);
	  break;		// finish searching
	}
      } else {
	// Solved auxiliary block, so queue it for resolving again
	if (NULL ==oc_push_pending(graph, to))
	  return -1;
      }

      // Cascade up to potentially find more solvable blocks
      if (-1 == oc_cascade(graph, to))
	return -1;

    } // end if(count_unsolved is 0 or 1)

    // If we reach this point, then pnode has been added to the
    // solved list. We continue to avoid the following free()
    continue;

  discard:
    OC_DEBUG && fprintf(stdout, "Skipping node %d\n\n", from);
    free(pnode);

  } // end while(items in pending queue)

  // Return done status and solved list (passed by reference)
  *solved_list = solved_head;
  return graph->done;


}

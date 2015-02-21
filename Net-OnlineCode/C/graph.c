// Graph decoding routines

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "online-code.h"
#include "graph.h"

#define OC_DEBUG 1
#define STEPPING 1
#define INSTRUMENT 1

// I'm moving back to the Perl way of doing things and storing an XOR
// list for each node (not just msg/aux)
#define OC_USE_CHECK_XOR_LIST 1


#ifdef INSTRUMENT

// Static structure to hold measurements relating to key bottlenecks

static struct {

  int delete_n_calls;
  int delete_n_seek_length;
  int delete_n_max_seek;

  int push_pending_calls;
  int pending_fill_level;
  int pending_max_full;

} m;

#endif

// Static structure to hold and return a list of freed oc_uni_block
// nodes (actually a circular list since it avoids some comparisons)
static oc_uni_block *free_head = NULL;
static oc_uni_block *free_tail = NULL;

static int ouser = 0;		// share among all graph instances

// uses pointer in universal block's a union to represent "next"

static oc_uni_block *hold_blocks(void) {
  if (NULL == (free_tail = malloc(sizeof(oc_uni_block))))
    return NULL;
  return free_head = free_tail->a.next = free_tail;
}

static oc_uni_block *alloc_block(void) {
  oc_uni_block *p;
  if (free_head == free_tail)
    return malloc(sizeof(oc_uni_block));
  
  // shift (read) head element
  p = free_head;
  free_tail->a.next = free_head = free_head->a.next;
  return p;
}

static void free_block(oc_uni_block *p) {
  // push (write) after tail
  p->a.next = free_head;
  free_tail = free_tail->a.next = p;
}

// clean up circular list completely
static void release_blocks(void) {
  oc_uni_block *p;
  free_tail->a.next = NULL;
  do {
    free_head = (p=free_head)->a.next;
    free(p);
  } while (free_head != NULL);
  free_tail = free_head;
}

// Create an up edge
oc_n_edge_ring *oc_create_n_edge(oc_graph *g, int upper, int lower) {

  oc_n_edge_ring *p, *ring;

  OC_DEBUG && fprintf(stdout, "Adding n edge %d -> %d\n", lower, upper);

  assert(upper > lower);

  if (NULL == (p = malloc(sizeof(oc_n_edge_ring))))
    return NULL;


  ring = g->n_rings + lower;

  // update the count of n edges in this ring
  ring->upper = 0;

  // we could push to the left (as here) or right; it doesn't matter
  p->upper          = upper;
  p->left           = ring->left;
  p->right          = ring;
  ring->left->right = p;
  ring->left        = p;

  return p;

}

// complementary function to oc_create_n_edge
void oc_delete_lower_end(oc_graph *g, oc_n_edge_ring *node, 
			 int upper, int lower, int decrement) {

  oc_n_edge_ring *ring;

  assert(node != NULL);

  OC_DEBUG && printf("Deleting lower half from %d up to %d\n", lower, upper);
  OC_DEBUG && printf("ring_node->upper is %d\n", node->upper);

  assert(upper == node->upper);	// reciprocity

  // Update the unsolved count first
  if (decrement) {
    OC_DEBUG && printf("Decrementing v_count for block %d\n", upper);
    assert(g->v_count[upper - g->mblocks]);
    --(g->v_count[upper - g->mblocks]);
  }

  // update node count in this ring
  ring = g->n_rings + lower;
  ring->upper =0; 

  // remove node from the ring
  node->left->right = node->right;
  node->right->left = node->left;

  free(node);
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
  oc_n_edge_ring *ring;

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
  //  OC_ALLOC(n_edges, coblocks, oc_uni_block *,             "n edges");

  // n rings: omit check blocks
  OC_ALLOC(n_rings, coblocks, oc_n_edge_ring,             "n rings");

  // "n pipes" are pointers from v edges down to n ring entries
  OC_ALLOC(v_pipes, ablocks + check_space, oc_n_edge_ring *, "n pipes");

  // unsolved (downward) edge counts: omit message blocks
  OC_ALLOC(v_count, ablocks + check_space, int,        "unsolved v_edge counts");

  // solved array: omit check blocks; assumed to be solved
  OC_ALLOC(solved, coblocks, char,                        "solved array");

  // xor lists: omit nothing
  OC_ALLOC(xor_list, coblocks + check_space, int *,       "xor lists");

  // Hold onto freed blocks
  if ( (NULL == free_head) && (NULL == hold_blocks()) )
    return fprintf(stderr, "Curiouser and curiouser!\n");
  else
    ++ouser;

  // initialise the rings that will store n edges
  for (msg = 0; msg < coblocks; ++msg) {
    graph->n_rings[msg].left = graph->n_rings[msg].right
      = graph->n_rings + msg;
  }

  // Register the auxiliary mapping
  // 1st stage: allocate/store message up edges, count aux down edges

  mp = codec->auxiliary;	// start of 2d message -> aux* map
  for (msg = 0; msg < mblocks; ++msg) {
    for (aux = 0; aux < q; ++aux) {
      aux_temp    = *(mp++);
      // this has to wait until later thanks to pipes
      //      if (NULL == oc_create_n_edge(graph, aux_temp, msg))
      //	return fprintf(stdout, "graph init: failed to malloc aux up edge\n");
      aux_temp   -= mblocks;	// relative to start of v_count[]
      assert (aux_temp >= 0);
      assert (aux_temp < ablocks);
      graph->v_count[aux_temp] += 2; // +2 trick explained below
    }
  }

  // 2nd stage: allocate down edges/pipes for auxiliary nodes

  for (aux = 0; aux < ablocks; ++aux) {
    aux_temp = graph->v_count[aux];
    aux_temp >>= 1;		// reverse +2 trick
    if (NULL == (p = calloc(1 + aux_temp, sizeof(int))))
      return fprintf(stdout, "graph init: failed to malloc aux down edges\n");

    graph->v_edges[aux] = p;
    p[0] = aux_temp;		// array size; edges stored in next pass

    // allocate pipe array, too (waste 1st element)
    if (NULL == (p = calloc(1 + aux_temp, sizeof(oc_n_edge_ring *))))
      return fprintf(stdout, "graph init: failed to malloc aux down pipes\n");
    graph->v_pipes[aux] = (oc_n_edge_ring **)p;
  }

  // 3rd stage: store down edges

  mp = codec->auxiliary;	// start of 2d message -> aux* map
  for (msg = 0; msg < mblocks; ++msg) {
    for (aux = 0; aux < q; ++aux) {
      aux_temp    = *(mp++) - mblocks;

      p = graph->v_edges[aux_temp];

      OC_DEBUG && fprintf(stdout,
			  "creating v edge/pipe from %d down to %d\n",
			  aux_temp + mblocks, msg);

      // The trick explained ...
      // * fills in array elements p[1] onwards (in reverse order)
      // * edge counts are correct after this pass (+2n - n = n)
      // * no extra array/pass to iterate over/recalculate edge counts
      temp = (graph->v_count[aux_temp])--;
      graph->v_edges[aux_temp][temp - p[0]] = msg;

      // deferred creation of up edge until now so that we can stash
      // the returned pointer in the array allocated in 2nd stage
      if (NULL == (ring = oc_create_n_edge(graph, aux_temp + mblocks, msg)))
	return fprintf(stdout, "graph init: failed to malloc aux up edge\n");

      graph->v_pipes[aux_temp][temp - p[0]] = ring;
    }
  }

  // Print edge count information
  if (OC_DEBUG) {
    for (aux = 0; aux < ablocks; ++aux)
      printf("v_count for aux block %d is %d\n", aux, 
	     (graph->v_count[aux]));
  }
#ifdef INSTRUMENT
  memset(&m, 0, sizeof(m));
#endif

  return 0;
}

// Install a new check block into the graph. Called from decoder.
// Returns node number on success, -1 otherwise
int oc_graph_check_block(oc_graph *g, int *v_edges) {

  int node;
  int count, solved_count, end, i, tmp;
  int mblocks;

  int xor_length = 1, *ep, *xp;

  oc_n_edge_ring **pipes;

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
    assert(tmp < g->coblocks);
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

  // also set up array of "pipes"
  if (NULL == (pipes = calloc(count - solved_count + 1,
			      sizeof(oc_n_edge_ring **))))
    return fprintf(stdout,
		   "Failed to allocate v_pipes for check block\n"),
      -1;

  g->v_pipes[node-g->mblocks] = pipes;
  *(pipes++) = NULL;		// unused element

  while (count--) {
    tmp = *ep;
    if (g->solved[tmp]) {
      *(xp++) = tmp;
      *ep     = v_edges[end--]; // move last node and check again
      solved_count--;
    } else {
      if (NULL == (*(pipes++) = oc_create_n_edge(g, node, tmp)))
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
  g->v_count[node - mblocks] = v_edges[0];

  if (OC_DEBUG) {
    printf("Set v_count for check block %d to %d\n", 
	   node, v_edges[0]);

    printf("Check block mapping after removing solved: ");
    oc_print_xor_list(v_edges,"\n");

    printf("XOR list after adding solved: ");
    oc_print_xor_list(g->xor_list[node],"\n");
  }

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
  g->v_edges[aux_node - mblocks] = NULL;

  // delete reciprocal up edges
  count = *(p++);
  while (count--) {
    oc_delete_lower_end(g,g->v_pipes[aux_node - mblocks][count],
			aux_node, *(p++), 0);
    //    oc_delete_n_edge(g, aux_node, *(p++), 0);

  }
}


// Cascade works up from a newly-solved message or auxiliary block
int oc_cascade(oc_graph *g, int node) {

  int mblocks  = g->mblocks;
  int coblocks = g->coblocks;
  oc_n_edge_ring *ring, *p;
  int to;

  assert(node < coblocks);

  OC_DEBUG && fprintf(stdout, "Cascading from node %d:\n", node);

  assert ((g->n_rings + node) != NULL);

  p = (ring = g->n_rings + node)->right;

  // update unsolved edge count and push target to pending
  while (p != ring) {
    to = p->upper;
    assert(to != node);

    if (OC_DEBUG) {
      fprintf(stdout, "  pending link %d\n", to);
      printf("Decrementing v_count for block %d\n", to);
    }

    assert(g->v_count[to - mblocks]);
    if (--(g->v_count[to - mblocks]) < 2)
      if (NULL == oc_push_pending(g, to))
	return -1;
    p = p->right;
  }
  return 0;
}

// Add a new node to the end of the pending list
oc_uni_block *oc_push_pending(oc_graph *g, int value) {

  oc_uni_block *p;

#ifdef INSTRUMENT

  m.push_pending_calls++;
  if (++m.pending_fill_level > m.pending_max_full)
    ++m.pending_max_full;

#endif

  if (NULL == (p = alloc_block()))
    return NULL;

  p->a.next = NULL;
  p->b.value = value;

  if (g->ptail != NULL)
    g->ptail->a.next = p;
  else
    g->phead = p;
  g->ptail = p;

  return p;
}

// Remove a node from the start of the pending list (returns a pointer
// to the node so that it can be re-used or freed later)
oc_uni_block *oc_shift_pending(oc_graph *g) {

  oc_uni_block *node;

#ifdef INSTRUMENT

  --m.pending_fill_level;

#endif

  node = g->phead;
  assert(node != NULL);

  if (NULL == (g->phead = node->a.next))
    g->ptail = NULL;

  return node;

}

void oc_flush_pending(oc_graph *graph) {

  oc_uni_block *tmp;

  assert(graph != NULL);

  while ((tmp = graph->phead) != NULL) {
    OC_DEBUG && fprintf(stdout, "Flushing pending node %d\n", tmp->b.value);
    graph->phead = tmp->a.next;
    free(tmp);
  }
  graph->ptail = NULL;

}

// Pushing to solved is similar to pushing to pending, but we don't
// need to allocate the new node
void oc_push_solved(oc_uni_block *pnode, 
		    oc_uni_block **phead,   // update caller's head
		    oc_uni_block **ptail) { // and tail pointers

  pnode->a.next  = NULL;

  if (*ptail != NULL)
    (*ptail)->a.next = pnode;
  else
    *phead = pnode;
  *ptail = pnode;
}

// helper function to delete edges from a solved aux or check node
void oc_decommission_node (oc_graph *g, int node) {

  int *down, upper, lower, i;
  int mblocks = g->mblocks;
  oc_n_edge_ring **pipes;

  assert(node >= mblocks);

  //  printf("Clearing v_count for node %d\n", node);
  //  g->v_count[node - mblocks] = 0;

  down = g->v_edges[node - mblocks];
  g->v_edges   [node - mblocks] = NULL;

  pipes = g->v_pipes[node - mblocks];

  if (NULL == down) return;	// nodes may be decommissioned twice

  if (OC_DEBUG) {
    printf("Decommissioning node %d's v edges: ", node);
    oc_print_xor_list(down, "\n");
  }

  for (i = down[0]; i > 0; --i) {
    oc_delete_lower_end (g, pipes[i], node, down[i], 0);
    //    oc_delete_n_edge (g, node, down[i], 0);
  }
  free(down);
}

// merge an xor list and a list of v edges into a new xor list
static int *oc_propagate_xor(int *xors, int *edges) {

  int *xp, *p;
  int tmp, count, found = 0;

  assert(NULL != xors);
  assert(NULL != edges);

  tmp = xors[0] + edges[0];
  if (NULL == (p = xp = calloc(tmp + 1, sizeof(int))))
    return NULL;

  // Write size and all elements of xor array
  *(xp++) = tmp;

  count = *(xors++);
  while (count--) {
    tmp = *(xors++);
    OC_DEBUG && printf("Propagating new XOR list element %d\n", tmp);
    *(xp++) = tmp;
  }

  // Write all down edges (caller already removed solved one)
  count = *(edges++);
  while (count--) {
    tmp = *(edges++);
    OC_DEBUG && printf("Propagating solved down edge %d\n", tmp);
    *(xp++) = tmp;
  }

  return p;
}

// Resolve nodes by working down from check or aux blocks
// 
// Returns 0 for not done, 1 for done and -1 for error (malloc)
// If any nodes are solved, they're added to solved_list
//
int oc_graph_resolve(oc_graph *graph, oc_uni_block **solved_list) {

  int mblocks  = graph->mblocks;
  int ablocks  = graph->ablocks;
  int coblocks = graph->coblocks;

  oc_uni_block *pnode;		// pending node

  // linked list for storing solved nodes (we return solved_head)
  oc_uni_block *solved_head = NULL;
  oc_uni_block *solved_tail = NULL;

  int from, to, count_unsolved, xor_count, i, *p, *xp, *ep;

  // mark solved list (passed by reference) as empty
  *solved_list = (oc_uni_block *) NULL;

  // Check whether our queue is empty. If it is, the caller needs to
  // add another check block
  if (NULL == graph->phead) {
    goto finish;
    //    return graph->done;
  }

  // Exit immediately if all message blocks are already solved
  if (0 == graph->unsolved_count) {
    graph->done = 1;
    goto finish;
  }

  while (NULL != graph->phead) { // while items in pending queue

    pnode = oc_shift_pending(graph);
    from  = pnode->b.value;

    assert(from >= mblocks);

    OC_DEBUG && fprintf(stdout, "\nStarting resolve at %d with ", from);

    count_unsolved = graph->v_count[from - mblocks];

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

      oc_n_edge_ring **pipes;

      // Discard unsolved auxiliary blocks
      if ((from < coblocks) && !graph->solved[from])
	goto discard;

      // Propagation rule matched (solved aux/check with 1 unsolved)

      // xor_list will be fixed-size array, so we need to count how
      // many elements will be in it.
      ep = graph->v_edges[from - mblocks]; assert (ep != NULL);
      xor_count = *(ep++);	// number of v edges

      pipes = graph->v_pipes[from - mblocks];
      assert(pipes != NULL);

      // find the single solved edge
      assert(to =  -1);
      for (i = 0; i < xor_count; ++i, ++ep)
	if (!graph->solved[*ep]) {
	  to = *ep;
	  break;
	}
      assert(to != -1);
      assert(i < xor_count);

      // remove to from the list of down edges here to simplify xor
      // propagation below
      *ep = graph->v_edges[from - mblocks][xor_count];
            graph->v_edges[from - mblocks][0]        = xor_count - 1;


      OC_DEBUG && fprintf(stdout, "Before shuffle ...\n");
      
      OC_DEBUG && fprintf(stdout, "i=%d, xor_count=%d ...\n", i, xor_count);
	    
      oc_delete_lower_end(graph, pipes[i + 1], from, to, 1);
      //      oc_delete_n_edge(graph, from, to, 1);

      // also delete to from pipes
      pipes[i + 1] = pipes[xor_count];

      if (to < mblocks)
	assert(graph->xor_list[to] == NULL);
      if (NULL ==
	  (p = oc_propagate_xor(graph->xor_list[from],
				graph->v_edges[from - mblocks])))
	return -1;

      if (OC_DEBUG) {
	fprintf(stdout, "Node %d solves node %d\n", from, to);
      }

      // Set 'to' as solved
      assert (!graph->solved[to]);
      pnode->b.value      = to;	// update value (was 'from')
      graph->solved[to] = 1;
      oc_push_solved(pnode, &solved_head, &solved_tail);

      // Save 'to' xor list and decommission 'from' node
      assert (NULL == graph->xor_list[to]);
      graph->xor_list[to] = p;
      oc_decommission_node(graph, from);

      if (OC_DEBUG) {
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
	  goto finish;
	}
      } else {
	// Solved auxiliary block, so queue it for resolving again
	if (NULL == oc_push_pending(graph, to))
	  return -1;
      }

      // Cascade up to potentially find more solvable blocks
      if (-1 == oc_cascade(graph, to))
	return -1;

    } // end if(count_unsolved is 0 or 1)

    // If we reach this point, then pnode has been added to the
    // solved list. We continue to avoid the following free()
    if (STEPPING) goto finish;
    continue;

  discard:
    OC_DEBUG && fprintf(stdout, "Skipping node %d\n\n", from);
    free_block(pnode);

  } // end while(items in pending queue)

 finish:

  if (graph->done && !--ouser) release_blocks();

#ifdef INSTRUMENT
  if (graph -> done) {
    fprintf(stderr, "Information on oc_delete_n_edge:\n");
    fprintf(stderr, "  Total Calls = %d\n", m.delete_n_calls);
    fprintf(stderr, "  Total Seeks = %d\n", m.delete_n_seek_length);
    fprintf(stderr, "  Avg.  Seeks = %g\n", ((double) m.delete_n_seek_length
					     / m.delete_n_calls));
    fprintf(stderr, "  Max.  Seek  = %d\n", m.delete_n_max_seek);

    fprintf(stderr, "\nInformation on pending queue:\n");
    fprintf(stderr, "  Total push calls = %d\n", m.push_pending_calls);
    fprintf(stderr, "  Max. Fill Level  = %d\n", m.pending_max_full);
  }
#endif

  // Return done status and solved list (passed by reference)
  *solved_list = solved_head;
  return graph->done;


}

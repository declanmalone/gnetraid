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

  //  OC_DEBUG && fprintf(stdout, "Adding n edge %d -> %d\n", lower, upper);

  assert(upper > lower);

  if (NULL == (p = malloc(sizeof(oc_n_edge_ring))))
    return NULL;


  ring = g->bottom + lower;

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
    OC_DEBUG && printf("Decrementing unknowns count for block %d\n", upper);
    assert(g->v_count[upper - g->mblocks]);
    --(g->v_count[upper - g->mblocks]);
  }

  // update node count in this ring
  ring = g->bottom + lower;
  ring->upper = 0; 

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
  oc_bone *bone;
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

  // unsolved (downward) edge counts: omit message blocks
  OC_ALLOC(v_count, ablocks + check_space, int,    "unsolved v_edge counts");

  //
  // New bones-related arrays
  //

  // solutions: omit check blocks; they are their own solutions
  OC_ALLOC(solution, coblocks, oc_bone *,          "solutions");

  // top end of edges: omit message blocks
  OC_ALLOC(top, ablocks + check_space, oc_bone *,  "top");

  // bottom end of edges: omit check blocks
  OC_ALLOC(bottom, coblocks, oc_n_edge_ring,       "bottom");


  // Hold onto freed blocks
  if ( (NULL == free_head) && (NULL == hold_blocks()) )
    return fprintf(stderr, "Curiouser and curiouser!\n");
  else
    ++ouser;

  // initialise the rings that will store bottom ends of edges
  for (msg = 0; msg < coblocks; ++msg) {
    graph->bottom[msg].left = graph->bottom[msg].right
      = graph->bottom + msg;
  }

  // Register the auxiliary mapping
  // 1st stage: allocate/store message up edges, count aux down edges

  mp = codec->auxiliary;	// start of 2d message -> aux* map
  for (msg = 0; msg < mblocks; ++msg) {
    for (aux = 0; aux < q; ++aux) {
      aux_temp    = *(mp++);
      aux_temp   -= mblocks;	// relative to start of v_count[]
      assert (aux_temp >= 0);
      assert (aux_temp < ablocks);
      graph->v_count[aux_temp] += 2; // +2 trick explained below
    }
  }

  // 2nd stage: allocate bones for auxiliary nodes

  for (aux = 0; aux < ablocks; ++aux) {
    aux_temp = graph->v_count[aux];
    aux_temp >>= 1;		// reverse +2 trick

    if (NULL == (bone = calloc(2 + aux_temp, sizeof(oc_bone))))
      return fprintf(stdout, "graph init: failed to malloc aux bones\n");

    // save bone size, aux node; edges stored in next pass
    bone->a.unknowns = aux_temp + 1;
    bone->b.size     = aux_temp + 1;
    bone[aux_temp + 1].a.node = aux + mblocks;
    graph->top[aux]  = bone;
  }

  // 3rd stage: store down edges

  mp = codec->auxiliary;	// start of 2d message -> aux* map
  for (msg = 0; msg < mblocks; ++msg) {
    for (aux = 0; aux < q; ++aux) {
      aux_temp    = *(mp++) - mblocks;

      bone = graph->top[aux_temp];

#if 0
      OC_DEBUG && fprintf(stdout,
			  "creating edge from %d down to %d\n",
			  aux_temp + mblocks, msg);
#endif

      // The trick explained ...
      // * fills in array elements bone[1 ...] (in reverse order)
      // * edge counts are correct after this pass (+2n - n = n)
      // * no extra array/pass to iterate over/recalculate edge counts
      temp = (graph->v_count[aux_temp])--;
      assert (temp - bone->a.unknowns >= 0);

      // fprintf(stdout, "temp is %d, unknowns is %d\n", 
      //   temp,  bone->a.unknowns);

      bone += temp - bone->a.unknowns + 1;

      bone->a.node = msg;

      // deferred creation of up edge until now so that we can stash
      // the returned pointer in the array allocated in 2nd stage
      if (NULL == (ring = oc_create_n_edge(graph, aux_temp + mblocks, msg)))
	return fprintf(stdout, "graph init: failed to malloc aux up edge\n");

      bone->b.link = ring;
    }
  }

  // Print details
  if (OC_DEBUG) {
    printf ("Auxiliary mapping expressed as bones:\n");
    for (aux = 0; aux < ablocks; ++aux) {
      bone = graph->top[aux];
#ifndef NDEBUG
      oc_validate_bone(bone, aux + mblocks);
#endif
      printf ("  ");
      oc_print_bone(bone, "\n");
    }
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

  oc_bone *bone;

  assert(g != NULL);
  assert(v_edges != NULL);

  node    = (g->nodes)++;
  mblocks = g->mblocks;

  OC_DEBUG && fprintf(stdout, "Graphing check node %d/%d:\n", node, g->node_space);

  // have we run out of space for new nodes?
  if (node >= g->node_space)
    return fprintf(stdout, "oc_graph_check_block: node >= node_space\n"), -1;

  // When using bones, most of the work is now done in oc_check_bone

  if (NULL == (bone=oc_check_bone(g, node, v_edges))) {
    fprintf(stderr, "Failed to allocate bone for check block\n");
    return -1;
  }

  // we only have to stash the pointer and unsolved v edge count
  g->top    [node - mblocks] = bone;
  g->v_count[node - mblocks] = bone->a.unknowns;

  if (OC_DEBUG) {
    printf("Set unknowns count for check block %d to %d\n", 
	   node, bone->a.unknowns);

    printf("New check block %d: ",node);
    oc_print_bone(bone, "\n");
  }

  // mark node as pending resolution
  if (NULL == oc_push_pending(g, node))
    return fprintf(stdout, "oc_graph_check_block: failed to push pending\n"),
      -1;

  // success: return index of newly created node
  return node;
}

// Aux rule triggers when an unsolved aux node has no unsolved v edges
void oc_aux_rule(oc_graph *g, int anode) {

  int mblocks = g->mblocks;
  int *p, i, count;
  oc_bone *bone;

  OC_DEBUG && fprintf(stdout, "Aux rule triggered on node %d\n", anode);
  assert(anode >=    mblocks);
  assert(anode <  g->coblocks);
  assert(g->v_count[anode - mblocks] == 0);

  // bone becomes a solution
  bone = g->top[anode - mblocks];
  g->solution[anode] = bone;

  // count all nodes except aux node itself:
  count = oc_count_unknowns(bone) - 1;
  OC_DEBUG && fprintf(stdout, "There are %d solved down edges\n", count);

  // find where the aux node is in the list, then bubble up
  i = oc_known_unsolved(bone, anode);
  oc_bubble_unsolved(bone, g, i);

  count = oc_count_unknowns(bone);
  assert(1 == count);

  // check that aux details in first element are OK
  assert(bone[1].a.node == anode);
  assert(bone[1].b.link == NULL);

  // clean up 
  g->top[anode - mblocks] = NULL; 
}


// Cascade works up from a newly-solved message or auxiliary block
int oc_cascade(oc_graph *g, int node) {

  int mblocks  = g->mblocks;
  int coblocks = g->coblocks;
  oc_n_edge_ring *ring, *p;
  int to;

  assert(node < coblocks);

  OC_DEBUG && fprintf(stdout, "Cascading from node %d:\n", node);

  assert ((g->bottom + node) != NULL);

  p = (ring = g->bottom + node)->right;

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

  oc_bone *bone = NULL;

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

    bone           = graph->top    [from - mblocks];
    count_unsolved = graph->v_count[from - mblocks];

    if (OC_DEBUG) {

      printf("\nStarting resolve at %d: ",from);
      oc_print_bone(bone, "");
      printf(" (%d unknowns)\n", count_unsolved);

    }

    if (count_unsolved > 1)
      goto discard;

    if (count_unsolved == 0) {

      if ((from >= coblocks) || graph->solution[from]) {

	// The first test above matches check blocks, while the second
	// matches a previously-solved auxiliary block (the order of
	// tests is important to avoid going off the end of the solved
	// array). In either case, the node has no unsolved edges and
	// so adds no new information. We can remove it from the
	// graph.

	//	oc_decommission_node(graph, from);
	goto discard;
      }

      // This is an unsolved aux block. Solve it with aux rule
      oc_aux_rule(graph,from);

      oc_push_solved(pnode, &solved_head, &solved_tail);
      if (-1 == oc_cascade(graph,from))
	return -1;


    } else if (count_unsolved == 1) {

      // Discard unsolved auxiliary blocks
      if ((from < coblocks) && !graph->solution[from])
	goto discard;

      // Propagation rule matched (solved aux/check with 1 unsolved)

      // find the unsolved child node in the list, then bubble up
      to = oc_unknown_unsolved(bone, graph);
      oc_bubble_unsolved(bone, graph, to);
      
      // to was previously an index; dereference it
      to = bone[1].a.node;

      oc_delete_lower_end(graph, bone[1].b.link, from, to, 1);

      if (OC_DEBUG) {
	fprintf(stdout, "Node %d solves node %d\nSolution: ", from, to);
	oc_print_bone(bone, "\n");
      }

      // Set 'to' as solved
      assert (!graph->solution[to]);
      pnode->b.value      = to;	// update value (was 'from')
      graph->solution[to] = bone;
      oc_push_solved(pnode, &solved_head, &solved_tail);


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

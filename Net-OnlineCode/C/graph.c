// Graph decoding routines

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "online-code.h"
#include "graph.h"

#define OC_DEBUG 0
#define STEPPING 1
#define INSTRUMENT 1

// I'm moving back to the Perl way of doing things and storing an XOR
// list for each node (not just msg/aux)
#define OC_USE_CHECK_XOR_LIST 1

// Defines related to "bucket" lists. Conceptually, the list of up
// edges is just a linked list but I'm going to implement them as a
// list of fixed-sized buckets for better performance. The average
// number of up (or down) edges that a node has is ln(F) ~= 7.66. When
// F = 2115 (the default when dealing with a large enough number of
// message blocks), roughly half of the nodes would need two (or more)
// buckets of size 8, so I'm going to use double the size of the
// buckets to 16 elements. This should result in much fewer than one
// quarter of the nodes requiring two or more buckets.
//
// With bucket sizes that are powers of two, we can replace
// potentially costly division with equivalent bit-level operations,
// which I'm using here. The naming of the macros reflects the
// original arithmetic operations that are being replaced:
//
#define BUCKET_SIZE     16                // bucket size s
#define BUCKET_MODULUS  (BUCKET_SIZE - 1) // i % s <=> i & mask   
#define BUCKET_DIVISOR  4                 // i / s <=> i >> shift 


// Separate out different calls to malloc so that I can profile them.
// I will convert these to inline functions after profiling.
void *alloc_oc_uni_block() {
  return malloc(sizeof(oc_uni_block));
}

void *alloc_bucket() {
  return malloc(BUCKET_SIZE * sizeof(int));
}

void *alloc_ints(int howmany) {
  return calloc(howmany, sizeof(int));
}

void *alloc_xor_list(int size) {
  return calloc(size, sizeof(int));
}

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
  if (NULL == (free_tail = alloc_oc_uni_block()))
    return NULL;
  return free_head = free_tail->a.next = free_tail;
}

static oc_uni_block *alloc_block(void) {
  oc_uni_block *p;
  if (free_head == free_tail)
    return alloc_oc_uni_block();
  
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


// iterate over n edges using a callback

typedef int oc_scan_callback(oc_graph *g, int mblocks, int lower, int upper);

int oc_scan_n_edge(oc_graph *g, oc_scan_callback *fp, int lower) {

  unsigned      bucket, offset;
  oc_uni_block *bp;
  int          *ip, count, retval;
  int mblocks = g->mblocks;

  bp = g->n_edge + lower;

  OC_DEBUG && fprintf(stdout, "Scanning %d n edges up from %d\n",
		      bp->b.value, lower);

  if (0 == bp->b.value) return 0;

  // where is the last value?
  bucket = offset = bp->b.value - 1;
  bucket >>= BUCKET_DIVISOR;
  offset &=  BUCKET_MODULUS;

  OC_DEBUG && fprintf(stdout, "Bucket = %d, offset = %d\n", bucket, offset);

  ip = bucket? ((oc_uni_block *)(bp = bp->a.next))->b.p : bp->a.next;
  do {
    count =  bucket? BUCKET_SIZE : (offset + 1);
    OC_DEBUG && fprintf(stdout, "Scanning %d elements in this bucket\n", 
			count);
    while (count--)
      if (retval = (*fp)(g, mblocks, lower, *(ip++)))
	return retval;
  } while ((bucket--) && (ip = (bp = bp->a.next)->b.p));

  return 0;			// success
}


// Create a graph up edge
oc_uni_block *oc_create_n_edge(oc_graph *g, int upper, int lower) {

  oc_uni_block *p, *bp, *ep;
  unsigned bucket, offset;

  OC_DEBUG && fprintf(stdout, "Adding n edge %d -> %d\n", lower, upper);

  assert(upper > lower);

  // The bucket structure is implemented as follows:
  //
  // * the value in the block stored in the n_edge array tells how
  //   many n edges there are
  // * if there are fewer than BUCKET_SIZE edges, the pointer stored
  //   in the n_edges block points to a list of ints
  // * otherwise, it's a treated as pointer to a linked list of (next,
  //   bucket) pointers

  bp = g->n_edge + lower;

  // calculate where the new element will go (and update count)
  bucket = offset = (bp->b.value)++;
  bucket >>= BUCKET_DIVISOR;
  offset &=  BUCKET_MODULUS;

  OC_DEBUG && fprintf(stdout, "Bucket = %d, offset = %d\n", bucket, offset);


  // optimise for the usual case where there's only one bucket and
  // it's not overflowing
  if (0 == bucket) {
    ((int *)(bp->a.next))[offset] = upper;
    return bp;
  }

  // do we need to convert from list of ints to linked list node?
  if ((1 == bucket) && (0 == offset)) {

    // allocate a block to store existing full bucket
    if (NULL == (p = alloc_block()))
      return NULL;

    p->a.next  = NULL; // overwritten later, but useful for testing
    p->b.p     = bp->a.next;	// old int list
    bp->a.next = p;
  }

  // skip to second-last bucket
  while (bucket--) bp = bp->a.next;

  // end bucket is full, so we need to allocate a new one
  if (0 == offset) {
    if (NULL == (bp = bp->a.next = alloc_block()))
      return NULL;
    if (NULL == (bp->b.p = alloc_bucket()))
      return NULL;
    bp->a.next = NULL;  // value never used
  } else {
    bp = bp->a.next;
  }

  // save value at correct offset
  ((int *)(bp->b.p))[offset] = upper;

  // return some valid pointer instead of NULL
  return bp;
  
}

// Delete a graph up edge
void oc_delete_n_edge (oc_graph *g, int upper, int lower, int decrement) {

  oc_uni_block *pp, *bp, *p;
  int          *ip;
  unsigned bucket, offset, skip, i;
  int mblocks = g->mblocks;

  assert(upper > lower);
  assert(upper >= mblocks); // disable during unit test

  OC_DEBUG && printf("Deleting n edge from %d up to %d\n", lower, upper);

  // To delete from a bucket list, we need to move the last element
  // from the last bucket into the space vacated by the deleted
  // element.
  //
  // We also have to take care to do what oc_create_n_edge does in
  // reverse:
  //
  // * deleting the last bucket in the chain when it empties
  //
  // * converting the index structure to point to the list of ints if
  //   we only have a single bucket left
  //
  // If the element we're searching for isn't there, the program
  // simply exits with a failed assert().

  // Update the unsolved edge count
  if (decrement) {
    OC_DEBUG && printf("Decrementing edge_count for block %d\n", upper);
    assert(g->edge_count[upper - g->mblocks]);
    --(g->edge_count[upper - g->mblocks]);
  }

  bp = g->n_edge + lower;

  assert ((bp->b.value > 0) && "Deleting edge from empty list");

  // where is the last element?
  bucket = offset = --(bp->b.value);
  bucket >>= BUCKET_DIVISOR;
  offset &=  BUCKET_MODULUS;

  OC_DEBUG && fprintf(stdout, "Bucket = %d, offset = %d\n", bucket, offset);

  // optimise for the usual case where there's only one bucket to
  // search
  if (0 == bucket) {
    ip = bp->a.next; 
    // unroll loop to save testing condition
    skip=ip[offset];		// last element
    if (   *ip  == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }

    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }

    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }

    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }
    if (*(++ip) == upper) { *ip = skip; return; }

    if (0) {
      do {
	if (*ip == upper) {
	  *ip = skip;
	  return;
	}
      } while (ip++);
    }

    assert (0 == "N edge not found in 0'th bucket");
  }

  // When bucket > 0, bp->next is a list of buckets
  pp = bp;
  bp = bp->a.next;
  ip = (int *) (bp->b.p);
  skip = bucket;

  // search full buckets
  while (skip) {
    // unroll loop and change to using pointer instead of array
    // arithmetic
    if (   *ip  == upper) goto found;
    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;

    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;

    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;

    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;
    if (*(++ip) == upper) goto found;

    pp = bp;
    bp = bp->a.next;
    ip = bp->b.p;
    --skip;
  }

  // search final bucket
  if (0) {
    switch(offset) {
    case 15:
      if (*ip == upper) goto found; ++ip;
    case 14:
      if (*ip == upper) goto found; ++ip;
    case 13:
      if (*ip == upper) goto found; ++ip;
    case 12:
      if (*ip == upper) goto found; ++ip;
    case 11:
      if (*ip == upper) goto found; ++ip;
    case 10:
      if (*ip == upper) goto found; ++ip;
    case 9:
      if (*ip == upper) goto found; ++ip;
    case 8:
      if (*ip == upper) goto found; ++ip;
    case 7:
      if (*ip == upper) goto found; ++ip;
    case 6:
      if (*ip == upper) goto found; ++ip;
    case 5:
      if (*ip == upper) goto found; ++ip;
    case 4:
      if (*ip == upper) goto found; ++ip;
    case 3:
      if (*ip == upper) goto found; ++ip;
    case 2:
      if (*ip == upper) goto found; ++ip;
    case 1:
      if (*ip == upper) goto found; ++ip;
    case 0:
      if (*ip == upper) goto found;
    }
  } else {
    i=offset;
    do {
      if (*ip == upper)
	goto found;
      ++ip;
    } while (i--);
  }

  // we shouldn't get here
  assert (0 == "up edge didn't exist");

  // Alternatively, emit a warning (not tested in this version)
  //  fprintf(stdout, "oc_delete_n_edge: up edge %d -> %d didn't exist\n",
  //  lower, upper);

  found:

  // at this point, we should have:
  //
  // *ip     is the found value value itself
  // bp      points to the bucket the value was found in
  // pp      points to the previous bucket

  // advance to the last bucket and move last element
  while (skip--)
    bp = (pp = bp)->a.next;

  assert(*ip == upper);

  OC_DEBUG && fprintf(stdout,
		      "Overwriting n_edge list element %d with element "
		      "%d, which was at offset %d in last bucket\n",
		      *ip,  ((int *)(bp->b.p))[offset], offset);

  *ip = ((int *)(bp->b.p))[offset];

  // delete the last bucket if necessary
  if (0 == offset) {
    free(bp->b.p);
    free_block(bp);
    pp->a.next = NULL;

    // convert main index back to having next point to int list
    if (1 == bucket) {
      g->n_edge[lower].a.next = pp->b.p;
    }
  }
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

  // Prior to implementing bucket lists I had an array of list
  // pointers for "n" edges. I'm replacing that with an array of
  // blocks that point to a list of "buckets"

  // "n" edge array: omit check blocks
  OC_ALLOC(n_edge, coblocks, oc_uni_block,                "n edge");

  // buckets: omit check blocks
  OC_ALLOC(buckets, coblocks << BUCKET_DIVISOR, int,      "n edge buckets");
  
  // unsolved (downward) edge counts: omit message blocks
  OC_ALLOC(edge_count, ablocks + check_space, int,        "unsolved v_edge counts");

  // solved array: omit check blocks; assumed to be solved
  OC_ALLOC(solved, coblocks, char,                        "solved array");

  // xor lists: omit nothing
  OC_ALLOC(xor_list, coblocks + check_space, int *,       "xor lists");

  // Hold on to freed blocks
  if ( (NULL == free_head) && (NULL == hold_blocks()) )
    return fprintf(stderr, "Curiouser and curiouser!\n");
  else
    ++ouser;

  // Make n edge structures point to correct place in buckets array
  for (msg = 0; msg < coblocks; ++msg)
    graph->n_edge[msg].a.next = (graph->buckets) + (msg << BUCKET_DIVISOR);

  // Register the auxiliary mapping
  // 1st stage: allocate/store message up edges, count aux down edges

  // I'm going to write to the n_edge structure directly here, but
  // that requires the following condition:
  assert (q <= BUCKET_SIZE);

  mp = codec->auxiliary;	// start of 2d message -> aux* map
  for (msg = 0; msg < mblocks; ++msg) {
    graph->n_edge[msg].b.value = q;
    for (aux = 0; aux < q; ++aux) {
      aux_temp    = *(mp++);
      if (0) {
	if (NULL == oc_create_n_edge(graph, aux_temp, msg))
	  return fprintf(stdout, "graph init: failed to malloc aux up edge\n");
      } else {
	((int *)(graph->n_edge[msg].a.next))[aux] = aux_temp;
      }
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
    if (NULL == (p = alloc_ints(1 + aux_temp)))
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

  // Print edge count information
  if (OC_DEBUG) {
    for (aux = 0; aux < ablocks; ++aux)
      printf("Set edge_count for aux block %d to %d\n", aux, 
	     (graph->edge_count[aux]));
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
  if (NULL == (xp = alloc_xor_list(solved_count + 2)))
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

  if (OC_DEBUG) {
    printf("Set edge_count for check block %d to %d\n", 
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
  while (count--) 
    oc_delete_n_edge(g, aux_node, *(p++), 0);
}


// Cascade works up from a newly-solved message or auxiliary block

// First, a callback to do work on each n edge
static int cascade_n_edge(oc_graph *g, int mblocks, int lower, int upper) {

  if (OC_DEBUG) {
    fprintf(stdout, "  pending link %d\n", upper);
    printf("Decrementing edge_count for block %d\n", upper);
  }

  // update unsolved edge count and push target to pending
  assert(g->edge_count[upper - mblocks]);
  if (--(g->edge_count[upper - mblocks]) < 2)
    if (NULL == oc_push_pending(g, upper))
      return -1;

  return 0;
}

int oc_cascade(oc_graph *g, int node) {

  assert(node < g->coblocks);

  OC_DEBUG && fprintf(stdout, "Cascading from node %d:\n", node);

  return oc_scan_n_edge(g, &cascade_n_edge, node);
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

  assert(node >= mblocks);

  //  printf("Clearing edge_count for node %d\n", node);
  //  g->edge_count[node - mblocks] = 0;

  down = g->v_edges[node - mblocks];
  g->v_edges   [node - mblocks] = NULL;


  if (NULL == down) return;	// nodes may be decommissioned twice

  if (OC_DEBUG) {
    printf("Decommissioning node %d's v edges: ", node);
    oc_print_xor_list(down, "\n");
  }

  for (i = down[0]; i > 0; --i) {
    oc_delete_n_edge (g, node, down[i], 0);
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
  if (NULL == (p = xp = alloc_xor_list(tmp + 1)))
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
      if ((from < coblocks) && !graph->solved[from])
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
      assert(i < xor_count);

      // remove to from the list of down edges here to simplify xor
      // propagation below
      *ep = graph->v_edges[from - mblocks][xor_count];
            graph->v_edges[from - mblocks][0]        = xor_count - 1;

      oc_delete_n_edge(graph, from, to, 1);
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

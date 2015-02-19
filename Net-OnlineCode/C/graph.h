// Graph decoding stuff

#ifndef OC_GRAPH_H
#define OC_GRAPH_H

#include "online-code.h"

typedef struct {

  int mblocks;
  int ablocks;
  int coblocks;
  int nodes;			// running count of all blocks
  int node_space;		// nodes < node_space

  // Node Edges
  // 
  // Block/node numbers are ordered by the relation:
  //
  // message block IDs < auxiliary block IDs < check block IDs
  // 
  // Downward edges (eg, check -> aux) are stored in fixed-sized
  // arrays since we know in advance (or can calculate) how many down
  // edges each node has. Also, this number never increases. The first
  // element of the list tells how many block numbers are in the rest
  // of the list.
  //
  // Upward edges are stored in linked lists since nodes can have new
  // upward edges added to them over time (ie, when new check blocks
  // arrive).

  int          **v_edges;	// downward ("v" points down)
  oc_uni_block  *n_edge;	// upward edges ("n" ~= upside-down "v")
  int           *buckets;	// storage for n edge buckets (1st only)

  int *edge_count;		// unsolved "v" edges (aux, check only)
  int *edge_count_x;		// "transparent" edge count (check only)

  unsigned char *solved;	// is node solved?

  // The XOR list contains the "expansion" of newly-solved
  // blocks/nodes. We could use a linked list, but an array will do
  // just as well since we can calculate its length at the time that
  // we resolve a node (or expand an xor list).
  int **xor_list;

  oc_uni_block *phead, *ptail;	// queue of pending nodes

  unsigned int  unsolved_count;	// count unsolved message blocks
  unsigned char done;		// are all message nodes decoded?

} oc_graph;


// Allocate spaces within graph structure and initialise them.  
//
// The fudge factor parameter is a multiplier (>1.0) telling how much
// extra space to allocate beyond the expected number of check blocks. 
//
// Returns 0 on success
//
int oc_graph_init(oc_graph *graph, oc_codec *codec, float fudge);


void oc_decommission_node (oc_graph *g, int node);
void oc_push_solved (oc_uni_block *pnode, 
		     oc_uni_block **phead,  // update caller's head
		     oc_uni_block **ptail); // and tail pointers
void oc_delete_n_edge (oc_graph *g, int upper, int lower, int decrement);
oc_uni_block *oc_push_pending(oc_graph *g, int value);


int oc_graph_resolve(oc_graph *graph, oc_uni_block **solved_list);

typedef int oc_scan_callback(oc_graph *g, int mblocks, int lower, int upper);

oc_uni_block *oc_create_n_edge(oc_graph *g, int upper, int lower);
int oc_scan_n_edge(oc_graph *g, oc_scan_callback *fp, int lower);

#endif

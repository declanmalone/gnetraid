// Graph decoding stuff

#ifndef OC_GRAPH_H
#define OC_GRAPH_H

#include "online-code.h"
#include "bones.h"

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
oc_n_edge_ring *oc_create_n_edge(oc_graph *g, int upper, int lower);
void oc_delete_n_edge (oc_graph *g, int upper, int lower, int decrement);
oc_uni_block *oc_push_pending(oc_graph *g, int value);


int oc_graph_resolve(oc_graph *graph, oc_uni_block **solved_list);

#endif

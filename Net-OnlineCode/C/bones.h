// "bones": "bundles of node elements"
//

#ifndef OC_BONES_H
#define OC_BONES_H

#include "graph.h"
#include "structs.h"

struct oc_n_edge_ring_node;


// Functions to give a range of indices for known/unknown elements or
// count knowns/unknowns
static inline int oc_first_unknown(oc_bone *b) {
  return 1;
}

static inline int oc_last_unknown(oc_bone *b) {
  return b->a.unknowns;
}

static inline int oc_first_known(oc_bone *b) {
  return b->a.unknowns + 1;
}

static inline int oc_last_known(oc_bone *b) {
  return b->b.size;
}

static inline int oc_count_unknowns(oc_bone *b) {
  return b->a.unknowns;
}

static inline int oc_count_knowns(oc_bone *b) {
  return b->b.size - b->a.unknowns;
}

oc_bone *oc_new_bone(oc_graph *g, int size);
oc_bone *oc_check_bone(oc_graph *g, int cnode, int *list);
void oc_validate_bone(oc_bone *bone, int anode);
int oc_unknown_unsolved(oc_bone *bone, oc_graph *g);
int oc_known_unsolved(oc_bone *bone, int anode);
void oc_bubble_unsolved(oc_bone *bone, oc_graph *g, int index);
void oc_print_bone(oc_bone *bone, char *final);

#endif

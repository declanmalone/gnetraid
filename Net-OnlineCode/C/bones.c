// Implementation of "bones"

#include <stdio.h>
#include <stdlib.h>

#include "bones.h"

oc_bone *oc_new_bone(int size) {
  // reserve one element at start for unknowns/size fields
  return malloc((size + 1) * sizeof(oc_bone));
}

// Create a bone that will attach to a check node
oc_bone *oc_check_bone(oc_graph *g, int cnode, int *list) {

  oc_bone        *bone, *bp;
  oc_n_edge_ring *ring;
  int             count, last_index;
  int             size, unknowns, lower;

  // size of list is stored in the first element
  unknowns = size = *(list++);
  
  // reserve one extra space for known check node
  last_index = size + 1;

  if (NULL == (bone = oc_new_bone(last_index)))
    return NULL;

  // save total size of array
  bone->b.size = last_index;

  // all the known elements go at the end of the list. Initially, only
  // the check node is known and  the rest go below it.
  bone[last_index]  .a.node = cnode; 
  bone[last_index--].b.link = NULL; // known => no edge

  count = size; bp = bone + 1;
  while (count--) {
    lower = *(list++);
    if ((g->solution)[cnode]) {
      bone[last_index].a.node = cnode; 
      bone[last_index].b.link = NULL; // known => no edge
      --last_index;
      --unknowns;
    } else {
      if (NULL == (ring = oc_create_n_edge(g, cnode, lower))) {
	fprintf(stderr, "oc_check_bone: failed to malloc up edge\n");
	return NULL;
      }
      bp->a.node = lower;
      bp->b.link = ring;
      ++bp;
    }
  }

  // save count of unknowns and return
  bone->a.unknowns = unknowns;
  return bone;

}

// We also use bones for aux nodes but I'm creating them directly
// during graph initialisation. This routine does some checks on the
// bone to make sure that it's correctly constructed.

void oc_validate_bone(oc_bone *bone, oc_graph *g, int anode) {

  int count, lower;
  oc_n_edge_ring *ring;

  // aux blocks are created before everything else, so these should
  // match:
  assert(bone->a.unknowns == bone->b.size);

  // iterate over the elements and maybe segfault if links weren't set
  // up correctly
  count = bone->b.size;
  ++bone;
  while (count--) {
    lower = bone->a.node;
    ring  = bone->b.link;
    ++bone;
    assert (lower <= anode);
    if (lower == anode)
      assert (ring == NULL);
    else 
      assert (ring->upper == anode);
  }
}


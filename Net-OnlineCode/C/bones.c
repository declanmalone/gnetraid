// Implementation of "bones"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "bones.h"

oc_bone *oc_new_bone(oc_graph *g, int size) {

  int required = size + 1;
  oc_bone *p;

  // printf("Requested new bone of size %d from pool of [%d,%d]\n",
  //   required, g->boneyard_next, g->boneyard_size);

  if (required + g->boneyard_next >= g->boneyard_size)
    return NULL;

  p = g->boneyard + g->boneyard_next;
  g->boneyard_next += required;

  return p;
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

  if (NULL == (bone = oc_new_bone(g, last_index)))
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
    if (g->solution[lower]) {
      bone[last_index].a.node = lower; 
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

void oc_validate_bone(oc_bone *bone, int anode) {

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

// When the propagation rule triggers we should be left with a single
// unsolved value in the bone, but we don't know which one it is. The
// following scans the list of unknowns, looks them up in the graph
// and returns the index of the first match.

int oc_unknown_unsolved(oc_bone *bone, oc_graph *g) {

  int count, node, index;
  int coblocks = g->coblocks;
  count = bone->a.unknowns;
  index = 0;
  while (count--) {
    node = bone[++index].a.node;
    assert (node < coblocks);
    //    if (node >= coblocks)	// check blocks aren't in solution[]
    //      continue;
    if (!g->solution[node])
      return index;
  }
  fprintf(stderr, "oc_unknown_unsolved: didn't find any unsolved\n");
  exit(1);
}

// When the aux rule triggers, we know that there should be only one
// unsolved value in the list, but this time we know that it's the aux
// node. As with the previous routine, we return the array index it
// lives at.
int oc_known_unsolved(oc_bone *bone, int anode) {

  int count, node, index;
  count = bone->a.unknowns;
  index = 0;
  while (count--) {
    node = bone[++index].a.node;
    if (node == anode)
      return index;
  }
  fprintf(stderr, "oc_known_unsolved: didn't find unsolved aux\n");
  exit(1);

}

// When either the propagation rule or the aux rule triggers we want
// to shift the single unsolved value to the start. We call one of the
// above routines to find where it is. Then, the following routine
// "bubbles it up" to the start of the list and deletes any reciprocal
// links for any of the other previously-unknown edges.

void oc_bubble_unsolved(oc_bone *bone, oc_graph *g, int index) {

  int count, node;
  oc_n_edge_ring *ring;

  // swap node, ring elements to front
  node = bone[index].a.node;
  if (index != 1) {
    bone[index].a.node = bone[1]    .a.node;
    bone[1]    .a.node = node;
    ring               = bone[index].b.link;
    bone[index].b.link = bone[1]    .b.link;
    bone[1]    .b.link = ring;
  }

  // set unknown count
  bone->a.unknowns = 1;

  // delete reciprocal links for other elements. If called during the
  // propagation rule, bone[1] will still contain a reciprocal link;
  // we leave it for the caller to deal with.
  count = bone->a.unknowns - 1;
  ++bone;
  while (++bone, count--)
    oc_delete_lower_end(g, bone->b.link, node, bone->a.node, 0);
}


void oc_print_bone(oc_bone *bone, char *final) {

  static char null[]  = "";
  static char comma[] = ", ";
  int i, min, max;

  char *sep = null;

  printf("[");
  min = 1; max = oc_last_unknown(bone);
  for (i = min; i <= max; ++i) {
    printf("%s%d", sep, bone[i].a.node);
    sep = comma;
  }
  printf("] <- [");
  sep = null;
  min = max + 1; max = oc_last_known(bone);
  for (i = min; i <= max; ++i) {
    printf("%s%d", sep, bone[i].a.node);
    sep = comma;
  }
  printf("]%s",final);

}

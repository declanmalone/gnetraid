// Data structures for use in encoder/decoder

#ifndef OC_STRUCTS_H
#define OC_STRUCTS_H

// This file is intended to act as a reference for the various data
// structures used to support the basic algorithms. It's broken down
// by functional area. Some data structures are complex and have
// struct definitions here. Others (such as arrays) are more simple
// and so don't need type defs, but I will document them here too.

// Online Code (base "class") --- basic structure
//
// The oc_codec structure holds basic parameters for the scheme. See
// "online-code.h" for details.


// Online Code --- probability distribution table
//
// Simple array of floats with F (max degree) entries


// Online Code --- Message, Auxiliary and Check blocks
//
// There are various different structures for storing information
// related to each type of block. They're all unified by an (integer)
// index variable that treats blocks as being stored (conceptually, at
// least) in a single array organised as follows:
//
//   message blocks < auxiliary blocks < check blocks
//
// Given a "block number" it's possible to determine which type of
// block it is by simple numeric comparison(s). The relative ordering
// of message, auxiliary and check blocks also gives us the
// nomenclature distinguishing betewen "upward" and "downward" edges
// as described in the next section ("Graph Edges").
//
// Although the number of check blocks sent or received is potentially
// unbounded, the Online Code algorithm does place probablistic limits
// on how many check blocks need to be received and stored. For this
// reason, rather than using dynamic allocation, blocks are stored in
// fixed-sized arrays that are a fixed multiple ("fudge factor") of
// the expected size.

// Online Code --- Graph Edges
//
// The Online Code algorithm works by creating "auxiliary" blocks,
// which are composed of several "message" blocks, and "check" blocks,
// which are composed of several "auxiliary" and/or "message"
// blocks. We can treat the relationship between aux/check blocks and
// their constituent message/aux blocks as being directed edges in a
// graph. I call these edges "downward" edges since they are coming
// from higher-numbered block numbers and point down to lower-numbered
// ones (as described in the previous section).
//
// During encoding and (especially) decoding we also need to be able
// to traverse these links in the opposite direction, so at different
// points in the algorithm we have different structures that also
// track reciprocal "upwards" edges.
//
// Broadly speaking, a list of edges emanating from a node will either
// be stored as a fixed-size array or as a linked list. The decision
// to use one or the other depends mainly on whether edges need to be
// created or destroyed individually and on whether the number of
// edges can be calculated in advance.

// Online Code --- Linked list of block numbers
//
// This basic structure is used in various places:
//
// * storage of "upward" edges
// * storage of pending nodes during graph traversal
// * building of lists of blocks to be used during XOR operations

struct oc_linked_list_int;
typedef struct oc_linked_list_int oc_block_list;

struct oc_linked_list_int {
  oc_block_list *next;
  int value;
};

// Replacing above with a version based on unions so that I can write
// generic linked-list/circular list routines using a single type.
// The most common use case will be for list structures with a single
// 'next' pointer and an integer 'value', so the naming of the fields
// in the unions below reflect that usage.
typedef struct {
  union {
    int   i;
    void *next;
  } a;
  union {
    int   value;
    void *p;
  } b;
} oc_uni_block;



// n edges are stored in circular lists (one ring per message or
// auxiliary block)
struct oc_n_edge_ring_node;
typedef struct oc_n_edge_ring_node oc_n_edge_ring;
struct oc_n_edge_ring_node {
  int upper;			// node at the other end
  oc_n_edge_ring *left;
  oc_n_edge_ring *right;
};


// "Bones" are part edge, part xor list. The C struct needs extra
// information (compared to the Perl implementation) because I'm not
// using hashed keys to look up the lower ends of the edges and
// because we need to store the total length of the bone.

typedef struct {

  union {
    int unknowns;		// number of unknown nodes in the list
    int node;			// the actual node numbers
  } a;
  union {
    int             size;	// sum of knowns + unknowns
    oc_n_edge_ring *link;	// lower end of edge
  } b;

} oc_bone;


// Online Code --- Auxiliary Mapping
//
// The basic structure encodes a list of edges going from message
// blocks to auxiliary blocks, so a 2-D array with mblocks x q
// elements suffices.
//
// Where the reverse mapping (that of auxliary blocks to message
// blocks) is needed, it uses one linked list per auxliary block.
//



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
  // The naming convention I'm using reflects this:
  //
  // * downward edges ("v" points down) go down from check/aux nodes
  // * up edges ("n" points up) go up from message/aux
  // 

  // These are the old structures I was using
  //oc_n_edge_ring ***v_pipes;	// pipe from top node to bottom ring
  //int             **v_edges;	// downward ("v" points down)
  //int             **xor_list;	// node solutions
  //oc_n_edge_ring   *n_rings;	// doubly-linked rings of n edges
  //unsigned char    *solved;	// is node solved?


  // They're replaced by structures using bones:
  oc_bone          **top;	// upper side of link
  oc_n_edge_ring    *bottom;	// lower side (rings)
  oc_bone          **solution;	// bone morphs into an xor list 

  // These two stay the same in the new implementation
  int               *v_count;	// per-node count of unsolved v edges

  // Avoid using malloc for bones
  oc_bone           *boneyard;
  int                boneyard_size;
  int                boneyard_next;

  oc_uni_block *phead, *ptail;	// queue of pending nodes

  unsigned int  unsolved_count;	// count unsolved message blocks
  unsigned char done;		// are all message nodes decoded?

} oc_graph;




#endif

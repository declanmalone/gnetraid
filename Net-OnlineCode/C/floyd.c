// Floyd's algorithm -- implementation

#include <math.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#include "floyd.h"

// Floyd's algorithm generates a random combination of k picks from a
// set of size n. It's very similar to the Fisher-Yates algorithm
// except that it generates a combination rather than a permutation
// (ie, the order of the elements doesn't matter).
//
// The algorithmic complexity of the two algoriths is the same, but
// Floyd's algorithm uses much less memory especially in the case
// where n is large and k is relatively small. The extra costs in the
// Fisher-Yates algorithm arise from needing to keep a shuffle array
// of size n. By contrast, Floyd's algorithm only needs to maintain a
// structure of size k.
//
// The basic algorithm is:
//
//   initialize set S to empty
//   for J := N-K + 1 to N do
//      T := RandInt(1, J)
//      if T is not in S then
//          insert T in S
//      else
//          insert J in S
//   (if needed: traverse set S to produce a list L)
//
// The Perl implementation is very straightforward since sets are
// easily implemented in terms of Perl hashes. Since C doesn't have
// any similar elementary type, there are various ways we can
// implement them:
// 
// * maintain the set as an unordered list. Insertions are O(1) and 
//   searches average out to O(k^2). Memory usage is the minimal O(k)
//
// * maintain the set as a sorted list. Cost to search is O(log(k))
//   but insertion requires moving O(k^2) elements.
//
// * maintain the set as a binary search tree. Cost to search is
//   O(log(k)) while inserting is O(1) for inserting an element that
//   was searched for but not found, or O(log(k)) otherwise.
//   Practically speaking, the overall cost is O(log(k)) for
//   both. Memory usage is O(k), though with a larger constant factor
//   than either list format. The graph needs to be traversed at the
//   end to produce a list, so add O(k) to the total cost.
//
// * maintain the set as a bit array. The array memory size is O(n)
//   but with 1/8th of the constant factor of the Fisher-Yates
//   algorithm. Insertion and lookups are both O(1) but the array
//   needs to be scanned at the end adding a further O(n) to the total
//   cost.
//
// * skip lists can be used instead of binary search trees and they
//   have similar space/time metrics.
//
// * hashing algorithms allow various trade-offs to be made between
//   space and time complexity. They're a reasonable choice but there
//   are many variables to consider and they may need tuning to the
//   expected k,n values
//
// Besides the basic structures, there are other many other hybrid
// structures and ways to tune to the structures to deal with expected
// access patterns, improve memory accesses and so on. For example:
//
// * binary search trees might need balancing to prevent worst-case
//   performance (though Floyd's algorithm tends to insert elements in
//   a random order, making this less important)
//
// * bit arrays could use a more compact quadtree (or octree or
//   higher-dimension) representation to save space and reduce the
//   cost of the final scan.
//
// * Bloom filters (a form of hashing which returns either "probably
//   in set" or "definitely not in set") can optimise for the more
//   common case (assuming large n, and n much greater than k) where
//   the randomly-selected T element is not in the set. The false
//   positive rate can be controlled/tuned. Variations of Bloom
//   filters that allow traversal of set elements also exist.
//
// * etc.
//
// I will probably not be replacing the use of the Fisher-Yates
// shuffle for use in generating the auxiliary block mappings.
// Although it may not be quite as efficient as Floyd's algorithm,
// when used to generate the auxiliary mapping it has to work with
// much smaller arrays. When using the default values of q=3 and
// e=0.01, for sufficiently large numbers of message blocks, the array
// needed for the FY shuffle will only be 1.65% of the number of
// message blocks. I may change my mind on this later, but for now
// I'll just be using Floyd's algorithm for generating check block
// mappings since this is the area where the greatest improvement can
// be made.
//
// Since the original FY routine has such bad perfomance with a high
// value of n, almost any implementation of the sets to support
// Floyd's algorithm should make a vast improvement. As a result, I'm
// going to focus on implementing the simplest data structures first
// (unordered list and bit array) and leave refining them or
// implementing some other option until later.

// declare some static globals so that different methods don't have to
// include them in local data structures or pass them as arguments.

static int global_start;
static int global_n, global_k;

#define STASH_GLOBALS(START, N, K) (\
   global_start = START, global_n = N, global_k = K )

// Set implementation for SET_UNORDERED_LIST

 // The structures below are also used by SET_ORDERED_LIST
static int *int_list = 0;
static int items;

void oc_alloc_int_list(int start, int n, int k) {
  STASH_GLOBALS(start, n, k);
}

// I'll actually allocate the list here so that SET_OUT returns a
// freshly-allocated array and I avoid a memcpy.
static void clear_int_list(void) {
  //printf("Allocating/clearing int_list (size %d)\n", global_k);
  int_list = malloc(global_k * sizeof(int));
  if (NULL == int_list) {
    fprintf(stderr, "clear_int_list: Failed to allocate int_list\n");
    exit (1);
  }
  items = 0;
}

int scan_unordered_list(int x) {
  int    *p = int_list;
  int count = items;
  while (count--)
    if (*(p++) == x) return 1;
  return 0;
}

static void append_int_list(int x) {
  //printf("Adding %d (item %d/%d)\n", x, items+1, global_k);
  if (items == global_k) {
    fprintf(stderr, "append_int_list: list is already full\n");
    exit (1);
  }
  int_list[items++] = x;
}

static int *return_int_list(void) {
  return int_list;
}
// oc_rng_rand(rng, x) returns floats in the range [0,x). This macro
// makes it work like the RandInt in the pseudocode returning ints in
// the range [LOW,HIGH].

#define RandInt(LOW,HIGH) \
  (LOW + floor(oc_rng_rand(rng, HIGH - LOW + 1)))

// The high-level algorithm, modified to use zero-based arrays
int *oc_floyd(oc_rng_sha1 *rng, int start, int n, int k) {
  int j, t;
  SET_CLR();			// initialize set S to empty
  j =  n-k;
  //  printf("oc_floyd: going to choose %d elements\n", k);
  while (j < n) {		// for J := N-K + 1 to N do
    t = RandInt(0,j);		//   T := RandInt(1, J)
    if (!SET_GET(t+start))	//   if T is not in S then
      SET_PUT(t+start);		//     insert T in s
    else			//   else
      SET_PUT(j+start);		//     insert J in S
    ++j;
  }

  return SET_OUT();
}

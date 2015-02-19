#include <stdio.h>
#include <string.h>

#include "online-code.h"
#include "decoder.h"
#include "rng_sha1.h"

// test new bucket-based implementation of up edge lists

#define MBLOCKS 40
#define BUCKET_SIZE     16                // bucket size s
#define BUCKET_MODULUS  (BUCKET_SIZE - 1) // i % s <=> i & mask   
#define BUCKET_DIVISOR  4                 // i / s <=> i >> shift 

oc_rng_sha1 rng; // only needed to create aux map
oc_decoder  dec;


void expect_eq(int a, int b, char *message) {
  printf("Testing %s: %sok\n", message,
	 (a == b) ? "" : "NOT ");
}

void expect_ne(int a, int b, char *message) {
  printf("Testing %s: %sok\n", message,
	 (a != b) ? "" : "NOT ");
}

void expect_is(int a, char *message) {
  printf("Testing %s: %sok\n", message,
	 (a) ? "" : "NOT ");
}

void expect_not(int a, char *message) {
  printf("Testing %s: %sok\n", message,
	 (!a) ? "" : "NOT ");
}

void expect_seq(char *a, char *b, char *message) {
  printf("Testing %s: %sok\n", message,
	 (strcmp(a,b) == 0) ? "" : "NOT ");
}

// put values 1..items into list for node 0. Returns 0 for success.
int fill_sequence(int start, int items) {
  int tmp = 0, upper;
  for (upper = 0; upper < items; ++upper)
    if (NULL == oc_create_n_edge(&(dec.graph), start + upper, 0))
      ++tmp;
  return tmp;
}

// remove values 1..items from the list
void clear_sequence(int start, int items) {
  int upper;
  for (upper = 0; upper < items; ++upper)
    oc_delete_n_edge(&(dec.graph), start + upper, 0, 0);
}


char *pbuf;
char printbuf[200];

typedef int scan_callback(oc_graph *g, int mblocks, int lower, int uppper);

int our_callback(oc_graph *g, int mblocks, int lower, int upper) {

  // sprintf puts in a trailing \0, but doesn't count it in the
  // returned value
  pbuf += sprintf(pbuf, "%d ", upper);
  return 0;

}

char *printable_list(int node) {

  // clear string (in case list will be empty)
  *(pbuf = printbuf) = '\0';

  oc_scan_n_edge(&(dec.graph), &our_callback, node);

  return printbuf;
}


int main (int ac, char *argv[]) {

  int tmp, msg, aux, *tp;
  int q, f, mblocks, ablocks, coblocks;
  double e;

  oc_rng_init_seed(&rng, "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0");
  tmp = oc_decoder_init(&dec, MBLOCKS, &rng, 0, 0.0);
  
  expect_not(tmp & OC_FATAL_ERROR, "oc_decoder_init");

  q=dec.base.q;   mblocks=dec.base.mblocks;
  e=dec.base.e;   ablocks=dec.base.ablocks;
  f=dec.base.F;   coblocks=dec.base.coblocks;



  // decoder init already created q up edges from each message block

  // print the mapping for the first message block (informative
  // purposes)
  printf("Message block 0 links to: %s\n", printable_list(0));

  // make sure that the n_edge counts are all q for message blocks
  tmp = 0;
  for (msg = 0; msg < mblocks; ++msg)
    if (dec.graph.n_edge[msg].b.value != 3)
      ++tmp;
  expect_not(tmp, "count of message n_edges should be q after decoder init");

  // make sure that the n_edge counts are all zero for aux blocks
  tmp = 0;
  for (aux = mblocks; aux < coblocks; ++aux)
    if (dec.graph.n_edge[aux].b.value != 0)
      ++tmp;
  expect_not(tmp, "count of aux n_edges should be 0 after decoder init");

  // Remove those edges
  printf("Removing the n_edges created from auxiliary map\n");
  for (msg=0; msg < mblocks; ++msg) {
    for (aux=0; aux < q; ++aux) {
      // interrogate auxiliary map array to find "upper" (msg is "lower")
      oc_delete_n_edge(&(dec.graph),
		       dec.base.auxiliary[msg * q + aux],
		       msg, 0);
    }
  }

  // make sure that the n_edge counts are all zero
  tmp = 0;
  for (msg = 0; msg < coblocks; ++msg)
    if (dec.graph.n_edge[msg].b.value != 0)
      ++tmp;
  expect_not(tmp, "deleting q n_edges brings #edges to zero");

  // Since adding q edges and deleting them again is sufficient to
  // test that the basic add/delete work within a single bucket, I
  // only need to test scanning the list and make sure there are no
  // boundary/off-by-one issues when we completely fill the first
  // bucket.

  tmp = fill_sequence(1, BUCKET_SIZE);

  expect_not(tmp, "problems filling up first bucket");

  printf("Adding 1..16 to n_edge list; got back %s\n", printable_list(0));

  expect_seq("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 ",
	     printable_list(0),
	     "scan of full first bucket gives 1..16");

  // test deleting from various positions and re-adding to bring us
  // back up to BUCKET_SIZE entries between tests

  printf ("Deleting n_edge 0->16\n");
  oc_delete_n_edge(&(dec.graph), 16, 0, 0);
  expect_seq("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 ",
	     printable_list(0),
	     "delete last element from first bucket");
  expect_not((NULL == oc_create_n_edge(&(dec.graph), 16, 0)), 
	    "adding element 16 back onto end of list");
  

  printf ("Deleting n_edge 0->10\n");
  oc_delete_n_edge(&(dec.graph), 10, 0, 0);
  expect_seq("1 2 3 4 5 6 7 8 9 16 11 12 13 14 15 ",
	     printable_list(0),
	     "delete central element from first bucket");
  expect_not((NULL == oc_create_n_edge(&(dec.graph), 10, 0)), 
	    "adding element 10 back onto end of list");

  printf ("Deleting n_edge 0->1\n");
  oc_delete_n_edge(&(dec.graph), 1, 0, 0);
  expect_seq("10 2 3 4 5 6 7 8 9 16 11 12 13 14 15 ",
	     printable_list(0),
	     "delete first element from first bucket");
  expect_not((NULL == oc_create_n_edge(&(dec.graph), 1, 0)), 
	    "adding element 1 back onto end of list");

  // The list is getting a bit messy, so clear it and start again,
  // this time with 17 elements

  clear_sequence(1,16);
  tmp = fill_sequence(1, BUCKET_SIZE + 1);

  expect_not(tmp, "filling beyond first bucket");

  printf("Added 1..17 to n_edge list; got back %s\n", printable_list(0));

  expect_seq("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 ",
	     printable_list(0),
	     "scan of overflowing first bucket gives 1..17");

  // delete element 17
  oc_delete_n_edge(&(dec.graph), 17, 0, 0);
  printf("Deleted 17 from n_edge list; got back %s\n", printable_list(0));
  expect_seq("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 ",
	     printable_list(0),
	     "shrinking back to one bucket");

  // fill up the second bucket
  tmp = fill_sequence(17, BUCKET_SIZE);

  expect_not(tmp, "filling second bucket");
  printf("Added 17..32 to n_edge list; got back %s\n", printable_list(0));

  expect_seq("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 "
	     "17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 ",
	     printable_list(0),
	     "scan of filling two buckets gives 1..32");

  // put an element in the third bucket
  tmp = fill_sequence(33, 1);

  expect_not(tmp, "entering third bucket");
  printf("Added 33 to n_edge list; got back %s\n", printable_list(0));

  expect_seq("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 "
	     "17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 ",
	     printable_list(0),
	     "scan of entering third bucket gives 1..33");

  // delete sole element from 3rd bucket
  oc_delete_n_edge(&(dec.graph), 33, 0, 0);
  printf("Deleted 17 from n_edge list; got back %s\n", printable_list(0));
  expect_seq("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 "
	     "17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 ",
	     printable_list(0),
	     "shrinking back to two buckets");

  // put it back again so I can test removing something from a
  // different bucket
  tmp = fill_sequence(33, 1);

  expect_not(tmp, "entering third bucket");
  printf("Added 33 to n_edge list; got back %s\n", printable_list(0));

  expect_seq("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 "
	     "17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 ",
	     printable_list(0),
	     "scan of entering third bucket gives 1..33");

  // delete something from element from 1st bucket of 3
  oc_delete_n_edge(&(dec.graph), 1, 0, 0);
  printf("Deleted 17 from n_edge list; got back %s\n", printable_list(0));
  expect_seq("33 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 "
	     "17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 ",
	     printable_list(0),
	     "deleting from 1st of 3 buckets");

  // put it back again so I can test removing something from a
  // different bucket
  tmp = fill_sequence(34, 1);

  expect_not(tmp, "entering third bucket");
  printf("Added 34 to n_edge list; got back %s\n", printable_list(0));

  expect_seq("33 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 "
	     "17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 34 ",
	     printable_list(0),
	     "scan of entering third bucket gives 1..33");

  // delete some element from 2nd bucket of 3
  oc_delete_n_edge(&(dec.graph), 18, 0, 0);
  printf("Deleted 18 from n_edge list; got back %s\n", printable_list(0));
  expect_seq("33 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 "
	     "17 34 19 20 21 22 23 24 25 26 27 28 29 30 31 32 ",
	     printable_list(0),
	     "deleting from 2nd of 3 buckets");

  // delete all but one of the elements (leaving 17)
  clear_sequence(2, 15);
  clear_sequence(19, 34 - 19 + 1);
  printf("Deleting everything except 17; got back %s\n", printable_list(0));
  expect_seq("17 ",
	     printable_list(0),
	     "deleting everything except 17");
  
}

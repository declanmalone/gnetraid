// Port of codec.pl

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <assert.h>

#include "online-code.h"
#include "encoder.h"
#include "decoder.h"
// #include "xor.h"

extern char *optarg;		// getopt-related
extern int   optind;

const char *null_seed = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

oc_encoder  enc;
oc_decoder  dec;
oc_rng_sha1 erng, drng;

// Test string (pre-padded to simplify things)
#define LENGTH 41		// string length not including '\0'
#define PADLEN 83		// twice LENGTH plus 1 for '\0'

char message[PADLEN] = "The quick brown fox jumps over a lazy dog"
                       "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
char ostring[PADLEN];		// decoder message buffer
char xmit[PADLEN];		// "transmitted" block

// Auxiliary caches used by encoder and decoder, respectively
char *aux_cache;
char *aux_solved;

// Cache for received check blocks (with a huge fudge factor)
#define CHK_CACHE_BYTES (PADLEN * 10)
char chk_cache[CHK_CACHE_BYTES];

// encoder/decoder flags
int eargs = 0;
int dargs = 0; //OC_EXPAND_MSG;


// simple XOR routine (for now)
void xor(char *dst, char *src, int count) {
  while (count--)
    *(dst++) ^= *(src++);
}

void test_xor(void) {
  // basic test; should print cAMELcASE
  memcpy(xmit, "CamelCase", 9);
  xor (xmit, "         ", 9);
  printf("%.9s\n", xmit);
}

// print an xor list
void print_xor_list(int *xp) {
  int count = *(xp++);
  while (count--) {
    printf("%d%s", *(xp++), (count == 0) ? "\n" : ", ");
  }
}

// calculate the length of a linked list
int linked_len (oc_block_list *list) {
  int len = 0;
  while (NULL != list) {
    ++len;
    list = list->next;
  }
  return len;
}

// print contents of linked list
void print_linked_list(oc_block_list *list) {
  while (NULL != list) {
    printf("%d%s", list->value, (NULL == list->next) ? "" : ", ");
    list = list->next;
  }
}

int main(int argc, char * const argv[]) {

  int    opt, random_seed = 1, mblocks, flags;
  char   seed[20];
  double e;
  int    block_size = 4;
  int    q, f, ablocks, coblocks;
  int    done, i, j, check_count;
  int    msg, aux, aux_block, *mp;
  int    remainder, padding;
  int   *exor_list, *dxor_list, count;

  oc_block_list *solved, *sp;

  // parse opts
  while ((opt = getopt(argc, argv, "ds:")) != -1) {
    switch(opt) {
    case 'd':
      memcpy(seed, null_seed, 20);
      random_seed = 0;
      break;
    case 's':
      if ((0 == optarg) || (20 != strlen(optarg))) {
	fprintf(stderr, "codec: -s seed must be 20 chars (no nulls)\n");
	exit(1);
      }
      memcpy(seed, optarg, 20);
      random_seed = 0;
      break;
    default:
      fprintf(stderr, "codec [-d]|[-s seed] [block_size]\n");
      exit(1);
    }
  }
  if (optind < argc)
    block_size = atoi(argv[optind]);

  if ((block_size > LENGTH) || (block_size <= 0))
    return fprintf(stderr, "Invalid block size %d\n", block_size);

  if (random_seed)
    oc_rng_init_random(&erng);
  else
    oc_rng_init_seed(&erng, seed);
  oc_rng_init_seed(&drng, erng.seed);

  assert(0 == strcmp(oc_rng_as_hex(&erng), oc_rng_as_hex(&drng)));

  // Set up strings and such
  printf ("SEED: %s\n", oc_rng_as_hex(&erng));

  assert(strlen(message) == LENGTH * 2);

  printf("Test string: %.*s\n", LENGTH, message);
  printf("Length: %d\n", LENGTH);
  printf("Block size: %d\n", block_size);

  // Perl's a % b operator works differently from C's when a < 0
  // This version keeps a positive
  remainder = LENGTH % block_size;
  padding   = remainder ? block_size - remainder : 0;
  printf("Padding length: %d\n", padding);

  message[LENGTH + padding] = '\0';
  printf("Padded string: %s\n", message);

  mblocks = (LENGTH + padding) / block_size;
  // alternatively:
  // mblocks = (LENGTH + block_size - 1) / block_size;
  printf("Message blocks: %d\n", mblocks);

  
  // Set up Encoder using default qef
  flags = oc_encoder_init(&enc, mblocks, &erng, eargs, 0ll);
  if (flags & OC_FATAL_ERROR)
    return fprintf(stderr, "Fatal error setting up encoder\n");

  ablocks  = enc.base.ablocks;
  coblocks = enc.base.coblocks;
  q        = enc.base.q;
  e        = enc.base.e;
  f        = enc.base.F;

  printf("Auxiliary blocks: %d\n", ablocks);
  printf("Encoder parameters:\nq= %d, e= %.15g, f= %d\n", q, e, f);
  printf("Expected number of check blocks: %d\n",
	 (int) (0.5 + (mblocks * (1 + e * q))));
  printf("Failure probability: %e\n",pow(e/2,q + 1));

  printf("Setting up decoder with default parameters\n");

  // Set up Decoder, also with default args (except fudge, which is
  // specific to the decoder and must be relatively large for small
  // values of mblocks)
  flags = oc_decoder_init(&dec, mblocks, &drng, dargs, 2.0, 0);
  if (flags & OC_FATAL_ERROR)
    return fprintf(stderr, "Fatal error setting up decoder\n");

  // Make sure that calculations for qef agree between the two
  assert(ablocks  == dec.base.ablocks);
  assert(coblocks == dec.base.coblocks);
  assert(q        == dec.base.q);
  assert(e        == dec.base.e);
  assert(f        == dec.base.F);

  // The Perl version uses OC_EXPAND_AUX to avoid creating an aux
  // cache. I'm not implementing that functionality yet so I have to
  // calculate the aux block contents here.
  aux_cache = malloc(ablocks * block_size);
  if (NULL == aux_cache)
    return fprintf(stderr, "Failed to allocate encoder auxiliary cache\n");

  memset(aux_cache, 0, ablocks * block_size);
  mp = enc.base.auxiliary;
  for (msg = 0; msg < mblocks; ++msg) {
    for (aux = 0; aux < q; ++aux) {
      aux_block = *(mp++) - mblocks;
      xor(aux_cache + block_size * aux_block,
      	  message   + block_size * msg,
      	  block_size);
    }
  }

  // Set up decoder arrays (received check and solved msg/aux blocks)
  aux_solved = malloc(ablocks * block_size);
  if (NULL == aux_solved)
    return fprintf(stderr, "Failed to allocate decoder auxiliary cache\n");
  memset(ostring, 0, LENGTH + padding + 1); // statically allocated
  memset(chk_cache, 0, CHK_CACHE_BYTES);

  // main loop
  done = check_count = 0;
  while (!done) {

    // Encoder side: create a check block. The erng's current value is
    // taken to be the "uuid/seed" for this checkblock. In practice,
    // we'd create a random uuid/seed (or at least advance the rng)
    // and save it for sending to the decoder along with the xored
    // contents of the check block.

    printf("\nENCODE Block #%d %s\n", check_count + 1, oc_rng_as_hex(&erng));

    if (NULL == (exor_list = oc_encoder_check_block(&enc)))
      return fprintf(stderr, "codec failed to create encoder check block\n");

    //    printf("Encoder check block (degree %d): ",exor_list[0]);
    printf("Encoder check block: ");
    print_xor_list(exor_list);

    // XOR the contained message/auxiliary blocks
    memset(xmit, 0, block_size);
    mp    = exor_list;
    count = *(mp++);
    while (count--) {
      i = *(mp++);
      if (i < mblocks)
       	xor(xmit, message   + i             * block_size, block_size);
      else
	xor(xmit, aux_cache + (i - mblocks) * block_size, block_size);
    }

    // Check that xmit buffer is right
    if (1 == exor_list[0])
      printf("SOLITARY ENCODED: %.*s\n", block_size, xmit);

    free(exor_list);

    // At this point the encoder would send the saved seed plus the
    // contents of the xmit buffer

    // Decoder side: Normally the first thing we'd do now is to seed
    // our rng with the value given by the encoder, but we don't need
    // to do that here because both rngs are synchronised right from
    // the start.

    printf("\nDECODE Block #%d %s\n", check_count + 1, oc_rng_as_hex(&drng));

    // Save contents of checkblock and add it to the graph
    memcpy(chk_cache + check_count * block_size,
	   xmit, block_size);
    if (-1 == oc_accept_check_block(&dec, &drng))
      return fprintf(stderr, "Failed to accept check block\n");

    ++check_count;

    // loop until resolve tells us we're done (ie, message fully
    // decoded) or we need to read a new check block
    while(1) {

      done = oc_resolve(&dec, &solved);
      if (NULL == solved)	// oc_resolve() solved nothing:
	break;			// we need a new check block

      printf("This checkblock solved %d composite block(s) (",
	     linked_len(solved));
      print_linked_list(solved);
      printf(")\n");
      
      if (done)
	printf("This solves the entire message\n");

      // Iterate over solved nodes
      while (solved != NULL) {
	sp = solved;
	i  = solved->value;

	if (NULL == (dxor_list = oc_expansion(&dec, i)))
	  return fprintf(stderr, "oc_expansion error on node %d\n", i);

	printf("\nDecoded block %d is composed of: ", i);
	print_xor_list(dxor_list);
	printf("\n");

	if (0 == *dxor_list)
	  return fprintf(stderr,"Decoded block had empty XOR list\n");

	// Check that cache contents are right
	if (1 == dxor_list[0]) {
	  j = dxor_list[1];
	  printf("SOLITARY DECODED: '%.*s' (check #%d)\n", block_size, 
		 chk_cache + (j - coblocks) * block_size,
		 (j - coblocks + 1));
	}

	// re-use xmit buffer and mp to XOR all the blocks
	memset(xmit, 0, block_size);
	mp    = dxor_list;
	count = *(mp++);

	while (count--) {
	  j = *(mp++);
	  if (j < mblocks) {
	    if (dargs & OC_EXPAND_MSG)
	      return fprintf(stderr,
                "got msg block %d with OC_EXPAND_MSG set\n", j);

	    xor(xmit, ostring + (j * block_size), block_size);
	  } else if (j >= coblocks) {
	    printf("DECODER: XORing check block #%d into %d\n",
		   j - coblocks + 1, i);
	    j -= coblocks;
	    xor(xmit, chk_cache + j * block_size, block_size);
	  } else {
	    if (dargs & OC_EXPAND_AUX)
	      return fprintf(stderr,
                "got aux block %d with OC_EXPAND_AUX set\n", j);
	    printf("DECODER: XORing block %d (auxiliary block) into %d\n",
		   j, i);
	    j -= mblocks;
	    xor(xmit, aux_solved + j * block_size, block_size);
	  }
	}

	// save newly-decoded message/aux block
	if (i < mblocks) {
	  memcpy(ostring + i * block_size, xmit, block_size);
	  printf("Decoded message block %d: '%.*s'\n",
		 i, block_size, ostring + i * block_size);
	} else {
	  printf("Decoded auxiliary block %d.\n", i);
	  i =- mblocks;
	  memcpy(aux_solved + i * block_size, xmit, block_size);
	}

	free(dxor_list);

	solved = solved->next;
	free(sp);
      }


      if (done)
	break;			// escape inner loop

    }

  }

  printf("Decoded text: '%.*s'\n", LENGTH, ostring);

}

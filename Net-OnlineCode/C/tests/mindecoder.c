// A minimal decoder test

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

#include "online-code.h"
#include "decoder.h"

extern char *optarg;		// getopt-related
extern int   optind;

const char *null_seed = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

oc_rng_sha1 rng;
oc_decoder  d;

int main(int argc, char * const argv[]) {

  int    opt, random_seed = 1, mblocks = 1, flags;
  char   seed[20];
  double e;
  int    q, f, ablocks, coblocks;
  int    done, i, j;
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
	fprintf(stderr, "mindecoder: -s seed must be 20 chars (no nulls)\n");
	exit(1);
      }
      memcpy(seed, optarg, 20);
      random_seed = 0;
      break;
    default:
      fprintf(stderr, "mindecoder [-d]|[-s seed] [mblocks]\n");
      exit(1);
    }
  }
  if (optind < argc)
    mblocks = atoi(argv[optind]);

  if (random_seed)
    oc_rng_init_random(&rng);
  else
    oc_rng_init_seed(&rng, seed);

  printf ("RNG seed: %s\n", oc_rng_as_hex(&rng));

  flags = oc_decoder_init(&d, mblocks, &rng, OC_EXPAND_MSG, 3.0, 0ll);

  if (flags & OC_FATAL_ERROR)
    return fprintf(stderr, "OC decoder init returned fatal error\n");

  q = d.base.q;
  e = d.base.e;
  f = d.base.F;
  ablocks  = d.base.ablocks;
  coblocks = d.base.coblocks;

  printf ("mblocks=%d, ablocks=%d, coblocks=%d\n",
	  mblocks, ablocks, coblocks);

  printf ("q=%d, e=%1.15g, F=%d\n", q, e, f);

  printf ("Expected number of check blocks: %d\n",
	  (int) (0.5 + (mblocks * (1 + e * q))));
  printf ("Failure probability: %g\n", pow(e/2,q + 1));

  printf ("Alternative number of check blocks: %d\n",
	  (int) (0.5 + (1 + e) * coblocks));

  printf ("1-epsilon/2 times composite = %g\n",
	  (coblocks * (1-e/2)));
  printf ("\n");


  // main loop
  i = done = 0;
  while (!done) {
    if (-1 == oc_accept_check_block(&d, &rng))
      return fprintf(stderr, "mindecoder: fatal error in oc_accept_check_block\n");

    ++i;
    while (1) {
      if (-1 == (done = oc_resolve(&d, &solved)))
	return fprintf(stderr, "mindecoder: fatal error in oc_resolve\n");

      if (NULL == solved) break;

      // print out list of blocks that this check block solves
      printf ("%d (%d): solves ", i, done);
      while (solved != NULL) {
	sp = solved; // stash
	printf("%d%s", sp->value, ((NULL == sp->next) ? "\n" : ", "));
	solved = solved->next;
	free(sp);
      }

      if (done) break;
    }
  }
}

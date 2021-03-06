// Based on probdist.pl

#include <stdio.h>

#include "online-code.h"

// null-terminated lists of test values
double e_values[] = { 0.01l, 0.001l, 0.1l, 0 };
int    q_values[] = { 3, 4, 7, 0 };
int    n_values[] = { 1, 2, 1000, 0 }; // number of blocks

// global codec structure
oc_codec codec;

void codec_info(int flags) {

  int i, f, max;

  printf("\nflags\tE_CHANGED\tF_CHANGED\tFATAL_ERROR\n");
  printf("   %02x\t%d\t\t%d\t\t%d\n", flags, 
	 flags & OC_E_CHANGED, flags & OC_F_CHANGED, flags & OC_FATAL_ERROR);
  flags = codec.flags;		/* should be the same */
  printf("   %02x\t%d\t\t%d\t\t%d\n\n", flags, 
	 flags & OC_E_CHANGED, flags & OC_F_CHANGED, flags & OC_FATAL_ERROR);

  if (flags & OC_FATAL_ERROR) return;

  // print e to 15 significant digits to provide output that's
  // comparable to probdist.pl
  printf("Codec returned:\n  mblocks=%d, q=%d, e=%1.15g F=%d\n",
	 codec.mblocks, codec.q, codec.e, codec.F);
  printf("  ablocks=%d, coblocks=%d\n\n", codec.ablocks, codec.coblocks);

  printf("Probability Table (first 10 elements):\n");

  f = codec.F;
  max = (f > 10) ? 10 : f;
  for (i = 0; i < max; ++i) {
    printf("   %1.15g\n", codec.p[i]);
  }
  printf("\n");
}

main() {

  double  e, *ep;
  int    *qp, *np;
  int     q, n, f;
  int     flags;

  // test initialisation without optional args
  n = 1000;
  printf("Making codec with blocks=%d (default parameters)\n", n);

  codec_info(flags = oc_codec_init(&codec, n, 0ll));

  for (ep = e_values; e=*ep; ++ep) {
    for (qp = q_values; q=*qp; ++qp) {
      for (np = n_values; n=*np; ++np) {

	printf("Making codec with blocks=%d, q=%d, e=%f\n", n, q, e);

	codec_info(flags = oc_codec_init(&codec, n, q , e, 0ll));
	
      }
    }
  }
}

// Based on probdist.pl

#include <stdio.h>

#include "online-code.h"

// null-terminated lists of test values
float e_values[] = { 0.01, 0.001, 0.1, 0 };
int   q_values[] = { 3, 4, 7, 0 };
int   n_values[] = { 1, 2, 1000, 0 }; // number of blocks

// global codec structure
oc_codec codec;

void codec_info(int flags) {

  printf("\nflags\tE_CHANGED\tF_CHANGED\tFATAL_ERROR\n");
  printf("   %02x\t%d\t\t%d\t\t%d\n", flags, 
	 flags & OC_E_CHANGED, flags & OC_F_CHANGED, flags & OC_FATAL_ERROR);
  flags = codec.flags;		/* should be the same */
  printf("   %02x\t%d\t\t%d\t\t%d\n\n", flags, 
	 flags & OC_E_CHANGED, flags & OC_F_CHANGED, flags & OC_FATAL_ERROR);

  if (flags & OC_FATAL_ERROR) return;

  printf("Codec returned:\n  mblocks=%d, q=%d, e=%1.12f, F=%d\n",
	 codec.mblocks, codec.q, codec.e, codec.F);
  printf("  ablocks=%d, coblocks=%d\n\n", codec.ablocks, codec.coblocks);

}

main() {

  float  e, *ep;
  int   *qp, *np;
  int    q, n, f;
  int    flags;

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

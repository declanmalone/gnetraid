/* Copyright (c) Declan Malone 2009 */

#include <spu_intrinsics.h>
#include <spu_mfcio.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "common.h"

int main(unsigned long long spe, 
	 unsigned long long argp, unsigned long long envp)
{

  int i;
  
  uint32_t sum=1000;
  uint32_t countdown=20;

  /* read from mailbox, add read value to sum, quit on 0 */
  uint32_t spu_id;

  printf ("SPU task waiting to read\n");

  while (1) {
    spu_id = spu_read_in_mbox();
    printf ("SPU task got value %u\n", spu_id);

    if (spu_id == 0) break;

    if (--countdown == 0) break;

    for (i=0; i < 10000 + spu_id; ++i) 
      sum ^= i;			/* don't optimise out */

    // the event we want to handle:
    spu_write_out_intr_mbox(sum);

  }

  // specific "goodbye" message
  spu_write_out_intr_mbox(0);

  printf ("SPU returning\n");

  return 0;
}

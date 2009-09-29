#include <spu_intrinsics.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <spu_mfcio.h>

#include "common.h"

int main(unsigned long long spe, 
	 unsigned long long argp, unsigned long long envp)
{

  uint32_t sum=0;

  /* read from mailbox, add read value to sum, quit on 0 */
  uint32_t spu_id;

  printf ("SPU task waiting to read\n");

  while (1) {
    spu_id = spu_read_in_mbox();
    // printf ("SPU task got value %u\n", spu_id);
    sum ^= spu_id;
    if (spu_id == 0) break;
  }

  printf ("SPU returning value %u\n");

  spu_write_out_mbox(sum);

  return sum;
}

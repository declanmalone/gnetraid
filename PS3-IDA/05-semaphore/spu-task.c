/* Copyright (c) Declan Malone 2009 */

#include <spu_intrinsics.h>
#include <spu_mfcio.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

#include "common.h"

int main(unsigned long long spe, 
	 unsigned long long argp, unsigned long long envp)
{

  /* read from mailbox, quit if >= argp, change case otherwise */
  uint32_t spu_message;
  uint16_t addr_part;
  uint16_t val_part;

  //printf ("SPU: Got initial arguments %lld, %lld\n", argp, envp);


  //printf ("SPU: Ready to read commands\n");


  while (1) {
    spu_message = spu_read_in_mbox();

    addr_part=(uint16_t) (spu_message >> 16);
    val_part =(uint16_t) (spu_message);

    printf ("SPU: working on slot %u, value %u\n", addr_part, val_part);

    // Use a two-stage shutdown mechanism. The first time the host
    // sends an out-of-range value, the SPU immediately tries to read
    // another mailbox message. If another out-of-range message is
    // received, the SPU quits. Otherwise, it ignores the message and
    // continues processing the new (valid) data.
    //
    // My reason for doing this is that I think there may be some
    // problem with my event-handling code on the PPE when the SPU
    // program quits before the event handler has had a chance to
    // receive the message from the SPU acknowledging the
    // idle/shutdown message.

    if (addr_part >= argp) {
      printf ("SPU: ACK idle/shutdown command\n");
      // spu_message=((uint32_t) argp << 16);
      spu_write_out_intr_mbox(spu_message); /* acknowledgement */

      spu_message = spu_read_in_mbox();

      addr_part=(uint16_t) (spu_message >> 16);
      val_part =(uint16_t) (spu_message);
      
      if (addr_part >= argp) {
	printf ("SPU: Got second idle/shutdown command\n");
	break;
      } else {
	printf ("SPU: Waking up from idle state\n");
      }
      // fall through to normal execution
    }

    if ((((char) val_part >= 'a') && ((char) val_part <= 'z')) ||
	(((char) val_part >= 'A') && ((char) val_part <= 'Z'))) {
      val_part^=0x20;
    }

    //printf ("SPU: returning slot %u, value %u\n", addr_part, val_part);
    spu_message=((uint32_t) addr_part << 16) | val_part;

    spu_write_out_intr_mbox(spu_message);

  }

  printf ("SPU: shutdown\n");

  return 0;
}

/* Copyright (c) Declan Malone 2009 */

// Event thread and related variables

#include "host.h"
#include "ppu-event.h"
#include "ppu-queue.h"
#include "ppu-scheduler.h"
#include "ppu-ida.h"


// One event handler thread per program run
void *event_thread(void * arg) {

  codec_t  *c = arg;

  uint32_t slot;
  int      sender;

  event_queue_t    *q = c->task_queue;
  spe_event_unit_t  thisevent;

  while (c->running_spes) {

    if (verbose)
      printf ("event: waiting for message\n");
    if (spe_event_wait(c->handler, &thisevent, 1, -1) < 1) {
      printf ("event: hmmm... no messages?\n");
      continue;
    }

    sender = thisevent.data.u32;

    if (verbose)
      printf ("event: message waiting from SPE %d\n", sender);
    
    spe_out_intr_mbox_read (thisevent.spe,
			    &slot,
			    1,
			    SPE_MBOX_ALL_BLOCKING);
    if (verbose) {
      printf("event: SPE no %d finished with slot: %u\n", sender, slot);
      printf("event: comparing slot %d with buffer_slots %d\n", 
	     slot, c->buffer_slots);
    }

    if (slot >= c->buffer_slots) {
      int remain = --(c->running_spes);
    if (verbose)
      printf ("event: SPE %d ACKs idle state (%d more running)\n",
	      sender,remain);
      spe_event_handler_deregister(c->handler,&(c->spe_event[sender]));
      event_queue_push(q, SPU_0_IDLE + sender, 0);
      if (remain <=0)
	break;
    } else {
      if (verbose)
	printf ("event: telling scheduler about SPU_DONE event\n");
      event_queue_push(q, SPU_0_DONE + sender, slot);
    }
  }
  if (verbose)
    printf("event: exiting as last SPE has said goodbye\n");
  pthread_exit(arg);
}

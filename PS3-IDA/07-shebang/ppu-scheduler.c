/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#include <libspe2.h>
#include <string.h>
#include <errno.h>

#include "host.h"
#include "ppu-ida.h"
#include "ppu-scheduler.h"
#include "ppu-queue.h"

// not used: "don't check for an error state you don't know how to handle"
// static volatile unsigned scheduler_running=0;

// give printable names to events easier debugging/reporting
// must match with states listed in enum in header file
char* event_name[]= { 
  "NOP",
  "READ_SLOT",  "READ_EOF"  , "READ_ERROR",

  "SPU_0_DONE", "SPU_1_DONE", "SPU_2_DONE",
  "SPU_3_DONE", "SPU_4_DONE", "SPU_5_DONE",

  "SPU_0_IDLE", "SPU_1_IDLE", "SPU_2_IDLE",
  "SPU_3_IDLE", "SPU_4_IDLE", "SPU_5_IDLE",

  "WROTE_SLOT", "WRITE_ERROR", "PING_SCHEDULER"
};

// factor out code for sending shutdown messages to SPEs since it can
// be called from several places.  To shut down SPEs completely, two
// calls to this routine are needed. The first call will be
// acknowledged by the SPE, and this acknowledgement should be
// detected by the event thread, which will end when it receives
// num_spe acks. The second (consecutive) shutdown message causes the
// SPE to exit (without any acknowledgement). The purpose of this
// two-stage shutdown sequence is to allow clean exits of all threads.
//
// As noted in the comments for the double-buffered SPE task code, it
// makes sense to treat the first shutdown message as a "flush"
// message. Then any subsequent non-flush message will wake the task
// up again (and allow it to receive more input, although that is not
// implemented in the PPE code), whereas a second "flush" message will
// be interpreted as a signal to shut down completely.
//
void schedule_spe_shutdown(codec_t *c) {
  int i;
  uint32_t message = c->buffer_slots;;

  for (i=0; i < c->num_spe; ++i) {
    if (verbose)
      printf ("scheduler: sending EOF signal to SPU %d\n",i);
    if (spe_in_mbox_write(c->run_context[i],
			  &message,1,
			  SPE_MBOX_ALL_BLOCKING) == 0) {
      printf("PPE: Couldn't send SPE shutdown command!\n");
    }
  }
}

// send a message to an active SPE to process a block of data
void schedule_task(codec_t *c, unsigned *readq, unsigned *workq,
		   uint16_t slot) {

  static int next_spe=0;
  int chosen_spe;
  int i;
  uint32_t message;
  unsigned num_spe = c->num_spe;

  // don't assume that a task is actually schedulable right now
  if (*workq >= num_spe * MBOX_QUEUE_DEPTH)        return;
  if (c->input_slot[slot].state  != SLOT_RUNNABLE) return;
  if (c->output_slot[slot].state != SLOT_EMPTY)    return;
  if (!*readq) return;

  // scan list of SPEs to find one with available mbox space
  chosen_spe=num_spe;   /* value signifies none chosen */
  for (i=0; i < num_spe; i++) {
    if ((c->mboxq)[(next_spe + i) % num_spe] < MBOX_QUEUE_DEPTH) {
      chosen_spe=(next_spe + i) % num_spe;
      break;
    }
  }
  // did we find an SPE we can send this to?
  if (chosen_spe != num_spe) {

    int k = c->k;
    int n = c->n;

    ++(c->mboxq)[chosen_spe];
    ++(*workq);
    --(*readq);         /* move state from readq to workq */

    // Propagate the number of bytes read in the input slot to the
    // bytes needing to be written in the output slot. Note that when
    // splitting, for every k bytes of input we need to generate n
    // bytes of output. But for combining, we have k bytes of output
    // for every k bytes of input (1:1).  Rather than including a
    // conditional statement here, we assume that when setting up a
    // combine step that n will be set to k. If this doesn't happen,
    // then this next bit of code will have unpredictable results, to
    // say the least. Also note that since integer division is used
    // here, it assumes that the number of bytes read is a multiple of
    // k, or else there will be some bytes lost due to rounding.
    // Again, it's up the the setup routines to ensure that the size
    // of each slot is a multiple of k (* w), and to the read routine
    // to ensure that it pads files at EOF to also be a multiple of k
    // * w. That said, the code here is simple:

    c->output_slot[slot].bytes = (c->input_slot[slot].bytes / k) * n;

    if (verbose)
      printf ("scheduler: starting slot %d on SPE%d\n", slot, chosen_spe);
    message=(uint32_t) slot;
    if (spe_in_mbox_write(c->run_context[chosen_spe],
                          &message,1,
                          SPE_MBOX_ALL_BLOCKING) == 0) {
      printf("scheduler: Couldn't schedule task. I am mortified.\n");
    }
    next_spe=(chosen_spe + 1) % num_spe;
    c->input_slot [slot].state = SLOT_RUNNING;
    c->output_slot[slot].state = SLOT_RUNNING;

  } else {
    if (verbose)
      printf ("scheduler: all mboxes are full; can't schedule right now\n");
  }

  return;
}

// if the scheduler detected a read error or read eof, it needs to
// tell the writer thread. This routine does that.
void schedule_signal_no_more_writes (codec_t *c) {
  int i;

  for (i=0; i < c->buffer_slots; ++i) {
    c->output_slot[i].state = SLOT_EOF;
    sem_post(&(c->output_slot[i].sem));
  }
}

// main scheduler thread
void *scheduler_thread(void *arg) {
  codec_t       *c = arg;
  event_queue_t *q = c -> task_queue;

  uint32_t event, slot;

  // keep track of some state variable here, ie running totals of
  // blocks in read, work and write queues and whether we've got eof
  // on input
  unsigned readq=0;
  unsigned writeq=0;
  unsigned workq=0;		/* total work jobs in progress */
  unsigned num_spe = c->num_spe;
  unsigned max_workq = (num_spe * MBOX_QUEUE_DEPTH);
  unsigned eof=0;
  unsigned ackq=0;		/* pending shutdown ACKs */

  int i;

  // Can only run one scheduler at a time
  //if (scheduler_running++) return arg;

  if (verbose) 
    printf ("scheduler: task queue address is %ld\n", (long) q);
  if (verbose) 
    printf ("scheduler: num_spe  is %u\n", num_spe);


  // event handling main loop
  while (1) {

    // block until something happens
    if (verbose)
      printf("scheduler: waiting to shift\n");
    event_queue_shift(q, &event, &slot);
    if (verbose)
      printf ("scheduler: got event %d:'%s', slot %ld\n",
	      event, event_name[event], (unsigned long) slot);

    if (verbose)
      printf ("scheduler: readq %d, workq %d, writeq %d, ackq %d\n", 
	      readq, workq, writeq, ackq);

    switch (event) {
      // let NOP be caught by default (unknown) event case
      //    case NOP: break;

    case PING_SCHEDULER:

      // facilitate debugging
      printf ("scheduler: ACK\n");
      break;

    case READ_SLOT: 

      ++readq;
      c->input_slot[slot].state = SLOT_RUNNABLE;

      if ((c->output_slot[slot].state == SLOT_EMPTY)
	  && (workq < max_workq))
	schedule_task(c, &readq, &workq, slot);

      break;

    case SPU_0_IDLE:    case SPU_1_IDLE:    case SPU_2_IDLE:
    case SPU_3_IDLE:    case SPU_4_IDLE:    case SPU_5_IDLE:

      // Let's take care of this here. The event thread must notify us
      // of ACKs to idle/shutdown messages
      --ackq;
      // max_workq  -= MBOX_QUEUE_DEPTH;
      // c->mboxq[event - SPU_0_IDLE] = MBOX_QUEUE_DEPTH;

      break;

    case SPU_0_DONE:    case SPU_1_DONE:    case SPU_2_DONE:
    case SPU_3_DONE:    case SPU_4_DONE:    case SPU_5_DONE:

      --workq;
      ++writeq;			/* move state from workq to writeq */

      // Sure-fire way to determine when an mbox slot is available for
      // writing is to wait for the task to complete. This isn't the
      // most effective way of utilising all our queues, but it
      // shouldn't make any difference in reality since most SPU code
      // will only use double-buffering at most, and we use the full 4
      // mailbox slots.
      c->mboxq[event - SPU_0_DONE]--;


      if (verbose) 
	printf ("scheduler: SPU %d completed work slot %d \n",
		event - SPU_0_DONE, slot);

      // save returned message
      // TODO (shouldn't be needed)

      // update buffer slot states, and increment buffer semaphores so
      // that reader and writer threads can (possibly) unblock and
      // start filling/emptying the slot.
      c->input_slot [slot].state = SLOT_EMPTY;
      c->output_slot[slot].state = SLOT_FLUSHING;
      sem_post(&(c->input_slot [slot].sem));
      sem_post(&(c->output_slot[slot].sem));

      // check whether we can schedule a new task. We know that there
      // is an SPE task queue slot available, but we have to scan
      // through the list of input/output buffers to find a slot
      // that's ready to run.
 
      // scan through buffer_slots - 1 slots, because this slot isn't
      // usable (it's flushing)
      for (i=1; i < c->buffer_slots; ++i) {
	slot = (1 + slot) % c->buffer_slots;
	if ((c->input_slot [slot].state == SLOT_RUNNABLE) &&
	    (c->output_slot[slot].state == SLOT_EMPTY)) {
	  schedule_task(c, &readq, &workq, slot);
	  break;
	}
      }
 
      break;

    case READ_EOF:
    case WROTE_SLOT:

      // handle both of these together since both of them can indicate
      // that we have no more work to do.

      if (event == WROTE_SLOT) {
	--writeq;
	c->output_slot[slot].state = SLOT_EMPTY;

	if ((c->input_slot[slot].state == SLOT_RUNNABLE) &&
	    (workq < max_workq)) {
	  schedule_task(c, &readq, &workq, slot);
	  break;
	}
      } else {
	eof=1;
      }


      // if readq is now empty, and we're at eof, we should signal all
      // SPEs to stop. This might block, but at least we know that we
      // won't be telling SPEs to shut down before we're done sending
      // them work.

      if (eof && !(readq || ackq)) {
	if (verbose)
	  printf ("scheduler: at EOF and no more readq; shutting down SPEs\n");
	schedule_spe_shutdown(c);
	ackq += num_spe + 1; // +1 to prevent bouncing back up again later
      }


      // important bit that both have in common. If READ_EOF comes
      // late (after final write) this will tell the writer to shut
      // down. Likewise, if the final WROTE_SLOT message comes last,
      // and there's no more work, we also tell the writer to stop.
      if (eof && !(readq || workq || writeq)) {
	schedule_signal_no_more_writes(c);
      }

      break;

    case WRITE_ERROR:
    case READ_ERROR:

      // errno gets clobbered by (successful) semaphore operations, so
      // caller saves it and passes it in value.
      if (event == WRITE_ERROR) 
	printf ("PPE: Write error detected: %s\n", 
		strerror(c->write_thread_error));
      else {
	// tell writer thread to stop writing
	schedule_signal_no_more_writes(c);

	printf ("PPE: Read error detected: %s\n", 
		strerror(c->read_thread_error));
      }

      // send shutdown messages to SPEs (don't wait for acks)
      schedule_spe_shutdown(c);
      schedule_spe_shutdown(c);

      return arg;		/* non-zero = failure */

    default:
      printf ("PPE: Unknown event received by scheduler: %u\n",event);
    }

    // Only quit if eof and no tasks pending also wait for any pending
    // ACKS from SPEs. We wait for ackq < 2 since ackq should finish
    // at 1 to prevent it from bouncing back up if it reaches 0 and we
    // get new WROTE_SLOT messages afterwards.
    if (eof && !(readq || workq || writeq || (ackq>1))) {
      if (verbose)
	printf ("scheduler: EOF and no pending work; shutting down\n");

      if (c->running_spes) {
	printf ("scheduler: %d SPE(s) still running!\n",c->running_spes);
	continue;
      }

      // send another idle/shutdown message to each SPE to shut it
      // down completely.
      schedule_spe_shutdown(c);

      return NULL;		/* NULL = success */
    }

    // Debug why we're going back to wait for more messages
    if (verbose) {
      printf("scheduler: about to loop.. available state info:\n");
      printf ("scheduler: eof %d, readq %d, workq %d, writeq %d, ackq %d\n", 
	    eof,readq, workq, writeq,ackq);
      printf ("scheduler: Number of running SPEs: %d\n", c->running_spes);
    }

  }

  printf ("scheduler: no more work; exiting.\n");
  return NULL;
}



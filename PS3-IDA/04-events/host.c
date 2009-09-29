/* Copyright (c) Declan Malone 2009 */

#include <libspe2.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "common.h"

#define N_THREADS 3

const char *spu_prog="spu-task";

// The purpose of this code is to use PPU event handlers to achieve
// notification of data being transferred from an SPU via its outbound
// mailbox. 
//
// As it stands, the code isn't perfect. In particular, the main loop
// ends up getting stuck when the SPE task has finished. This is due
// to it testing the "running" variable, finding that there is still a
// task running, then attempting to read from a mailbox. In fact, it
// seems like there's a lag between the message being sent and
// variable being updated, so by the time the main loop gets to do a
// (blocking) read on the mbox, the listening process is no longer
// there.
//
// A workaround would be for the SPE thread to wait around for a while
// after it's done it's main work and do a few (non-blocking) mailbox
// reads, just on the off chance that the host is still writing data.
//
// Another workaround would be to change from using blocking writes to
// non-blocking writes.
//
// The best solution, though, would be to use a semaphore to
// co-ordinate between the main task and the event handling task. The
// event handler would increment the semaphore to indicate a pending
// mailbox message that needs to be read, while the main task would
// wait until the semaphore was non-zero and only then would it
// attempt to read from the correct mbox.
//
// Another problem with the code as it stands is that no attempt is
// made to distinguish between which SPE sent the message. All in all,
// though, it does demonstrate setting up an event handler thread,
// responding to messages, changing global state, etc. For a more
// complex/complete example, use the semaphore idea above.
//


void *ppu_thread(void *arg) {
  spe_context_ptr_t context = *(spe_context_ptr_t *) arg;
  unsigned int      entry   = SPE_DEFAULT_ENTRY;

  spe_context_run(context,&entry,0,NULL,NULL,NULL);

  printf ("SPU thread shutdown\n");
  pthread_exit(NULL);
}

// Some stuff needs to be global for our event watching threads
spe_context_ptr_t     context[N_THREADS];
pthread_t             pthread[N_THREADS + 1];

// variable for synchronisation with main loop
volatile int running=0;

// event handler stuff
spe_event_handler_ptr_t handler; // one for all contexts, apparently
spe_event_unit_t        event[N_THREADS];

// One event handler shared among all run contexts. 
void *event_thread(void * arg) {
  
  uint32_t message;

  while (1) {
    spe_event_wait(handler, event, N_THREADS, -1);

    printf("Got event from spe no %d: ", event[0].data.u32);

    spe_out_intr_mbox_read (event[0].spe,
			    &message,
			    1,
			    SPE_MBOX_ANY_BLOCKING);

    printf ("%d\n", message);

    // check for thread termination message
    if (message == 0) { 
      if (--running <= 0) {
	printf("event_thread: No more running threads. Leaving \n");
	return;
      }
    }
  }
}


int main (int ac, char *av[]) {

  uint32_t              i,j,value,result;
  spe_program_handle_t *program_image;

  program_image=spe_image_open(spu_prog);
  if (!program_image) {
    printf ("Couldn't load image %s\n",spu_prog);
    return 1;
  }

  printf("Creating worker threads: ...\n");

  // Set up one event handler for ALL contexts
  printf ("  set up event handler\n");
  handler = spe_event_handler_create();
  if (handler == NULL) {
    printf ("Failed to set up handler\n");
    return 1;
  }

  // Create a thread for the event listener
  pthread_create(&pthread[N_THREADS],NULL,&event_thread,NULL);

  for (i=0;i<N_THREADS;i++) {
    printf ("  create context\n");
    context[i] = spe_context_create(SPE_EVENTS_ENABLE,NULL);

    event[i].spe=context[i];
    event[i].events=SPE_EVENT_OUT_INTR_MBOX;
    //event[i].data.ptr=???
    event[i].data.u32=i;	/* which context? */
    if (spe_event_handler_register(handler, &event[i])) {
      printf ("Failed to register event handler\n");
      return 1;
    }

    printf ("  load program\n");
    value=spe_program_load(context[i],program_image);

    printf ("  create SPE run thread\n");
    pthread_create(&pthread[i],NULL,&ppu_thread,&context[i]);

    ++running;
  }

  printf("Writing values to mailbox\n");

  // write values using mailboxes.  Every time the SPU task receives a
  // message, it waits for a while and then writes the value back in
  // the outbound mailbox. We have to remove the returning message
  // since the SPU will block until we do.

  value=1; i=0;
  while (running) {
    if (spe_in_mbox_write(context[i],&value,1,SPE_MBOX_ALL_BLOCKING) == 0) {
      printf("Message could not be written\n");
      break;
    }
    value++;
    if (++i >= N_THREADS) i=0;
    printf ("Still here...\n");
  }

  printf("PPE: No more running SPE tasks\n");

  // Finish (+1 extra thread to join)
  for (i=0;i<N_THREADS + 1;i++) {
    value=pthread_join(pthread[i],NULL);
    printf ("Got back value %u from thread %d\n",value,i);
    if (i != N_THREADS) {
      spe_context_destroy(context[i]);
    }
  }
  
  printf ("End of PPU thread\n");
  return 0;

}

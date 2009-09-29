/* Copyright (c) Declan Malone 2009 */

/* Based on:

   http://www.lemma.ufpr.br/wiki/index.php/Cell_BE_Tutorial

*/


#include <libspe2.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "common.h"

#define N_THREADS 1

const char *spu_prog="spu-task";

void *ppu_pthread_function(void *arg) {
  spe_context_ptr_t context = *(spe_context_ptr_t *) arg;
  unsigned int      entry   = SPE_DEFAULT_ENTRY;
  spe_stop_info_t   return_info;

  spe_context_run(context,&entry,0,NULL,NULL,&return_info);

  printf ("PPU got return value %d from spe_context_run\n",
	  return_info.result.spe_exit_code);



  /*
    Neither of the two ways of returning from this thread seem to
    actually return a value back to the main thread. For some reason I
    don't have full manpages for Posix threads so I can't check my
    assumption that pthread_join should snarf the return value. Also,
    I noticed that the 32-bit return value from the SPE thread was
    truncated to 8 bits. So: the best solution would be for the SPE
    program to write its return value back into the host program's
    memory space with a DMA transfer, or, since this program is
    intended as a way to learn about mailboxes, I should probably use
    a mailbox message to send it back...
  */
  return return_info.result.spe_exit_code;

  pthread_exit(return_info.result.spe_exit_code);
}


int main (int ac, char *av[]) {

  spe_context_ptr_t     context[N_THREADS];
  pthread_t             pthread[N_THREADS];
  uint32_t              i,j,value,result;
  spe_program_handle_t *program_image;

  program_image=spe_image_open(spu_prog);
  if (!program_image) {
    printf ("Couldn't load image %s\n",spu_prog);
    return 1;
  }

  printf("Creating worker threads: ...\n");

  for (i=0;i<N_THREADS;i++) {
    printf ("  create context\n");
    context[i] = spe_context_create(0,NULL);

    printf ("  load program\n");
    value=spe_program_load(context[i],program_image);

    printf ("  create thread\n");
    pthread_create(&pthread[i],NULL,&ppu_pthread_function,&context[i]);
  }

  printf("Writing values to mailbox\n");

  // write values using mailboxes
  for (i=0;i<N_THREADS;i++) {
    value=1;
    while (1) {
      if (spe_in_mbox_write(context[i],&value,1,SPE_MBOX_ALL_BLOCKING) == 0) {
	printf("Message could not be written\n");
	break;
      }
      if (value == 0) break;
      value <<= 1;
      /* printf ("New value: %d", value); */
    };
  }

  // SPU program stops reading once it receives 0 as a message At that
  // point, it takes the sum (xor) of all values it's been passed and
  // sends back a mailbox message with that sum to the host (us).

  printf("Reading sum from mailbox\n");

  for (i=0;i<N_THREADS;i++) {
    // reading from the SPE's out mailbox doesn't block if no
    // messages are available, so we have to loop until
    while(spe_out_mbox_read(context[i],&value,1)==0) {}
    printf ("Thread %d returned value %u\n",i,value);
  }

  // shut down all SPE contexts and wait for local threads to finish
  for (i=0;i<N_THREADS;i++) {
    value=pthread_join(pthread[i],NULL);
    printf ("Got back value %u from thread %d\n",value,i);
    spe_context_destroy(context[i]);
  }

  printf ("End of PPU thread\n");
  return 0;
} 









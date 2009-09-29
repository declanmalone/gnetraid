/* Copyright (c) Declan Malone 2009 */

// Based on documentation for spe_context_run. To summarise: normally,
// when the main routine of the SPE program is called, there are three
// input variables which are assigned to the following regsiters:
//
// * r3 spe  - the address of the SPE context being run
// * r4 argp - usually a pointer to argv of the main program
// * r5 envp - usually the environment pointer of the main program
//
// However, quoting from the manpage: [i]f SPE_RUN_USER_REGS is set,
// then the registers are initialized with a copy of an
// (uninterpreted) 48-byte user data field pointed to by argp. envp is
// ignored in this case.
//
// For my application, I want to pass some initialisation data which
// is just a little bit more than 48 bytes. If I cut down on the size
// of some fields then I can bring the structure size down to exactly
// 48 bytes. So that's what this test program attempts to do. The
// advantage is that I can avoid one DMA transfer when the program
// starts up.
//
// The main point to note here is the use of a union to cast between
// three vectors and the actual options structure. Also, main has to
// be declared as taking three vector parameters rather than regular
// long long ints.

#include <libspe2.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "common.h"

#define N_THREADS 1

const char *spu_prog="spu-task";

task_setup_t spe_opts;

void *ppu_pthread_function(void *arg) {
  spe_context_ptr_t context = *(spe_context_ptr_t *) arg;
  unsigned int      entry   = SPE_DEFAULT_ENTRY;

  // use the SPE_RUN_USER_REGS flag to pass the address of the
  // spe_opts structure.

  spe_context_run(context,&entry,SPE_RUN_USER_REGS,
		  &spe_opts,NULL,NULL);

  pthread_exit(NULL);
}


int main (int ac, char *av[]) {

  spe_context_ptr_t     context[N_THREADS];
  pthread_t             pthread[N_THREADS];
  uint32_t              i,j,value,result;
  spe_program_handle_t *program_image;
  int                   struct_size;

  // Check that the size of task_setup_t is 48 bytes
  struct_size=sizeof(task_setup_t);
  if (struct_size == 48) {
    printf("Structure size OK: exactly 48 bytes\n");
  } else {
    printf("Sorry, but structure size (%d) != 48 bytes\n",struct_size);
    exit(1);
  }

  // set up some values in the opts structure.
  spe_opts.n=12;
  spe_opts.k=8;
  spe_opts.w=4;
  spe_opts.buf_pairs=2;
  spe_opts.host_cols=16384;
  spe_opts.spu_cols=4096;
  spe_opts.mode=SPU_SPLIT;
  spe_opts.out_values=0x0123456789abcdefll;

  // use macro to report these values
  printf ("Options values being sent to SPE:\n");
  DUMP_OPTS((&spe_opts));

  // Open the SPU image
  program_image=spe_image_open(spu_prog);
  if (!program_image) {
    printf ("Couldn't load image %s\n",spu_prog);
    return 1;
  }

  printf("Creating SPU thread: ...\n");

  for (i=0;i<N_THREADS;i++) {
    printf ("  create context\n");
    context[i] = spe_context_create(0,NULL);

    printf ("  load program\n");
    value=spe_program_load(context[i],program_image);

    // SPE_RUN_USER_REGS set in thread function above
    printf ("  create thread\n");
    pthread_create(&pthread[i],NULL,&ppu_pthread_function,&context[i]);
  }

  // shut down all SPE contexts and wait for local threads to finish
  for (i=0;i<N_THREADS;i++) {
    value=pthread_join(pthread[i],NULL);
    // printf ("Got back value %u from thread %d\n",value,i);
    spe_context_destroy(context[i]);
  }

  printf ("End of PPU thread\n");
  return 0;
} 









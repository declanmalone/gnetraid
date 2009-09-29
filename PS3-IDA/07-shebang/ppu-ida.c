/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <malloc.h>

#include "common.h"
#include "host.h"
#include "ppu-ida.h"
#include "ppu-io.h"
#include "ppu-event.h"
#include "ppu-scheduler.h"

/* Check whether we have sufficient info to start splitting */
char check_split_settings(codec_t *c) {

  if (!c->n || !c->k || !c->order || !c->w ||
      !c->nsharefiles || !c->infile || ! c->matrix )
    return 0;

  if (c->matrix_elements < c->n * c->k)
    return 0;

  return 1;
}

/* check same for combine */
char check_combine_settings(codec_t *c) {

  if (!c->n || !c->k || !c->order || !c->w ||
      !c->nsharefiles || !c->outfile || !c->inverse)
    return 0;

  if (c->inverse_elements < c->k * c->k)
    return 0;

  return 1;
}

// routines for calculating the optimum buffer sizes for SPE

//
// lowest common multiple routine is needed to find a block size which
// is a multiple of k, n and 16 (ensures that both input and output
// matrix chunks start and end on a 16-byte boundary). The lcm routine
// works by calling the greatest common divisor routine.
//
static unsigned gcd(unsigned a, unsigned  b) {
  unsigned t;
  while(b) {
    t = b;
    b = a % b;
    a = t;
  }
  return a;
}

static unsigned lcm(unsigned a, unsigned b) {
  return ((a / gcd(a,b)) * b);
}

// Actually, more than just ensuring that the extents of each
// submatrix are aligned to a 16-byte boundary, we have to ensure that
// each row in a rowwise matrix is aligned on a 16-byte boundary. This
// routine takes the k and n values for the transform and calculates
// the optimium (maximum) number of columns which satisfies these
// alignment conditions while not exceeding the max_space parameter.
//
// In addition to the n, k values, the routine takes a buf_pairs
// parameter which specifies how many pairs of input (k rows) and
// output (n rows) buffers are expected to be allocated in the
// SPE. This will be set to 1 for a single-buffered process, 2 for
// double-buffered process, or greater for a multi-buffered SPE
// process.
//
// The optimum number of columns is returned.
//
// TODO: in the case where the size of the input file is known (by
// being passed in in the range_start, range_next fields), and that
// size is relatively small (compared to allocated space in each SPE)
// then either reduce the number of SPEs to use (thus saving the
// overhead of starting SPE programs that will never get any work to
// do) or use a smaller block size than will fit in a single SPE. In
// either solution, we'd have to introduce the concept of a "minimal
// useful block size" below which we wouldn't try to split the input
// over several SPEs.

static unsigned
optimum_columns(unsigned k, unsigned n, unsigned w, 
		unsigned buf_pairs, unsigned max_space) {
  unsigned min_cols, max_times, space_needed;

  /*
    calculate the minimal number of columns needed to satisfy
    alignment. Then, how much space does this actually take up in each
    SPE?
  */
  min_cols=lcm(lcm(k,n),16);
  space_needed=(min_cols * w) * (k + n) * buf_pairs;

  /*
    sanity check max_space (estimating available data space after
    program installation), and check whether the required number of
    buffer pairs of min_cols can actually fit in the allotted
    space. The first check is needed since max_space is unsigned and
    without an explicit size check, the second test could fail if
    (SPU_MAX_SPACE - max_space) was less than zero.

    TODO: in the event that the SPE code is embedded in the PPE
    program, the PPE program can query the image size of the SPE
    program and use that to get a better estimate of how much space
    should be usable for table space (with appropriate estimates for
    other storage structures/stack/etc). That code should be
    implemented on the PPE side, but I'm documenting it here because
    this is currently where the determination of buffer sizes takes
    place.

  */
  if (max_space >= SPU_MAX_SPACE)
    return 0;
  if (SPU_MAX_SPACE - max_space < SPU_MAX_CODE)
    return 0;
  if (space_needed > max_space)
    return 0;

  /* how many times can min_cols' worth of data fit into max_space? */
  max_times=max_space / space_needed;

  return min_cols * max_times;

}

// IDA split and combine have a lot in common. These two routine
// factor out the common code sections, divided between common
// initialisations and then the common processing code.
static int ida_init(codec_t *c) {

  int i,rc;
  
  // clear error flags
  c -> read_thread_error      = IDA_ERR_OK;
  c -> write_thread_error     = IDA_ERR_OK;
  c -> event_thread_error     = IDA_ERR_OK;
  c -> scheduler_thread_error = IDA_ERR_OK;
  c -> ida_error              = IDA_ERR_OK;


  // calculate optimium value for spe_matrix_cols
  c -> spe_matrix_cols =
    optimum_columns(c->k, c-> n, c->w, c->spe_num_bufpairs, 
		    SPU_MAX_SPACE - SPU_MAX_CODE);

  if (c-> spe_matrix_cols == 0)
    return (c->ida_error = IDA_ERR_LCM);


  // now figure out how many multiples of spe_matrix_cols can fit in
  // the PPE memory. We only set the result in c->ppe_matrix_blocks
  // here and leave it up to the ida_split or ida_combine routines to
  // actually allocate the memory since they will have to allocate
  // different amounts of space for each buffer
  //
  c -> ppe_matrix_blocks = PPU_MAX_ALLOC /
    ((c -> k + c -> n) * c-> spe_matrix_cols * c -> w);

  if (c-> ppe_matrix_blocks == 0)
    return (c->ida_error = IDA_ERR_LCM);

  // these two values are aliases. Should delete one of them!
  c -> buffer_slots = c -> ppe_matrix_blocks;

  // allocate and initialise the buffer slot status structures now
  // that we know how many slots it should contain. Since the size of
  // the input slot status array is the same as that for the output,
  // we can roll two mallocs into one double-sized. We need separate
  // loops for initialisation, though, because input slots start with
  // semaphore value 1, while output slots start at 0.
  //
  if ((c->input_slot = 
       malloc(c->ppe_matrix_blocks * 2 * sizeof(slot_state_t))) == 0)
    return (c->ida_error = - errno);
  c->output_slot = &c->input_slot[c->ppe_matrix_blocks];

  for (i = 0; i < c->ppe_matrix_blocks; ++i) {
    c->input_slot[i].state = SLOT_EMPTY;
    c->input_slot[i].bytes = 0;
    if (sem_init(&(c->input_slot[i].sem),0,1))
      return (c->ida_error = IDA_ERR_SEM);
    c->output_slot[i].state = SLOT_EMPTY;
    c->output_slot[i].bytes = 0;
    if (sem_init(&(c->output_slot[i].sem),0,0)) 
      return (c->ida_error = IDA_ERR_SEM);
  }

  // allocate in, out matrix structures, but (again) leave allocating
  // the memory for matrix values and setting up the correct values
  // for rows and organisation to the ida_split and ida_combine
  // routines.
  //
  if ((c->in  = malloc(sizeof(gf2_matrix_t))) == 0)
    return (c->ida_error = - errno);
  if ((c->out = malloc(sizeof(gf2_matrix_t))) == 0)
    return (c->ida_error = - errno);

  c->in ->cols  = c->spe_matrix_cols * c->ppe_matrix_blocks;
  c->in ->width = c->w;
  c->out->cols  = c->spe_matrix_cols * c->ppe_matrix_blocks;
  c->out->width = c->w;


  // allocate a task queue
  c -> task_queue = malloc(sizeof(event_queue_t));
  if (c->task_queue == 0)
    return (c->ida_error = - errno);

  if (event_queue_init(c->task_queue, EVENT_QUEUE_SIZE))
    return (c->ida_error = - errno);

  // allocate mboxq array, initialise to zeros
  if ((c->mboxq = malloc(sizeof(unsigned) * c->num_spe)) == 0)
    return (c->ida_error = - errno);

  for (i=0; i < c->num_spe; ++i)
    c->mboxq[i] = 0;


  // allocate a thread list
  if ((c->thread_id = 
       malloc(sizeof(pthread_t) * (SPE_THREADS + c->num_spe))) == 0)
    return (c->ida_error = - errno);


  // allocate SPE run contexts
  if ((c->run_context = 
       malloc(sizeof(spe_context_ptr_t) * c->num_spe)) == 0)
    return (c->ida_error = - errno);
  

  // allocate SPE event array
  if ((c->spe_event = 
       malloc(sizeof(spe_event_unit_t) * c->num_spe)) == 0)
    return (c->ida_error = - errno);
  
  // allocate structure for SPE run parameters and save a reference to
  // it in a global variable so that spe_thread can access it later
  if ((rc=posix_memalign((void**)&(c->spe_run_args), 16, sizeof(task_setup_t))))
    return (c->ida_error = -rc);
  spe_opts = c->spe_run_args;

  return IDA_ERR_OK;

}

static int ida_process(codec_t *c) {

  int i, j, rc;
  uint32_t message;

  // set up remaining initial parameters for SPE (same for
  // split/combine)

  if (verbose) {
    printf("PPE: starting processing\n");
    fflush(stdout);
  }

  spe_opts->n = c->n;
  spe_opts->k = c->k;
  spe_opts->w = c->w;
  spe_opts->spe_cols   = c->spe_matrix_cols;
  // mode set by split/combine
  spe_opts->buf_pairs  = c->spe_num_bufpairs;
  spe_opts->host_cols  = c->ppe_matrix_blocks * c->spe_matrix_cols;
  // xform_values set by split/combine
  spe_opts->in_values  = (uint64_t) c->in ->values;
  spe_opts->out_values = (uint64_t) c->out->values;


  //  printf ("PPE: about to send opts:\n");
  //DUMP_OPTS(spe_opts);

  // start up each SPE program
  for (i=0; i < c->num_spe; i++) {
    printf ("  create context %d\n",i);
    c->run_context[i] = spe_context_create(SPE_EVENTS_ENABLE,NULL);

    printf ("  load program for SPE %d\n",i);
#ifdef EMBED_SPU
    rc = spe_program_load(c->run_context[i],&program_image);
#else
    rc = spe_program_load(c->run_context[i],program_image);
#endif

    printf ("  create SPE run thread %d\n",i);
    if (pthread_create(&(c->thread_id[SPE_THREADS + i]),
		       NULL,
		       &spe_thread,
		       &(c->run_context[i]))) {
      printf ("  FAIL: %s", strerror(errno));
      exit (1);
    }
  }

  printf ("SPE: number of SPEs is %d\n", c->num_spe);
  c->running_spes = c->num_spe;

  // start up event thread and scheduler thread
  c->handler = spe_event_handler_create();
  if (c->handler == NULL) {
    printf ("PPE: Failed to set up handler\n");
    return (c->ida_error = IDA_ERR_EVENT);
  }
  for (i=0; i < c->num_spe; ++i) {
    c->spe_event[i].spe      = c->run_context[i];
    c->spe_event[i].events   = SPE_EVENT_OUT_INTR_MBOX;
    c->spe_event[i].data.u32 = i;        /* which context? */

    if (spe_event_handler_register(c->handler, &c->spe_event[i])) {
      printf ("PPE: Failed to register event handler for SPE %d\n",i);
      return (c->ida_error = IDA_ERR_EVENT);
    }
  }
  
  if (pthread_create(&c->thread_id[EVENT_THREAD], NULL,
                     &event_thread, c)) {
    printf ("PPE: fail creating event thread %s", strerror(errno));
    exit (1);
  }

  if (pthread_create(&c->thread_id[SCHEDULER_THREAD], NULL,
                     &scheduler_thread, c)) {
    printf ("PPE: fail creating scheduler thread: %s", strerror(errno));
    exit (1);
  }

  // wait for scheduler thread to finish
  if (verbose) {
    printf ("PPE: waiting for scheduler to join\n");
    fflush(stdout);
  }
  rc = pthread_join(c->thread_id[SCHEDULER_THREAD], NULL);
  if (verbose) {
    printf ("PPE: scheduler has joined with rc %d\n",rc);
    fflush(stdout);
  }

  // Finish: join SPE thread and destroy run context(s)
  for (i=0; i < c->num_spe + SPE_THREADS; i++) {
    if (i == SCHEDULER_THREAD) 
      continue;
    printf ("PPE: waiting to join thread %d\n",i);
    rc = pthread_join(c->thread_id[i], NULL);
    if (i == EVENT_THREAD) 
      spe_event_handler_destroy(c->handler);
    printf ("PPE: joined thread %d, return code %u\n",i,rc);
    if (i >= SPE_THREADS) {
      spe_context_destroy(c->run_context[i - SPE_THREADS]);
    }
  }

  if (verbose) {
    printf ("PPE: End of all slave threads\n");
    fflush(stdout);
  }


  // free any memory allocated since ida_init
  for (i = 0; i < c->ppe_matrix_blocks; ++i) {
    sem_destroy(&(c->input_slot[i].sem));
    sem_destroy(&(c->output_slot[i].sem));
  }
  free(c->input_slot);

  free((void*) c->in->values);
  free((void*) c->out->values);
  free(c->in);
  free(c->out);

  // task queue
  if (sem_destroy(&(c->task_queue->full)))
    printf ("ERROR: sem_destroy failed\n");
  if (sem_destroy(&(c->task_queue->empty)))
    printf ("ERROR: sem_destroy failed\n");
  if (pthread_mutex_destroy(&(c->task_queue->lock))) 
    printf ("ERROR: pthread_mutex_destroy failed\n");
  free(c->task_queue->tasks);
  free(c->task_queue->args);
  free(c->task_queue);

  // mboxq, event, thread, run context, run_args arrays
  free(c->mboxq);
  free(c->thread_id);
  free(c->run_context); // members already destroyed above

  free(c->spe_event);
  free(c->spe_run_args);

  printf("PPE: end of processing\n");

  return 0;

}

long ida_split (codec_t *c) {
  int rc;
  
  printf("PPE: starting split\n");

  c-> current_operation = SPE_COL_ROW_ROWWISE;

  if ((rc=ida_init(c))) {
    c->ida_error = rc;
    return 0;
  }

  // split-specific initialisation

  c->in -> organisation = COLWISE;
  c->out-> organisation = ROWWISE;
  c->in -> rows = c -> k;
  c->out-> rows = c -> n;

  spe_opts->mode = SPE_COL_ROW_COLWISE;
  spe_opts->xform_values = (uint64_t) c->matrix;

  // allocate space for input/output matrices
  if ((c->in->values =
       (uint64_t) malloc(c->w * c->k * c->in->cols)) == 0)
    return (c->ida_error = - errno);
  if ((c->out->values =
       (uint64_t) malloc(c->w * c->n * c->out->cols)) == 0)
    return (c->ida_error = - errno);

  // set up single-reader/multi-writer threads

  if (pthread_create(&c->thread_id[READER_THREAD],NULL,
                     &single_reader_thread, c)) {
    printf ("PPE: fail creating single reader thread %s", strerror(errno));
    exit (1);
  }
  
  if (pthread_create(&c->thread_id[WRITER_THREAD],NULL,
                     &multi_writer_thread, c)) {
    printf ("PPE: fail creating multi writer thread: %s", strerror(errno));
    exit (1);
  }

  // call ida_process to do the work
  return (ida_process(c));
}


long ida_combine (codec_t *c) {
  int rc;
  
  printf("PPE: starting combine\n");

  c -> current_operation = SPE_ROW_COL_ROWWISE;
  c -> n = c-> k;		// needed by scheduler to calculate
				// output bytes from input bytes
  if ((rc=ida_init(c))) {
    c->ida_error = rc;
    return 0;
  }

  // combine-specific initialisation
  c->in -> organisation = ROWWISE;
  c->out-> organisation = COLWISE;
  c->in -> rows = c -> n;
  c->out-> rows = c -> k;

  spe_opts->mode = SPE_ROW_COL_COLWISE;
  spe_opts->xform_values = (uint64_t) c->inverse;

  // allocate space for input/output matrices
  if ((c->in->values =
       (uint64_t) malloc(c->w * c->n * c->in->cols)) == 0)
    return (c->ida_error = - errno);
  if ((c->out->values =
       (uint64_t) malloc(c->w * c->k * c->out->cols)) == 0)
    return (c->ida_error = - errno);

  // set up multi-reader/single-writer threads

  if (pthread_create(&c->thread_id[READER_THREAD],NULL,
                     &multi_reader_thread, c)) {
    printf ("PPE: fail creating multi  reader thread %s", strerror(errno));
    exit (1);
  }
  
  if (pthread_create(&c->thread_id[WRITER_THREAD],NULL,
                     &single_writer_thread, c)) {
    printf ("PPE: fail creating single writer thread: %s", strerror(errno));
    exit (1);
  }

  // call ida_process to do the work
  return (ida_process(c));

}  

/* Copyright (c) Declan Malone 2009 */

#ifndef PPU_CNC_H
#define PPU_CNC_H

#include "ppu-queue.h"
#include "ppu-scheduler.h"

// Command/control interpreter for host
// Also contains definition of main codec parameters struct.

// structure for holding all transform parameters and thread-related
// variables. All parameters should be stored here to avoid using
// global variables. The only thing that isn't stored here is a
// pointer to the SPE program image to load and SPE program
// parameters.
//
typedef struct {
  // basic algorithm settings
  int    k;			// quorum
  int    n;			// total number of shares
  int    order;			// field size in bits
  int    w;		        // field size in bytes
  uint32_t poly;		// all bits of the irreducible field
                                // polynomial except the high bit,
                                // which is assumed to be 1 (unused,
                                // since polynomials are hard-coded
                                // into the GF(2^x) arithmetic
                                // routines)

  // file-related info
  char*  infile;		// (input) file to be split
  char*  outfile;		// (output) file to be combined
  char*  padding;		// words to use as padding at EOF
  int    padding_elements;	// how many elements in padding?
  char** sharefiles;		// names of share files
  int    nsharefiles;		// number of elements in prev array
  int    share_header_size;	// size of share header in bytes
  OFF_T  range_start;           // must be a multiple of (k * sec_level)
  OFF_T  range_next;		// as above, 0 = until end of file

  // detailed transform info
  char*  matrix;		// rowwise transform matrix values
  int    matrix_elements;	// how many matrix elements filled?
  char*  inverse;		// rowwise inverse matrix values
  int    inverse_elements;      // how many inverse elements filled?

  // everything up to this point should be set up by the
  // command_interpreter routine. Everything after is handled by
  // ida_split or ida_combine

  // matrix buffer usage for SPE, PPE
  gf2_matrix_t *in, *out;	// PPE matrices
  int    spe_matrix_cols;	// num. columns in each SPE local
				// store matrix
  int    spe_num_bufpairs;	// how many pairs of above-sized
				// matrix buffers does SPE use?
  int    ppe_matrix_blocks;	// multiply by spe_matrix_cols to find
				// how many columns in PPE
				// input/output matrices.

  // other options
  int    timer;			// seconds between status messages
  int    num_spe;		// number of SPEs to use

  // Variables for thread use/co-ordination

  // scheduler task/event queue
  event_queue_t  *task_queue;

  // Save list of created threads. Threads will be stored in the
  // following order (even if they're not created in this order):
  //
  // 0:  scheduler thread
  // 1:  event thread
  // 2:  reader thread
  // 3:  writer thread
  // 4+: SPE threads
  //
  // See the enum later for mnemonics for these indexes
  //
  pthread_t *thread_id;

  // buffer/slot tracking for I/O threads
  // input_slot  states: EMPTY -> RUNNABLE -> RUNNING -> EMPTY
  // output_slot states: EMPTY -> RUNNING -> FLUSHING -> EMPTY|EOF
  slot_state_t *input_slot;
  slot_state_t *output_slot;
  unsigned buffer_slots;	// how many elements in above arrays?

  // event handler/callback variables
  spe_event_handler_ptr_t  handler; // handles all contexts
  spe_event_unit_t        *spe_event;

  // track running SPE state
  spe_context_ptr_t *run_context;
  volatile unsigned  running_spes;
  unsigned          *mboxq;	// num_spe elements

  // other process tracking info
  int current_operation;	// run mode, from common.h
  OFF_T current_offset;		// progress counter, updated by single
				// reader/writer threads


  // save error codes from threads (negative = copy of errno,
  // otherwise see enum of application-specific errors below)
  int  read_thread_error;
  int  write_thread_error;
  int  event_thread_error;
  int  scheduler_thread_error;
  // SPE errors (besides failure to start) handled by event thread

  // Error code from split/combine. Those routines return a long
  // indicating the number of bytes processed, so without an
  // out-of-band error signalling mechanism there's no way to
  // distinguish between an error number (eg, 0, -1) and having
  // successfully processed that many bytes (null input file, or file
  // with 0xfff..ff bytes)
  int  ida_error;

  // structure for passing parameters to SPE
  task_setup_t *spe_run_args;

} codec_t;

// mnemonics for thread indexes in thread_id array
enum { SCHEDULER_THREAD, EVENT_THREAD, READER_THREAD, 
       WRITER_THREAD, SPE_THREADS };

// enumerate some things that can go wrong with call to ida_*
enum { IDA_ERR_OK,		// no error
       IDA_ERR_PARAM,		// general parameter errors
       IDA_ERR_MALLOC,		// failed in call to malloc
       IDA_ERR_THREAD,		// failed to create thread
       IDA_ERR_SPE,		// failed to create SPE run context
       IDA_ERR_SEM,		// failed to create/use semaphore
       IDA_ERR_LCM,		// impossible to satisfy alignment
				// constraint with current parameters
       IDA_ERR_READ,		// read/write error
       IDA_ERR_WRITE,
       IDA_ERR_SHARESIZE,	// unequal share sizes (non-fatal)
       IDA_ERR_EVENT,		// some problem with event handler
				// (eg, fail to read mbox, spurious
				// return message from SPE)
};

/* codec data, functions */

void codec_reset (codec_t *c);
void command_interpreter(void);

#endif

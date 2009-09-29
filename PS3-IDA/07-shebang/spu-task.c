/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#include <spu_intrinsics.h>
#include <spu_mfcio.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

#include "common.h"
#include "spu-math.h"
#include "spu-alloc.h"
#include "spu-dma.h"
#include "spu-task.h"


// verbose flag is now a #define to allow compiler to optimise out all
// debug statements using Dead Code Elimination feature. (see
// spu-task.h)
//
// Set for extra noise: removed in favour of macro to allow compiler
// to do dead code removal (see header file for value)
// const int verbose = 0;

// matrix structures (copy of PPE structures w/o values allocation)
//
gf2_matrix_t xform;
gf2_matrix_t ppe_in;
gf2_matrix_t ppe_out;

// local buffers
volatile gf2_matrix_t *in; 
volatile gf2_matrix_t *out;
char *in_free, *out_free;


// round a number upwards to be a multiple of align bytes (use macro
// instead)
//
//uint32_t align_up (uint32_t num, int align) {
//  int pad = num % align;
//  if (pad) {
//    return num + (align - pad);
//  } else {
//    return num;
//  }
//}

// Read program parameters/main loop
// 
// The following is used to convert the registers set when using the
// spe_context_run SPE_RUN_USER_REGS option into a task_setup_t
// structure that we can read the options values from.
//
union {
  struct {
    vec_ullong2 r3;
    vec_ullong2 r4;
    vec_ullong2 r5;
  } registers;
  task_setup_t structure;
} args_structure;


int main(vec_ullong2 spe, vec_ullong2 argp, vec_ullong2 envp) {

  task_setup_t *opts;
  int       arg_errors;
  uint32_t  spe_message, ea_hi, ea_lo;
  int       dma_tag;
  int       i, j, rc;
  int       ppe_blocks;
  int       block_size, size;

  int       slot = 0;

  // temporary values to store mem/free pointers from malloc_aligned
  void *mem_ptr, *free_ptr;

  char *xform_values;

  printf ("SPE: task starting\n");

  // put args into union so we can unpack indivdual members
  args_structure.registers.r3 = spe;
  args_structure.registers.r4 = argp;
  args_structure.registers.r5 = envp;
  opts = &args_structure.structure;


  if (verbose) {
    printf ("SPE: Got args\n");
    DUMP_OPTS(opts);
  }

  // This version of the SPE task code should be able to handle any
  // valid parameters that the PPE sends our way. This changes the
  // error-checking code somewhat from the previous version.
  // 
  arg_errors = 0;
  if (opts->k <= 0)                      ++arg_errors;
  if (opts->n <= 0)                      ++arg_errors;
  if (opts->k > opts->n)                 ++arg_errors;
  if ((opts->w != 1) && (opts->w != 2) &&
      (opts->w != 4))                    ++arg_errors;
  if (LS_MATRIX_COLS % 16)               ++arg_errors;
  if ((opts->mode <= SPE_NOTHING) && 
      (opts->mode >= SPE_INVALID))       ++arg_errors;
  if (opts->buf_pairs > 2)               ++arg_errors;
  if (opts->host_cols % LS_MATRIX_COLS)  ++arg_errors;
  ppe_blocks = opts->host_cols / LS_MATRIX_COLS;

  printf ("SPE: ppe_blocks is %d\n", ppe_blocks);
  //
  // One thing we can't check is that the organisations of the
  // supplied matrices are correct (since for economy of code we just
  // get pointers to the matrix values rather than to the matrix
  // structs). We'll just have to trust that the PPE sets them up
  // correctly. We can check that the pointers are valid,
  // though. Later, we can use the mode information to tell what
  // organisations are used for the matrices.
  //
  if (!opts->xform_values)               ++arg_errors;
  if (!opts->in_values)                  ++arg_errors;
  if (!opts->out_values)                 ++arg_errors;
  if (arg_errors) {
    printf ("There was some problem with the supplied args:\n");
    DUMP_OPTS(opts);
    printf ("Local store lookup table size = %llu bytes\n",
	    (unsigned long long) gf2_info(0));
    exit (1);
  }

  // Set up our local matrix structures
  xform_values = malloc(align_up(opts->k * opts->n * opts->w,16));
  if (xform_values == 0) {
    printf ("SPE: Unable to allocate space for xform matrix\n");
    exit(1);
  }
  in = malloc(opts->buf_pairs * sizeof(gf2_matrix_t));
  if (in == 0) {
    printf ("SPE: Unable to allocate input matrices\n");
    exit(1);
  }
  out = malloc(opts->buf_pairs * sizeof(gf2_matrix_t));
  if (out == 0) {
    printf ("SPE: Unable to allocate output matrices\n");
    exit(1);
  }

  // Need to allocate different amounts of space for input/output
  // matrices depending on mode. Since we test the mode later, leave
  // allocation until then. But since I'm using malloc_aligned, I also
  // need to set up some storage space for storing addresses to pass
  // to free().
  in_free  = malloc(N_BUFS * sizeof (void*));
  out_free = malloc(N_BUFS * sizeof (void*));
  if ((in_free == 0) ||(out_free == 0)) {
    printf ("SPE: Unable to allocate pointers for freeing i/o space\n");
    exit(1);
  }
  
  // save details of main matrix in PPE memory. The main things to
  // note are number of columns and pointer to values array. The rest
  // are just stored for completeness.
  ppe_in.rows            = opts->k;
  ppe_in.cols            = opts->host_cols;
  ppe_in.width           = opts->w;
  ppe_in.alloc_bits      = FREE_NONE;
  ppe_in.values          = opts->in_values;
  ppe_out.rows           = opts->n;
  ppe_out.cols           = opts->host_cols;
  ppe_out.width          = opts->w;
  ppe_out.alloc_bits     = FREE_NONE;
  ppe_out.values         = opts->out_values;

  // Only one transform matrix ...
  xform.rows         = opts->n;
  xform.cols         = opts->k;
  xform.width        = opts->w;
  xform.organisation = ROWWISE;	/* xform is always row-wise */
  xform.alloc_bits   = FREE_NONE;
  xform.values       = (uint64_t) (uint32_t) xform_values;

  // ... but possibly multiple local in/out buffer pairs
  for (i=0; i < N_BUFS; ++i) {
    in[i].rows            = opts->k;
    in[i].cols            = LS_MATRIX_COLS;
    in[i].width           = opts->w;
    in[i].alloc_bits      = FREE_NONE;
    out[i].rows           = opts->n;
    out[i].cols           = LS_MATRIX_COLS;
    out[i].width          = opts->w;
    out[i].alloc_bits     = FREE_NONE;

    // The (uint64_t) (uint32_t) idiom above is used to suppress
    // (harmless) warnings about casting from pointer to integer of
    // different size.

    in[i].values = 0;
    out[i].values = 0;

    // determine organisation of input/output matrices from mode
    switch (opts->mode) {
    case SPE_ROW_COL_ROWWISE:
    case SPE_ROW_COL_COLWISE:
    case SPE_ROW_COL_REORG:
    case SPE_ROW_COL_REORG_ROW:
    case SPE_ROW_COL_REORG_COL:
      in[i].organisation  = ROWWISE;
      out[i].organisation = COLWISE;
      rc=malloc_aligned(opts->n * opts->w * opts->spe_cols, 16,
			&mem_ptr,&free_ptr);
      in[i].values = (uint32_t) mem_ptr;
      in_free[i]   = (uint32_t) free_ptr;
      if (rc || !in[i].values) {
	printf ("SPE: Failed to allocate local input matrix values\n");
	exit (1);
      }
      rc=malloc_aligned(opts->k * opts->w * opts->spe_cols, 16,
		     &mem_ptr, &free_ptr);
      out[i].values = (uint32_t) mem_ptr;
      out_free[i]   = (uint32_t) free_ptr;
      if (rc || !out[i].values) {
	printf ("SPE: Failed to allocate local input matrix values\n");
	exit (1);
      }
      if (verbose) 
	printf ("SPE: Allocated local I/O slot %d\n",i);
      if (verbose) 
	printf ("SPE: slot %d in addr is %d, out addr is %d\n",i,
		(int) in[i].values, (int) out[i].values);
      break;
    case SPE_COL_ROW_ROWWISE:
    case SPE_COL_ROW_COLWISE:
      in[i].organisation  = COLWISE;
      out[i].organisation = ROWWISE;
      rc=malloc_aligned(opts->k * opts->w * opts->spe_cols, 16,
			&mem_ptr, &free_ptr);
      in[i].values = (uint32_t) mem_ptr;
      in_free[i]   = (uint32_t) free_ptr;
      if (rc || !in[i].values) {
	printf ("SPE: Failed to allocate local input matrix values\n");
	exit (1);
      }
      rc=malloc_aligned(opts->n * opts->w * opts->spe_cols, 16,
			&mem_ptr, &free_ptr);
      out[i].values = (uint32_t) mem_ptr;
      out_free[i]   = (uint32_t) free_ptr;
      if (rc || !out[i].values) {
	printf ("SPE: Failed to allocate local input matrix values\n");
	exit (1);
      }
      if (verbose) 
	printf ("SPE: Allocated local I/O slot %d\n",i);
      if (verbose) 
	printf ("SPE: slot %d in addr is %d, out addr is %d\n",i,
		(int) in[i].values, (int) out[i].values);
      break;
    default:
      printf ("SPE: mode %d not handled yet\n",opts->mode);
      exit(1);
    }
  }

  if (verbose) {
    printf("SPE: about to transfer xform values, addr is %llu\n",
	   opts->xform_values);
  }


  // DMA in the transform matrix values from main memory.
  // number of bytes needs to be aligned up to be a multiple of 16 bytes
  ea_lo = (uint32_t) opts->xform_values;
  ea_hi = opts->xform_values >> 32;
  dma_tag = 1;
  spu_mfcdma64(xform_values, ea_hi, ea_lo, 
	       align_up(xform.rows * xform.cols * xform.width,16),
	       dma_tag, MFC_GET_CMD);
  // wait for completion
  spu_writech(MFC_WrTagMask, 1 << dma_tag);
  (void) spu_mfcstat(MFC_TAG_UPDATE_ALL);

  // Print received array
  if (verbose)  {
    printf ("SPE: received xform matrix via DMA:\n\n");
    dump_matrix(&xform);
  }

  // allocate space for DMA list transfer structure
  if (spe_dma_alloc_xfer_list(opts, in, out, N_BUFS)) {
    printf("SPE: failed to allocate DMA transfer list\n");
    exit(1);
  }

  // printf ("SPE: sleeping a while\n");
  // sleep(2);
  printf ("SPE: Ready to read commands\n");

  // Double-buffered version. This is made more complicated than
  // normal double-buffering code due to the need to handle EOF
  // signals. In particular, since notifying the host of completed
  // blocks lags behind our buffer-filling and processing activities,
  // it's easy to get to a situation where we end up blocking forever
  // waiting for the next mailbox message which will never arrive
  // since we haven't yet gotten around to acknowledging the previous
  // EOF command. The solution seems to be to treat an EOF command as
  // being a flush command. Then we can temporarily suspend reading
  // new commands until we have cleared our buffers, and acknowledge
  // the EOF/flush command at the correct time. I'm also introducing
  // an extra bit of state information on each buffer: namely
  // introducing a new state to distinguish between an empty slot and
  // a "flush/eof" message.

  if (N_BUFS == 2) {
    int      itag[2] = { 0,1 };
    int      otag[2] = { 2,3 };
    uint32_t LS_FLUSH = ppe_blocks;
    uint32_t LS_EMPTY = ppe_blocks + 1;
    uint32_t in_addr [2] = { LS_EMPTY, LS_EMPTY };
    uint32_t out_addr[2] = { LS_EMPTY, LS_EMPTY };
    int      flushing = 0, workq = 0, eof = 0;
    int      cur = 1;

    in_addr[0] = spu_read_in_mbox();
    if (in_addr[0] == LS_FLUSH) {
      ++flushing; eof++;
    } else {
      (*dma_input_get_func)(opts, 0, in, in_addr[0], itag[0], MFC_GET_CMD);
      ++workq;
    }

    while (1) {

      if (verbose)
	printf("SPE: about to read next mbox\n");

      if (!flushing) {		// don't read again until all flushed
	// read-ahead next buffer. Leave eof actions until correct time 
	in_addr[cur] = spu_read_in_mbox();
	if (in_addr[cur] == LS_FLUSH) {
	  if (eof++) {
	    if (verbose)
	      printf ("SPE: Got second EOF command; exiting\n");
	    break;
	  }
	  if (verbose)
	    printf ("SPE: Got first EOF command; flushing\n");
	  ++flushing;
	} else {
	  printf ("SPE: got request to work on input block %lu\n", 
		  in_addr[cur]);
	  // schedule regular input DMA transfer and reset eof count
	  (*dma_input_get_func)(opts, cur, in, in_addr[cur], itag[cur], 
				MFC_GET_CMD);
	  ++workq;
	  if (verbose && eof)
	    printf ("SPE: waking up after FLUSH/EOF command\n");
	  eof = 0;
	}
      }

      // come back to working on current slot
      cur ^= 1;

      if (verbose)
	printf("SPE: checking output buffer flush\n");

      // combine two waits
      spe_dma_wait_mask((1 << otag[cur]) | (1 << itag[cur]));

      
      // check what to do with output buffer
      if (out_addr[cur] == LS_FLUSH) {
	if (verbose) 
	  printf ("SPE: Sending ACK EOF message\n");
	spu_write_out_intr_mbox(LS_FLUSH);
	out_addr[cur] = LS_EMPTY;
	--flushing;
      } else if (out_addr[cur] != LS_EMPTY) {
	//spe_dma_wait(otag[cur]);
	if (verbose) 
	  printf ("SPE: Sending ACK on completed work block %d\n",
		  (int) out_addr[cur]);
	spu_write_out_intr_mbox(out_addr[cur]);
	out_addr[cur] = LS_EMPTY;
	--workq;
      }

      if (verbose)
	printf("SPE: about to process input (in_addr[%d]=%lu)\n",
	       cur, in_addr[cur]);

      // check what to do with input buffer
      if (in_addr[cur] == LS_FLUSH) {
	out_addr[cur] = LS_FLUSH;
      } else if (in_addr[cur] < LS_FLUSH) {
	//  wait for pending DMA input, work on buffer, initiate
	//  output DMA and mark output buffer as flushing
	out_addr[cur] = in_addr[cur];
	// spe_dma_wait(itag[cur]);
	gf2_matrix_multiply(&xform, &in[cur], &out[cur]);
	(*dma_output_put_func)(opts, cur, out, out_addr[cur], 
			       otag[cur], MFC_PUT_CMD);
	in_addr[cur] = LS_EMPTY;
      }

      if(verbose)
	printf ("SPE: looping ...\n");

    }

    // while handling EOF above made things a little complicated, it
    // has the advantage that there's no post-processing to do, since
    // all output buffers must have been flushed before exiting the
    // loop.

    if (verbose && workq)
      printf("WARN: workq was not empty when SPE thread finished\n");

  } else {

    // single-buffered method
    printf ("WARN: using old single-buffered method as N_BUFS != 2\n");

    while (1) {
      if (verbose) printf ("SPE: waiting on mbox\n");
      spe_message = spu_read_in_mbox();

      if (verbose) printf ("SPE: asked to work on slot %u\n", spe_message);

      // Use a two-stage shutdown mechanism. The first time the host
      // sends an out-of-range value, the SPE immediately tries to
      // read another mailbox message. If another out-of-range message
      // is received, the SPE quits. Otherwise, it ignores the message
      // and continues processing the new (valid) data.
      //
      // My reason for doing this is that I think there may be some
      // problem with my event-handling code on the PPE when the SPE
      // program quits before the event handler has had a chance to
      // receive the message from the SPE acknowledging the
      // idle/shutdown message.

      if (spe_message >= ppe_blocks) {
	if (verbose) printf ("SPE: ACK idle/shutdown command\n");
	// spe_message=((uint32_t) argp << 16);
	spu_write_out_intr_mbox(spe_message); // acknowledgement 

	if (verbose) printf ("SPE: Reading from mbox\n");
	spe_message = spu_read_in_mbox();

	if (spe_message >= ppe_blocks) {
	  printf ("SPE: Got second idle/shutdown command\n");
	  break;
	} else {
	  printf ("SPE: Waking up from idle state\n");
	}
	// fall through to normal execution
      }

      // Do processing on this block
      if (verbose > 1) 
	printf ("SPE: before DMA in, local slot is %d, PPE slot is %d\n",
		slot, spe_message);
      if (verbose > 1) 
	printf ("SPE: before DMA in call, local address is %d\n",
		(uint32_t) in[slot].values);

      (*dma_input_get_func)(opts,
			    slot,
			    in,
			    spe_message,
			    1,
			    MFC_GET_CMD);
      if (verbose) 
	printf ("SPE: after DMA in call, local address is %d\n",
		(uint32_t) in[slot].values);

      if (verbose)
	printf("SPE: waiting for input DMA transfer to complete\n");
      spe_dma_wait(1);

      //    if (verbose) {
      //  printf ("SPE: got input matrix block %d\n", spe_message);
      //  dump_matrix(&in[0]);
      //}

      // do the actual matrix multiplication
      gf2_matrix_multiply(&xform,
			  &in[slot],
			  &out[slot]);

      (*dma_output_put_func)(opts,
			     slot,
			     out,
			     spe_message,
			     1,
			     MFC_PUT_CMD);
      spe_dma_wait(1);

      if (verbose) printf ("SPE: finished slot %u\n", spe_message);

      spu_write_out_intr_mbox(spe_message);

      slot = (slot + 1) % N_BUFS;

    }
  }

  printf ("SPE: shutdown\n");

  return 0;
}

/* Copyright (c) Declan Malone 2009 */

#include <spu_intrinsics.h>
#include <spu_mfcio.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

#include "common.h"
#include "spu-math.h"
#include "spu-alloc.h"

// Set for extra noise
int verbose = 0;

// Hard-code number of buffers; leave dynamic allocation for
// a later refinement
#define N_BUFS 2

// Statically allocated matrix structures
//
gf2_matrix_t xform;		// copy of PPE structures
gf2_matrix_t ppe_in;
gf2_matrix_t ppe_out;

gf2_matrix_t in   [N_BUFS];	// local buffers
gf2_matrix_t out  [N_BUFS];

char xform_values [8 * 8];
char in_values    [N_BUFS][LS_MATRIX_COLS * 8];
char out_values   [N_BUFS][LS_MATRIX_COLS * 8];

//
// DMA transfer routines
//
// Need different routines depending on whether the matrix in main
// memory is stored in row-wise or col-wise format.
//
// There are four routines that initiate the DMA for {get,put}
// {row,col} format transfers, and one routine to wait for completion
// of the transfer. This code isn't restricted to data transfers of
// less than 16 Kbytes, since it uses a transfer list to save any/all
// memory segments that need to be moved.
//
// The get/put routines access the global in/out matrix structs to
// determine the start address of the matrix values in the host memory
// and to calculate the starting address(es) of the sub-block to be
// transferred. Also, we use a global variable to a pointer to a block
// of memory to be used for the transfer list, along with a few more
// globals to segment the DMA transfer list to allow for multiple
// concurrent DMA transfers.

mfc_list_element_t *dma_xfer_list;
void *dma_xfer_list_free;	// used to free above list
int dma_row_matrix_slots;	// slots to reserve for row transfers
int dma_col_matrix_slots;	// slots to reserve for col transfers

// To avoid repeated checks on whether a matrix is a row-wise or
// col-wise one, we can check once during initialisation of the DMA
// transfer list and set up a function pointer to call the correct
// get/put routine depending on input/output matrix organisation.
// Likewise, we need to store a pointer to the structure describing
// the corresponding input/output matrices in the PPE main memory.
typedef void dma_getput_func_t (int buffer_slot,
				gf2_matrix_t *local_matrix,
				int matrix_block,
				int tag);
dma_getput_func_t *dma_input_get_func;
dma_getput_func_t *dma_output_put_func;

dma_getput_func_t spe_dma_get_rows; // forward function declarations
dma_getput_func_t spe_dma_put_rows;
dma_getput_func_t spe_dma_get_cols;
dma_getput_func_t spe_dma_put_cols;

gf2_matrix_t *ppe_rowwise, *ppe_colwise;

int spe_dma_alloc_xfer_list(gf2_matrix_t *inputs,
			    gf2_matrix_t *outputs,
			    int nbufs) {

  gf2_matrix_t *rowwise, *colwise;

  if (inputs->organisation == ROWWISE) {
    rowwise=inputs;   ppe_rowwise = &ppe_in;
    colwise=outputs;  ppe_colwise = &ppe_out;
    dma_input_get_func  = spe_dma_get_rows;
    dma_output_put_func = spe_dma_put_cols;
  } else {
    rowwise=outputs;  ppe_rowwise = &ppe_out;
    colwise=inputs;   ppe_colwise = &ppe_in; 
    dma_input_get_func  = spe_dma_get_cols;
    dma_output_put_func = spe_dma_put_rows;
  }

  // calculate how many slots to allocate for the DMA transfer list
  // based on: 
  // * colwise matrices count the number of 16Kb blocks (rounded up)
  //   in the matrix block
  // * rowwise matrices multiply the number of rows by the number of
  //   16Kb blocks needed to transfer a single row
  // * the number of buffer pairs to allocate (1=single-buffered I/O)

  dma_row_matrix_slots = rowwise->rows *
    ((LS_MATRIX_COLS * rowwise->width + 16383) / 16384);
  dma_col_matrix_slots = 
    (colwise->rows * LS_MATRIX_COLS * colwise->width + 16383) / 16384;

  // malloc apparently returns 8-byte aligned addresses, but it's
  // safer to use my own code to guarantee that.
  return
    malloc_aligned((dma_col_matrix_slots + dma_row_matrix_slots) 
		   * nbufs * sizeof(mfc_list_element_t),
		   8, (void*)&dma_xfer_list, &dma_xfer_list_free);
}

// For the following four routines:
// local_matrix: array of local matrix buffers
// buffer_slot:  which local store buffer to transfer
// matrix_block: which block of the main-memory matrix to transfer
// tag:          a DMA tag ID to use
void spe_dma_get_rows(int buffer_slot, gf2_matrix_t *local_matrix,
		      int matrix_block, int tag) {

  int      list_slot, slot;
  uint64_t ea_begin,  ea;
  int      row_size, size, r;

  row_size  = LS_MATRIX_COLS * ppe_rowwise->width;
  list_slot = (dma_row_matrix_slots + dma_col_matrix_slots) * buffer_slot;
  slot      = list_slot;
  ea_begin  = ppe_rowwise->values + row_size * matrix_block;

  for (r=0; r < ppe_rowwise->rows; ++r) {
    ea = ea_begin + r * ppe_rowwise->cols * ppe_rowwise->width;
    for (size = row_size; size > 0; size -= 16384, ea += 16384) {
      dma_xfer_list[slot].notify   = 0;
      dma_xfer_list[slot].reserved = 0;
      dma_xfer_list[slot].size     = (size > 16384) ? 16384 : size;
      dma_xfer_list[slot].eal      = ea;
      ++slot;
    }
  }

  if (verbose)
    printf ("SPE: performing list of %d dma row transfers\n",
	    dma_row_matrix_slots);

  // spu_mfcdma64(ls, ea_hi, list, size, tag, cmd)
  spu_mfcdma64((void*) (uint32_t) ((local_matrix[buffer_slot]).values),
	       mfc_ea2h(ea_begin),
	       (uint32_t) &(dma_xfer_list[list_slot]),
	       dma_row_matrix_slots * sizeof(mfc_list_element_t),
	       tag,
	       MFC_GETL_CMD);
}

void spe_dma_put_rows(int buffer_slot, gf2_matrix_t *local_matrix,
		      int matrix_block, int tag) {

  int      list_slot, slot;
  uint64_t ea_begin,  ea;
  int      row_size, size, r;

  row_size  = LS_MATRIX_COLS * ppe_rowwise->width;
  list_slot = (dma_row_matrix_slots + dma_col_matrix_slots) * buffer_slot;
  slot      = list_slot;
  ea_begin  = ppe_rowwise->values + row_size * matrix_block;

  for (r=0; r < ppe_rowwise->rows; ++r) {
    ea = ea_begin + r * ppe_rowwise->cols * ppe_rowwise->width;
    for (size = row_size; size > 0; size -= 16384, ea += 16384) {

      dma_xfer_list[slot].notify   = 0;
      dma_xfer_list[slot].reserved = 0;
      dma_xfer_list[slot].size     = (size > 16384) ? 16384 : size;
      dma_xfer_list[slot].eal      = ea;
      ++slot;
    }

  }

  // spu_mfcdma64(ls, ea_hi, list, size, tag, cmd)
  spu_mfcdma64((void*) (uint32_t) ((local_matrix[buffer_slot]).values),
	       mfc_ea2h(ea_begin),
	       (uint32_t) &(dma_xfer_list[list_slot]),
	       dma_row_matrix_slots * sizeof(mfc_list_element_t),
	       tag,
	       MFC_PUTL_CMD);

}

void spe_dma_get_cols(int buffer_slot, gf2_matrix_t *local_matrix,
		      int matrix_block, int tag) {

  int      list_slot, slot;
  uint64_t ea_begin,  ea;
  int      block_size, size;

  block_size = LS_MATRIX_COLS * ppe_colwise->rows * ppe_colwise->width;
  list_slot  = (dma_col_matrix_slots + dma_col_matrix_slots) * buffer_slot
    + dma_row_matrix_slots;
  slot       = list_slot;
  ea_begin   = ppe_colwise->values + block_size * matrix_block;

  ea = ea_begin;
  for (size = block_size; size > 0; size -= 16384, ea += 16384) {
    dma_xfer_list[slot].notify   = 0;
    dma_xfer_list[slot].reserved = 0;
    dma_xfer_list[slot].size     = (size > 16384) ? 16384 : size;
    dma_xfer_list[slot].eal      = ea;
    ++slot;
  }

  // spu_mfcdma64(ls, ea_hi, list, size, tag, cmd)
  spu_mfcdma64((void*) (uint32_t) ((local_matrix[buffer_slot]).values),
	       mfc_ea2h(ea_begin),
	       (uint32_t) &(dma_xfer_list[list_slot]),
	       dma_col_matrix_slots * sizeof(mfc_list_element_t),
	       tag,
	       MFC_GETL_CMD);
}

void spe_dma_put_cols(int buffer_slot, gf2_matrix_t *local_matrix,
		      int matrix_block, int tag) {
  int      list_slot, slot;
  uint64_t ea_begin,  ea;
  int      block_size, size;

  block_size = LS_MATRIX_COLS * ppe_colwise->rows * ppe_colwise->width;
  list_slot  = (dma_col_matrix_slots + dma_col_matrix_slots) * buffer_slot
    + dma_row_matrix_slots;
  slot       = list_slot;
  ea_begin   = ppe_colwise->values + block_size * matrix_block;

  ea = ea_begin;
  for (size = block_size; size > 0; size -= 16384, ea += 16384) {
    dma_xfer_list[slot].notify   = 0;
    dma_xfer_list[slot].reserved = 0;
    dma_xfer_list[slot].size     = (size > 16384) ? 16384 : size;
    dma_xfer_list[slot].eal      = ea;
    ++slot;
  }

  // spu_mfcdma64(ls, ea_hi, list, size, tag, cmd)
  spu_mfcdma64((void*) (uint32_t) ((local_matrix[buffer_slot]).values),
	       mfc_ea2h(ea_begin),
	       (uint32_t) &(dma_xfer_list[list_slot]),
	       dma_col_matrix_slots * sizeof(mfc_list_element_t),
	       tag,
	       MFC_PUTL_CMD);
}

void spe_dma_wait (int tag) {
  spu_writech(MFC_WrTagMask, 1 << tag);
  (void) spu_mfcstat(MFC_TAG_UPDATE_ALL);
}

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

  printf ("SPE: task starting\n");

  // put args into union so we can unpack indivdual members
  args_structure.registers.r3 = spe;
  args_structure.registers.r4 = argp;
  args_structure.registers.r5 = envp;
  opts = &args_structure.structure;

  // To keep things simple, this demo uses hard-coded parameters for
  // k, n, w (and some others). The main point is to simplify the
  // memory calculations and not have to implement arithmetic
  // operators for any field size apart from GF(2^8). The first thing
  // we do here is to check that the right parameters have been passed
  // in.
  // 
  arg_errors = 0;
  if (opts->k != 8)                      ++arg_errors;
  if (opts->n != 8)                      ++arg_errors;
  if (opts->w != 1)                      ++arg_errors;
  if (LS_MATRIX_COLS % 16)               ++arg_errors;
  if (opts->spe_cols != LS_MATRIX_COLS)  ++arg_errors;
  if ((opts->mode <= SPE_NOTHING) && 
      (opts->mode >= SPE_INVALID))       ++arg_errors;
  if (opts->buf_pairs != 1)              ++arg_errors;
  if (opts->host_cols % LS_MATRIX_COLS)  ++arg_errors;
  ppe_blocks = opts->host_cols / LS_MATRIX_COLS;
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
  xform.values       = (uint64_t) &xform_values;

  // ... but possibly multiple local in/out buffer pairs
  for (i=0; i < N_BUFS; ++i) {
    in[i].rows            = opts->k;
    in[i].cols            = LS_MATRIX_COLS;
    in[i].width           = opts->w;
    in[i].alloc_bits      = FREE_NONE;
    in[i].values          = (uint64_t) (uint32_t) &in_values[i];
    out[i].rows           = opts->n;
    out[i].cols           = LS_MATRIX_COLS;
    out[i].width          = opts->w;
    out[i].alloc_bits     = FREE_NONE;
    out[i].values         = (uint64_t) (uint32_t) &out_values[i];

    // The (uint64_t) (uint32_t) idiom above is used to suppress
    // (harmless) warnings about casting from pointer to integer of
    // different size.

    // determine organisation of input/output matrices from mode
    switch (opts->mode) {
    case SPE_ROW_COL_ROWWISE:
    case SPE_ROW_COL_COLWISE:
    case SPE_ROW_COL_REORG:
    case SPE_ROW_COL_REORG_ROW:
    case SPE_ROW_COL_REORG_COL:
      in[i].organisation  = ROWWISE;
      out[i].organisation = COLWISE; 
      break;
    case SPE_COL_ROW_ROWWISE:
    case SPE_COL_ROW_COLWISE:
      in[i].organisation  = COLWISE;
      out[i].organisation = ROWWISE;
      break;
    default:
      printf ("SPE: mode %d not handled yet\n",opts->mode);
      exit(1);
    }
  }

  // DMA in the transform matrix values from main memory.
  ea_lo = (uint32_t) opts->xform_values;
  ea_hi = opts->xform_values >> 32;
  dma_tag = 1;
  spu_mfcdma64(xform_values, ea_hi, ea_lo, 
	       xform.rows * xform.cols * xform.width,
	       dma_tag, MFC_GET_CMD);
  // wait for completion
  spu_writech(MFC_WrTagMask, 1 << dma_tag);
  (void) spu_mfcstat(MFC_TAG_UPDATE_ALL);

  // Print received array
  if (1 || verbose)  {
    printf ("SPE: received xform matrix via DMA:\n\n");
    dump_matrix(&xform);
  }

  // allocate space for DMA list transfer structure
  if (spe_dma_alloc_xfer_list(in, out, N_BUFS)) {
    printf("SPE: failed to allocate DMA transfer list\n");
    exit(1);
  }

  // printf ("SPE: sleeping a while\n");
  // sleep(2);
  printf ("SPE: Ready to read commands\n");


  while (1) {
    if (verbose) printf ("SPE: Reading from mbox\n");
    spe_message = spu_read_in_mbox();

    if (verbose) printf ("SPE: asked to work on slot %u\n", spe_message);

    // Use a two-stage shutdown mechanism. The first time the host
    // sends an out-of-range value, the SPE immediately tries to read
    // another mailbox message. If another out-of-range message is
    // received, the SPE quits. Otherwise, it ignores the message and
    // continues processing the new (valid) data.
    //
    // My reason for doing this is that I think there may be some
    // problem with my event-handling code on the PPE when the SPE
    // program quits before the event handler has had a chance to
    // receive the message from the SPE acknowledging the
    // idle/shutdown message.

    if (spe_message >= ppe_blocks) {
      if (verbose) printf ("SPE: ACK idle/shutdown command\n");
      // spe_message=((uint32_t) argp << 16);
      spu_write_out_intr_mbox(spe_message); /* acknowledgement */

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

    (*dma_input_get_func)(0,
			  in,
			  spe_message,
			  1);
    spe_dma_wait(1);

    if (verbose) {
      printf ("SPE: got input matrix block %d\n", spe_message);
      dump_matrix(&in[0]);
    }

#ifdef LAZY_TEST
    // just copy input matrix to output and DMA that back
    for (i=0; (i < in->rows) && (i < out->rows); ++i) {
      for (j=0; j < LS_MATRIX_COLS * in->width; ++j) {
	((char*)out->values)[i * LS_MATRIX_COLS * in->width + j] =
	  ((char*)in->values)[i * LS_MATRIX_COLS * in->width + j];
      }
    }
#endif

    // do the actual matrix multiplication
    gf2_matrix_multiply_u8(&xform,
			   0x1b,
			   &in,
			   &out);

    (*dma_output_put_func)(0,
			   out,
			   spe_message,
			   1);
    spe_dma_wait(1);

    if (verbose) printf ("SPE: finished slot %u\n", spe_message);

    spu_write_out_intr_mbox(spe_message);

  }

  printf ("SPE: shutdown\n");

  return 0;
}

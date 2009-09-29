/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */


// DMA transfer routines
//
// Different routines depending on whether the matrix in main memory
// is stored in row-wise or col-wise format.
//
// There are two routines that initiate the DMA for get/put row or col
// format transfers, and two routines to wait for completion of the
// transfer. This code isn't restricted to data transfers of less than
// 16 Kbytes, since it uses a transfer list to save any/all memory
// segments that need to be moved. For the non-list-DMA transfers,
// care is also taken to ensure that each individual transfer is no
// more than 16K.
//
// There is a single get/put function in each class (rowwise/colwise),
// with determination of whether a get/put operation being made by the
// user passing in a mode parameter, which should be MFC_GET or
// MFC_PUT (or similar, for list/fenced/barriered transfers)
//
// The get/put routines access the global in/out matrix structs to
// determine the start address of the matrix values in the host memory
// and to calculate the starting address(es) of the sub-block to be
// transferred. Also, we use a global variable to a pointer to a block
// of memory to be used for the transfer list, along with a few more
// globals to segment the DMA transfer list to allow for multiple
// concurrent DMA transfers.

#include <stdio.h>

#include "spu-alloc.h"
#include "spu-task.h"
#include "spu-dma.h"
#include "spu-matrix.h"

mfc_list_element_t *dma_xfer_list;
void *dma_xfer_list_free;	// used to free above list
int dma_row_matrix_slots;	// slots to reserve for row transfers
int dma_col_matrix_slots;	// slots to reserve for col transfers

dma_getput_func_t *dma_input_get_func;
dma_getput_func_t *dma_output_put_func;

dma_getput_func_t spe_dma_getput_rows; // forward function declarations
dma_getput_func_t spe_dma_getput_cols;

gf2_matrix_t *ppe_rowwise, *ppe_colwise;

int spe_dma_alloc_xfer_list(task_setup_t *opts,
			    gf2_matrix_t *inputs,
			    gf2_matrix_t *outputs,
			    int nbufs) {

  gf2_matrix_t *rowwise, *colwise;

  if (inputs->organisation == ROWWISE) {
    rowwise=inputs;   ppe_rowwise = &ppe_in;
    colwise=outputs;  ppe_colwise = &ppe_out;
    dma_input_get_func  = spe_dma_getput_rows;
    dma_output_put_func = spe_dma_getput_cols;
  } else {
    rowwise=outputs;  ppe_rowwise = &ppe_out;
    colwise=inputs;   ppe_colwise = &ppe_in; 
    dma_input_get_func  = spe_dma_getput_cols;
    dma_output_put_func = spe_dma_getput_rows;
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


  if (verbose >1) {
    printf ("SPE: dma_row_matrix_slots is %d\n", dma_row_matrix_slots);
    printf ("SPE: dma_col_matrix_slots is %d\n", dma_col_matrix_slots);
    printf ("SPE: Trying to allocate 8 bytes x %d for DMA xfer list\n",
	    (dma_col_matrix_slots + dma_row_matrix_slots) 
	    * nbufs);
  }
  return
    malloc_aligned((dma_col_matrix_slots + dma_row_matrix_slots) 
		   * nbufs * sizeof(mfc_list_element_t),
		   8, (void*)&dma_xfer_list, &dma_xfer_list_free);
}

// For the following two routines:
// local_matrix: array of local matrix buffers
// local_slot:  which local store buffer to transfer
// ppe_slot: which block of the main-memory matrix to transfer
// tag:          a DMA tag ID to use
// mode: MFC_GETL[BF]_CMD or MFC_PUTL[BF]_CMD
void spe_dma_getput_rows(task_setup_t *opts,
			 int local_slot, gf2_matrix_t *local_matrix,
			 int ppe_slot, int tag, int mode) {

  int      use_list, list_slot, slot;
  uint64_t ea_begin,  ea;
  int64_t  size;
  int      row_size, r, count = 0;

  // I suspect that the problem I'm having with my double-buffered
  // code is related to using DMA lists. Rather than use conditional
  // compilation to select between direct and list-based DMA, I'll
  // check the passed mode, and if it's a list-oriented operation,
  // I'll use the list. Otherwise, I'll do each DMA transfer
  // individually. Turns out that this was the problem... probably
  // happens when multiple DMA requests are outstanding and one of the
  // list's effective addresses straddles a 32-bit page boundary.
  if ((mode == MFC_PUTL_CMD)  || (mode == MFC_GETL_CMD) ||
      (mode == MFC_PUTLF_CMD) || (mode == MFC_GETLF_CMD) || 
      (mode == MFC_PUTLB_CMD) || (mode == MFC_GETLB_CMD) ) {
    use_list=1;
  } else if ((mode == MFC_PUT_CMD)  || (mode == MFC_GET_CMD) ||
	     (mode == MFC_PUTF_CMD) || (mode == MFC_GETF_CMD) || 
	     (mode == MFC_PUTB_CMD) || (mode == MFC_GETB_CMD) ) {
    use_list=0;
  } else {
    printf ("ERROR: unrecognised mode for DMA transfer\n");
    return;
  }

  row_size  = LS_MATRIX_COLS * ppe_rowwise->width;
  list_slot = (dma_row_matrix_slots + dma_col_matrix_slots) * local_slot;
  slot      = list_slot;
  ea_begin  = ppe_rowwise->values + row_size * ppe_slot;

  for (r=0; r < ppe_rowwise->rows; ++r) {
    ea = ea_begin + r * ppe_rowwise->cols * ppe_rowwise->width;
    for (size = row_size; size > 0; size -= 16384, ea += 16384) {
      if (use_list) {
	dma_xfer_list[slot].notify   = 0;
	dma_xfer_list[slot].reserved = 0;
	dma_xfer_list[slot].size     = (size > 16384) ? 16384 : size;
	dma_xfer_list[slot].eal      = (uint32_t) ea;
	++slot;
      } else {
	spu_mfcdma64((void*) (uint32_t)
		     local_matrix[local_slot].values + r * row_size +
		     row_size - size,
		     mfc_ea2h(ea), mfc_ea2l(ea),
		     (size > 16384) ? 16384 : size,
		     tag, mode);
      }
      ++count;
    }
  }

  if (((uint32_t) ea < (uint32_t) ea_begin))
    printf ("WARN: detected wrap-around of EAL\n");
  if (verbose && (count != dma_row_matrix_slots))
    printf ("WARN: DMA get rows used %d != %d reserved dma slots\n",
	    count, dma_row_matrix_slots);
  if (verbose)
    printf ("SPE: performing list of %d dma row transfers\n",
	    dma_row_matrix_slots);

  // spu_mfcdma64(ls, ea_hi, list, size, tag, cmd)
  if (use_list)
    spu_mfcdma64((void*) (uint32_t) local_matrix[local_slot].values,
		 mfc_ea2h(ea_begin),
		 (uint32_t) &(dma_xfer_list[list_slot]),
		 dma_row_matrix_slots * sizeof(mfc_list_element_t),
		 tag, mode);
}


void spe_dma_getput_cols(task_setup_t *opts,
			 int local_slot, gf2_matrix_t *local_matrix,
			 int ppe_slot, int tag, int mode) {

  int      use_list, list_slot, slot;
  uint64_t ea_begin,  ea;
  int64_t  size;
  int      block_size, count=0;

  if (verbose > 1)
    printf ("SPE: DMA: local matrix has %d rows, %d columns\n",
	    local_matrix[local_slot].rows, local_matrix[local_slot].cols);
  if (verbose > 1) 
    printf ("SPE: DMA: incoming local matrix address is %d\n",
	    (int) (local_matrix));
  if (verbose > 1) 
    printf ("SPE: DMA: incoming local matrix address is %d\n",
	    (int) (&local_matrix[local_slot]));
  if (verbose > 1) 
    printf ("SPE: DMA: incoming local address to transfer to is %ld\n",
	    (long) (local_matrix[local_slot].values));

  if ((mode == MFC_PUTL_CMD)  || (mode == MFC_GETL_CMD) ||
      (mode == MFC_PUTLF_CMD) || (mode == MFC_GETLF_CMD) || 
      (mode == MFC_PUTLB_CMD) || (mode == MFC_GETLB_CMD) ) {
    use_list=1;
  } else if ((mode == MFC_PUT_CMD)  || (mode == MFC_GET_CMD) ||
	     (mode == MFC_PUTF_CMD) || (mode == MFC_GETF_CMD) || 
	     (mode == MFC_PUTB_CMD) || (mode == MFC_GETB_CMD) ) {
    use_list=0;
  } else {
    printf ("ERROR: unrecognised mode for DMA transfer\n");
    return;
  }

  block_size = LS_MATRIX_COLS * ppe_colwise->rows * ppe_colwise->width;
  list_slot  = (dma_col_matrix_slots + dma_col_matrix_slots) * local_slot
    + dma_row_matrix_slots;
  slot       = list_slot;
  ea_begin   = ppe_colwise->values + block_size * ppe_slot;

  ea = ea_begin;
  for (size = block_size; size > 0; size -= 16384, ea += 16384) {
    if (use_list) {
      dma_xfer_list[slot].notify   = 0;
      dma_xfer_list[slot].reserved = 0;
      dma_xfer_list[slot].size     = (size > 16384) ? 16384 : size;
      dma_xfer_list[slot].eal      = (uint32_t) ea;
      ++slot;
    } else {
      spu_mfcdma64((void*) (uint32_t)
		   local_matrix[local_slot].values + block_size - size,
		   mfc_ea2h(ea), mfc_ea2l(ea),
		   (size > 16384) ? 16384 : size,
		   tag, mode);
    }
    ++count;
  }

  if (((uint32_t) ea < (uint32_t) ea_begin))
    printf ("WARN: detected wrap-around of EAL\n");

  if (verbose && (count != dma_col_matrix_slots))
    printf ("WARN: DMA get cols used %d != %d reserved dma slots\n",
	    count, dma_col_matrix_slots);
  if (verbose) 
    printf ("SPE: DMA PPE slot %d into local input slot %d\n",
	    ppe_slot, local_slot);
  if (verbose > 1) 
    printf ("SPE: DMA: Local address to transfer to is %d\n",
	    (int) (local_matrix[local_slot].values));

  if (use_list)
    // spu_mfcdma64(ls, ea_hi, list, size, tag, cmd)
    spu_mfcdma64((void*) (uint32_t) (local_matrix[local_slot].values),
		 mfc_ea2h(ea_begin),
		 (uint32_t) &(dma_xfer_list[list_slot]),
		 dma_col_matrix_slots * sizeof(mfc_list_element_t),
		 tag,
		 mode);
  if (verbose) 
    printf ("SPE: Initiated DMA PPE slot %d into local input slot %d\n",
	    ppe_slot, local_slot);
}

void spe_dma_wait (int tag) {
  spu_writech(MFC_WrTagMask, 1 << tag);
  (void) spu_mfcstat(MFC_TAG_UPDATE_ALL);
}

// this version assumes that the caller calculates 1 << tag first
void spe_dma_wait_mask (int mask) {
  spu_writech(MFC_WrTagMask, mask);
  (void) spu_mfcstat(MFC_TAG_UPDATE_ALL);
}


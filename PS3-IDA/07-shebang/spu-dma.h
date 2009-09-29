/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#ifndef SPU_DMA_H
#define SPU_DMA_H

#include <spu_intrinsics.h>
#include <spu_mfcio.h>

#include "common.h"

//
// DMA transfer routines
//

#include "spu-dma.h"

extern mfc_list_element_t *dma_xfer_list;
extern void *dma_xfer_list_free;	// used to free above list
extern int dma_row_matrix_slots;	// slots to reserve for row transfers
extern int dma_col_matrix_slots;	// slots to reserve for col transfers

// To avoid repeated checks on whether a matrix is a row-wise or
// col-wise one, we can check once during initialisation of the DMA
// transfer list and set up a function pointer to call the correct
// get/put routine depending on input/output matrix organisation.
// Likewise, we need to store a pointer to the structure describing
// the corresponding input/output matrices in the PPE main memory.
typedef void dma_getput_func_t (task_setup_t *opts,
				int local_slot,
				gf2_matrix_t *local_matrix,
				int ppe_slot,
				int tag, 
				int mode);
dma_getput_func_t *dma_input_get_func;
dma_getput_func_t *dma_output_put_func;


// For the following two routines:
// local_matrix: array of local matrix buffers
// buffer_slot:  which local store buffer to transfer
// matrix_block: which block of the main-memory matrix to transfer
// tag:          a DMA tag ID to use
// mode: MFC_GETL[BF]_CMD or MFC_PUTL[BF]_CMD
dma_getput_func_t spe_dma_getput_rows; // forward function declarations
dma_getput_func_t spe_dma_getput_cols;

extern gf2_matrix_t *ppe_rowwise, *ppe_colwise;

int spe_dma_alloc_xfer_list(task_setup_t *opts,
			    gf2_matrix_t *inputs,
			    gf2_matrix_t *outputs,
			    int nbufs);
void spe_dma_wait (int tag);
void spe_dma_wait_mask (int mask);

#endif

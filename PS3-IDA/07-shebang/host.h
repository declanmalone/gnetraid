/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#ifndef HOST_H
#define HOST_H

#include <libspe2.h>

#include "common.h"

// verbosity level (note verbosity on PPE side and SPE side can be set
// independently to facilitate debugging of one and not the other)
#define verbose 1

// max number of SPE available
#define TOTAL_SPE 6
#define MAX_SPE_THREADS  TOTAL_SPE
//#define MAX_SPE_THREADS  1

// how many messages can we write to SPE mailbox without blocking?
#define MBOX_QUEUE_DEPTH 4

#define OFF_T off_t

// how many pairs of input/output buffer pairs in SPE?
#define SPE_BUFFER_PAIRS  2

// The following parameters say how much space each SPE has, and how
// much of that we should reserve for code. The difference is the
// total amount of memory we have for allocating matrix buffers.

#define SPU_MAX_SPACE (256 * 1024) // 256 Kbytes, total RAM for SPE
#define SPU_MAX_CODE  (80 * 1024)  // space to reserve for SPU code,
                                   // stack and other static data

// how large a space should we allocate to input/output matrices on
// the PPU side?
#define PPU_MAX_ALLOC 0x00200000 // 2Mb, shared between in/out bufs


// size of scheduler task/event queue
#define EVENT_QUEUE_SIZE  40

// Global variables
extern task_setup_t         *spe_opts;


#ifdef EMBED_SPU
extern spe_program_handle_t program_image;
#else
const char           *spe_prog = "spu-task";
spe_program_handle_t *program_image;
#endif


// SPE thread routine
void *spe_thread(void *arg);

#endif

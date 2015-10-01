/* Copyright (c) Declan Malone 2009 */

// Reed-Solomon coding/decoding routines

#include <stdint.h>

 #ifdef QUICK_TEST
#include "common.h"		// needed for TEST_LS_MATRIX_COLS
#endif

#include "host.h"
#include "ppu-queue.h"
#include "ppu-scheduler.h"
#include "ppu-event.h"
#include "ppu-cnc.h"

#ifdef QUICK_TEST
// test values
extern char __attribute__ ((aligned (16))) xform_values[64];
char __attribute__ ((aligned (16))) inverse_values[64];

// likewise, for a quick test, it's handy to have statically allocated
// input and output matrices
char __attribute__ ((aligned (16))) in_values [IN_SIZE];
char __attribute__ ((aligned (16))) out_values[OUT_SIZE];
#endif

// Check whether we have sufficient info to start splitting
char check_split_settings(codec_t *c);

// Check same for combine
char check_combine_settings(codec_t *c);

// The actual split/combine routines
long ida_split  (codec_t *c);
long ida_combine(codec_t *c);


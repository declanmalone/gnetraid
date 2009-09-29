/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

// Reed-Solomon coding/decoding routines

#include <stdint.h>

#include "host.h"
#include "ppu-queue.h"
#include "ppu-scheduler.h"
#include "ppu-event.h"
#include "ppu-cnc.h"

// Check whether we have sufficient info to start splitting
char check_split_settings(codec_t *c);

// Check same for combine
char check_combine_settings(codec_t *c);

// The actual split/combine routines
long ida_split  (codec_t *c);
long ida_combine(codec_t *c);


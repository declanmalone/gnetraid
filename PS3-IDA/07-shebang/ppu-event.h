/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

// ppu-event.h: Event thread and related variables


#include <stdint.h>
#include <libspe2.h>

#include "host.h"

// One event handler thread per program run
void *event_thread(void * arg);


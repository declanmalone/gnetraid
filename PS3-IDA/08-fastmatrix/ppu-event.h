/* Copyright (c) Declan Malone 2009 */

// ppu-event.h: Event thread and related variables


#include <stdint.h>
#include <libspe2.h>

#include "host.h"

// One event handler thread per program run
void *event_thread(void * arg);


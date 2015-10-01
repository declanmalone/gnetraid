/* Copyright (c) Declan Malone 2009 */


// ppu-scheduler.c: main scheduler thread

// Almost all global state variables are mediated through the
// scheduler thread. Instead of other threads modifying these values
// directly, they send an appropriate message to the scheduler through
// its event queue. The scheduler then updates the global state on the
// caller's behalf

// These structures track whether slots in the input/output buffers
// are available for writing to. Both semaphores and regular flags are
// stored for the simple reason that the current value of a semaphore
// cannot be read: only wait and post (P and V) operations are
// available for it. The reader and writer threads use the semaphores
// exclusively (so they will block until the required buffer slot
// becomes available for writing/reading), while the scheduler updates
// the 'available' member and uses that info to decide whether a task
// can be scheduled (tasks are only scheduled when the input buffer
// *is not* available (ie, it is full), and the corresponding output
// buffer *is* available (ie, it is empty).

#ifndef PPU_SCHEDULER_H
#define PPU_SCHEDULER_H

#include <pthread.h>
#include <semaphore.h>
#include "host.h"

// enumerate slot statuses.
enum {
  SLOT_EMPTY, SLOT_RUNNABLE, SLOT_RUNNING, SLOT_FLUSHING, SLOT_EOF,
};

typedef struct {
  int   state;			// see enum below
  long  bytes;			// how full is this buffer?
  sem_t sem;
} slot_state_t;

// task/event names for scheduler
enum { NOP,
       READ_SLOT,  READ_EOF,   READ_ERROR,

       SPU_0_DONE, SPU_1_DONE, SPU_2_DONE,
       SPU_3_DONE, SPU_4_DONE, SPU_5_DONE,

       SPU_0_IDLE, SPU_1_IDLE, SPU_2_IDLE,
       SPU_3_IDLE, SPU_4_IDLE, SPU_5_IDLE,

       WROTE_SLOT, WRITE_ERROR,
       PING_SCHEDULER,		// test scheduler receive queue
};
extern char* event_name[];

void *scheduler_thread(void *arg);


#endif

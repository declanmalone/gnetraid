/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

// More-or-less generic multi-thread queue object. Everything except
// the type of the stored data should be the same for any other
// similar implementation.

#ifndef PPU_QUEUE_H
#define PPU_QUEUE_H

#include <stdint.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdlib.h>

typedef struct event_queue {
  sem_t    full;		/* how many slots are full? */
  sem_t    empty;		/* how many slots are empty? */
  pthread_mutex_t lock;		/* lock for atomic updates */
  unsigned head;		/* higher memory location */
  unsigned tail;		/* lower memory location */
  unsigned size;
  uint32_t *tasks;
  uint32_t *args;
} event_queue_t;

// return 0 on success, -1 and sets errno otherwise
int event_queue_init (event_queue_t *q, unsigned size);

// Use Perl style naming for unshift/shift/push/pop operations
// LIFO operation: use push/pop or unshift/shift combination
// FIFO operation: use unshift/pop or push/shift combination
// shift/unshift happen at tail, push/pop happen at head

// unshift: insert an entry at tail of queue
void event_queue_unshift(event_queue_t *q, uint32_t task, uint32_t arg);

// shift: remove an entry from tail of queue
void event_queue_shift(event_queue_t *q, uint32_t *task, uint32_t *arg);

// push: insert an entry at head of queue
void event_queue_push(event_queue_t *q, uint32_t task, uint32_t arg);

// pop: remove an entry from head of queue
void event_queue_pop(event_queue_t *q, uint32_t *task, uint32_t *arg);

#endif

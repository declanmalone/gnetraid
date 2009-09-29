/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#include "ppu-queue.h"

// return 0 on success, -1 and sets errno otherwise
int event_queue_init (event_queue_t *q, unsigned size) {

  // q must already have been allocated
  if (q == NULL) return -1;

  // allocate memory for the tasks and args arrays
  q->tasks=malloc(size * sizeof(uint32_t));
  if (q->tasks == NULL) return -1;

  q->args=malloc(size * sizeof(uint32_t));
  if (q->args == NULL) return -1;

  // set head and tail pointers
  q->head = 0; q->tail = 0;

  // set up full semaphore with initial value 0, shared between threads
  if (sem_init(&(q->full), 0, 0)) return -1;

  // set up empty semaphore with initial value size, shared between threads
  if (sem_init(&(q->empty), 0, size)) return -1;

  // set up mutex for atomic update of head, tail pointers
  pthread_mutex_init(&(q->lock),NULL);

  // save queue size
  q->size=size;

  return 0;
}

// Use Perl style naming for unshift/shift/push/pop operations
// LIFO operation: use push/pop or unshift/shift combination
// FIFO operation: use unshift/pop or push/shift combination
// shift/unshift happen at tail, push/pop happen at head

// unshift: insert an entry at tail of queue
void event_queue_unshift(event_queue_t *q, uint32_t task, uint32_t arg) {

  sem_wait(&(q->empty));
  pthread_mutex_lock(&q->lock);

  q->tail = (q->tail - 1) % q->size;
  q->tasks[q->tail]=task;
  q->args [q->tail]=arg;

  pthread_mutex_unlock(&(q->lock));
  sem_post(&(q->full));

  return;
}

// shift: remove an entry from tail of queue
void event_queue_shift(event_queue_t *q, uint32_t *task, uint32_t *arg) {

  sem_wait(&(q->full));
  pthread_mutex_lock(&(q->lock));
  //  {
  //    printf ("\bevent_queue_shift: failed to grab mutex \n");
  //  }

  *task = q->tasks[q->tail];
  *arg  = q->args [q->tail];
  q->tail = (q->tail + 1) % q->size;

  pthread_mutex_unlock(&(q->lock));
  sem_post(&(q->empty));

  return;
}

// push: insert an entry at head of queue
void event_queue_push(event_queue_t *q, uint32_t task, uint32_t arg) {

  sem_wait(&(q->empty));
  pthread_mutex_lock(&(q->lock));

  q->tasks[q->head]=task;
  q->args [q->head]=arg;
  q->head = (q->head + 1) % q->size;

  pthread_mutex_unlock(&(q->lock));
  sem_post(&(q->full));

  return;
}

// pop: remove an entry from head of queue
void event_queue_pop(event_queue_t *q, uint32_t *task, uint32_t *arg) {

  sem_wait(&(q->full));
  pthread_mutex_lock(&(q->lock));

  q->head = (q->head - 1) % q->size;
  *task = q->tasks[q->head];
  *arg  = q->args [q->head];

  pthread_mutex_unlock(&(q->lock));
  sem_post(&(q->empty));

  return;
}


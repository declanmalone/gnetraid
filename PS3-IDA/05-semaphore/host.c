/* Copyright (c) Declan Malone 2009 */

#include <libspe2.h>
#include <pthread.h>
#include <semaphore.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

// This demo is intended to show how to use semaphores on the PPE side
// to co-ordinate between independent reader, writer and SPE execution
// threads. It extends the event demo somewhat on the PPE side, but
// cuts down SPE-side functionality to a bare minimum.
//

#include "common.h"

#define VOLATILE
#define BUFFER_SLOTS  18	/* >0 OK */
#define NUM_SPE 6		/* >6 won't work */
#define MBOX_QUEUE_DEPTH 4	/* >4 OK, but not advised */
#define EVENT_QUEUE_SIZE 18	/* >0 OK */

// I was having problems with reading/writing the number of running
// SPEs, so I'm wrapping accesses to it using a mutex and function
// call. In retrospect, this shouldn't be needed ...
pthread_mutex_t running_spes_lock; /* atomic writes *and* reads */
volatile int running_spes=0;

int atomic_int_init(pthread_mutex_t *lock, volatile int *var, int val) {
  if (pthread_mutex_init(lock,NULL)) {
    return -1;
  }
  *var=val;
  return 0;
}

int atomic_int_add(pthread_mutex_t *lock, volatile int *var, int val) {
  int v;
  if (pthread_mutex_lock(lock)) {
    printf ("Failed to get mutex lock on atomic int\n");
    exit (1);
  }
  *var += val;
  v=*var;
  pthread_mutex_unlock(lock);
  return v;
}

int atomic_int_read(pthread_mutex_t *lock, volatile int *var) {
  int v;
  if (pthread_mutex_lock(lock)) {
    printf ("Failed to get mutex lock on atomic int\n");
    exit (1);
  }
  v=*var;
  pthread_mutex_unlock(lock);
  return v;
}

void atomic_int_destroy(pthread_mutex_t *lock, int *var, int val) {
  if (pthread_mutex_destroy(lock)) {
    printf ("Failed to free mutex lock on atomic int\n");
    exit(1);
  }
}


const char *spu_prog="spu-task";


// More-or-less generic multi-thread queue object. Everything except
// the type of the stored data should be the same for any other
// similar implementation.

typedef VOLATILE struct event_queue {
  sem_t full;			/* how many slots are full? */
  sem_t empty;			/* how many slots are empty? */
  pthread_mutex_t lock;		/* lock for atomic updates */
  unsigned head;		/* "higher" memory location */
  unsigned tail;		/* "lower" memory location */
  unsigned size;
  uint32_t *tasks;
  uint32_t *args;

} event_queue_t;

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

// task/event names for scheduler
enum { NOP,
       READ_SLOT,  READ_EOF,   READ_ERROR, 
       SPU_0_DONE, SPU_1_DONE, SPU_2_DONE,
       SPU_3_DONE, SPU_4_DONE, SPU_5_DONE,
       SPU_0_IDLE, SPU_1_IDLE, SPU_2_IDLE,
       SPU_3_IDLE, SPU_4_IDLE, SPU_5_IDLE,
       WROTE_SLOT, WRITE_ERROR
};
char* event_name[]= { // easier debugging/reporting
  "NOP",
  "READ_SLOT",  "READ_EOF"  , "READ_ERROR", 
  "SPU_0_DONE", "SPU_1_DONE", "SPU_2_DONE",
  "SPU_3_DONE", "SPU_4_DONE", "SPU_5_DONE",
  "SPU_0_IDLE", "SPU_1_IDLE", "SPU_2_IDLE",
  "SPU_3_IDLE", "SPU_4_IDLE", "SPU_5_IDLE",
  "WROTE_SLOT", "WRITE_ERROR"
};

// Global variable

// By allocating the same number of input/output buffer slots it lets
// us use a single address to refer to a pair of buffers.
VOLATILE uint16_t in_buf [BUFFER_SLOTS];
VOLATILE uint16_t out_buf[BUFFER_SLOTS];

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

// enumerate slot statuses. Since there's only a single reader and
// writer thread there's no need to mark slots as "currently being
// filled by reader" or "currently being emptied by writer". If we had
// multiple readers, we'd have to introduce a new reader state between
// EMPTY and RUNNABLE to indicate reservation by one reader
// thread. Likewise, for multiple writer threads, we'd need a new
// state between RUNNING and FLUSHING (?)
enum {
  SLOT_EMPTY, SLOT_RUNNABLE, SLOT_RUNNING, SLOT_FLUSHING, SLOT_EOF,
};

VOLATILE struct {
  int state;		/* EMPTY -> RUNNABLE -> RUNNING */
  sem_t sem;
} input_buffers[BUFFER_SLOTS];

VOLATILE struct {
  int state;		/* EMPTY -> RUNNING -> FLUSHING */
  sem_t sem;
} output_buffers[BUFFER_SLOTS];


// Some stuff needs to be global for our event watching threads
spe_context_ptr_t     context[NUM_SPE];
pthread_t             pthread[NUM_SPE + 4];

// event handler stuff
spe_event_handler_ptr_t handler; // one callback for all contexts
spe_event_unit_t        event[NUM_SPE];

// global task queue
event_queue_t task_queue;
unsigned mboxq[6] = { 0,0,0,0,0,0 };


// thread routines

VOLATILE unsigned scheduler_running=0;
VOLATILE unsigned reader_running=0;
VOLATILE unsigned writer_running=0;

void schedule_task(unsigned *readq, unsigned *workq, 
		   uint16_t addr, uint16_t value) {

  static int next_spe=0;
  int chosen_spe;
  int i;
  uint32_t message;

  // don't assume that a task is actually schedulable...
  if (*workq >= NUM_SPE * MBOX_QUEUE_DEPTH)        return;
  if (input_buffers[addr].state  != SLOT_RUNNABLE) return;
  if (output_buffers[addr].state != SLOT_EMPTY)    return;

  // scan list of SPEs to find one with available mbox space
  chosen_spe=NUM_SPE;	/* value signifies none chosen */
  for (i=0; i < NUM_SPE; i++) {
    if ((mboxq)[(next_spe + i) % NUM_SPE] < MBOX_QUEUE_DEPTH) {
      chosen_spe=(next_spe + i) % NUM_SPE;
      break;
    }
  }
  // did we find an SPE we can send this to?
  if (chosen_spe != NUM_SPE) {
    ++(mboxq)[chosen_spe];
    ++(*workq);
    --(*readq);		/* move state from readq to workq */
    
    //printf ("scheduler: starting slot %d, value %d\n", addr, value);
    message=(((uint32_t) addr) << 16) | value;
    if (spe_in_mbox_write(context[chosen_spe],
			  &message,1,
			  SPE_MBOX_ALL_BLOCKING) == 0) {
      printf("scheduler: Couldn't schedule task. I am mortified.\n");
    }
    next_spe=(chosen_spe + 1) % NUM_SPE;
    input_buffers[addr].state  = SLOT_RUNNING;
    output_buffers[addr].state = SLOT_RUNNING;
  }

  return;
}

void *scheduler_thread(void *queue) {
  event_queue_t *q = queue;
  uint32_t event, arg;

  // keep track of some state variable here, ie running totals of
  // blocks in read, work and write queues and whether we've got eof
  // on input
  unsigned readq=0;
  unsigned writeq=0;
  unsigned workq=0;		/* total work jobs in progress */
  unsigned max_workq=NUM_SPE * MBOX_QUEUE_DEPTH;
  unsigned eof=0;
  unsigned ackq=0;		/* pending shutdown ACKs */

  int i;
  uint32_t message;
  uint16_t addr_part, val_part;

  uint32_t timestamp=0;

  // Can only run one scheduler at a time
  if (scheduler_running++) return queue;

  // event handling main loop
  while (1) {

    // block until something happens
    printf("scheduler: waiting to shift\n");
    event_queue_shift(q,&event, &arg);
    printf ("%06d: got event %d:'%s', arg %ld\n", timestamp,
        event, event_name[event], (unsigned long) arg);

    printf ("%06d: readq %d, workq %d, writeq %d, ackq %d\n", 
	    timestamp++, readq, workq, writeq, ackq);

    switch (event) {
      //    case NOP: break;

    case READ_SLOT: 

      ++readq;
      input_buffers[arg].state = SLOT_RUNNABLE;

      if ((output_buffers[arg].state == SLOT_EMPTY)
	  && (workq < max_workq))
	schedule_task(&readq, &workq, arg, in_buf[arg]);

      break;

    case READ_ERROR:

      // errno gets clobbered by (successful) semaphore operations, so
      // caller saves it and passes it in arg.
      //printf ("Read error detected: %s\n", strerror(arg));
      return queue;		/* non-zero = failure */

    case SPU_0_IDLE:    case SPU_1_IDLE:    case SPU_2_IDLE:
    case SPU_3_IDLE:    case SPU_4_IDLE:    case SPU_5_IDLE:

      // Let's take care of this here. The event thread must notify us
      // of ACKs to idle/shutdown messages
      --ackq;
      break;

    case SPU_0_DONE:    case SPU_1_DONE:    case SPU_2_DONE:
    case SPU_3_DONE:    case SPU_4_DONE:    case SPU_5_DONE:

      --workq;
      ++writeq;			/* move state from workq to writeq */

      // Sure-fire way to determine when an mbox slot is available for
      // writing is to wait for the task to complete. This isn't the
      // most effective way of utilising all our queues, but it
      // shouldn't make any difference in reality since most SPU code
      // will only use double-buffering at most, and we use the full 4
      // mailbox slots.
      mboxq[event - SPU_0_DONE]--;

      // decode messsage into address (slot number) and value parts.
      addr_part=(uint16_t) (arg >> 16);
      val_part =(uint16_t) (arg);

      //      if (addr_part >= BUFFER_SLOTS) {
      //	--running_spes;
      //	printf ("scheduler: adios SPE %d\n", event - SPU_0_DONE);
      //	break;
      //}

      //printf ("scheduler: SPU %d completed work slot %d (arg %ld)\n",
      //      event - SPU_0_DONE, addr_part, (unsigned long) arg);

      // save returned message
      out_buf[addr_part]=val_part;

      // update buffer slot states, and increment buffer semaphores so
      // that reader and writer threads can (possibly) unblock and
      // start filling/emptying the slot.
      input_buffers[addr_part].state  = SLOT_EMPTY;
      output_buffers[addr_part].state = SLOT_FLUSHING;
      sem_post(&(input_buffers [addr_part].sem));
      sem_post(&(output_buffers[addr_part].sem));

      // check whether we can schedule a new task. We know that there
      // is an SPE task queue slot available, but we have to scan
      // through the list of input/output buffers to find a slot
      // that's ready to run.
 
      for (i=1; i < BUFFER_SLOTS; ++i) {
	arg = (i + addr_part) % BUFFER_SLOTS;
	if ((input_buffers[arg].state  == SLOT_RUNNABLE) &&
	    (output_buffers[arg].state == SLOT_EMPTY)) {
	  schedule_task(&readq, &workq, arg, in_buf[arg]);
	  break;
	}
      }
 
      break;

    case READ_EOF:
    case WROTE_SLOT:

      // handle both of these together since both of them can indicate
      // that we have no more work to do.

      if (event == WROTE_SLOT) {
	--writeq;
	output_buffers[arg].state = SLOT_EMPTY;

	if ((input_buffers[arg].state == SLOT_RUNNABLE) &&
	    (workq < max_workq)) {
	  schedule_task(&readq, &workq, arg, in_buf[arg]);
	  break;
	}
      } else {
	eof=1;
      }

      // Did we just write the last buffer? If so, send first shutdown
      // signal to the SPEs, and also mark all slots in the output
      // buffer as SLOT_EOF and add one to all the corresponding
      // semaphores so that the reader can
      if (eof && !(readq || workq || writeq)) {
	//printf ("scheduler: sending EOF signals to writer\n");

	if (ackq) {
	  printf ("scheduler: somehow ackq != 0 after last WROTE_SLOT\n");
	  exit (1);
	}

	for (i=0; i < BUFFER_SLOTS; ++i) {
	  output_buffers[i].state = SLOT_EOF;
	  sem_post(&(output_buffers[i].sem));
	}

	// We also send first idle/shutdown message to each SPE at this
	// point
	for (i=0; i < NUM_SPE; ++i) {
	  message=((uint32_t) BUFFER_SLOTS) << 16;
	  printf ("scheduler: sending EOF signal to SPU %d\n",i);
	  if (spe_in_mbox_write(context[i],
				&message,1,
				SPE_MBOX_ALL_BLOCKING) == 0) {
	    printf("Couldn't send SPE shutdown command. I am mortified.\n");
	    return queue;	/* deaded */
	  }
	}
	ackq += NUM_SPE;
      }

      break;

    case WRITE_ERROR:

      printf ("Read error detected: %s\n", strerror(arg));
      return queue;		/* non-zero = failure */

    default:
      printf ("Unknown event received by scheduler: %u\n",event);
    }

    // only quit if eof and no tasks pending
    // also wait for any pending ACKS from SPEs
    i=atomic_int_read(&running_spes_lock,&running_spes);
    if (eof && !(readq || workq || writeq || ackq)) {
      int value;
      //printf ("scheduler: EOF and no pending work; shutting down\n");

      if (value=atomic_int_read(&running_spes_lock,&running_spes)) {
	printf ("scheduler: %d SPE(s) still running!\n",value);
	continue;
      }

      // send another idle/shutdown message to each SPE to shut it
      // down completely.
	for (i=0; i < NUM_SPE; ++i) {
	  message=((uint32_t) BUFFER_SLOTS) << 16;
	  printf ("scheduler: sending EOF signal to SPU %d\n",i);
	  if (spe_in_mbox_write(context[i],
				&message,1,
				SPE_MBOX_ALL_BLOCKING) == 0) {
	    printf("Couldn't send SPE shutdown command. I am mortified.\n");
	    return queue;	/* deaded */
	  }
	}

      return NULL;		/* NULL = success */
    }

    // Debug why we're going back to wait for more messages
    printf("scheduler: about to loop.. available state info:\n");
    printf ("scheduler: eof %d, readq %d, workq %d, writeq %d, ackq %d\n", 
	    eof,readq, workq, writeq,ackq);
    i=atomic_int_read(&running_spes_lock,&running_spes);
    printf ("scheduler: Number of running SPEs: %d\n",i);

  }
}

void *reader_thread(void *arg) {

  char *message=arg;
  int i;
  unsigned head = 0;

  // Can only run one reader at a time
  if (reader_running++) return arg;

  do {
    //printf ("reader: trying to lock slot %d\n",head);
    sem_wait(&(input_buffers[head].sem));
    //printf ("reader: got lock on slot %d\n",head);

    in_buf[head]=message[i];
    event_queue_push(&task_queue,READ_SLOT,head);

    head=(head+1) % BUFFER_SLOTS;
  }  while (message[i++]);

  //printf ("reader: sending EOF message and quitting\n");
  event_queue_push(&task_queue,READ_EOF,head);

  pthread_exit(arg);
  return arg;
}

void *writer_thread(void *arg) {

  char *s       = arg;
  unsigned head = 0;

  // Can only run one writer at a time
  if (writer_running++) return arg;

  while (1) {
    //printf ("writer: trying to lock slot %d\n",head);
    sem_wait(&(output_buffers[head].sem));
    //printf ("writer: got lock on slot %d\n",head);

    // use a special state of SLOT_EOF to tell writer to exit
    if (output_buffers[head].state == SLOT_EOF) {
      //printf ("writer: detected EOF; finishing\n");
      break;
    }

    *s=(char) out_buf[head];
    ++s;
    *s='\0';			/* terminate output string */

    //printf ("writer: output string is now '%s'\n", (char *)arg);

    event_queue_push(&task_queue,WROTE_SLOT,head);

    head=(head+1) % BUFFER_SLOTS;
  }

  pthread_exit(arg);
  return arg;
}

void *spu_thread(void *arg) {
  spe_context_ptr_t context = *(spe_context_ptr_t *) arg;
  unsigned int      entry   = SPE_DEFAULT_ENTRY;

  if (spe_context_run(context,&entry,0,(void*) BUFFER_SLOTS,
		      NULL,
		      NULL)) {
    printf ("SPU: spe_context_run error!\n");
    pthread_exit(arg);
  }

  printf ("SPU: thread shutdown\n");
  pthread_exit(NULL);
}

// One event handler shared among all run contexts. 
void *event_thread(void * arg) {
  
  uint32_t message;
  uint16_t addr_part, val_part;
  int      sender;
  int      timestamp = 0;
  spe_event_unit_t thisevent;

  while (atomic_int_read(&running_spes_lock,&running_spes)) {

    printf ("event: waiting for message\n");
    if (spe_event_wait(handler, &thisevent, 1, -1) < 1) {
      printf ("event: hmmm... no messages?\n");
      continue;
    }

    sender = thisevent.data.u32;

    printf ("event: message waiting from SPE %d\n", sender);
    
    spe_out_intr_mbox_read (thisevent.spe,
			    &message,
			    1,
			    SPE_MBOX_ALL_BLOCKING);
    addr_part=(uint16_t) (message >> 16);
    val_part =(uint16_t) (message);

    printf("event: Got event %4d from spe no %d: %u, %u\n", timestamp++, 
    	   sender, addr_part, val_part);

    if (addr_part >= BUFFER_SLOTS) {
      int remain=atomic_int_add(&running_spes_lock, &running_spes, -1);
      printf ("event: SPE %d ACKs idle state (%d more running)\n",
	      sender,remain);
      spe_event_handler_deregister(handler,&event[sender]);
      event_queue_push(&task_queue, SPU_0_IDLE + sender, 0);
      if (remain <=0)
	break;
    } else {
      event_queue_push(&task_queue, SPU_0_DONE + sender, message);
    }
  }
  printf("event: exiting as last SPE has said goodbye\n");
  pthread_exit(arg);
}

// Initialise buffers, semaphores and other state information (not
// just scheduler)
int scheduler_init (event_queue_t *q, unsigned queue_size) {
  int i;

  // allocate and initialise semaphores for input/output buffer slots
  // input buffer slots have a starting value 1 (available to reader
  // thread). output buffer slots have a starting value 0, so the
  // writer thread will block until the scheduler increments the
  // semaphore for the next slot after each SPU work job is done. In
  // both cases, the 'available' bit is set to indicate that the slot
  // is available for *writing* (by either the reader process or an
  // SPU task.
  for (i=0; i < BUFFER_SLOTS; ++i) {
    if (sem_init(&(input_buffers[i].sem),0,1)) return -1;
    input_buffers[i].state = SLOT_EMPTY;

    if (sem_init(&(output_buffers[i].sem),0,0)) return -1;
    output_buffers[i].state = SLOT_EMPTY;
  }

  // set up event queue
  if (event_queue_init(q,queue_size)) {
    return -1;
  }

  // use a mutex to get atomic reads/writes on number of running SPEs
  if (atomic_int_init(&running_spes_lock, &running_spes, NUM_SPE)) {
    printf ("Failed to initialise atomic lock\n");
    return -1;
  }

  return 0;
}

const char *input_string="Jackdaws love my sphinx of quartz. " 
  "Doc, note, I dissent. A fast never prevents a fatness: I diet on cod.";
// const char *input_string="cAMELcASE";
char output_string[1024];

int main (int ac, char *av[]) {

  uint32_t              i, addr, value;
  spe_program_handle_t *program_image;


  program_image=spe_image_open(spu_prog);
  if (!program_image) {
    printf ("Couldn't load image %s\n",spu_prog);
    return 1;
  }

  printf ("Setting up global scheduler state\n");
  if (scheduler_init(&task_queue, EVENT_QUEUE_SIZE)) {
    printf ("Failed to initialise global state: %s\n", strerror(errno));
    return 1;
  }

  printf ("Testing task queue\n");
  printf ("pushing values:");
  for (i=0; i < EVENT_QUEUE_SIZE; ++i) {
    event_queue_push(&task_queue, i, i);
    printf (" %d", i);
  }
  printf ("\nshifted out values:");
  for (i=0; i < EVENT_QUEUE_SIZE; ++i) {
    event_queue_shift(&task_queue,&addr,&value);
    printf (" %d", addr);
  }
  printf ("\n");
    

  printf("Creating worker threads: ...\n");

  // Set up one event handler for ALL contexts
  printf ("  set up event handler\n");
  handler = spe_event_handler_create();
  if (handler == NULL) {
    printf ("Failed to set up handler\n");
    return 1;
  }

  for (i=0;i<NUM_SPE;i++) {
    printf ("  create context %d\n",i);
    context[i] = spe_context_create(SPE_EVENTS_ENABLE,NULL);

    event[i].spe=context[i];
    event[i].events=SPE_EVENT_OUT_INTR_MBOX;
    //event[i].data.ptr=???
    event[i].data.u32=i;	/* which context? */
    if (spe_event_handler_register(handler, &event[i])) {
      printf ("Failed to register event handler for SPE %d\n",i);
      return 1;
    }

    printf ("  load program for SPE %d\n",i);
    value=spe_program_load(context[i],program_image);

    printf ("  create SPE run thread %d\n",i);
    if (pthread_create(&pthread[i],NULL,&spu_thread,&context[i])) {
      printf ("  FAIL: %s", strerror(errno));
      exit (1);
    }

  }

  printf("Starting read, write, scheduler threads\n");

  if (pthread_create(&pthread[NUM_SPE],NULL,
		     &scheduler_thread, &task_queue)) {
    printf ("FAIL: %s", strerror(errno));
    exit (1);
  }
  if (pthread_create(&pthread[NUM_SPE + 1],NULL,
		     &writer_thread, output_string)) {
    printf ("FAIL: %s", strerror(errno));
    exit (1);
  }
  if (pthread_create(&pthread[NUM_SPE + 2], NULL,
		     &reader_thread,(char*) input_string)) {
    printf ("FAIL: %s", strerror(errno));
    exit (1);
  }
  if (pthread_create(&pthread[NUM_SPE + 3], NULL,
		     &event_thread,NULL)) {
    printf ("FAIL: %s", strerror(errno));
    exit (1);
  }

  printf ("Started %d threads... main thread waiting to join\n",
	  NUM_SPE + 4);

  // Finish: join threads and destroy SPE run contexts
  for (i=0;i<NUM_SPE + 4;i++) {
    printf ("PPE: waiting to join thread %d\n",i);
    value=pthread_join(pthread[i],NULL);
    printf ("PPE: joined thread %d, return code %u\n",i,value);
    if (i < NUM_SPE) {
      spe_context_destroy(context[i]);
    }
  }

  printf ("End of all PPU slave threads\n");
  printf ("Got transformed string: '%s'\n", output_string);
  return 0;

}

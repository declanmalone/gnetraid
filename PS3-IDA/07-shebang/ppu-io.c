/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

// some of these routines have more debug code than others ...

#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

#include "host.h"
#include "ppu-ida.h"
#include "ppu-scheduler.h"
#include "ppu-io.h"

// Input/output thread routines

void* single_reader_thread (void *arg) {
  codec_t       *c = arg;
  event_queue_t *q = c->task_queue;

  int   single_fd;
  long  bytes_read = 0;
  int   slot=0;
  int   j, rc, eof = 0;

  int   n = c -> n;
  int   k = c -> k;
  int   w = c -> w;
  int   n_slots         = c -> ppe_matrix_blocks;
  int   spe_matrix_cols = c -> spe_matrix_cols;
  char *in_values       = (char*) (c -> in -> values);
  int   pad;

  /*
  if (verbose) 
    printf("reader: started single reader thread. n_slots is %d\n",n_slots);
  if (verbose) 
    printf ("reader: task queue address is %ld\n", (long) q);
  if (verbose)
    printf("reader: attempting to open infile '%s'\n",c->infile);
  */

  single_fd = open (c->infile, O_RDONLY);
  if (single_fd <= 0) {
    c->read_thread_error= -errno;
    event_queue_push(q, READ_ERROR, errno);
    return arg;
  }

  // seek to desired start position and set up current_offset variable
  if (c->range_start) {
    if (c->range_start != lseek(single_fd, c->range_start, SEEK_SET)) {
      c->read_thread_error= -errno;
      event_queue_push(q, READ_ERROR, errno);
      return arg;
    }
  }
  c->current_offset = c->range_start;

  do {
    // wait for the current input buffer slot to become available
    // before filling it
    // printf ("reader: waiting for semaphore on slot %d\n", slot);
    sem_wait(&(c->input_slot[slot].sem));
    // printf ("reader: got semaphore on slot %d\n", slot);
    // printf ("reader: going to read into array %llu\n", 
    //   (unsigned long long)in_values);

    // our input matrix is colwise, so we can try to read in the full
    // matrix slot in one go. The read might return fewer bytes than
    // requested, so we loop until we have enough data or hit EOF.
    // 
    // If range_next is set, we might have to read less than a full
    // block if we're near the end of the range. But round up the
    // number of bytes to the next multiple of k * w (rabin.pl script
    // doesn't do that for us (yet))
    bytes_read = 0;
    j          = w * spe_matrix_cols * k;
    if (c->range_next && (c->current_offset + j > c->range_next)) {
      if (verbose) {
	printf ("reader: reading fewer bytes approaching range_next\n");
	printf ("reader: range_next is %lu, j is %lu\n", c->range_next, j);
      }
      j = c->range_next - c->current_offset;
      if ((pad= j % (c->w * c->k))) {
	if (verbose) {
	  printf ("reader: We have to round up range_next\n");
	  printf ("reader: added %d bytes\n",(c->w * c->k) - pad);
	}
	j += (c->w * c->k) - pad;
      }
      if (verbose) printf ("reader: j is now %lu\n", j);
      if (j == 0)
	eof = 1;
    }
    if (verbose)
      printf ("reader: bytes to read: %lu\n", (unsigned long) j);
    while (j > 0) {
      rc=read(single_fd, 
	      &in_values[slot * w * spe_matrix_cols * k + bytes_read],
	      j
	      );
      if (rc < 0) {
	printf("reader: error %d\n",rc);
	if ((rc == -EAGAIN) || (rc == -EINTR))
	  continue;
	c->read_thread_error = errno;
	event_queue_push(q, READ_ERROR, errno);
	goto cleanup;
      } else if (rc == 0) {
	if (verbose)
	  printf("reader: eof\n");
	eof = 1;
	break;
      } else {
	bytes_read += rc;
	j -= rc;
      }
    }

    c->current_offset += bytes_read;

    // handle padding of file if we're at eof and the last read didn't
    // fill a full matrix column. Since we expect that each matrix
    // block is already aligned to k * w bytes, padding cannot
    // overflow the current slot so we add the full amount here.
    //
    if (eof && (pad = (c->current_offset % (c->k * c->w)))) {
      pad = (c->k * c->w) - pad;
      memcpy (&in_values[slot * w * spe_matrix_cols * k + bytes_read],
	      c->padding, pad);
      if (verbose)
	printf ("Padded from %lu to %lu bytes (+%d)\n", 
		(unsigned long) c->current_offset, 
		(unsigned long) c->current_offset + pad, pad);
      bytes_read += pad;
      c->current_offset += pad;
    }

    // notify scheduler that we've read in this slot
    if (verbose)
      printf("reader: read slot, bytes read %lu; notifying scheduler\n",
	     bytes_read);
    c->input_slot[slot].bytes = bytes_read;
    if (bytes_read)
      event_queue_push(q, READ_SLOT, slot);

    if (verbose)
      printf("reader: advancing to next slot\n");

    // advance to read next slot
    slot = (slot + 1) % n_slots;

  } while (!eof);

  // notify on EOF

  if (verbose)
    printf("reader: notify scheduler of eof\n");
  c->input_slot[slot].bytes = 0;
  event_queue_push(q, READ_EOF, slot);

 cleanup:
  close (single_fd);

  return 0;  
}

void* multi_reader_thread (void *arg) {
  codec_t       *c = arg;
  event_queue_t *q = c->task_queue;

  int  *share_fd;
  int   num_fd = c->nsharefiles;

  long  min_read, bytes_read = 0;
  int   slot = 0;
  int   i, j, rc, eof = 0;

  int   n = c -> n;
  int   k = c -> k;
  int   w = c -> w;
  int   n_slots         = c -> ppe_matrix_blocks;
  int   spe_matrix_cols = c -> spe_matrix_cols;
  char *in_values       = (char*) (c -> in -> values);

  if (verbose) 
    printf("reader: started multi reader thread\n");

  share_fd=malloc(num_fd * sizeof(int));
  if (share_fd == 0) {
    c->read_thread_error=errno;
    event_queue_push(q, READ_ERROR, errno);
    return arg;
  }

  for (i=0; i < num_fd; ++i) {
    share_fd[i] = open(c->sharefiles[i], O_RDONLY);
    if (share_fd[i] <= 0) {
      c->read_thread_error=errno;
      event_queue_push(q, READ_ERROR, errno);
      return arg;
    }
    lseek (share_fd[i], c->share_header_size, SEEK_SET);
  }

  do {
    // wait for the current input buffer slot to become available
    // before filling it
    if (verbose)
      printf ("writer: waiting for semaphore on slot %d\n", slot);
    sem_wait(&(c->input_slot[slot].sem));
    if (verbose)
      printf ("writer: got semaphore on slot %d\n", slot);

    // Our input matrix is rowwise, so we need to read in a separate
    // slice for each fd. We keep track of the minimum number of bytes
    // read in so that if one stream hits EOF before the others, we
    // report reading in the minimum value and emit a warning.
    min_read = w * spe_matrix_cols + 1;

    for (i=0; i < k; ++i) {

      bytes_read = 0;
      j          = w * spe_matrix_cols;
      do {
	rc=read(share_fd[i], 
		&in_values[slot * w * spe_matrix_cols +
			   i    * w * spe_matrix_cols * n_slots +
			   bytes_read
			   ],
		j);
	if (rc < 0) {
	  if ((rc == -EAGAIN) || (rc == -EINTR))
	    continue;
	  c->read_thread_error = errno;
	  event_queue_push(q, READ_ERROR, errno);
	  goto cleanup;
	} else if (rc == 0) {
	  eof ++;
	  // printf ("EOF on input\n");
	  if (bytes_read < min_read) 
	    min_read = bytes_read;
	  break;
	} else {
	  bytes_read += rc;
	  j -= rc;
	}
      } while (j > 0);
    }

    if (eof % k) {
      if (verbose)
	printf ("Detected different input stream lengths.\n");
      bytes_read = min_read;
    }

    if (verbose)
      printf ("reader: multi-read read %d rows of length %ld",
	      c->k,  bytes_read);

    // notify scheduler that we've read in this slot
    // note bytes_read is multiplied by the number of rows
    c->input_slot[slot].bytes = bytes_read * k;
    event_queue_push(q, READ_SLOT, slot);

    // advance to read next slot
    slot = (slot + 1) % n_slots;

  } while (!eof);

  c->input_slot[slot].bytes = 0;
  event_queue_push(q, READ_EOF, slot);

 cleanup:
  for (i=0; i < num_fd; ++i) {
    close (share_fd[i]);
  }
  free(share_fd);

  return 0;  

}

void * single_writer_thread (void *arg) {
  codec_t       *c = arg;
  event_queue_t *q = c->task_queue;

  int   single_fd;

  long  bytes_written, j;
  int   i, rc;
  int   slot = 0;

  int   n = c -> n;
  int   k = c -> k;
  int   w = c -> w;
  int   n_slots         = c -> ppe_matrix_blocks;
  int   spe_matrix_cols = c -> spe_matrix_cols;
  char *out_values      = (char*) (c -> out -> values);

  single_fd = open(c->outfile, O_WRONLY|O_CREAT, 0644);
  if (single_fd <= 0) {
      c->read_thread_error=errno;
      event_queue_push(q, READ_ERROR, errno);
      return arg;
  }

  // seek to correct output location, set up current_offset
  if (c->range_start) {
    if (c->range_start != lseek(single_fd, c->range_start, SEEK_SET)) {
      c->read_thread_error= -errno;
      event_queue_push(q, READ_ERROR, errno);
      return arg;
    }
  }
  c->current_offset = c->range_start;

  // output colwise matrix. Stream EOF is detected by examining the
  // buffer state, while determination of how many bytes to write is
  // done by looking at the bytes variable in the same structure.
  while (1) {
 
    // wait for next buffer slot to become ready to write
    sem_wait(&(c->output_slot[slot].sem));

    // detect EOF
    if (c->output_slot[slot].state == SLOT_EOF)
      break;

    // as with single-reader, if range_next is set, and current offset
    // is approaching it, don't write a full block. This code is a lot
    // simpler than the reader, as we don't have to worry about
    // alignment or padding.
    bytes_written = 0;
    j             = c->output_slot[slot].bytes;
    if (c->range_next && (c->current_offset + j > c->range_next)) {
      j = c->range_next - c->current_offset;
    }
    do {
      rc=write(single_fd, 
	       &out_values[slot * w * spe_matrix_cols * k + 
			   bytes_written],
	       j);
      if (rc < 0) {
	if ((rc == -EAGAIN) || (rc == -EINTR))
	  continue;
	c->read_thread_error = errno;
	event_queue_push(q, WRITE_ERROR, errno);
	goto cleanup;
      }
      bytes_written += rc;
      j             -= rc;
    } while (j > 0);

    // notify scheduler of successful write
    event_queue_push(q, WROTE_SLOT, slot);

    // move on to using next slot in local matrix
    slot = (slot + 1) % n_slots;
  }

  // writer doesn't need to notify scheduler of EOF, since it was what
  // signalled it in the first place
 cleanup:
  close (single_fd);

  return 0;
}


void* multi_writer_thread (void *arg) {
  codec_t       *c = arg;
  event_queue_t *q = c->task_queue;

  int  *share_fd;
  int   num_fd = c->nsharefiles;

  long  bytes_written, j;
  int   i, rc;
  int   slot = 0;

  int   n = c -> n;
  int   k = c -> k;
  int   w = c -> w;
  int   n_slots         = c -> ppe_matrix_blocks;
  int   spe_matrix_cols = c -> spe_matrix_cols;
  char *out_values      = (char*) (c -> out -> values);

  share_fd=malloc(num_fd * sizeof(int));
  if (share_fd == 0) {
    c->read_thread_error=errno;
    event_queue_push(q, READ_ERROR, errno);
    return arg;
  }

  for (i=0; i < num_fd; ++i) {
    share_fd[i] = open(c->sharefiles[i], O_WRONLY | O_CREAT, 0644);
    if (share_fd[i] <= 0) {
      c->read_thread_error=errno;
      event_queue_push(q, READ_ERROR, errno);
      return arg;
    }
    lseek (share_fd[i], c->share_header_size, SEEK_SET);
  }

  // output rowwise matrix (combine mode)
  while (1) {
 
    // wait for next buffer slot to become ready to write
    sem_wait(&(c->output_slot[slot].sem));

    // detect EOF
    if (c->output_slot[slot].state == SLOT_EOF)
      break;

    // bytes value needs to be divided among n rows
    for (i = 0; i < num_fd; ++i) {
      bytes_written = 0;
      j             = c -> output_slot[slot].bytes / n;
      do {
	rc=write(share_fd[i],
		 &out_values[w * spe_matrix_cols * slot +
			     w * spe_matrix_cols * n_slots * i +
			     bytes_written
			     ],
		 j);
	if (rc < 0) {
	  if ((rc == -EAGAIN) || (rc == -EINTR))
	    continue;
	  c->read_thread_error = errno;
	  event_queue_push(q, WRITE_ERROR, errno);
	  goto cleanup;
	}
	bytes_written += rc;
	j             -= rc;
      } while (j > 0);
    }

    // notify scheduler of successful write
    event_queue_push(q, WROTE_SLOT, slot);
      
    // move on to using next slot in local matrix
    slot = (slot + 1) % n_slots;
  }

  // writer doesn't need to notify scheduler of EOF, since it was what
  // signalled it in the first place

 cleanup:
  for (i=0; i < num_fd; ++i) {
    close (share_fd[i]);
  }
  free(share_fd);

  return 0;
}


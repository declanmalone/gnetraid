/* Copyright (c) Declan Malone 2009 */

#include <libspe2.h>
#include <pthread.h>
#include <semaphore.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define IDENTITY_DEBUG

// This demo is intended to show how to use DMA transfers on the SPE
// side. Overall, the demo implements a version of Reed-Solomon coding
// using Galois Field arithmetic. The host side sets up a transform
// matrix and reads in input from a file into a large buffer
// matrix. After each block of input has been read in, the host sends
// a message to the SPE which applies the transform matrix to the
// block of the larger matrix and then uses another DMA transfer to
// send the result back to the host. The host then takes each row of
// the result matrix and writes it to a separate (share) file.
//
// The reverse operation is also possible, where the host provides an
// inverted matrix to the SPE and uses the share files as input. The
// resulting output should equal the initial input file.
//
// The intention is that this example can be extended to be a
// fully-functional Reed-Solomon encoder/decoder, but in order to
// concentrate on DMA transfers various limitations are in place,
// notably:
//
// * hard-coded transform parameters (matrix size, RS parameters)
// * statically-allocated matrix buffers
// * no double-buffering in SPE task code
// * no multi-threading in host (apart from SPE thread)
// * requests run only on a single SPE
// * unoptimised matrix code on SPE side
//
// I've made some efforts towards making the code more easy to
// implement these things later, however, such as using
// multi-buffering in the host program (even though it only requests a
// single buffer's worth of work at a time), and allocation of arrays
// for double-buffering in the SPE program.

#include "common.h"

#define MATRIX_BLOCKS  2	/* >0 OK */
#define NUM_SPE 1		/* >1 not implemented */
#define MBOX_QUEUE_DEPTH 4	/* >1 not implemented */

const char *spe_prog="spu-task";

// Parameters for the RS coding (don't change)
#define OPT_N  8
#define OPT_K  8
#define OPT_W  1

// Reed-Solomon coding/decoding matrices
#ifdef IDENTITY_DEBUG

// multiplying by an identity matrix is a good way to debug the code
// since it will simply "stripe" (interleave) input bytes over several
// output files.

char __attribute__ ((aligned (16))) xform_values[64] = {
  0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
};

char __attribute__ ((aligned (16))) inverse_values[64] = {
  0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
};

#else
char __attribute__ ((aligned (16))) xform_values[64] = {
  0x35, 0x36, 0x82, 0x7A, 0xD2, 0x7D, 0x75, 0x31,
  0x0E, 0x76, 0xC3, 0xB0, 0x97, 0xA8, 0x47, 0x14,
  0xF4, 0x42, 0xA2, 0x7E, 0x1C, 0x4A, 0xC6, 0x99,
  0x3D, 0xC6, 0x1A, 0x05, 0x30, 0xB6, 0x42, 0x0F,
  0x81, 0x6E, 0xF2, 0x72, 0x4E, 0xBC, 0x38, 0x8D,
  0x5C, 0xE5, 0x5F, 0xA5, 0xE4, 0x32, 0xF8, 0x44,
  0x89, 0x28, 0x94, 0x3C, 0x4F, 0xEC, 0xAA, 0xD6,
  0x54, 0x4B, 0x29, 0xB8, 0xD5, 0xA4, 0x0B, 0x2C,
};

char __attribute__ ((aligned (16))) inverse_values[64] = {
  0x3E, 0x02, 0x23, 0x87, 0x8C, 0xC0, 0x4C, 0x79,
  0x5D, 0x2B, 0x2A, 0x5B, 0x7E, 0xFE, 0x25, 0x36,
  0xF2, 0xA9, 0xB5, 0x57, 0xA2, 0xF6, 0xA2, 0x7D,
  0x11, 0x5E, 0xE4, 0x61, 0x59, 0xF4, 0xB9, 0x42,
  0xD5, 0x16, 0xB8, 0x5B, 0x30, 0x85, 0x1E, 0x72,
  0x3B, 0xF7, 0x1B, 0x5B, 0x4C, 0x55, 0x35, 0x04,
  0x58, 0x95, 0x73, 0x33, 0x8A, 0x77, 0x1C, 0xF4,
  0x59, 0xC0, 0x7B, 0x13, 0x9F, 0x8B, 0xBE, 0xE3,
};
#endif

// statically-allocated space for I/O matrices
#define IN_SIZE  (OPT_N * OPT_W * LS_MATRIX_COLS * MATRIX_BLOCKS )
#define OUT_SIZE (OPT_K * OPT_W * LS_MATRIX_COLS * MATRIX_BLOCKS )
char __attribute__ ((aligned (16))) in_values [IN_SIZE];
char __attribute__ ((aligned (16))) out_values[OUT_SIZE];

// Global variable

// Some stuff needs to be global for our event watching threads
spe_context_ptr_t context[NUM_SPE];
pthread_t         pthread[NUM_SPE];

// Structure for initialisation of SPE
task_setup_t spe_opts;

// event handler stuff
spe_event_handler_ptr_t handler; // one callback for all contexts
spe_event_unit_t        event[NUM_SPE];

// SPE thread routine

void *spe_thread(void *arg) {
  spe_context_ptr_t context = *(spe_context_ptr_t *) arg;
  unsigned int      entry   = SPE_DEFAULT_ENTRY;

  // use the SPE_RUN_USER_REGS flag to pass the address of the
  // spe_opts structure.
  if (spe_context_run(context,&entry,SPE_RUN_USER_REGS,
		      &spe_opts,NULL,NULL)) {
    printf ("SPE: spe_context_run error!\n");
    pthread_exit(arg);
  }

  printf ("SPE: thread shutdown\n");
  pthread_exit(NULL);
}

int main (int ac, char *av[]) {

  uint32_t              i, addr, value;
  spe_program_handle_t *program_image;
  gf2_matrix_t          in, out;
  int                   recv_message[MBOX_QUEUE_DEPTH], 
    send_message[MBOX_QUEUE_DEPTH], rc;

  // file related
  char *single_file;
  int   single_fd;

  // in general, the following should have n filenames/handles for
  // split, k for combine, but we hard-code n = k = 8 to cut down on
  // work
  char *share_files[OPT_N] = {
    "share.0", "share.1", "share.2", "share.3",
    "share.4", "share.5", "share.6", "share.7",
  };
  int share_fds[OPT_N];
  int j, eof;
  unsigned long bytes_read, bytes_written, min_read;

  // Check command-line arguments to decide on mode of operation
  // (split or combine) and get a filename. In split mode, the file is
  // the input file, while in combine mode it's the output file. Share
  // file names are fixed ("share.1" and so on), so we don't need to
  // enter them.
  //
  if (ac != 3) {
    printf ("DMA demo: split/combine files using Reed-Solomon codes\n\n");
    printf ("Usage:\n host split input_file\n host combine output_file\n");
    exit (0);
  }

  program_image=spe_image_open(spe_prog);
  if (!program_image) {
    printf ("Couldn't load image %s\n",spe_prog);
    return 1;
  }

  // set up input/output matrix structures (SPE only cares about the
  // values pointer, but we could use the struct ourselves)
  in.width         = OPT_W;
  in.rows          = OPT_N;
  in.cols          = LS_MATRIX_COLS * MATRIX_BLOCKS;
  in.values        = (uint64_t) in_values;
  out.width        = OPT_W;
  out.rows         = OPT_K;
  out.cols         = LS_MATRIX_COLS * MATRIX_BLOCKS;
  out.values       = (uint64_t) out_values;

  // local initialisation: open files, set mode based on command-line
  // arguments
  //
  if (strcmp (av[1], "split") == 0) {

    single_fd = open (av[2], O_RDONLY);
    if (single_fd <= 0) {
      printf ("Couldn't open input file for split: %s\n", 
	      strerror(errno));
      exit (1);
    }
    for (i=0; i < OPT_N; ++i) {
      share_fds[i] = creat(share_files[i], 0644);
      if (share_fds[i] <= 0) {
	printf ("Couldn't open sharefile %d for writing: %s\n", 
		i, strerror(errno));
	exit (1);
      }
    }
    in.organisation  = COLWISE;
    out.organisation = ROWWISE;
    spe_opts.mode=SPE_COL_ROW_COLWISE;
    spe_opts.xform_values = (uint64_t) &xform_values;

  } else if (strcmp (av[1], "combine") == 0) {

    single_fd = creat(av[2], 0644);
    if (single_fd <= 0) {
      printf ("Couldn't open output file for combine: %s\n", 
	      strerror(errno));
      exit (1);
    }
    for (i=0; i < OPT_K; ++i) {
      share_fds[i] = open(share_files[i], O_RDONLY);
      if (share_fds[i] <= 0) {
	printf ("Couldn't open sharefile %d for reading: %s\n", 
		i, strerror(errno));
	exit (1);
      }
    }
    in.organisation  = ROWWISE;
    out.organisation = COLWISE;
    spe_opts.mode=SPE_ROW_COL_COLWISE;
    spe_opts.xform_values = (uint64_t) &inverse_values;

  } else {
    printf ("host: try 'split' or 'combine' followed by a file\n");
    exit (1);
  }

  // set up remaining initial parameters for SPE

  spe_opts.n=OPT_N;
  spe_opts.k=OPT_K;
  spe_opts.w=OPT_W;
  spe_opts.buf_pairs=1;
  spe_opts.host_cols=LS_MATRIX_COLS * MATRIX_BLOCKS;
  spe_opts.spe_cols=LS_MATRIX_COLS;
  spe_opts.in_values    = (uint64_t) &in_values;
  spe_opts.out_values   = (uint64_t) &out_values;

  printf("Creating SPE worker thread ...\n");

  for (i=0;i<NUM_SPE;i++) {
    printf ("  create context %d\n",i);
    context[i] = spe_context_create(0,NULL);

    printf ("  load program for SPE %d\n",i);
    value=spe_program_load(context[i],program_image);

    printf ("  create SPE run thread %d\n",i);
    if (pthread_create(&pthread[i],NULL,&spe_thread,&context[i])) {
      printf ("  FAIL: %s", strerror(errno));
      exit (1);
    }
  }

#ifdef QUICK_TEST
  // before reading in from file, do a quick test to show that the SPE
  // can DMA in the correct section of the input matrix

  // set up some dummy values in input matrices
  for (i=0; i < IN_SIZE; ++i) {
    in_values[i]  = i & 0xff;
  }

  for (i = 0; i <= MATRIX_BLOCKS; ++i) {
    send_message[i % MBOX_QUEUE_DEPTH] = i; // MATRIX_BLOCKS;

    printf ("PPE: sending message %d to SPE\n", i);
    if (spe_in_mbox_write(context[0],
			  &send_message[i % MBOX_QUEUE_DEPTH],
			  1,
			  SPE_MBOX_ALL_BLOCKING) == 0) {
      printf("PPE: Message could not be written\n");
      break;
    } else {
      printf ("PPE: message sent\n");
    }

    // printf ("PPE: sleeping a while\n");
    // sleep (3);

    // wait for reply (but ignore the output matrix)
    rc=spe_out_intr_mbox_read (context[0], 
			       &recv_message[i %MBOX_QUEUE_DEPTH],
			       1, SPE_MBOX_ALL_BLOCKING);
    printf ("PPE: got reply %d\n", recv_message[i % MBOX_QUEUE_DEPTH]);
  }

  printf ("PPE: output matrix dump\n");
  dump_matrix(&out);
#endif

  // main loop

  eof=0; addr=0;
  if (strcmp (av[1], "split") == 0) {

    // SPLIT

    do {
      // addr is the slot number of our local matrix. We want to read
      // in a full slot's worth of data before telling the SPE to
      // operate on it. If we don't get enough bytes, we keep reading
      // some more until we get the EOF return from read.

      // our input matrix is colwise, so we can try to read in the
      // full matrix slot. read might return fewer bytes than
      // requested, so this is done in a loop.
      bytes_read = 0;
      j          = OPT_W * LS_MATRIX_COLS * OPT_K;
      do {
	rc=read(single_fd, 
		&in_values[addr * OPT_W * LS_MATRIX_COLS * OPT_K + 
			   bytes_read],
		j
		);
	if (rc < 0) {
	  printf ("Read error on input: %s\n", strerror(errno));
	  exit (1);
	}
	if (rc == 0) {
	  eof = 1;
	  printf ("EOF on input\n");
	  break;
	} else {
	  bytes_read += rc;
	  j -= rc;
	}
      } while (j > 0);

      if (bytes_read) {
	// first notify SPE of work needed
	if (spe_in_mbox_write(context[0],
			      &addr,
			      1,
			      SPE_MBOX_ALL_BLOCKING) == 0) {
	  printf("PPE: Message could not be sent to SPE\n");
	  exit (1);
	}

	// next wait until it replies
	rc=spe_out_intr_mbox_read (context[0], 
				   &recv_message[0],
				   1, SPE_MBOX_ALL_BLOCKING);
	if (addr != recv_message[0]) {
	  printf ("Expected SPE to respond with same address!\n");
	  exit (1);
	}

	// now write one row of returned output matrix to each output
	// file. If we reached EOF before filling the full slot, we
	// round up bytes_read. As with read, write can also write
	// fewer bytes than requested, so we loop until all of them
	// are put out.
	j = (bytes_read + OPT_K - 1) / OPT_K;
	for (i=0; i < OPT_K; ++i) {
	  bytes_written = 0;
	  do {
	    rc=write(share_fds[i], 
		     &out_values[addr * OPT_W * LS_MATRIX_COLS +
				 i * OPT_W * MATRIX_BLOCKS * LS_MATRIX_COLS +
				 bytes_written
				 ],
		     j);
	    if (rc < 0) {
	      printf ("write error on output: %s\n", strerror(errno));
	      exit (1);
	    }
	    bytes_written += rc;
	  } while (bytes_written < j);
	}
      }
      addr = (addr + 1) % MATRIX_BLOCKS;
    } while (!eof);

  } else if (strcmp (av[1], "combine") == 0) {

    // COMBINE

    do {
      // The input matrix for split is rowwise
      min_read = OPT_W * LS_MATRIX_COLS + 1;

      for (i=0; i < OPT_K; ++i) {
	bytes_read = 0;
	j          = OPT_W * LS_MATRIX_COLS * OPT_K;
	do {
	  rc=read(share_fds[i], 
		  &in_values[addr * OPT_W * LS_MATRIX_COLS +
			     i * OPT_W * MATRIX_BLOCKS * LS_MATRIX_COLS +
			     bytes_read
			     ],
		  j);
	  if (rc < 0) {
	    printf ("Read error on input: %s\n", strerror(errno));
	    exit (1);
	  }
	  if (rc == 0) {
	    eof ++;
	    if (bytes_read < min_read) 
	      min_read = bytes_read;
	    break;
	  } else {
	    bytes_read += rc;
	    j          -= rc;
	  }
	} while (j > 0);
      }

      // were all input streams of the same length?
      if (eof % OPT_K) {
	printf ("Detected different input stream lengths.\n");
	bytes_read = min_read;
      }

      if (bytes_read) {
	// first notify SPE of work needed
	if (spe_in_mbox_write(context[0],
			      &addr,
			      1,
			      SPE_MBOX_ALL_BLOCKING) == 0) {
	  printf("PPE: Message could not be sent to SPE\n");
	  exit (1);
	}

	// next wait until it replies
	rc=spe_out_intr_mbox_read (context[0], 
				   &recv_message[0],
				   1, SPE_MBOX_ALL_BLOCKING);
	if (addr != recv_message[0]) {
	  printf ("Expected SPE to respond with same address!\n");
	  exit (1);
	}

	// output colwise matrix (up to EOF on input streams)
	bytes_written = 0;
	j             = bytes_read * OPT_K;
	do {
	  rc=write(single_fd, 
		   &out_values[addr * OPT_W * LS_MATRIX_COLS * OPT_K + 
			      bytes_written],
		   j);
	  if (rc < 0) {
	    printf ("write error on output: %s\n", strerror(errno));
	    exit (1);
	  }
	  bytes_written += rc;
	  j             -= rc;
	} while (j > 0);
      }

      // move on to using next slot in local matrix
      addr = (addr + 1) % MATRIX_BLOCKS;
    } while (!eof);

  }

  // tell SPE(s) to finish
  addr=LS_MATRIX_COLS;
  for (i=0;i<NUM_SPE;i++) {
    for (j=0; j < 2; ++j) {
      if (spe_in_mbox_write(context[0],
			    &addr,
			    1,
			    SPE_MBOX_ALL_BLOCKING) == 0) {
	printf("PPE: Message could not be written\n");
	exit (1);
      }
    }
  }


  // Finish: join SPE thread and destroy run context(s)
  for (i=0;i<NUM_SPE;i++) {
    printf ("PPE: waiting to join thread %d\n",i);
    value=pthread_join(pthread[i],NULL);
    printf ("PPE: joined thread %d, return code %u\n",i,value);
    if (i < NUM_SPE) {
      spe_context_destroy(context[i]);
    }
  }

  printf ("End of all SPE slave threads\n");
  return 0;

}

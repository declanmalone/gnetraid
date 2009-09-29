/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

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

#include "common.h"
#include "host.h"
#include "ppu-cnc.h"

// demo 07: the whole shebang
//
// This demo builds upon all the previous demos and rolls them into
// one application. The C code here is intended to do all the heavy
// processing required for a Reed-Solomon/Information Dispersal
// Algorithm codec. An associated Perl program handles the less
// CPU-intensive parts of the code (such as initial matrix creation,
// matrix inverse, friendlier command-line processing, etc.) and it
// calls this code as a helper program.
//
// New features in this demo:
//
// * fully dynamic data structure allocation
// * calculation of matrix size parameters wrt available SPE memory
// * double-buffering in SPE task code
// * full host multithreading (for asynchronous input/output)
// * multiple SPE support
// * command interpreter/mini language
// * user-selectable transform parameters (k, n, input/output files,
//   etc.)
// * support for GF(2^16) and GF(2^32) arithmetic/transforms
// * restartable SPE programs (allows loading new parameters)
// * build host with embedded SPE program
// * code re-structured for improved readability
// * workaround for bug which arises using DMA list transfers when //
//   several DMA requests are active and effective address straddles a
//   32-bit address boundary
//
// This C code mainly aggregates all the functionality from previous
// demos, but also includes some incremental improvements. The
// included Perl program is platform-independent, and actually
// provides a complete implementation of the same kinds of math/matrix
// routines implemented here, although it is quite generic (and can
// actually work on fields of up to 1024 bits) and, as a result, is
// very slow (expect this Perl/C/SPE implementation to be 10, 100, or
// more times faster than the Perl code on its own). The combination
// of the Perl program for high-level, non-critical code, and the C
// program for specialised, computation-heavy processing is a kind of
// demo in itself. Coding in C for SPEs takes a lot of development
// effort, and this division of labour shows one way (among many) of
// coding only the critical sections in C, while simultaneously
// achieving many of the benefits of using a high-level scripting
// language. So coding in this way can give you two kinds of speed:
// raw processing speed, and speed of development. That's provided
// that the interface between the two languages isn't too bad, of
// course; I think the mini language that interfaces the C and Perl
// here just about counts as acceptable.
//
// Besides the use of multiple SPEs, a multi-threaded host and
// double-buffering of data on SPEs, no other Cell-specific
// optimisations (eg, to use SIMD operations or optimise memory layout
// for more efficient matrix multiplication) are implemented here.
//
// The hybrid Perl/C implementation presented here produces share
// files which are compatible with those produced with my Crypt::IDA
// Perl modules, which are available from CPAN. Although programming
// interfaces are different, this code gives you the option of using
// the PS3 platform to speed up creation of shares, even if they're
// destined to be recombined on a different platform.

// Global variables

// Allow choice of building with embedded SPE program, or loaded as a
// separate program at run time. 
#ifdef EMBED_SPU
extern spe_program_handle_t program_image;
#else
const char           *spe_prog = "spu-task";
spe_program_handle_t *program_image;
#endif
task_setup_t         *spe_opts;

// The following removed in favour of macro of same name (see host.h,
// or spu-task.h for separate SPE verbosity variable)
//
// const int verbose = 0;

// SPE thread routine

void *spe_thread(void *arg) {
  spe_context_ptr_t context = *(spe_context_ptr_t *) arg;
  unsigned int      entry   = SPE_DEFAULT_ENTRY;

  // use the SPE_RUN_USER_REGS flag to pass the address of the
  // spe_opts structure.
  if (spe_context_run(context,&entry,SPE_RUN_USER_REGS,
		      spe_opts,NULL,NULL)) {
    printf ("SPE: spe_context_run error!\n");
    pthread_exit(arg);
  }

  printf ("PPE: SPE thread shutdown\n");
  pthread_exit(NULL);
}


// See ppu-io.c, ppu-event.c and ppu-scheduler.c for other threads

int main (int ac, char *av[]) {


#ifndef EMBED_SPU

  // If the spu-task program wasn't embedded at compilation time, load
  // it up now.

  // same image will be used for each SPE
  program_image=spe_image_open(spe_prog);
  if (!program_image) {
    printf ("Couldn't load image %s\n",spe_prog);
    return 1;
  }

#endif

  command_interpreter();


  return 0;

  // main loop

}

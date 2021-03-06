// Impemention of SHA1-based random number generator for Online Codes
// Copyright (c) Declan Malone 2014

#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "rng_sha1.h"

// The endianness of the machine will have a bearing on conversion of
// the SHA1 output into one or more 32-bit numbers. GCC provides
// macros to determine endianness, so I'm using them here. Later I
// will replace this with something that's more portable.

// Since most popular machines (x86, ARM) are little-endian, I'll
// arbitrarily optimise extraction for those platforms. Note that this
// is the opposite of what I did in the Perl program initially (where
// I assumed "network" or "big-endian"). I'll change the Perl program
// later to ensure interoperability.

#ifndef __BYTE_ORDER__
#error "Can't determine this machine's byte order"
#else
#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
#define EXTRACT_NATIVE_U32(dest,src_ptr) (dest = (*(uint32_t *)(src_ptr)))
#else
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define EXTRACT_NATIVE_U32(dest,src_ptr) (dest =			\
					  (((uint8_t*)src_ptr)[0] << 24) & \
					  (((uint8_t*)src_ptr)[1] << 16) & \
					  (((uint8_t*)src_ptr)[2] << 8)  & \
					  (((uint8_t*)src_ptr)[3]))
#else
#error "This compiler has byte order macro set, but I don't recognise its value"
#endif
#endif
#endif

// init just makes sure that the RNG has known start value. It's
// probably not needed in most cases, but can be useful if you want a
// deterministic sequence of numbers for testing

void oc_rng_init(oc_rng_sha1 *rng) {

  assert((void*) rng != 0);

  memset(rng->seed,    0, OC_RNG_BYTES);
  memset(rng->current, 0, OC_RNG_BYTES);

  rng->reserved = 0;
  rng->subprt   = 0;

}

// Initialise with user-supplied seed, which is assumed to be
// OC_RNG_BYTES long. We can't actually test that it's the right size
// in C, so caller must be careful to declare it properly, otherwise a
// segmentation fault or other bugs might result

void oc_rng_init_seed(oc_rng_sha1 *rng, const char *seed) {

  assert((void*) rng != 0);

  memcpy(rng->seed,    seed, OC_RNG_BYTES);
  memcpy(rng->current, seed, OC_RNG_BYTES);

  rng->reserved = 0;
  rng->subprt   = 0;

}

void oc_rng_init_random(oc_rng_sha1 *rng) {

  assert((void*) rng != 0);

  int rc;

  rc=oc_rng_random_uuid(rng->seed);

  if (rc != OC_RNG_BYTES) {
    fprintf(stderr, "rng_init_random: only read %d of %d random bytes\n",
	    rc, OC_RNG_BYTES);
    exit(1);
  }

  memcpy(rng->current, rng->seed, OC_RNG_BYTES);

  rng->reserved = 0;
  rng->subprt   = 0;

}


void oc_rng_advance(oc_rng_sha1 *rng) {

  assert((void*) rng != 0);

  if (++(rng->subprt) >= OC_RNG_RANDS_PER_SUM) {
    // use rng->current as both input and output (works fine according
    // to run of compat program)
    SHA1(rng->current,OC_RNG_BYTES,rng->current);
    rng->subprt = 0;
  }
}

// Generate a random seed/uuid by reading from /dev/urandom.  This
// only works on Unix-like systems that have this device file.  The
// routine reads OC_RNG_BYTES bytes from the file and writes them to
// dest. It returns the number of characters actually read/written or
// -1 to indicate a file access problem.

int oc_rng_random_uuid(char *dest) {

  int fd, rc;
  int bytes = 0;

  fd = open (OC_RANDOM_SOURCE, O_RDONLY);

  if (fd < 0) { return fd; }

  // use a loop in case we read fewer than the required number of bytes
  do {
    rc = read (fd, dest + bytes, OC_RNG_BYTES - bytes);

    if (rc > 0) {
	bytes += rc;
	assert(OC_RNG_BYTES - bytes >= 0);
    } else if (rc == 0) {
	fprintf (stderr, "rng_sha1: Random source dried up (unexpected EOF)!\n");
	exit(1);
    } else {
      fprintf(stderr, "rng_sha1: Failed to read from " OC_RANDOM_SOURCE "\n");
      exit(1);
    }
  } while (bytes < OC_RNG_BYTES);

  close(fd);

  return bytes;

}

double oc_rng_rand(oc_rng_sha1 *rng, double max) {

  long double  temp;			    // prevent overflow
  uint32_t sha_word;
  uint32_t max_int = 0xfffffffful;    // max 32-bit integer

  assert(max > 0);
  assert(max_int == 0xfffffffful);

  while(1) {
    oc_rng_advance(rng);

    // extract the correct 32-bit word from the 160-bit hash
    EXTRACT_NATIVE_U32(sha_word, rng->current + (rng->subprt) * 4);

    assert(sha_word <= 0xffffffffl);

    // Values have to be in the range [0,max) (ie, including 0, but
    // not max)
    if(sha_word < max_int) {
      temp = (double) sha_word / (double) max_int;
      return max * temp;
    }
  }
}


// allocate a static buffer for converting rng to hex string
static char hex_print_buffer[OC_RNG_BYTES << 1 + 1];

const char *oc_rng_as_hex(oc_rng_sha1 *rng) {

  char *in, *out = hex_print_buffer;
  unsigned char byte, high, low;
  int i;

  assert(rng != NULL);

  in=rng->current;
  for (i = 0; i < OC_RNG_BYTES; ++i, ++in) {
    byte = *in;
    high = byte >> 4;
    low  = byte & 15;

    *(out++) = high + ((high < 10) ? '0' : ('a' - 10));
    *(out++) = low  + ((low  < 10) ? '0' : ('a' - 10));
  }
  *out = '\0';
  return hex_print_buffer;
}


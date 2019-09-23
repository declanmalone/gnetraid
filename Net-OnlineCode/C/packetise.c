// Based on codec.c (also implemented in Perl)

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <assert.h>
#include <openssl/sha.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

#include "online-code.h"
#include "encoder.h"
#include "decoder.h"
// #include "xor.h"

#define OC_DEBUG 0

extern char *optarg;		// getopt-related
extern int   optind;

const char *null_seed = "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

oc_encoder  enc;
oc_decoder  dec;
oc_rng_sha1 erng, drng;

// Test string (pre-padded to simplify things)
#define LENGTH 41		// string length not including '\0'
#define PADLEN 83		// twice LENGTH plus 1 for '\0'

#ifdef OLD_WITH_STRING
char e_message[PADLEN] = "The quick brown fox jumps over a lazy dog"
                         "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
char d_message[PADLEN];		// decoder message buffer
char xmit[PADLEN];		// "transmitted" block
#else
char *e_message, *xmit;
char *d_message = "";
#endif

// Auxiliary caches used by encoder and decoder, respectively
char *e_aux_cache;
char *d_aux_cache;

// Cache for received check blocks (with a huge fudge factor)
#ifdef OLD_WITH_STRING
#define CHK_CACHE_BYTES (PADLEN * 10)
char chk_cache[CHK_CACHE_BYTES];
#else
#define CHK_CACHE_BYTES 0
char *chk_cache;
#endif

// encoder/decoder flags
int eargs = 0;
int dargs = 0; //OC_EXPAND_MSG;


// simple XOR routine (for now)
void xor(unsigned char *dst, unsigned char *src, int count) {
  while (count--)
    *(dst++) ^= *(src++);
}

void test_xor(void) {
  // basic test; should print cAMELcASE
  memcpy(xmit, "CamelCase", 9);
  xor (xmit, "         ", 9);
  printf("%.9s\n", xmit);
}

// Print a checksum for a check/aux block. Not part of the algorithm,
// but useful for comparing the values between encoder/decoder since
// those blocks have non-printable chars.

void print_sum(char *data, int size, char *before, char *after) {

  static char    sha_buf[21];
  int            count = 4;	// No. of hex bytes to print
  unsigned char *cp = sha_buf;
         
  SHA1(data, size, sha_buf);

  printf("%s", before);

  // Hex conversion (we don't need to print full SHA1 sum)
  while (count--)
    printf ("%02x", (unsigned int) *(cp++));

  printf("%s", after);
}

void usage() {
  printf("Packetise: convert a file to online code packets\n\n");
  printf("packetise.pl [-d][-s seed] [-b block_size] [-p packets] infile\n\n");
}

int main(int argc, char * const argv[]) {

  int    opt, random_seed = 1, mblocks, flags;
  char   seed[20];
  double e;
  int    block_size = 1024;
  int    q, f, ablocks, coblocks;
  int    done, i, j, check_count;
  int    msg, aux, aux_block, *mp;
  int    remainder, padding;
  off_t  filesize, padded, to_read;
  int   *exor_list, *dxor_list, count;
  int    packets=32768, rc;
  char  *filename;
  FILE  *INFILE;
  
  oc_uni_block *solved, *sp;

  // parse opts
  while ((opt = getopt(argc, argv, "ds:b:p:")) != -1) {
    switch(opt) {
    case 'd':
      memcpy(seed, null_seed, 20);
      random_seed = 0;
      break;
    case 's':
      if ((0 == optarg) || (20 != strlen(optarg))) {
	fprintf(stderr, "codec: -s seed must be 20 chars (no nulls)\n");
	exit(1);
      }
      memcpy(seed, optarg, 20);
      random_seed = 0;
      break;
    case 'b':			// block size
      block_size = atoi(optarg);
      if (block_size <= 0) {
	fprintf(stderr, "Invalid block size %d\n", block_size);
	exit(1);
      }
      memcpy(seed, optarg, 20);
      random_seed = 0;
      break;
    case 'p':
      packets = atoi(optarg);
      if (packets <= 0) {
	fprintf(stderr, "Invalid number of packets %d\n",packets);
	exit(1);
      }
      break;
    default:
      usage();
      exit(1);
    }
  }
  if (optind >= argc) {
    usage();
    exit(1);
  }

  struct stat statinfo;
  filename = argv[optind];
  if (stat(filename, &statinfo)) {
    fprintf(stderr, "Input file not found");
    exit(1);
  }
  filesize = statinfo.st_size;
  padded   = filesize;
  while (padded % block_size) { ++padded; }

  INFILE = fopen(filename, "r");
  if (INFILE == NULL) {
    fprintf(stderr, "Problem opening file for read: %s\n", strerror(errno));
    exit(1);
  }

  // set up memory and slurp file
  if (NULL == (e_message = malloc(padded))) {
    fprintf(stderr, "Failed to malloc %d bytes for file\n", padded);
    exit(1);
  }
  xmit = malloc(block_size);
  to_read = filesize;
  while (to_read > 0) {
    rc = fread(e_message + filesize - to_read, to_read, 1, INFILE);
    if (rc < 0) {
      fprintf(stderr, "Problem reading file: %s\n", strerror(errno));
      exit(1);
    }
    if (rc == 0) { break; };
    to_read -= rc;
  }

  if (random_seed)
    oc_rng_init_random(&erng);
  else
    oc_rng_init_seed(&erng, seed);
  oc_rng_init_seed(&drng, erng.seed);

  assert(0 == strcmp(oc_rng_as_hex(&erng), oc_rng_as_hex(&drng)));

  // Set up strings and such
  printf ("SEED: %s\n", oc_rng_as_hex(&erng));
  printf("Block size: %d\n", block_size);

  mblocks = (padded) / block_size;
  printf("Message blocks: %d\n", mblocks);
  
  // Set up Encoder using default qef
  flags = oc_encoder_init(&enc, mblocks, &erng, eargs, 0ll);
  if (flags & OC_FATAL_ERROR)
    return fprintf(stderr, "Fatal error setting up encoder\n");

  ablocks  = enc.base.ablocks;
  coblocks = enc.base.coblocks;
  q        = enc.base.q;
  e        = enc.base.e;
  f        = enc.base.F;

  printf("Auxiliary blocks: %d\n", ablocks);
  printf("Encoder parameters:\nq= %d, e= %.15g, f= %d\n", q, e, f);
  printf("Expected number of check blocks: %d\n",
	 (int) (0.5 + (mblocks * (1 + e * q))));
  printf("Failure probability: %e\n",pow(e/2,q + 1));

  // allocate memory for auxiliary blocks
  e_aux_cache = malloc(ablocks * block_size);
  if (NULL == e_aux_cache)
    return fprintf(stderr, "Failed to allocate encoder auxiliary cache\n");

  memset(e_aux_cache, 0, ablocks * block_size);
  mp = enc.base.auxiliary;
  for (msg = 0; msg < mblocks; ++msg) {
    for (aux = 0; aux < q; ++aux) {
      aux_block = *(mp++) - mblocks;
      assert(aux_block >= 0);
      assert(aux_block < ablocks);
      xor(e_aux_cache + block_size * aux_block,
      	  e_message   + block_size * msg,
      	  block_size);
    }
  }

  // print out encoder's aux cache
  if (0) {
    printf ("ENCODER: Auxiliary block signatures:\n");
    for (aux = 0; aux < ablocks; ++aux) {
      printf("  signature %d :", aux + mblocks);
      print_sum(e_aux_cache + block_size * aux, block_size," ", "\n");
    }
  }

  if (0) {
    // Set up decoder arrays (received check and solved msg/aux blocks)
    d_aux_cache = malloc(ablocks * block_size);
    if (NULL == d_aux_cache)
      return fprintf(stderr, "Failed to allocate decoder auxiliary cache\n");
    memset(d_message, 0, LENGTH + padding + 1);
    memset(chk_cache, 0, CHK_CACHE_BYTES);
    memset(d_aux_cache, 0, ablocks * block_size);
  }
  // main loop
  done = check_count = 0;
  while (packets--) {

    // Encoder side: create a check block. The erng's current value is
    // taken to be the "uuid/seed" for this checkblock. In practice,
    // we'd create a random uuid/seed (or at least advance the rng)
    // and save it for sending to the decoder along with the xored
    // contents of the check block.

    //printf("\nENCODE Block #%d %s\n", check_count, oc_rng_as_hex(&erng));

    if (NULL == (exor_list = oc_encoder_check_block(&enc)))
      return fprintf(stderr, "codec failed to create encoder check block\n");

    //    printf("Encoder check block (degree %d): ",exor_list[0]);
    //printf("Encoder check block: ");
    //oc_print_xor_list(exor_list, "\n");

    // XOR the contained message/auxiliary blocks
    memset(xmit, 0, block_size);
    mp    = exor_list;
    count = *(mp++);
    while (count--) {
      i = *(mp++);
      //printf("Encoder XORing block %d into check block %d\n", i, check_count);
      assert (i < coblocks);
      if (i < mblocks)
       	xor(xmit, e_message   + i             * block_size, block_size);
      else
	xor(xmit, e_aux_cache + (i - mblocks) * block_size, block_size);
    }

    
    if (0) {
      // Check that xmit buffer is right (rint plain text/signature)
      if ((1 == exor_list[0]) && (i < mblocks))
	printf("SOLITARY ENCODED:\n");
      else
	print_sum(xmit, block_size, "Encoder check block signature: ", "\n");
  }
    //    free(exor_list);

    // At this point the encoder would send the saved seed plus the
    // contents of the xmit buffer

    // Decoder side: Normally the first thing we'd do now is to seed
    // our rng with the value given by the encoder, but we don't need
    // to do that here because both rngs are synchronised right from
    // the start.

    if (0) {
      printf("\nDECODE Block #%d %s\n", check_count, oc_rng_as_hex(&drng));

      // Save contents of checkblock and add it to the graph
      memcpy(chk_cache + check_count * block_size,
	     xmit, block_size);
      if (-1 == oc_accept_check_block(&dec, &drng))
	return fprintf(stderr, "Failed to accept check block\n");
      print_sum(chk_cache + check_count * block_size, block_size,
		"Decoder check block signature: ", "\n");
    }
    
    ++check_count;

  } // end while(packets)

  printf("Decoded text: '%.*s'\n", LENGTH + padding, d_message);

}

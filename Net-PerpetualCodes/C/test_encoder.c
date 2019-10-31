#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#include "gf_types.h"
#include "perpetual.h"
#include "gf8.h"
#include "gf16_32.h"

struct perp_settings_2015 settings = {
  1024,  // size_t   blocksize;
  2048,  // unsigned gen;
  192/8, // unsigned short alpha;
  16,    // unsigned short qbits;	/* field size (number of bits) */
  0,     // unsigned short q;		/* field size (number of elements) */
  0,     // unsigned short code_size;	/* qbits * alpha / 8 */
};

struct perp_encoder_2015 encoder = {
  0,     // seed
         // options
  0,     // deterministic
  0,     // *message
  0      // packets
};

// encode_block just uses a switch statement to select the right field
// arithmetic functions to use (consults settings)
void encode_block(struct perp_settings_2015 *s,
		  struct perp_encoder_2015 *e,
		  unsigned *i,
		  unsigned char *code,
		  unsigned char *sym) {
  // temporary pointer and value variables
  gf8_t  *p8,  *mp8,  v8;
  gf16_t *p16, *mp16, v16;
  gf32_t *p32, *mp32, v32;

  short qbits = s->qbits;
  short alpha = s->alpha;
  short gen   = s->gen;
  short blocksize = s->blocksize;
  short j,k;
  short code_size = s->code_size;

  *i = rand() % gen;
  for (j=0; j < code_size; ++j)
    code[j] = rand() & 0xff;

  // implicit 1 on the diagonal (byte arithmetic)
  mp8 = e->message + (*i * blocksize);
  memcpy(sym, mp8, blocksize);

  // iterate over code (field elements) and FMA message blocks (bytes),
  // casting to field types as needed
  unsigned message_size = gen * blocksize;
  switch (qbits) {
  case 8:
    for (j = 0; j < alpha; ++j) {
      v8 = code[j];
      gf8_vec_fma(sym, e->message + ((*i + j + 1) % gen) * blocksize,
		  v8, blocksize);
    }
    break;
  case 16:
    p16 = (gf16_t *) code;
    for (j = 0; j < alpha; ++j) {
      v16 = p16[j];
      gf16_vec_fma((gf16_t *) sym,
		   (gf16_t *)  (e->message + ((*i + j + 1) % gen) * blocksize),
		   v16, blocksize >> 1);
    }
    break;
  case 32:
    p32 = (gf32_t *) code;
    for (j = 0; j < alpha; ++j) {
      v32 = p32[j];
      gf32_vec_fma((gf32_t *) sym,
		   (gf32_t *) (e->message + ((*i + j + 1) % gen) * blocksize),
		   v32, blocksize >> 2);
    }
    break;
  default:
    fprintf(stderr, "Unsupported qbits %d\n", qbits);
    exit(1);
  }
}

int main(int argc, char *argv[]) {
  
  unsigned int opt,value;
  
  while ((opt = getopt(argc, argv, "b:g:a:q:p:s:dh")) != -1) {
    switch (opt) {
    case 'b':
      settings.blocksize = atoi(optarg);
      break;
    case 'g':
      settings.gen = atoi(optarg);
      break;
    case 'a':
      settings.alpha = atoi(optarg);
      break;
    case 'q':
      settings.qbits = atoi(optarg);
      settings.q = 1 << (atoi(optarg));
      break;
    case 'p':
      encoder.packets = atoi(optarg);
      break;
    case 's':
      encoder.seed = atoi(optarg);
      encoder.deterministic = 0;
      break;
    case 'd':
      encoder.deterministic = 1;
      encoder.seed = 1;
      break;
    case 'h':
    default: /* '?' */
      fprintf(stderr,
	      "Usage:\n  %s [options] infile > outfile\n"
	      "Creates packets encoded using Perpetual Codes algorithm\n\n"
	      "Options:\n"
	      "-b n   blocksize\n"
	      "-g n   generation size\n"
	      "-a n   alpha value\n"
	      "-q n   field bits (1, 4, 8, 16, 32)\n"
	      "-p n   number of packets to produce\n"
	      "-s n   random seed to use (calls srand(n) if n is not 0)\n"
	      "-d     deterministic (calls srand(1))\n",
	      argv[0]);
      exit(EXIT_FAILURE);
    }
  }

  // Check options, set up arrays
  perp_init_encoder_2015(&settings, &encoder);

  // Some debug messages after setup
  fprintf(stderr, "code_size is %d\n", settings.code_size);


  if (optind == argc) {
    fprintf(stderr, "You need to supply an infile\n");
    exit(EXIT_FAILURE);
  }

  int fh = open(argv[optind], O_RDONLY);
  if (fh == -1) {
    fprintf(stderr, "Problem opening '%s': %s\n", argv[optind], strerror(errno));
    exit(1);
  }

  // allocate space for message
  size_t message_size = settings.gen * settings.blocksize;
  if (0 == (encoder.message = malloc(message_size))) {
    fprintf(stderr, "Failed to allocate memory to read input file\n");
    exit(1);
  }

  // Slurp input file
  int  eof = 0;
  char *buf = encoder.message;
  int bytes_read = 0;
  while (bytes_read < message_size) {
    int this_read = read(fh, buf + bytes_read, message_size - bytes_read);
    if (this_read == 0) { eof = 1; break; }
    if (this_read <  0) {
      fprintf(stderr, "I/O problem on infile: %s\n", strerror(errno));
      exit(1);
    }
    bytes_read += this_read;
  }
  if (bytes_read < message_size) {
    fprintf(stderr, "Premature EOF on infile. Quitting.\n");
    exit(1);
  }
    
  // Output file (fd 1 = stdout) will have fixed-sized records
  unsigned recsize = sizeof(unsigned) + settings.code_size + settings.blocksize;
  fprintf(stderr, "Record size is %u\n", recsize);
  gf8_t *outbuf = malloc(recsize);
  if (outbuf == 0) {
    fprintf(stderr, "Problem allocating record buffer\n");
    exit(1);
  }

  while (encoder.packets--) {
  
    unsigned      *i    = (unsigned *) outbuf;
    unsigned char *code = outbuf + sizeof(unsigned);
    unsigned char *sym  = code + settings.code_size;

    encode_block(&settings, &encoder, i, code, sym);
    
    int bytes_written = 0;
    int bytes_left = recsize;
    while (bytes_written < recsize) {
      int rc = write(1, outbuf + bytes_written, recsize - bytes_written);
      if (rc < 0) {
	fprintf(stderr, "Problem writing to output: %s\n",
		strerror(errno));
	exit(1);
      } else {
	bytes_written += rc;
      }
    }
  }

  exit(0);
}

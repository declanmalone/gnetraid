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
  switch (qbits) {
  case 8:
    for (mp8 += blocksize, j = 0; j < alpha; ++j) {
      v8 = code[j];
      gf8_vec_fma(sym, mp8, v8, blocksize);
    }
    break;
  case 16:
    p16 = (gf16_t *) code;
    for (mp8 += blocksize, j = 0; j < alpha; ++j) {
      v16 = p16[j];
      gf16_vec_fma((gf16_t *) sym, (gf16_t *) mp8, v16, blocksize >> 1);
    }
    break;
  case 32:
    p32 = (gf32_t *) code;
    for (mp8 += blocksize, j = 0; j < alpha; ++j) {
      v32 = p32[j];
      gf32_vec_fma((gf32_t *) sym, (gf32_t *) mp8, v32, blocksize >> 2);
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

  if (optind == argc) {
    fprintf(stderr, "You need to supply an infile\n");
    exit(EXIT_FAILURE);
  }

  int fh = open(argv[optind], O_RDONLY);
  if (fh == -1) {
    fprintf(stderr, "Problem opening '%s': %s\n", argv[optind], strerror(errno));
    exit(1);
  }

  // Output file will have fixed-sized records
  unsigned recsize = sizeof(unsigned) + settings.code_size + settings.blocksize;
  fprintf(stderr, "Record size is %u\n", recsize);
  gf8_t *buf = malloc(recsize);
  if (buf == 0) {
    fprintf(stderr, "Problem allocating buffer of size '%u'\n", recsize);
    exit(1);
  }

  unsigned i;
  char     *code, *sym;
  unsigned packets = 0;
  int  eof = 0;
  while (1) {
    int bytes_read = 0;
    while (bytes_read < recsize) {
      int this_read = read(fh, buf + bytes_read, recsize - bytes_read);
      if (this_read == 0) { eof = 1; break; }
      if (this_read <  0) {
	fprintf(stderr, "I/O problem on infile: %s\n", strerror(errno));
	exit(1);
      }
      bytes_read += this_read;
    }
    ++packets;
    i = *(unsigned *)buf;
    // fprintf(stderr, "i=%u\n", i);
    code = buf + sizeof(unsigned);
    sym  = code + settings.code_size;
    if (eof) break;
    //continue;
    int rc;
    switch(settings.qbits) {
    case  8: rc = pivot_gf8 (&settings, &encoder, i,
			     (gf8_t *)  code, (gf8_t *)  sym); break;
    case 16: rc = pivot_gf16(&settings, &encoder, i,
			     (gf16_t *) code, (gf16_t *) sym); break;
    case 32: rc = pivot_gf32(&settings, &encoder, i,
			     (gf32_t *) code, (gf32_t *) sym); break;
    }
    if (0 == rc) {
      fprintf(stderr, "Completed pivoting after %d packets\n",packets);
      switch(settings.qbits) {
      case  8: rc = solve_gf8 (&settings, &decoder); break;
      case 16: rc = solve_gf16(&settings, &decoder); break;
      case 32: rc = solve_gf32(&settings, &decoder); break;
      }
      if (0 == rc) {
        // dump_decoded(&settings, &decoder);
	int bytes_written = 0;
	int bytes_left = settings.gen * settings.blocksize;
	while (bytes_written < bytes_left) {
	  int rc = write(1, decoder.symbol + bytes_written, bytes_left);
	  if (rc < 0) {
	    fprintf(stderr, "Problem writing to output: %s\n",
		    strerror(errno));
	  } else {
	    bytes_left -= rc;
	    bytes_written += rc;
	  }
	}
	
	break;
      } else {
	fprintf(stderr, "Failed to decode\n");
	exit(1);
      }
    }
    if (eof) break;
  }
  fprintf(stderr, "Fully decoded after %d packets\n", packets);
  exit(0);
}

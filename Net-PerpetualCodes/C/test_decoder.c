#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>

#include "gf_types.h"
#include "perpetual.h"

struct perp_settings_2015 settings = {
  1024,  // size_t   blocksize;
  2048,  // unsigned gen;
  192/8, // unsigned short alpha;
  8,     // unsigned short qbits;	/* field size (number of bits) */
  256,   // unsigned short q;		/* field size (number of elements) */
  0,     // unsigned short code_size;	/* qbits * alpha / 8 */
};

struct perp_decoder_2015 decoder;

int main(int argc, char *argv[]) {
  
  // I was just going to hard-code settings, but I'll want to use
  // getopt eventually, so might as well get it out of the way
  unsigned int opt,value;
  
  while ((opt = getopt(argc, argv, "b:g:a:q:h")) != -1) {
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
    case 'h':
    default: /* '?' */
      fprintf(stderr,
	      "Usage:\n  %s -b blocksize -g gen -a alpha -q bits infile > outfile\n\n",
	      argv[0]);
      exit(EXIT_FAILURE);
    }
  }

  fprintf(stderr, "An unsigned int is %d bytes\n", sizeof(unsigned));
  
  // Check options, set up arrays
  perp_init_decoder_2015(&settings, &decoder);

  if (optind == argc) {
    fprintf(stderr, "You need to supply an infile\n");
    exit(EXIT_FAILURE);
  }

  int fh = open(argv[optind], O_RDONLY);
  if (fh == -1) {
    fprintf(stderr, "Problem opening '%s': %s\n", argv[optind], strerror(errno));
    exit(1);
  }

  // Input file will have fixed-sized records
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
    fprintf(stderr, "i=%u\n", i);
    code = buf + sizeof(unsigned);
    sym  = code + settings.code_size;
    if (eof) break;
    //continue;
    int rc;
    switch(settings.qbits) {
    case  8: rc = pivot_gf8 (&settings, &decoder, i,
			     (gf8_t *)  code, (gf8_t *)  sym); break;
    case 16: rc = pivot_gf16(&settings, &decoder, i,
			     (gf16_t *) code, (gf16_t *) sym); break;
    case 32: rc = pivot_gf32(&settings, &decoder, i,
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

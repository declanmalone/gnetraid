
/* Fast split/recombine using Rabin's IDA */ /* -*- C -*- */
/* Copyright (c) Declan Malone 2009-2019 */
/* License: GPL 2 */

/*********************************************************************
 
This program implements the main transformation loop of Rabin's
Information Dispersal Algorithm.  It does *not*:

 * Generate a transformation matrix

 * Write any meta-data to an output stream

 * Read any meta-data from an input stream

 * Calculate a matrix inverse

All these tasks are left up to the calling program. When the calling
program has taken care of these things, it can call on these routines
to either:

 * Calculate one or more shares determined by particular row(s) of the
   transform matrix, with output to file(s) (the "coder"); or

 * Input data from k share files and recombine them using a supplied 
   k x k inverse transform matrix (the "decoder").

In both cases the routines can be passed a value specifying the size
(in bytes) of any header information stored in share files. It's up to
the calling program to read/write the headers for share files. The
routines here will seek past the header before reading/writing share
data.

*********************************************************************/

#include "rabin-ida.h"

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>

/* GF(2**8) tables from Math::FastGF2 */
static const signed short fast_gf2_log[] = {
  -256, 255, 25, 1, 50, 2, 26, 198,
  75, 199, 27, 104, 51, 238, 223, 3,
  100, 4, 224, 14, 52, 141, 129, 239,
  76, 113, 8, 200, 248, 105, 28, 193,
  125, 194, 29, 181, 249, 185, 39, 106,
  77, 228, 166, 114, 154, 201, 9, 120,
  101, 47, 138, 5, 33, 15, 225, 36,
  18, 240, 130, 69, 53, 147, 218, 142,
  150, 143, 219, 189, 54, 208, 206, 148,
  19, 92, 210, 241, 64, 70, 131, 56,
  102, 221, 253, 48, 191, 6, 139, 98,
  179, 37, 226, 152, 34, 136, 145, 16,
  126, 110, 72, 195, 163, 182, 30, 66,
  58, 107, 40, 84, 250, 133, 61, 186,
  43, 121, 10, 21, 155, 159, 94, 202,
  78, 212, 172, 229, 243, 115, 167, 87,
  175, 88, 168, 80, 244, 234, 214, 116,
  79, 174, 233, 213, 231, 230, 173, 232,
  44, 215, 117, 122, 235, 22, 11, 245,
  89, 203, 95, 176, 156, 169, 81, 160,
  127, 12, 246, 111, 23, 196, 73, 236,
  216, 67, 31, 45, 164, 118, 123, 183,
  204, 187, 62, 90, 251, 96, 177, 134,
  59, 82, 161, 108, 170, 85, 41, 157,
  151, 178, 135, 144, 97, 190, 220, 252,
  188, 149, 207, 205, 55, 63, 91, 209,
  83, 57, 132, 60, 65, 162, 109, 71,
  20, 42, 158, 93, 86, 242, 211, 171,
  68, 17, 146, 217, 35, 32, 46, 137,
  180, 124, 184, 38, 119, 153, 227, 165,
  103, 74, 237, 222, 197, 49, 254, 24,
  13, 99, 140, 128, 192, 247, 112, 7,
};

static const unsigned char fast_gf2_exp[] = {
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  1, 3, 5, 15, 17, 51, 85, 255,
  26, 46, 114, 150, 161, 248, 19, 53,
  95, 225, 56, 72, 216, 115, 149, 164,
  247, 2, 6, 10, 30, 34, 102, 170,
  229, 52, 92, 228, 55, 89, 235, 38,
  106, 190, 217, 112, 144, 171, 230, 49,
  83, 245, 4, 12, 20, 60, 68, 204,
  79, 209, 104, 184, 211, 110, 178, 205,
  76, 212, 103, 169, 224, 59, 77, 215,
  98, 166, 241, 8, 24, 40, 120, 136,
  131, 158, 185, 208, 107, 189, 220, 127,
  129, 152, 179, 206, 73, 219, 118, 154,
  181, 196, 87, 249, 16, 48, 80, 240,
  11, 29, 39, 105, 187, 214, 97, 163,
  254, 25, 43, 125, 135, 146, 173, 236,
  47, 113, 147, 174, 233, 32, 96, 160,
  251, 22, 58, 78, 210, 109, 183, 194,
  93, 231, 50, 86, 250, 21, 63, 65,
  195, 94, 226, 61, 71, 201, 64, 192,
  91, 237, 44, 116, 156, 191, 218, 117,
  159, 186, 213, 100, 172, 239, 42, 126,
  130, 157, 188, 223, 122, 142, 137, 128,
  155, 182, 193, 88, 232, 35, 101, 175,
  234, 37, 111, 177, 200, 67, 197, 84,
  252, 31, 33, 99, 165, 244, 7, 9,
  27, 45, 119, 153, 176, 203, 70, 202,
  69, 207, 74, 222, 121, 139, 134, 145,
  168, 227, 62, 66, 198, 81, 243, 14,
  18, 54, 90, 238, 41, 123, 141, 140,
  143, 138, 133, 148, 167, 242, 13, 23,
  57, 75, 221, 124, 132, 151, 162, 253,
  28, 36, 108, 180, 199, 82, 246, 1,
  3, 5, 15, 17, 51, 85, 255, 26,
  46, 114, 150, 161, 248, 19, 53, 95,
  225, 56, 72, 216, 115, 149, 164, 247,
  2, 6, 10, 30, 34, 102, 170, 229,
  52, 92, 228, 55, 89, 235, 38, 106,
  190, 217, 112, 144, 171, 230, 49, 83,
  245, 4, 12, 20, 60, 68, 204, 79,
  209, 104, 184, 211, 110, 178, 205, 76,
  212, 103, 169, 224, 59, 77, 215, 98,
  166, 241, 8, 24, 40, 120, 136, 131,
  158, 185, 208, 107, 189, 220, 127, 129,
  152, 179, 206, 73, 219, 118, 154, 181,
  196, 87, 249, 16, 48, 80, 240, 11,
  29, 39, 105, 187, 214, 97, 163, 254,
  25, 43, 125, 135, 146, 173, 236, 47,
  113, 147, 174, 233, 32, 96, 160, 251,
  22, 58, 78, 210, 109, 183, 194, 93,
  231, 50, 86, 250, 21, 63, 65, 195,
  94, 226, 61, 71, 201, 64, 192, 91,
  237, 44, 116, 156, 191, 218, 117, 159,
  186, 213, 100, 172, 239, 42, 126, 130,
  157, 188, 223, 122, 142, 137, 128, 155,
  182, 193, 88, 232, 35, 101, 175, 234,
  37, 111, 177, 200, 67, 197, 84, 252,
  31, 33, 99, 165, 244, 7, 9, 27,
  45, 119, 153, 176, 203, 70, 202, 69,
  207, 74, 222, 121, 139, 134, 145, 168,
  227, 62, 66, 198, 81, 243, 14, 18,
  54, 90, 238, 41, 123, 141, 140, 143,
  138, 133, 148, 167, 242, 13, 23, 57,
  75, 221, 124, 132, 151, 162, 253, 28,
  36, 108, 180, 199, 82, 246, 1, 0,
  /* The following are needed to make 1/0 = 0 on some platforms */
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
};

inline unsigned char gf2_mul8 (unsigned char a, unsigned char b) {
  /* keep 8-bit log/exp tables handy */
  static const signed short  *log_table=fast_gf2_log;
  static const unsigned char *exp_table=fast_gf2_exp+512;

  return exp_table[log_table[a] + log_table[b]];
}


codec_t codec;

int did_init=0;

void fatal(const char *s) {
  fprintf(stderr, "ERROR: %s\n", s);
  exit(1);
}

void fatal_strerr(const char* s,int err) {
  fprintf(stderr,"%s: %s", s, strerror(err));
  exit(1);
}

void codec_init (int k, int n, int order, int header, 
                 char* infile, char* outfile, char* poly, char *inverse) {
  int len;

  assert(!did_init);
  assert(sizeof(char) == 1);

  assert (k > 0);
  codec.k=k;

  assert((n > 0) && (k <= n));
  codec.n=n;

  assert((order > 0) && (order <=1024) && (order & 7 == 0));
  codec.order=order;

  codec.sec_level=order >> 3;

  codec.share_header_size=header;

  /* we only allow one initialisation, so both infile and outfile must
     be provided at this stage. They can both be the same filename. */
  assert(infile != (char*)0);
  assert(outfile != (char*)0);

  len=strlen(infile);
  assert(len > 0);
  codec.infile=malloc(len + 1);
  assert(codec.infile != (char*)0);
  strcpy(codec.infile, infile);

  len=strlen(outfile);
  assert(len > 0);
  codec.outfile=malloc(len + 1);
  assert(codec.outfile != (char*)0);
  strcpy(codec.outfile, outfile);

  /* poly is simply sec_level bytes with no \0 terminator */
  codec.poly=malloc(codec.sec_level);
  assert(codec.poly != (char*) 0);
  memcpy(codec.poly, poly, codec.sec_level);

  did_init=1;
}

/* Free any memory used by codec structure and then blank it */
void codec_reset (void) {
  int i;

  if (codec.poly != NULL)    free(codec.poly);
  if (codec.infile != NULL)  free(codec.infile);
  if (codec.outfile != NULL) free(codec.outfile);
  if (codec.padding != NULL) free(codec.padding);
  if (codec.sharefiles != NULL) {
    for (i=0; i<codec.nsharefiles; ++i) {
      free(codec.sharefiles[i]);
    }
    free(codec.sharefiles);
  }
  if (codec.matrix != NULL)  free(codec.matrix);
  if (codec.inverse != NULL) free(codec.inverse);

  memset(&codec,0,sizeof(codec));
}

/*-----------------------------------------------------------------*/

/* bit vector and GF(2) arithmetic */

/*
  xor: no checks done for valid pointers or overlapping memory
  areas. 
*/

void vector_xor(char *dest, char* x, unsigned bytes) {
  while (bytes--) {
    *(dest++) ^= *(x++);
  }
}

int vector_size_in_bits (char* s, int bytes) {

  static char lookup_byte[256]= {
    0,1,2,2,3,3,3,3,4,4,4,4,4,4,4,4, /*   0 -  15 */
    5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5, /*  16 -  31 */
    6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6, /*  32 -  47 */
    6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6, /*  48 -  63 */
    7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, /*  63 -  79 */
    7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, /*  80 -  95 */
    7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, /*  96 - 111 */
    7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, /* 112 - 127 */
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*           */
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*     :     */
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*           */
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*     :     */
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*           */
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*     :     */
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /*           */
    8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, /* 240 - 255 */
  };

  if (bytes == 0) return 0;

  while ((bytes > 1) && (*s == 0)) {
    ++s; --bytes;
  }

  return (--bytes << 3) + lookup_byte[*s];

}

unsigned char vector_shift_left(char* r,unsigned bytes, 
                                unsigned char carry_in) {
  char carry_out;

  /* unroll first loop iteration to avoid superfluous assignment of
     carry_in = carry_out */
  carry_out= (r[--bytes] & 128) >> 7;
  r[bytes] = ((r[bytes] << 1) | carry_in);

  while (bytes--) { 
    carry_in=carry_out;
    carry_out= (r[bytes] & 128) >> 7;
    r[bytes] = ((r[bytes] << 1) | carry_in);
  };

  return carry_out;
}

void vector_shift_left_many (char* s, int bits, int len) {

  int   full_bytes     = bits >> 3;
  int   remaining_bits = bits & 7;
  char  i=0;

  if (full_bytes) {
    /* byte-level shift */
    while (i + full_bytes < len) {
      s[i]=s[i + full_bytes];
      ++i;
    }

    /* bit-level shift of left part of string */
    if (full_bytes < len) {
      while (remaining_bits--) {
	vector_shift_left(s,i,0);
      }
    }
 
    /* zero any remaining bytes on right */
    while (i < len) {
      s[i++]=0;
    }
  } else {
    while (remaining_bits--) {
      vector_shift_left(s,len,0);
    }
  }
}

/* 
  Efficient way to test a vector for equality with small (<256)
  values. This saves having to allocate a full-sized vector for common
  cases of comparing a vector with 0 or 1, for example.
*/
int vector_eq_byte (char *s, char b, int len) {

  while (--len > 0) {
    if ( *(s++) != 0 )
      return 0;			/* 0: not equal */
  }

  return (*s == b) ? 1 : 0;	/* 1: equal, 0: not equal */

}

/* opposite of vector_eq_byte */
int vector_ne_byte (char *s, char b, int len) {

  while (--len > 0) {
    if ( *(s++) != 0 )
      return 1;
  }

  return (*s != b) ? 1 : 0;

}

/* efficiently set a vector to a small (<256) value */
void vector_set_byte (char *s, char b, int len) {
  while (--len > 0) {
    *(s++)=0;
  }
  *s=b;
}

/* GF(2) arithmetic ... */
/*
   Multiply two numbers in GF(2^order) modulo an irreducible poly.
   For efficiency, we require scratch be pre-allocated to hold a word
   of size "bytes". We will clobber any data stored in it.
*/
void gf2_multiply(char *dest, char *x, char *y, char* poly,
		  int bytes, char* scratch) {
  char* b=scratch;
  char carry;
  unsigned int bits=bytes << 3;	/* order of the polynomial */
  int  current_byte=bytes - 1;
  char current_bit=1;

  /* Variable initialisation is unrolling of first loop iteration */
  /* Initialise b = x */
  memcpy(b,x,bytes);

  /* Working from right of vector (highest memory location, lowest bit
     thereof) */
  if (y[current_byte] & 1) {	/* first line of multplication */
    memcpy(dest,x,bytes);
  } else {
    memset(dest,0,bytes);
  }

  while (--bits) {

    /* update the bitmask to move left within a byte, and
       downwards across bytes */
    if (current_bit & 128) {
      current_bit=1;
      current_byte--;
    } else {
      current_bit<<=1;
    }

    if (vector_shift_left(b,bytes,0)) {	/* if carry out */
      vector_xor(b,poly,bytes);
    }
    if (y[current_byte] & current_bit) {
      vector_xor(dest,b,bytes);
    }
  }
}

/* Calculate the multiplicative inverse of x wrt poly */
int gf2_invert(char *dest, char *x, char* poly, int bytes,
	       char* scratch) {

  /* scratch area needs to be large enough to fit 4 variables. If
     we're passed a valid pointer, we'll use that space (which must be
     of an appropriate size!). Otherwise, we'll malloc and free the
     space ourselves. Return value is 0 on success, or error number
     otherwise (ENOMEM, EDOM).
  */

  char* u,*v,*z,*g,*h,*t;
  int   i;
  int   did_alloc=0;

  if (vector_eq_byte(x,0,bytes)) 
    return EDOM;		/* no inverse for zero */

  if (scratch == NULL) {
   scratch=malloc(4 * bytes);
   did_alloc=1;
  }
  if (scratch == NULL)
    return ENOMEM;		/* out of memory */

  u=scratch + 0*bytes; memcpy(u,poly,bytes);              /* u = poly */
  v=scratch + 1*bytes; memcpy(v,x,bytes);                 /* v = x    */
  z=dest;              memset(z,0,bytes);                 /* z = 0    */
  g=scratch + 2*bytes; memset(g,0,bytes-1); g[bytes-1]=1; /* g = 1    */
  h=scratch + 3*bytes;                                    /* h = any  */


  /* unroll first loop iteration */
  i=(bytes << 3) + 1 - vector_size_in_bits(v,bytes);

  memcpy(h,v,bytes); vector_shift_left_many(h,i,bytes);
  vector_xor(u,h,bytes);

  memcpy(h,g,bytes); vector_shift_left_many(h,i,bytes);
  vector_xor(z,h,bytes);

  while (vector_ne_byte(u,1,bytes)) {
    i=vector_size_in_bits(u,bytes) - vector_size_in_bits(v,bytes);
    if (i < 0) {
      t=u; u=v; v=t;
      t=z; z=g; g=t;
      i=-i;
    }
    memcpy(h,v,bytes); vector_shift_left_many(h,i,bytes);
    vector_xor(u,h,bytes);
    memcpy(h,g,bytes); vector_shift_left_many(h,i,bytes);
    vector_xor(z,h,bytes);
  }
  if (z != dest) {		/* we may have swapped z,g above */
    memcpy(dest,z,bytes);
  }
  if (did_alloc) free(scratch);
  return 0;
}

/*-----------------------------------------------------------------*/

/* Matrix arithmetic */

/*
  Allocate a new matrix of the given dimensions. (copy constructor)

  If passed in another matrix, any values in it will be copied into
  the new matrix. If the dimensions of the new matrix are smaller the
  one being copied from, then rows will be dropped from the end or
  columns dropped from the right. The new matrix may also have a
  different organisation from the matrix being copied, in which case
  elements will be copied in in the correct order.

  As a convenience, if using this to copy another matrix, setting
  rows, cols or width to zero will make the new matrix inherit the
  respective setting from the matrix being copied from. If another
  matrix is not supplied, setting these fields to zero is an error.

  This routine uses malloc to create both the matrix and its values
  array. It also sets the struct's alloc_bits to reflect this. If you
  want to allocate a new matrix, but want to take care of your own
  allocation, then don't use this routine. Do remember to set
  alloc_bits to the appropriate value so that you can call
  gf2_matrix_free on it safely, though.

  Returns a pointer to the newly allocated struct on success, or NULL
  on error.
*/
gf2_matrix_t*
gf2_matrix_alloc (gf2_matrix_t* from, int rows, int cols, int width,
		  char org) {

  int           i,j,k;
  gf2_matrix_t* new;
  char          simple_copy=0;
  char*         copy_from;
  char*         copy_to;
  int           copy_rows,copy_cols;
  int           from_down,from_right,to_down,to_right;

  if (from == NULL) {

    if ((rows<=0) || (cols<=0) || (width<=0) || (org<=0))
      return NULL;

  } else {

    if (rows==0)  rows = from->rows;
    if (cols==0)  cols = from->cols;
    if (width==0) width= from->width;
    if (org==0)   rows = from->organisation;

    /*
      routine can handle different row, col, org settings, but not
      different word sizes
    */
    if (width!=from->width) return NULL;

    if ((rows==from->rows) && (cols==from->cols) &&
        (width==from->width) && (org==from->organisation))
      simple_copy=1;

  }

  new=malloc(sizeof (gf2_matrix_t));
  if (new == NULL)  return NULL;

  new->values=malloc(rows * cols * width);
  if (new->values == NULL) { free(new); return NULL; }

  new->alloc_bits   = FREE_BOTH;
  new->rows         = rows;
  new->cols         = cols;
  new->width        = width;
  new->organisation = org;

  if (from == NULL) {
    memset(new->values, 0, rows * cols * width);

  } else {

    if (simple_copy) {

      memcpy(new->values,from->values,rows * cols * width);

    } else if (org == from->organisation) {

      if (org == COLWISE) {

	if ((rows > from->rows) || (cols > from->cols)) {
	  /* this is inefficient, but easier to code */
	  memset (new->values,0,rows * cols * width);
	}

	copy_rows=((rows > from->rows) ? from->rows : rows) * width;
        copy_cols=((cols > from->cols) ? from->cols : cols);

	copy_from=from->values;   j=from->rows * width;
	copy_to  =new ->values;   k=      rows * width;

	for (i=0; i < copy_cols; ++i) {
	  memcpy(copy_to, copy_from, copy_rows);
	  copy_from += j; copy_to += k;
	}

      } else {			/* row-wise organisation */

	if ((rows > from->rows) || (cols > from->cols)) {
	  /* this is inefficient, but easier to code */
	  memset (new->values,0,rows * cols * width);
	}

        copy_cols=((cols > from->cols) ? from->cols : cols) * width;
	copy_rows=((rows > from->rows) ? from->rows : rows);

	copy_from=from->values;   j=from->cols * width;
	copy_to  =new ->values;   k=      cols * width;

	for (i=0; i < copy_rows; ++i) {
	  memcpy(copy_to, copy_from, copy_cols);
	  copy_from += j; copy_to += k;
	}
      }

    } else {

      /*
        can't do simple copy or optimised row-wise/col-wise copy, so
        we have to copy each element individually.
      */
      copy_cols=((cols > from->cols) ? from->cols : cols);
      copy_rows=((rows > from->rows) ? from->rows : rows);

      if ((rows > from->rows) || (cols > from->cols)) {
        /* this is inefficient, but easier to code */
	memset (new->values,0,rows * cols * width);
      }

      from_right = gf2_matrix_offset_right(from);
      from_down  = gf2_matrix_offset_down (from);
      to_right   = gf2_matrix_offset_right(new);
      to_down    = gf2_matrix_offset_down (new);

      for (i=0; i < copy_rows; ++i) {
	for (j=0; j < copy_cols; ++j) {
	  memcpy(new->values  + i * to_down   + j * to_right,
		 from->values + i * from_down + j * from_right,
		 width);
	}
      }
    }
  }

  return new;

}

void gf2_matrix_free (gf2_matrix_t *m) {
  if (m->alloc_bits & 1)
    free(m->values);
  if (m->alloc_bits & 2)
    free(m);
}

/* Create a new identity matrix or if passed an existing matrix, store
   an identity matrix in it. If matrix is passed in, any other passed
   values may be set to 0 to indicate that the values from the
   existing structure should be used. Otherwise, they should agree
   with the stored values, or else the routine returns with an error.

   Returns pointer to matrix on success, or NULL otherwise.
*/

gf2_matrix_t*
gf2_identity_matrix (gf2_matrix_t* dest, int rows, int cols, 
		     int width, int org) {

  int   i,j,k;

  if (dest == NULL) {

    if (rows != cols)                         return NULL;
    if ((rows <= 0) || (cols <= 0))	      return NULL;
    if ((width <= 0) || (width > 128))	      return NULL;
    if (org == 0)			      return NULL;

    dest=malloc(sizeof(gf2_matrix_t));
    if (dest == NULL) return NULL;

    dest->values=malloc(rows * cols * width);
    if (dest->values == NULL) {
      free(dest);
      return NULL;
    }

    dest->alloc_bits=FREE_BOTH;

    dest->rows         = rows;
    dest->cols         = cols;
    dest->width        = width;
    dest->organisation = org;

  } else {

    if (dest->rows != dest->cols)             return NULL;
    if (rows  && (dest->rows != rows))        return NULL;
    if (cols  && (dest->cols != rows))        return NULL;
    if (org   && (dest->organisation != org)) return NULL;
    if (width && (dest->rows != width))       return NULL;

    /* update local vars with values from struct */
    rows=dest->rows;
    cols=dest->cols;
    width=dest->width;

  }

  /*
    Blank matrix values, then set diagonal elements to 1.
      Since the matrix is square, we don't need to distinguish between
    ROWWISE/COLWISE organisation.
  */
  memset(dest->values, 0, rows * cols * width);
  i=0; j=width-1;
  k=(rows + 1) * width;           /* offset of next diagonal */
  do {
    (dest->values)[j]=1;	      	 /* set low byte/bit */
    j+=k;
  } while (++i < rows);

  return dest;
}

/*
  Some routines to help find the location of a given cell within the
  block allocated to the matrix and otherwise navigate within that
  block. All take account of the organisation setting for the matrix,
  where relevant. The most efficient way to navigate a matrix would be
  to write a routine which assumes a certain ROWWISE/COLWISE
  organisation. The next best would be to call gf2_matrix_offset_right
  and gf2_matrix_offset_down once in the code and then use them to
  traverse to the right/down the matrix. The least efficient way would
  be to call gf2_matrix_offset to calculate the address of the desired
  row and colum.
*/

int gf2_matrix_row_size_in_bytes (gf2_matrix_t *m) {

  if (m == NULL) return 0;

  return (m->cols * m->width);
}

int gf2_matrix_col_size_in_bytes (gf2_matrix_t *m) {

  if (m == NULL) return 0;

  return (m->rows * m->width);
}

/* 
  offset of the matrix element to the right of this one (no checks for
  end of row)
*/
int gf2_matrix_offset_right (gf2_matrix_t *m) {

  if (m == NULL) return 0;

  switch (m->organisation) {
  case ROWWISE:
    return m->width;
  case COLWISE:
    return m->rows * m->width;
  }
  return 0;
}

int gf2_matrix_offset_down (gf2_matrix_t *m) {

  if (m == NULL) return 0;

  switch (m->organisation) {
  case ROWWISE:
    return m->cols * m->width;
  case COLWISE:
    return m->width;
  }
  return 0;
}

/*
  Note we use (row, column) style rather than (x,y). Also, we return
  the address of the chosen element rather than an offset, since this
  is usually more useful. Since this is the least efficient method
  (and it's documented as such), we can afford to do some bounds
  checking here, since presumably efficiency is not the main concern.
*/
char* gf2_matrix_element (gf2_matrix_t *m, int r, int c) {
  if (m == NULL) return NULL;

  if ((r < 0) || (r >= m->rows)) return NULL;
  if ((c < 0) || (c >= m->cols)) return NULL;

  return (char*) (m + (gf2_matrix_offset_down(m) * r) +
                      (gf2_matrix_offset_right(m) * c));

}

/*
  invert a matrix, returning a new one or NULL on error. Clobbers
  original matrix (turns it into an identity matrix, actually, if
  everything proceeded correctly, since I'm using the Gauss-Jordan
  elimination algorithm). This algorithm is about O(n^3) which is
  sub-optimal, but should be fine for relatively small matrices.
*/
gf2_matrix_t* gf2_matrix_invert(gf2_matrix_t *m) {

  gf2_matrix_t* inverse;
  int           rows, width, org;
  int           move_right,move_down;
  int           i,j,k;

  char*         diagonal_element;
  char*         current_element;
  char*         top_of_row;
  char*         top_of_col;
  char*         scan_down;
  char*         current_row;
  char*         current_id_row;
  char*         scan_down_id;
  char          can_remove_zero;

  char          *x, *y, *z, *scratch;

  if (m == NULL)          return NULL;
  if (m->rows != m->cols) return NULL;

  rows  = m->rows;
  width = m->width;
  org   = m->organisation;

  scratch=malloc(width * 4);
  if (scratch == NULL)    return NULL;
  x=scratch + width;
  y=x       + width;
  z=y       + width;

  inverse=gf2_identity_matrix(NULL,rows,rows,width,org);
  if (inverse == NULL) {
    free(scratch);
    return NULL;
  }

  top_of_col       = m->values;
  diagonal_element = m->values;
  current_id_row   = inverse->values;

  move_right=gf2_matrix_offset_right(m);
  move_down =gf2_matrix_offset_down (m);

  for (i=0; i < rows; ++i) {	/* i counts across columns */

    /* do we have a zero in the diagonal? if so, try to remove it */
    if(vector_eq_byte(diagonal_element,0,width)) {
      can_remove_zero = 0;
      scan_down       = top_of_row;
      scan_down_id    = inverse->values;
      for (j=0; j < rows; ++j) { /* scan down rows */
        if (i==j) continue;
        if (vector_ne_byte(scan_down,0,width)) {
          can_remove_zero=1;
          memcpy(diagonal_element,scan_down,width);
	  break;
	}
	scan_down    += move_down;
	scan_down_id += move_down;
      }
      if (!can_remove_zero) {
	free(scratch);
        free(inverse->values);
	free(inverse);
	return NULL;
      }
      for (k=0; k < rows ; ++k) {
        vector_xor(current_id_row + k * move_right,
	           scan_down_id   + k * move_right,
		   width);
        if (k > i)
          vector_xor(current_row  + (k  ) * move_right,
	             scan_down    + (k-i) * move_right,
		     width);
      }
    }

    /* UNFINISHED */


    /* Now zero all non-diagonal elements in this column */
    for (j=0; j < rows; ++j) {	/* j counts down rows */

      current_row    += move_down;
      current_id_row += move_down;

    }

    /* normalise diagonal to 1 */




    top_of_row += move_right;

  }

  free(scratch);
  return inverse;

}

/*
  Multiply matrices: result <- a * b. If result is not already
  instantiated, it will be created.  Returns 0 on success.
*/
int gf2_matrix_multiply (gf2_matrix_t* result, char org, char* poly,
			 gf2_matrix_t* a, gf2_matrix_t* b) {
  /*
    No attempt at optimisations will be made here, as I'm not likely
    to use this code. I'm doing it more so I have working reference
    code to act as a template for gf2_circular_matrix_multiply
  */

  char  did_alloc=0;
  int   width;
  char* p, *scratch;
  int   i,j,k;

  /*
    Check that the input matrices are properly instantiated and are of
    dimensions suitable for multiplication (since we're multiplying
    matrices, the order they're presented in may be significant here).
  */
  if ((a == NULL) || (b == NULL) || (poly == NULL))
    return 1;

  if ((a->cols != b->rows) /* || (a->rows != b->cols) */ ||
      (a->width != b->width))
    return 1;
  width=a->width;

  if ((result != NULL) && (result->organisation != org))
    return 1;

  /* allocate a new matrix if one wasn't already provided */
  if (result == NULL) {
    result=gf2_matrix_alloc (NULL, a->rows, b->cols, width, org);
    did_alloc=1;
  }
  if (result == NULL) return ENOMEM;

  scratch=malloc(width * 2);
  if (scratch == NULL) {
    if (did_alloc) free(result);
    return ENOMEM;
  }
  p=scratch+width;

  for (i=0; i < result->rows; ++i) {
    for (j=0; j < result->cols; ++j) {
      for (k=0; k < a->cols; ++k) {
	gf2_multiply(p,
		     gf2_matrix_element(a,i,k),
		     gf2_matrix_element(b,k,j),
		     poly,width,scratch);
	vector_xor(gf2_matrix_element(result,i,j),p,width);
      }
    }
  }

  free(scratch);
  return 0;
}

/*
  gf2_transform_streams is a matrix multiply function using circular
  input and output buffers. Multiplication is done on one full column
  of the input/output matrices at a time, with callbacks being used to
  fill the input buffer or empty the output buffer as needed. The
  function takes the following parameters:

  * An input matrix
  * A transformation matrix
  * An output matrix
  * A polynomial to be used for the multiplication
  * An arry of callback closures for filling elements in the input matrix
  * A number indicating how many fill callbacks there are
  * An array of callback closure for emptying elements from the output matrix
  * A number indicating how many empty callbacks there are
  * A length parameter, specifying how many input bytes to read

  The last parameter should be a multiple of the input matrix's column
  size (in bytes). It can be set to zero to indicate that the multiply
  should proceed until there is no more input to process.

  Callback closures are effectively wrappers around simple function
  pointers which allow extra identifying information (such as a
  filehandle) to be passed along with it, without the calling routine
  having to know anything about the type of data it's passing.

  The callbacks themselves take three parameters, the first two of
  which are of type gf2_matrix_closure_t (which the callback can
  interrogate to find its private data) and a (char) pointer to a
  block of memory to be filled/emptied. The remaining argument
  specifies the MAXIMUM number of bytes that the callback is allowed
  to put into or take out from the buffer. Callbacks may fill or empty
  less than the requested number of bytes, and they should return the
  ACTUAL number of bytes filled or emptied. A fill callback which has
  no more input should return 0 to signify eof.

  This routine returns the number of bytes actually processed
*/

OFF_T
gf2_transform_streams (gf2_matrix_t *in, gf2_matrix_t *transform,
		       gf2_matrix_t *out, char* poly,
		       gf2_matrix_closure_t fill_some,
		       gf2_matrix_closure_t empty_some,
		       OFF_T bytes_to_read) {

  OFF_T bytes_read=0;
  int       width;

  /* variables for controlling usage of input/output buffer */
  char*     IR;			/* input read ptr (where we read) */
  char*     IW;			/* input write ptr (where callback writes) */
  char*     OW;			/* output write ptr (where we write) */
  char*     OR;			/* output read ptr (where callback reads) */
  char*     IEND;		/* last address in input buffer */
  char*     OEND;		/* last address in output buffer */
  OFF_T ILEN;
  OFF_T OLEN;
  OFF_T IF,	OF;		/* input/output fill levels (bytes) */
  int       col_size;		/* min amount of input we need to process */
  char      eof;
  OFF_T rc;
  OFF_T max_fill_or_empty;

  /* variables for doing the matrix multiply */
  int       i,j,k;
  char*     p;
  char*     scratch;
  char*     trow;
  char*     icol;
  char*     ocol;
  OFF_T idown,iright,odown,oright,tdown,tright;

  /*
    Many checks based on code in gf2_matrix_multiply, but we have a
    few new ones
  */

  if ((in == out) || (in == transform) || (transform == out)) {
    printf("ERROR: in, out and transform must be separate matrices\n");
    return 0;
  }
    
  if ((in == NULL) || (out == NULL) || (poly == NULL) || (transform == NULL)) {
    printf("ERROR: NULL matrix/poly passed to gf2_circular_matrix_multiply\n");
    return 0;
  }

  /* 
     we don't have to check all dimensions for compatibilty; we can
     allow input matrix and output matrix to have different numbers of
     columns since they're actually buffers in this direction, and not
     matrices. Also, the algorithm produces one column of output for
     each column of input, so the output is guaranteed to have the
     same number of columns as the input.
  */
  if ((in->cols != transform->rows) || (transform->rows != out->rows)) {
    printf("ERROR: incompatible matrix sizes in gf2_circular_matrix_multiply\n");
    return 0;
  }

  width=in->width;
  if ((out->width != width) || (transform->width != width)) {
    printf("ERROR: Differing element widths in gf2_circular_matrix_multiply\n");
    return 0;
  }
  col_size=width * transform->cols;

  if ((in->organisation != COLWISE) || (transform->organisation != ROWWISE) ||
      (out->organisation != ROWWISE)) {
    printf("ERROR: expect matrices to be COLWISE, ROWWISE, ROWWISE respectively\n");
    return 0;
  }

  if (bytes_to_read % col_size) {
    printf("ERROR: number of bytes to read should be a multiple of k * s\n");
    return 0;
  }

  scratch=malloc(width * 2);
  if (scratch == NULL) {
    printf("ERROR: failed to allocate memory in gf2_circular_matrix_multiply\n");
    return 0;
  }
  p=scratch+width;

  idown=gf2_matrix_offset_down(in);        iright=gf2_matrix_offset_right(in);
  odown=gf2_matrix_offset_down(out);       oright=gf2_matrix_offset_right(out);
  tdown=gf2_matrix_offset_down(transform); 
  tright=gf2_matrix_offset_right(transform);

  IF=0; OF=0;
  ILEN=in ->rows * in ->cols * in ->width;  IEND=in ->values + ILEN - 1;
  OLEN=out->rows * out->cols * out->width;  OEND=out->values + OLEN - 1;  
  eof=0;

  do {

    while (!eof && (IF < col_size)) {

      /* 
	 We need to pass a max_fill value to fill_sub which will
	 neither overflow the buffer, nor overwrite as-yet unread
	 input.
      */
      max_fill_or_empty=ILEN-IF;

      if (IW >= IR) {		/* possible buffer overflow */
	if (IW + max_fill_or_empty > IEND) {
	  max_fill_or_empty=IEND - IW + 1;
	}
      } else {			/* possible write over unread items */
	if (IW + max_fill_or_empty >= IR) {
	  max_fill_or_empty=IR - IW;
	}
      }

      /*
	Another kind of overflow is reading more bytes than we've been
	told to, which would also be bad. The test below will only
	ever decrease the value in max_fill_or_empty, and never
	increase it. We need to be sure of this property since
	otherwise we might re-introduce one of the other kinds of
	buffer overflow we tried to avoid above.
      */
      if (bytes_to_read && 
	  (bytes_read + IF + max_fill_or_empty > bytes_to_read))
	max_fill_or_empty=bytes_to_read - IF - bytes_read;

      /* 
	 call the closure/callback telling it who it is, where to
	 write and the max number of bytes to write.
      */
      rc=(*(fill_some->fp))(fill_some,IW,max_fill_or_empty);

      /* check return value */
      if (rc < 0) {
       printf ("ERROR: read error on input stream: %s\n",strerror(errno));
      } else if (rc == 0) {
	eof = 1;
      } else {
	IF+=rc; IW+=rc;
	if (IW > IEND) IW -= ILEN;
	bytes_read+=rc;
	/* only check bytes_to_read if it wasn't set to 0 to signify
	   read until eof */
	if (bytes_to_read && (IF + bytes_to_read >= bytes_to_read))
	  eof=1;
      }
    }

    do {			/* see below; loop to flush output */

      /* Do we have enough space in oputput buffer to allow us to process */
      /* a chunk? If not, empty some until we do.                         */
      while ((eof && OF) || (OF + col_size > OLEN)) {

	max_fill_or_empty=OF;

	/* we want empty_sub to read from the tail, but we have to make */
	/* sure that emptying at the tail is neither going to overflow the */
	/* buffer nor empty data at head which we haven't written yet. */
	if (OR >= OW)  {	/* possible buffer overflow */
	  if (OF + col_size > OLEN) {
	    max_fill_or_empty=OEND - OR + 1;
	  }
	} else {		/* possible write over unwritten data */
	  if (OR + col_size > OW) {
	    max_fill_or_empty=OW - OR;
	  }
	}

	rc=(*(empty_some->fp))(empty_some,OR,max_fill_or_empty);

	if (rc ==0) {
	  printf ("ERROR: write error in gf2_circular_matrix_multiply\n");
	  return 0;
	}

	OF-=rc;
	OR+=rc;
	if (OR > OEND) OR -= OLEN;
      }

      /*
	The actual processing ... produce one column of output from
	one column of input
      */
      while ((IF >= col_size) && (OF + col_size <= OLEN)) {

	unsigned char sum;

	/* for each row of transform matrix ...*/
	for (i=0, trow=transform->values;
	     i < transform->rows ; 
	     ++i, trow+=tdown ) {

	  /* multiply first row element by first column element */
	  icol=IR; ocol=OW;
	  //	  gf2_multiply(ocol,trow,icol,poly,width,scratch);
	  sum = gf2_mul8(*trow, *icol);

	  /* then add the products of all the rest */
	  for (j=1; j < transform->cols; ++j) {
	    //	    gf2_multiply(p,trow + j * tright,icol + j * idown, poly,width,scratch);
	    sum ^= gf2_mul8(*(trow + j * tright), *(icol + j * idown));
	    // vector_xor(ocol + j * odown,p,width);
	    *(ocol + j * odown) ^= sum;
	    printf("foo");// this routine isn't called!!!
	  }

	  IF-=col_size; OF+=col_size;
	  IR+=col_size; if(IR>IEND) IR-=ILEN;
	  OW+=col_size; if(OW>IEND) OW-=OLEN;
	}
      }
      
      /* If we're at eof here, we keep looping until all output is flushed... */

    } while (eof && OF);


  } while (!eof);
}

/*------------------------------------------------------------------*/

/* signal handler to periodically print status information */
void sig_alarm_handler(int signum) {

         int   i;
  static char  buf[CMDBUFSIZ];
         char* s=buf;
	 int   save_errno=errno;

  if (codec.current_operation == 17) {

    /* want to create the full status string before writing it to
       stdout to avoid a situation where the reading process doesn't
       get a full line to read
    */
    s+=sprintf(buf,"STATUS: ");
    for (i=0; i < codec.nextchild; ++i) {
      s+=sprintf(s,OFF_T_FMT " ",(OFF_T) 
		 codec.children[i]->current_offset);
    }
    printf("%s\n",buf);
    fflush(stdout);
  } else if (codec.current_operation != NOTHING) {
    printf("STATUS: " OFF_T_FMT "\n",(OFF_T) codec.current_offset);
    fflush(stdout);
  }

  /* need to re-enable our sighandler? */
  /*  signal(SIGALRM, &sig_alarm_handler); */
  alarm (codec.timer);
  errno=save_errno;
}

/*-----------------------------------------------------------------*/

/* create many shares at once, in a single loop */
int create_many_shares(int nshares,int* share_list) {
  int   in_fd;			/* single file for reading */
  int*  out_fds;		/* array of output file descriptors */
  int   i,j,k;
  int   pad=0;
  int   col_size=codec.sec_level * codec.k;
  char* col;
  char* m;
  char* total;
  char* product;
  char* scratch;
  OFF_T rc;  

  /* open files, exiting on error */
  i=open(codec.infile, O_RDONLY);
  if (i < 0) {
       i=errno;
       printf ("ERROR: Unable to open input file %s: %s\n", 
	       codec.infile, strerror(i));
    return i;
  }
  in_fd=i;
  if (lseek(in_fd,codec.range_start,SEEK_SET)
      != codec.range_start) {
    i=errno;
    printf ("ERROR: Unable to seek to start of input range "
	    OFF_T_FMT ": %s\n", 
	    codec.range_start, strerror(i));
    return i;
  }

  out_fds=malloc(nshares * sizeof(int));
  if (out_fds == (int*) 0)  return ENOMEM;
  for (i=0; i<nshares; ++i) {
    if ((out_fds[i]=open(codec.sharefiles[share_list[i]], 
                         O_WRONLY)) < 0) {
      i=errno;
      printf ("ERROR: Unable to open output file %s: %s\n", 
	      codec.sharefiles[share_list[i]], strerror(i));
      return i;
    }
    if (lseek(out_fds[i],codec.share_header_size,SEEK_SET)
        != codec.share_header_size) {
      i=errno;
      printf ("ERROR: Unable to seek past share file header %s: %s\n", 
	      codec.sharefiles[i], strerror(i));
      return i;
    }
  }

  /* more initialisation */
  codec.current_offset=codec.range_start; /* offset in input file */
  col=malloc(col_size);
  if (col==(char*)0)     return ENOMEM;
  
  /* allocate three temporary variable: two for us, one for
     gf2_multiply */
  scratch=malloc(3* codec.sec_level);
  if (scratch==(char*)0)  return ENOMEM;
  product=&scratch[codec.sec_level];
  total=  &scratch[2* codec.sec_level];

  /* read first column of input */
  if (codec.range_next && codec.current_offset >= codec.range_next ) {
    i=0;
  } else {
    do {
      rc=read(in_fd,col,col_size);
    } while ((rc==-1) && (errno == EINTR));
    codec.current_offset+=col_size;
  }

  while (i>0) {
    if (i<col_size) {
      memcpy(col+i,codec.padding,(col_size -i) * codec.sec_level);
    }

    /* for each row to process */
    for (j=0; j <nshares; ++j) {

      /* multiply first row element by first column element */
      m=codec.matrix + share_list[j] * col_size;
      gf2_multiply(total,m,col,codec.poly,codec.sec_level,scratch);

      for (k=1; k < codec.k; ++k) {
        m+=codec.sec_level;
        gf2_multiply(product,m,col + k*codec.sec_level,
                     codec.poly,codec.sec_level,scratch);
	vector_xor(total,product,codec.sec_level);
      }

      /* output result of calculation to this row's file */
      do {
	rc=write(out_fds[share_list[j]],total,codec.sec_level);
      } while ((rc == -1) && (errno == EINTR));
      if (rc == -1) {
	return -1;
      }
    }

    /* read next column of input */
    if (codec.range_next && codec.current_offset >= codec.range_next ) {
      i=0;
    } else {
      do {
	i=read(in_fd,col,col_size);
      } while ((i==-1) && (errno == EINTR));
      codec.current_offset+=col_size;
    }
  }

  /* cleanup */
  close (in_fd);
  for (i=0; i < nshares; ++i) {
    close (out_fds[share_list[i]]);
  }
  free(out_fds);
  free(col);
  free(scratch);

  return 0;			/* success */

}

int combine_shares(int nshares,int* share_list) {
  int*  in_fds;			/* array of input file descriptors */
  int   out_fd;			/* single file for writing */
  int   i,j,k;
  int   col_size=codec.sec_level * codec.k;
  char* col;
  char* m;
  char* total;
  char* product;
  char* scratch;
  char  eof=0;

  /* open files, exiting on error */
  i=open(codec.outfile, O_CREAT|O_WRONLY, 0644);
  if (i < 0) {
       i=errno;
       printf ("ERROR: Unable to create outfile file %s: %s\n", 
	       codec.outfile, strerror(i));
    return i;
  }
  out_fd=i;
  if (lseek(out_fd,codec.range_start,SEEK_SET)
      != codec.range_start) {
    i=errno;
    printf ("ERROR: Unable to seek to start of output range "
	    OFF_T_FMT ": %s\n", 
	    (OFF_T) codec.range_start, strerror(i));
    return i;
  }


  in_fds=malloc(nshares * sizeof(int));
  if (in_fds == (int*) 0)  return ENOMEM;
  for (i=0; i<nshares; ++i) {
    if ((in_fds[i]=
	 open(codec.sharefiles[share_list[i]], O_RDONLY)) < 0) {
      i=errno;
      printf ("ERROR: Unable to open input file %s: %s\n", 
	      codec.sharefiles[share_list[i]], strerror(i));
      return i;
    }
    if (lseek(in_fds[i],codec.share_header_size,SEEK_SET)
	!= codec.share_header_size) {
      i=errno;
      printf ("ERROR: Unable to seek past share file header %s: %s\n", 
	      codec.sharefiles[i], strerror(i));
      return i;
    }
  }

  /* more initialisation */
  codec.current_offset=codec.range_start; /* offset in output file */
  col=malloc(col_size);
  if (col==(char*)0)     return ENOMEM;
  
  /* allocate three temporary variable: two for us, one for
     gf2_multiply */
  scratch=malloc(3* codec.sec_level);
  if (scratch==(char*)0)  return ENOMEM;
  product=&scratch[codec.sec_level];
  total=  &scratch[2* codec.sec_level];

  /* read one word per input share to fill column for multiply */
  if (codec.range_next && codec.current_offset >= codec.range_next ) {
    eof+=codec.k;
  } else {
    for (j=0; j <nshares; ++j) {
      do {
	i=read(in_fds[share_list[j]],
	       col + share_list[j] * codec.sec_level,codec.sec_level);
      } while ((i==-1) && (errno == EINTR));
      if (i < codec.sec_level)  ++eof;
    }
  }

  while (!eof) {

    for (j=0; j <nshares; ++j) { /* for each row to process */

      /* multiply first row element by first column element */
      m=codec.inverse + share_list[j] * col_size;
      gf2_multiply(total,m,col,codec.poly,codec.sec_level,scratch);

      /* multiply remaining row, column elements */
      for (k=1; k < codec.k; ++k) {
        m+=codec.sec_level;
        gf2_multiply(product,m,col + k*codec.sec_level,
                     codec.poly,codec.sec_level,scratch);
	vector_xor(total,product,codec.sec_level);
      }

      /* output one word per row processed */
      do {
	i=write(out_fd,total,codec.sec_level);
      } while ((i==-1) && (errno == EINTR));

    }
    codec.current_offset+=col_size; /* counts bytes written to output */

    /* read next column */
    if (codec.range_next && codec.current_offset >= codec.range_next ) {
      eof+=codec.k;
    } else {
      for (j=0; j <nshares; ++j) {
	do {
	  i=read(in_fds[share_list[j]],
		 col + share_list[j] * codec.sec_level,codec.sec_level);
	} while ((i==-1) && (errno == EINTR));
	if (i<codec.sec_level)  ++eof;
      }
    }
  }

  /* cleanup */
  close (out_fd);
  for (i=0; i < nshares; ++i) {
    close (in_fds[share_list[i]]);
  }
  free(in_fds);
  free(col);
  free(scratch);

  if (eof % codec.k) 
    printf ("ERROR: share size mismatch; output probably truncated\n");
  return eof % codec.k;			/* 0 == success */

}

/*-----------------------------------------------------------------*/

/* helper functions for parsing and validating commands from stdin */

char* parse_hex(char* dest,int length, char* string) {

  int i;
  char lo,hi;
  char did_alloc=0;

  /* malloc new space if we weren't passed a place to store the result  */
  if (dest == NULL) {
    if ((dest=malloc(length))==NULL) return NULL; else did_alloc=1;
  }

  for (i=0; i < (length <<1); i+=2) {
    hi=tolower(string[i]);
    lo=tolower(string[i+1]);

    if (hi >= '0' && hi <= '9') {
      hi = hi - '0';
    } else if (hi >= 'a' && hi <= 'f') {
      hi = hi - 'a' + 10; 
    } else {
      if (did_alloc) free(dest);
      return NULL;
    }
    
    if (lo >= '0' && lo <= '9') {
      lo = lo - '0';
    } else if (lo >= 'a' && lo <= 'f') {
      lo = lo - 'a' + 10; 
    } else {
      if (did_alloc) free(dest);
      return NULL;
    }

    dest[i>>1]=(hi << 4) | lo;

  }

  /* allow trailing spaces */
  if (string[i] == '\0' || isspace(string[i]))
    return dest;

  /* but fail if there's any other trailing junk */
  if (did_alloc) free(dest);
  return NULL;
}

/* slightly different from parse_hex in that we assume that the array
   pointer passed to us is already allocated. Also, instead of passing
   back the same pointer (or a newly allocated one, which we don't do
   anyway), we return the number of items we put in the list. If the
   specification is garbled or we would overrun the list, we return 0.
*/
int parse_share_list (int* dest, int max_len, char* s) {
  unsigned c,i,j,x,y;
  char     garbled=0;

  i=0;
  while (*s != '\0') {
    c=sscanf(s,"%u-%u",&x,&y);	/* '-' doesn't count towards c */
    if (c==0) {
      garbled=1; break;
    } else if (c==1) {
      if (i >=max_len) return 0;
      dest[i++]=x;
      do { ++s; } while (isdigit(*s));
    } else if (c==2) {
      if (x > y) {
	garbled=1; break;
      }
      for (j=x; j <= y; j++) {
	if (i >= max_len) return 0;
	dest[i++]=j;
      }
      s=strchr(s,'-');
      do { ++s; } while (isdigit(*s));
    }
    if (*s == ',') ++s;
  }
  return garbled ? 0 : i;
}

char parse_range (char *s, OFF_T* low, 
		  OFF_T* high) {
  char c=sscanf(s,"%lu-%lu",low,high);
  if (c != 2)        return c;
  if (*low > *high)  return 0;
  return c;
}

/* Check whether we have sufficient info to start splitting */
char check_split_settings(void) {

  if (!codec.n || !codec.k || !codec.order || !codec.sec_level ||
      !codec.nsharefiles || !codec.infile || ! codec.matrix )
    return 0;

  if (codec.matrix_elements < codec.n * codec.k)
    return 0;

  return 1;
}

/* check same for combine */
char check_combine_settings(void) {

  if (!codec.n || !codec.k || !codec.order || !codec.sec_level ||
      !codec.nsharefiles || !codec.outfile || !codec.inverse)
    return 0;

  if (codec.inverse_elements < codec.k * codec.k)
    return 0;

  return 1;
}

/*
  Main command interpreter loop read commands from stdin and output
  results to stdout.
*/
void command_interpreter (void) {

  char  buf[CMDBUFSIZ];
  char* s;
  char* cmd;
  char* arg;
  int*  sharelist=NULL;
  sighandler_t old_alarm_handler;

  int   i,j;

  memset(&codec,0,sizeof(codec));

  /* assume a simple 'command whitespace optional_arg \n' pattern */
  while(fgets(buf,CMDBUFSIZ,stdin) != NULL) {

    if (buf[0] == '#')   continue; /* simple comments */
    buf[strlen(buf)-1]='\0';       /* remove newline  */
    for(i=0; i< strlen(buf); ++i) {
      if (isspace(buf[i]))  break; /* found first space */
      buf[i]=tolower(buf[i]);	   /* make commands case-insensitive */
    }

    do {
      buf[i++]='\0';
    } while (i<strlen(buf) && isspace(buf[i]));

    cmd=buf;
    arg=buf+i;

    /* printf("Got command '%s', arg '%s'\n",cmd,arg); */

    if (!strcmp("shares",cmd) || !strcmp("n",cmd)) {               /* shares */
      i=atoi(arg);
      if (codec.n) {
        printf("WARN: ignoring extra value for shares: %d\n",i);
      } else {
	codec.n=i;
      }

    } else if (!strcmp("quorum",cmd) || !strcmp("k",cmd)) {        /* quorum */
      i=atoi(arg);
      if (codec.k) {
        printf("WARN: ignoring extra value for quorum: %d\n",i);
        continue;
      }
      codec.k=i;

    } else if (strcmp("security",cmd)==0) {                      /* security */
      i=atoi(arg);
      if (codec.sec_level) {
        printf("WARN: ignoring extra value for security: %d\n",i);
      } else if (i > 128) {
        printf("WARN: Invalid value for security: %d\n",i);
      } else {
	codec.sec_level=i;
	codec.order=i << 3;
      }

    } else if (strcmp("poly",cmd)==0) {	                             /* poly */
      if (!codec.sec_level) {
        printf("WARN: poly can only be used after security\n");
        continue;
      }
      if ((codec.poly=parse_hex(NULL,codec.sec_level,arg))==NULL)
	printf("WARN: invalid hex value %s passed to poly\n",arg);

    } else if (strcmp("header",cmd)==0) {                          /* header */
      i=atoi(arg);
      if (codec.share_header_size) {
        printf("WARN: ignoring extra value for header: %d\n",i);
        continue;
      }
      codec.share_header_size=i;


    } else if (strcmp("spawn",cmd)==0) {                            /* spawn */
      i=atoi(arg);
      codec.maxchildren=i;

    } else if (strcmp("timer",cmd)==0) {                            /* timer */
      i=atoi(arg);
      codec.timer=i;

    } else if (strcmp("infile",cmd)==0) {                          /* infile */
      if (codec.infile != NULL) {
        printf("WARN: ignoring extra value for infile: %s\n",arg);
	continue;
      }
      if (codec.infile=malloc(strlen(arg)+1)) {
	strcpy(codec.infile,arg);
      } else {
	printf("ERROR: malloc of infile name failed. Aborting\n");
        exit(1);
      }

    } else if (strcmp("range",cmd)==0) {                            /* range */
      if (parse_range(arg,&codec.range_start,&codec.range_next)!=2) {
	printf("WARN: garbled range line; ignored\n");
      }

    } else if (strcmp("outfile",cmd)==0) {                        /* outfile */
      if (codec.outfile != NULL) {
        printf("WARN: ignoring extra value for outfile: %s\n",arg);
	continue;
      }
      if (codec.outfile=malloc(strlen(arg)+1)) {
	strcpy(codec.outfile,arg);
      } else {
	printf("ERROR: malloc of outfile name failed. Aborting\n");
        exit(1);
      }

    } else if (strcmp("sharefile",cmd)==0) {                    /* sharefile */
      if (codec.n == 0 || codec.sec_level == 0) {
	printf("WARN: Supply n and security before sharefile\n");
        continue;
      }
      if (codec.sharefiles == NULL) {
        codec.sharefiles=malloc(codec.n * sizeof (char*));
        codec.nsharefiles=0;
      }
      if (codec.sharefiles == NULL) {
	printf("ERROR: malloc of sharefiles array failed. Aborting\n");
        exit(1);
      }
      if (codec.nsharefiles >= codec.n) {
	printf("WARN: Ignoring extra sharefile %s\n",arg);
        continue;
      }
      if (codec.sharefiles[codec.nsharefiles]=malloc(strlen(arg)+1)) {
	strcpy(codec.sharefiles[codec.nsharefiles],arg);
	++codec.nsharefiles;
      } else {
	printf("ERROR: malloc of sharefile name failed. Aborting\n");
        exit(1);
      }

    } else if (strcmp("padding",cmd)==0) {                        /* padding */
      if (codec.n == 0 || codec.sec_level == 0) {
	printf("WARN: Supply n and security before padding\n");
        continue;
      }
      if (codec.padding == NULL) {
        codec.padding=malloc((codec.n - 1) * codec.sec_level);
        codec.padding_elements=0;
      }
      if (codec.padding== NULL) {
	printf("ERROR: malloc of padding data failed. Aborting\n");
        exit(1);
      }
      if (codec.padding_elements >= codec.n - 1) {
	printf("WARN: Ignoring padding command on full padding\n");
        continue;
      }
      if (parse_hex((char*) (codec.padding + codec.padding_elements * 
                    codec.sec_level),codec.sec_level,arg)) {
        ++codec.padding_elements;
      } else {
	printf("WARN: invalid hex value %s passed to padding\n",arg);
        continue;
      }

    } else if (strcmp("matrix",cmd)==0) {                          /* matrix */
      if ((codec.n == 0) || (codec.k == 0) || 
	  (codec.sec_level == 0)) {
	printf("WARN: Supply n,k and security before matrix\n");
        continue;
      }
      if (codec.matrix == NULL) {
        codec.matrix=malloc(codec.n * codec.k * codec.sec_level);
        codec.matrix_elements=0;
      }
      if (codec.matrix== NULL) {
	printf("ERROR: malloc of matrix data failed. Aborting\n");
        exit(1);
      }
      if (codec.matrix_elements >= codec.n * codec.k) {
	printf("WARN: Ignoring matrix command on full matrix\n");
        continue;
      }
      if (parse_hex(codec.matrix + codec.matrix_elements * 
                    codec.sec_level,codec.sec_level,arg)) {
        ++codec.matrix_elements;
      } else {
	printf("WARN: invalid hex value %s passed to matrix\n",arg);
        continue;
      }

    } else if (strcmp("inverse",cmd)==0) {                        /* inverse */
      if (codec.k == 0 || codec.sec_level == 0) {
	printf("WARN: Supply k and security before inverse\n");
        continue;
      }
      if (codec.inverse == NULL) {
        codec.inverse=malloc(codec.k * codec.k * codec.sec_level);
        codec.inverse_elements=0;
      }
      if (codec.inverse== NULL) {
	printf("ERROR: malloc of inverse data failed. Aborting\n");
        exit(1);
      }
      if (codec.inverse_elements >= codec.n * codec.k) {
	printf("WARN: Ignoring inverse command on full inverse matrix\n");
        continue;
      }
      if (parse_hex(codec.inverse + codec.inverse_elements * 
		    codec.sec_level,codec.sec_level,arg)) {
        ++codec.inverse_elements;
      } else {
	printf("WARN: invalid hex value %s passed to inverse\n",arg);
        continue;
      }

    } else if (strcmp("split",cmd)==0) {                            /* split */

      if (!check_split_settings()) {
	printf("WARN: Some settings are missing. Can't split yet\n",arg);
        continue;
      }
      if (codec.k > codec.n) {
	printf("WARN: quorum > shares. Ignoring request to split");
        continue;
      }
      if (sharelist != NULL)  free(sharelist);
      sharelist=malloc(codec.n * sizeof(int));
      if (sharelist == NULL) { 
	printf("ERROR: malloc of sharelist failed. Aborting\n");
        exit(1);
      }
      if ((i=parse_share_list(sharelist,codec.n,arg)) == 0) {
	printf("WARN: garbled list of shares to split. Ignoring request\n");
        continue;
      }
      if (codec.timer) {
	codec.current_operation=SPLIT;
	old_alarm_handler=signal(SIGALRM, &sig_alarm_handler);
	alarm (codec.timer);
      }
/* 	if (create_many_shares(i,sharelist)==0) {  */
      ida_split(i,sharelist);
      printf("OK: split finished\n");
      fflush(stdout);
      if (codec.timer) {
	alarm(0);
	signal(SIGALRM,old_alarm_handler);
      }

    } else if (strcmp("combine",cmd)==0) {                        /* combine */

      if (!check_combine_settings()) {
	printf("WARN: Some settings are missing. Can't combine yet\n",arg);
        continue;
      }
      if (sharelist != NULL)  free(sharelist);
      sharelist=malloc(codec.k * sizeof(int));
      if (sharelist == NULL) { 
	printf("ERROR: malloc of sharelist failed. Aborting\n");
        exit(1);
      }
      if ((i=parse_share_list(sharelist,codec.k,arg)) == 0) {
	printf("WARN: garbled list of shares to combine. Ignoring request\n");
        continue;
      }
      if (codec.timer) {
	codec.current_operation=COMBINE;
	old_alarm_handler=signal(SIGALRM, sig_alarm_handler);
	alarm (codec.timer);
      }
      /*       if(combine_shares(i,sharelist)==0) { */
      ida_combine(i,sharelist);	/* screw return values */
      printf("OK: combine finished\n");
      fflush(stdout);
      if (codec.timer) {
	alarm(0);		/* deactivate pending alarms */
	signal(SIGALRM,old_alarm_handler);
      }

    } else if (strcmp("quit",cmd)==0) {                              /* quit */
      return;

    } else if (strcmp("reset",cmd)==0) {                            /* reset */
      codec_reset();

    } else {
      if (*cmd!='\0') 
	printf("WARN: Unknown command %s\n",cmd);
    }

    fflush(stdout);		   /* flush any output from the above */
  }

  
  /* signal (SIGALRM, sig_alarm_handler); */

}

OFF_T 
fill_from_fd (gf2_matrix_closure_t self,char *m,OFF_T len) {

  OFF_T result;

  assert(self->u1_type == 'i'); 

  do {
    result= read(self->u1.i,m,len);
  } while ((result == -1) && (errno == EINTR));

  return result;
}

OFF_T 
empty_to_fd (gf2_matrix_closure_t self,char *m,OFF_T len) {

  OFF_T result  ;
  assert(self->u1_type == 'i'); 

  /* 
    We have to check for EINTR, but not getting back more bytes than
    we asked for, since the calling routine should handle that.
  */
 do {
   result=write(self->u1.i,m,len); 
 } while ((result == -1) && (errno == EINTR));

  return result;
}

OFF_T ida_split(int nshares,int* share_list) {

  gf2_matrix_t* input;
  gf2_matrix_t* output;
  gf2_matrix_t* xform;

  struct gf2_streambuf_control *closures;
  struct gf2_streambuf_control *fill_closure;
  struct gf2_streambuf_control *empty_closures;

  /* how many columns to allocate for buffers? */
  int buffer_cols=8192;

  int   i;
  int   fd;
  OFF_T rc;

  if (codec.n > nshares)
    return 1;

  /* transform matrix is always ROWWISE */
  xform=gf2_matrix_alloc (NULL, nshares, codec.k, 
			  codec.sec_level, ROWWISE);
  if (xform == NULL)
    fatal ("ENOMEM allocate transform matrix");
  /* 
    Now copy transform rows from full transform matrix for each share
    that will be produced.
  */
  for (i=0; i < nshares; ++i) {
    memcpy(xform->values + i * codec.sec_level * codec.k,
	   codec.matrix + share_list[i] * codec.sec_level * codec.k,
	   codec.sec_level * codec.k);
  }

  /* set up input matrix as COLWISE, output as ROWWISE */
  input=gf2_matrix_alloc (NULL, codec.k, buffer_cols, // was nshares
			  codec.sec_level, COLWISE);
  if (input == NULL)
    fatal ("ENOMEM allocating input matrix");
  output=gf2_matrix_alloc (NULL, nshares, buffer_cols,
			   codec.sec_level, ROWWISE);
  if (output == NULL)
    fatal ("ENOMEM allocating output matrix");

  /* allocate closures */
  closures=malloc((nshares +1) * sizeof(struct gf2_streambuf_control));
  if (closures == NULL)
    fatal ("ENOMEM allocating closure array");
  fill_closure   = &closures[0];	/* first one for fill */
  empty_closures = &closures[1];	/* rest for empty */

  /* open all files and save handles in closures */
  fd=open(codec.infile, O_RDONLY);
  if (fd < 0) {
    fd=errno;
    fatal_strerr("Unable to open input file", fd);
  }
  fill_closure->handler.u1_type='i';
  fill_closure->handler.u1.i=fd;
  fill_closure->handler.fp=&fill_from_fd;
  SEEK(fd,codec.range_start,SEEK_SET);

  for (i=0, closures=empty_closures;
       i < nshares;
       ++i, ++closures) {
    fd=open(codec.sharefiles[i], O_WRONLY, 0644);
    if (fd < 0) {
      fd=errno;
      fatal_strerr("Unable to open output file", fd);
    }
    SEEK(fd,codec.share_header_size,SEEK_SET);
    closures->handler.u1_type='i';
    closures->handler.u1.i=fd;
    closures->handler.fp=&empty_to_fd;
  }

  rc=gf2_process_streams(xform, codec.poly,
		      input,  fill_closure,   1,
		      output, empty_closures, nshares,
		      codec.range_next - codec.range_start);

  gf2_matrix_free(input);
  gf2_matrix_free(output);
  gf2_matrix_free(xform);
  return rc;
}


OFF_T ida_combine (int nshares, int sharelist[]) { 

  gf2_matrix_t* input;
  gf2_matrix_t* output;
  gf2_matrix_t* xform;

  struct gf2_streambuf_control *closures;
  struct gf2_streambuf_control *fill_closures;
  struct gf2_streambuf_control *empty_closure;

  /* how many columns to allocate for buffers? */
  int buffer_cols=1;

  int   i;
  int   fd;
  OFF_T rc;

  /* 
    For combining, we expect that the matrix has already been inverted
    before calling this routine, so it will be a k x k square matrix,
    and nshares will be equal to k. We should really be performing the
    inverse ourselves here, but for now just we'll just use the
    inverse matrix provided for us. Since reading in the share header
    is already done for us, the values of k, sec_level,
    share_header_size, range_start and range_next should also be
    available for us in the codec structure.
  */
  /* transform matrix is always ROWWISE */
  xform=gf2_matrix_alloc (NULL, nshares, codec.k, 
			  codec.sec_level, ROWWISE);
  if (xform == NULL)
    fatal ("ENOMEM allocate transform matrix");
  if (codec.k != nshares) 
    fatal ("Number of shares to combine must equal quorum");
  memcpy(xform->values,codec.inverse,
	 codec.k * codec.k * codec.sec_level);

  /* set up input matrix as ROWWISE, output as COLWISE */
  input=gf2_matrix_alloc (NULL, nshares, buffer_cols, 
			  codec.sec_level, ROWWISE);
  if (input == NULL)
    fatal ("ENOMEM allocating input matrix");
  output=gf2_matrix_alloc (NULL, nshares, buffer_cols,
			   codec.sec_level, COLWISE);
  if (output == NULL)
    fatal ("ENOMEM allocating output matrix");

  /* allocate closures */
  closures=malloc((nshares +1) * sizeof(struct gf2_streambuf_control));
  if (closures == NULL)
    fatal ("ENOMEM allocating closure array");
  empty_closure = &closures[0];       /* first one for empty */
  fill_closures = &closures[1];       /* rest for fill */

  /* open all files and save handles in closures */
  fd=open(codec.outfile, O_WRONLY, 0644);
  if (fd < 0) {
    fd=errno;
    fatal_strerr("Unable to open output file", fd);
  }
  empty_closure->handler.u1_type='i';
  empty_closure->handler.u1.i=fd;
  empty_closure->handler.fp=&empty_to_fd;
  SEEK(fd,codec.range_start,SEEK_SET);

  for (i=0, closures=fill_closures;
       i < nshares;
       ++i, ++closures) {
    fd=open(codec.sharefiles[i], O_RDONLY);
    if (fd < 0) {
      fd=errno;
      fatal_strerr("Unable to open input share file", fd);
    }
    SEEK(fd,codec.share_header_size,SEEK_SET);
    closures->handler.u1_type='i';
    closures->handler.u1.i=fd;
    closures->handler.fp=&fill_from_fd;
  }

  rc=gf2_process_streams(xform, codec.poly,
			 input,  fill_closures, nshares,
			 output, empty_closure, 1,
			 codec.range_next - codec.range_start);
  gf2_matrix_free(input);
  gf2_matrix_free(output);
  gf2_matrix_free(xform);
  return rc;
};

// This is the only matrix multiply code actually called!
OFF_T
gf2_process_streams(gf2_matrix_t *xform, char *poly,
		    gf2_matrix_t *in,  
		    struct gf2_streambuf_control *fill_ctl, 
		    int fillers,
		    gf2_matrix_t *out,  
		    struct gf2_streambuf_control *empty_ctl, 
		    int emptiers,
		    OFF_T bytes_to_read) {

  OFF_T  bytes_read=0;
  int    width;

  /* variables for controlling usage of input/output buffer */
  /* All the commented-out variables are now handled in the
     gf2_streambuf_control structure on a per-stream basis. */
  char*     IR;			/* input read ptr (where we read) */
  /*  char*     IW;*/		/* input write ptr (where callback writes) */
  char*     OW;			/* output write ptr (where we write) */
  /* char*     OR; */		/* output read ptr (where callback reads) */
  /* char*     IEND; */		/* last address in input buffer */
  /* char*     OEND; */		/* last address in output buffer */

  /* 
    The following variables can vary depending on whether we have a
    single stream or multiple streams. When dealing with a single
    stream, they represent the full size of the matrix buffer, but for
    multiple streams, the values are divided by the number of streams.
  */
  OFF_T   ILEN;		/* length of input buffer */
  OFF_T   OLEN;		/* length of output buffer */
  OFF_T   IFmin;		/* input fill levels (bytes) */
  OFF_T   OFmax;		/* output fill levels (bytes) */
  OFF_T   want_in_size;	/* min input needed to process */
  OFF_T   want_out_size;	/* min amount of output space needed */

  char      eof;
  OFF_T   rc;
  OFF_T   max_fill_or_empty;
  /*  gf2_matrix_closure_t fill_some; */
  /*  gf2_matrix_closure_t empty_some; */

  /* variables for doing the matrix multiply */
  int    i,j,k;
  char*  p;
  char*  scratch;
  char*  trow;
  char*  icol;
  char*  ocol;
  OFF_T  idown,iright,odown,oright,tdown,tright;

  printf ("Asked to process " OFF_T_FMT " bytes\n", bytes_to_read);

  /*
    Many checks based on code in gf2_matrix_multiply, but we have a
    few new ones
  */

  if ((in == out) || (in == xform) || (xform == out)) {
    printf("ERROR: in, out and xform must be separate matrices\n");
    return 0;
  }
    
  if ((in == NULL) || (out == NULL) || (poly == NULL) || (xform == NULL)) {
    printf("ERROR: NULL matrix/poly passed to gf2_process_streams\n");
    return 0;
  }

#ifndef BUGGED
  if ((out->rows != xform->rows) || (in->cols != out->cols)) {
    printf("ERROR: incompatible matrix sizes gf2_process_streams; ");
    printf(" in rows is %d", in->rows);
    printf(" out rows is %d", out->rows);
    printf(" xform cols is %d", xform->cols);
    printf(" in cols is %d", in->cols);
    printf(" out cols is %d\n", out->cols);
    return 0;
  }
#endif

  width=in->width;
  if ((out->width != width) || (xform->width != width)) {
    printf("ERROR: Differing element widths in gf2_process_streams\n");
    return 0;
  }

  if (((fillers == 1)  && (in->organisation != COLWISE)) ||
      ((emptiers == 1) && (out->organisation != COLWISE)) ) {
    printf("ERROR: expect single-stream buffer to be COLWISE\n");
    return 0;
  }
  if (((fillers > 1) && (in->organisation != ROWWISE)) ||
      ((emptiers > 1) && (out->organisation != ROWWISE)) ) {
    printf("ERROR: expect multi-stream buffer to be ROWWISE\n");
    return 0;
  }
  if (xform->organisation != ROWWISE) {
    printf("ERROR: expect transform matrix to be ROWWISE\n");
    return 0;
  }

  if (bytes_to_read % (width * xform->cols)) {
    printf("ERROR: number of bytes to read should be a full column\n");
    return 0;
  }

  scratch=malloc(width * 2);
  if (scratch == NULL) {
    printf("ERROR: failed to allocate memory in gf2_process_streams\n");
    return 0;
  }
  p=scratch+width;

  idown=gf2_matrix_offset_down(in);  
  iright=gf2_matrix_offset_right(in);
  odown=gf2_matrix_offset_down(out); 
  oright=gf2_matrix_offset_right(out);
  tdown=gf2_matrix_offset_down(xform); 
  tright=gf2_matrix_offset_right(xform);

  /*
    Some variables have different values depending on whether we're
    provided with a single stream or multiple streams
  */
  IFmin=0; OFmax=0;  eof=0;
  OW=out->values;
  IR=in->values;
  if (fillers == 1) {
    ILEN=in->rows * in->cols * in->width; 
    fill_ctl[0].hp.IW = in->values;
    fill_ctl[0].END   = in->values + ILEN - 1;
    fill_ctl[0].BF=0;
    want_in_size = width * in->rows;
  } else {
    ILEN=in->cols * in->width;
    for (i=0; i < fillers; ++i) {
      fill_ctl[i].hp.IW = in->values + i * ILEN;
      fill_ctl[i].END   = fill_ctl[i].hp.IW + ILEN - 1;
      fill_ctl[i].BF=0;
    }
    want_in_size = width;
  }
  if (emptiers == 1) {
    OLEN=out->rows * out->cols * out->width;
    empty_ctl[0].hp.OR = out->values;
    empty_ctl[0].END   = out->values + OLEN - 1;
    empty_ctl[0].BF=0;
    want_out_size = width * out->rows;
  } else {
    OLEN=out->cols * out->width;
    for (i=0; i < emptiers; ++i) {
      empty_ctl[i].hp.OR = out->values + i * OLEN;
      empty_ctl[i].END   = empty_ctl[i].hp.OR + OLEN - 1;
      empty_ctl[i].BF=0;
    }
    want_out_size=width;
  }

  /* printf("want_in_size is %Ld; want_out_size is %Ld\n",
      (long long) want_in_size,(long long) want_out_size); 
      printf("ILEN is %Ld; OLEN is %Ld\n",
      (long long) ILEN,(long long) OLEN); */
  do {

    while (!eof && (IFmin < want_in_size)) {

      /* 
	go through each gf2_streambuf_control struct and request more
	input. Save IFMin as the (new) minimum fill level among them.
      */
      // printf("Need input: IFmin is %Ld\n", (long long) IFmin);

      for (i = 0, IFmin=ILEN; i < fillers; ++i) {
	max_fill_or_empty=ILEN - fill_ctl[i].BF;
	if (fill_ctl[i].hp.IW >= IR + i * idown) {
	  if (fill_ctl[i].hp.IW + max_fill_or_empty > 
	      fill_ctl[i].END)
	    max_fill_or_empty=fill_ctl[i].END - 
	      fill_ctl[i].hp.IW + 1;
	} else {
	  if (fill_ctl[i].hp.IW + max_fill_or_empty >= 
	      IR + i * idown) 
	    max_fill_or_empty=IR  + i * idown -
	      fill_ctl[i].hp.IW;
	}

	// printf ("Before maxfill adjustment: " OFF_T_FMT "\n",max_fill_or_empty); 
	if (bytes_to_read && 
	    (bytes_read + fill_ctl[i].BF + max_fill_or_empty > 
	     bytes_to_read))
	  max_fill_or_empty=
	    bytes_to_read - fill_ctl[i].BF - bytes_read;

	// printf ("Calling fill handler with maxfill " OFF_T_FMT "\n",max_fill_or_empty); 
	/* call handler */
	rc=(*(fill_ctl[i].handler.fp))
	  ( &(fill_ctl[i].handler), fill_ctl[i].hp.IW, max_fill_or_empty);

	/* check return value */
	if (rc < 0) {
	  printf ("ERROR: read error on input stream: %s\n",
	     strerror(errno)); 
	  return 0;
	} else if (rc == 0) {
	  printf ("Natural EOF on input stream\n"); 
	  eof++;
	} else {
	  fill_ctl[i].BF   +=rc;
	  fill_ctl[i].hp.IW+=rc;
	  if (fill_ctl[i].hp.IW > fill_ctl[i].END)
	    fill_ctl[i].hp.IW -= ILEN;
	  bytes_read+=rc;
	  /* WRONG!
	  if (bytes_to_read && 
	      (fill_ctl[i].BF + bytes_read >= bytes_to_read)) {
	    printf ("Read would exceed %lld\n",(long long) bytes_to_read);
	    eof++;
	  }
	  */
	}
	if (fill_ctl[i].BF < IFmin) 
	  IFmin=fill_ctl[i].BF;
      }

      if (eof) {
	printf ("EOF detected in one or more streams\n");  
	if ((fillers > 1) && (eof % fillers)) {
	  printf ("Not all input streams of same length\n");
	  return 0;
	}
      }

    }

    // printf("After input: IFmin is %Ld\n", (long long) IFmin); 
    

    do {			/* loop to flush output */

       // printf ("Checking for output space; OFmax is %Ld\n",
//	 (long long) OFmax); 
 
      /* Do we have enough space in oputput buffer to allow us to process */
      /* a chunk? If not, empty some until we do.                         */
      while ((eof && OFmax) || (OFmax + want_out_size > OLEN)) {

        /* printf ("Seems like we needed to flush\n"); */

	for (i=0,OFmax=0; i< emptiers; ++i) {

	  /* printf ("Outbuf %d is %Ld full, and OFmax is ???\n",
	     i,(long long)empty_ctl[i].BF); */

	  max_fill_or_empty=empty_ctl[i].BF;
	  if (empty_ctl[i].hp.OR >= OW + i * odown)  {
	    if (empty_ctl[i].BF + want_out_size > OLEN) {
	      max_fill_or_empty=empty_ctl[i].END - empty_ctl[i].hp.OR + 1;
	      /* printf ("Stopping overflow, max_empty is now %lld\n", 
		 (long long) max_fill_or_empty); */
	    }
	  } else {
	    if (empty_ctl[i].hp.OR + want_out_size > OW + i * odown) {
		max_fill_or_empty=OW + i * odown - empty_ctl[i].hp.OR;
		/* printf ("Stopping tail overwrite, max_empty is now %Ld\n", 
		   (long long) max_fill_or_empty);  */
	    }
	  }


	  if(max_fill_or_empty == 0) 
	    continue;
	  
	  /* call handler */
	  rc=(*(empty_ctl[i].handler.fp))
	    ( &(empty_ctl[i].handler),empty_ctl[i].hp.OR,max_fill_or_empty);
	  if (rc ==0) {
	    printf ("ERROR: write error in gf2_process_streams\n");
	    return 0;
	  }
	  empty_ctl[i].BF   -=rc;
	  empty_ctl[i].hp.OR+=rc;
	  if (empty_ctl[i].hp.OR > empty_ctl[i].END) 
	    empty_ctl[i].hp.OR -= OLEN;
	  if (empty_ctl[i].BF > OFmax) 
	    OFmax=empty_ctl[i].BF;
	}
      }

      /*
	The actual processing ... produce one column of output from
	one column of input
      */
      // printf ("On to processing: IFmin, OFmax are (%Ld,%Ld)\n",
//	 (long long) IFmin, (long long) OFmax);

      for (k=0;			/* kolumns processed */
	   (IFmin >= want_in_size) && (OFmax + want_out_size <= OLEN);
	   ++k) {

	/* for each row of xform matrix ...*/
	for (i=0, trow=xform->values;
	     i < xform->rows ; 
	     ++i, trow += tdown ) {
	  unsigned char sum;
	  /* multiply first row element by first column element */
	  icol=IR; ocol=OW;
	  //	  gf2_multiply(OW + i *odown,trow,icol,poly,width,scratch);
	  sum = gf2_mul8(*trow, *icol);

	  /* printf("{%02x}x{%02x} = {%02x}\n",
	     (unsigned char)*trow,(unsigned char)*icol,
	     (unsigned char)*(OW+i*odown));  */

	  /* then add the products of all the rest */
	  for (j=1; j < xform->cols; ++j) {
	    icol += idown; ocol+=odown;
	    //	    gf2_multiply(p, trow + j * tright, icol, poly, width, scratch);
	    sum ^= gf2_mul8(*(trow + j * tright), *icol);
	    /* printf("{%02x}x{%02x} = {%02x}",
	       (unsigned char)*(trow+j*tright),
	       (unsigned char)*icol,(unsigned char)*p); */
	    // vector_xor(OW + i*odown,p,width);
	    //	    *(OW + i*odown) ^= sum; // do at end
	    /* printf(" running total = {%02x}\n",
	       (unsigned char)*(OW + i*odown)); */
	  }
	  *(OW + i *odown) = sum;
	  /* printf("Total: {%02x}\n",(unsigned char)*(OW + i*odown)); */
	  
	}

	/* printf ("Processed one column: IFmin, OFmax are (%Ld,%Ld)\n",
		  (long long) IFmin, (long long) OFmax); */
	IFmin-=want_in_size; OFmax+=want_out_size;
	IR+=iright;
	if (IR > fill_ctl[0].END)
	  IR=in->values;
	OW+=oright;
	if (OW > empty_ctl[0].END) 
	  OW=out->values;
	/* printf ("Moving to next column: IFmin, OFmax are (%lld, %lld)\n",
	  (long long) IFmin, (long long) OFmax); */
      }

       // printf ("Finished processing chunk of k=%d columns\n",k);

      /* we've been updating IFmin and OFmax, but not the real BF
	 variables in the gf2_streambuf_control structures. We do that
	 after the processing loop is finished.
      */
      if (k) {
	for (i=0;  i < fillers; ++i) {
	  fill_ctl[i].BF -= k * want_in_size;
	}
	for (i=0; i < emptiers; ++i) {
	  empty_ctl[i].BF += k * want_out_size;
	}
      }

      /* If we're at eof here, keep looping until all output is flushed... */
      // printf ("Finished post-processing chunks: eof, IFmin, OFmax are (%d,%lld,%lld)\n",
//	 eof, (long long) IFmin, (long long) OFmax); 

    } while (eof && OFmax);


  } while (!eof);

  // printf ("Finished processing; returning " OFF_T_FMT " bytes read\n", 
// 	  bytes_read);
  
  return bytes_read;

}


/*-----------------------------------------------------------------*/

/* test routines */

void test_vector_xor(void) {

  char output[10];
  char mask[10];

  strcpy(output,"CamelCase");
  strcpy(mask,  "         ");

  printf("Testing vector_xor ...\n\n");

  printf("String before XOR: '%s'\n",output);
  vector_xor(output,mask,9);
  printf("String after XOR:  '%s'\n\n",output);

}

void test_vector_shift_left (void) {

  unsigned char pad[3]="\0\0\0";
  unsigned char input[3];
  int i=0;
  unsigned char carry;
  
  strcpy(input,"<>");
  /* input[0]='\000';  input[1]='\001'; */

  printf("Testing vector_shift_left ...\n\n");

  printf("      %2X %2X   => '%s'\n",input[0],input[1],input);
  while (++i <= 16) {
    assert(input[2] == '\000');

    carry=(input[0] & 128)>>7;
    carry=vector_shift_left(input,2,carry);

    assert(pad[2]=='\000');

    printf("%2d: %X %02X %02X\n",i,carry,input[0],input[1]);
  }
  printf("      %2X %2X   => '%s'\n",input[0],input[1],input);

  printf("\n");
}

void test_gf2_multiply(void) {

  unsigned char poly[2];
  unsigned char x[2];
  unsigned char y[2];
  unsigned char result[2];
  unsigned char temp[2];

  poly[0]=0x1b;
  x[0]=0x53;
  y[0]=0xca;

  printf("Testing gf2_multiply ...\n\n");

  gf2_multiply(result,x,y,poly,1,temp);

  printf("Result of {%02X} x {%02X} mod {1%02X} = {%02X}\n\n",
         x[0],y[0],poly[0],result[0]);

  gf2_multiply(result,y,x,poly,1,temp);

  printf("Result of {%02X} x {%02X} mod {1%02X} = {%02X}\n\n",
         y[0],x[0],poly[0],result[0]);

}

void test_gf2_mult_inv (void) {

  unsigned char poly[2];
  unsigned char x[2];
  unsigned char y[2];
  unsigned char result[2];
  unsigned char temp[2];
  int err;

  poly[0]=0x1b;
  x[0]=0x53;

  printf("Testing gf2_invert...\n\n");

  err=gf2_invert(result,x,poly,1,(char*)0);

  if (err) {
    printf("failed to get inverse of {%02X}: %d\n",x[0],err);
  } else {
    printf("Inverse of {%02X} = {%02X}\n",x[0],result[0]);
  }
  
  /* expect 0x53 * 0xca == 1 mod 11b */
  y[0]=0xca;
  err=gf2_invert(result,y,poly,1,(char*)0);

  if (err) {
    printf("failed to get inverse of {%02X}: %d\n",y[0],err);
  } else {
    printf("Inverse of {%02X} = {%02X}\n",y[0],result[0]);
  }

}

void test_size_in_bits(void) {

  unsigned char buf[5]="\0\0\0\001\xff";
  int i;

  printf("Testing size_in_bits...\n\n");

  for (i=0; i < 33; ++i) {
    printf("%2d : %02X%02X%02X%02X %02X : ",
           i,*buf,buf[1],buf[2],buf[3],buf[4]);
    printf("%d\n",vector_size_in_bits(buf,4));
    vector_shift_left(buf,4,0);
  }

  printf("\n");

}

void test_vector_shift_left_many (void) {

  unsigned char buf[5]="\0\0\0\001\xff";
  unsigned char b2[5] ="\0\0\0\001\xff";
  unsigned char b3[5] ="\0\0\0\001\xff";
  int i;

  printf ("Testing vector_shift_left_many...\n\n");

  printf ("Shift 1 bit at a time:\n");

  for (i=0; i < 33 ; ++i) {
    printf("%2d : %02X%02X%02X%02X %02X : ",
	   i,*buf,buf[1],buf[2],buf[3],buf[4]);
    printf("%d\n",vector_size_in_bits(buf,4));
    vector_shift_left_many(buf,1,4);
  }
  
  printf ("Shift 7 bits at a time:\n");

  for (i=0; i < 7 ; ++i) {
    printf("%2d : %02X%02X%02X%02X %02X : ",
	   i,*b2,b2[1],b2[2],b2[3],b2[4]);
    printf("%d\n",vector_size_in_bits(b2,4));
    vector_shift_left_many(b2,7,4);
  }

  printf ("Shift 9 bits at a time:\n");
  for (i=0; i < 7 ; ++i) {
    printf("%2d : %02X%02X%02X%02X %02X : ",
	   i,*b3,b3[1],b3[2],b3[3],b3[4]);
    printf("%d\n",vector_size_in_bits(b3,4));
    vector_shift_left_many(b3,9,4);
  }

 printf("\n");

}

/*-----------------------------------------------------------------*/

/* main */

#ifdef __STANDALONE__
int main (int argc, char* argv[]) {
/*

  test_vector_xor();
  test_vector_shift_left();

  test_gf2_multiply();
  test_vector_shift_left_many();
  test_size_in_bits();
  test_gf2_multiply();
  test_gf2_mult_inv();
*/

  command_interpreter();

/*

*/
}
#endif


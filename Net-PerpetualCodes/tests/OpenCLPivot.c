/* OpenCL kernel for pivoting */

/* Sticking code into a proper .c file to get syntax highlighting, etc. */

#ifdef SWITCH_TABLES
// include switch-based table lookups
#include "gf8_log_exp.c"

// Apparently "inline" is allowed
inline unsigned char gf8_inv(unsigned char a) {
    return gf8_exp(255-gf8_log(a));
}

inline unsigned char gf8_mul(unsigned char a, unsigned char b) {
    unsigned sum;
    // tables can't handle case of a or b == 0
    if ((a == 0) || (b == 0)) return 0;
    sum  = gf8_log(a) + gf8_log(b);
    sum -= (sum < 256) ? 0 : 256;
    return gf8_exp(sum);
}
#endif

#ifdef LONG_MULTIPLY
unsigned char gf8_mul(unsigned int a, unsigned char b) {
    unsigned char product = (b & 1) ? a : 0;
    a = (a & 128) ? ((a << 1) ^  0x11b) : (a << 1);
    product ^=  (b & 2) ? a : 0;
    a = (a & 128) ? ((a << 1) ^  0x11b) : (a << 1);
    product ^=  (b & 4) ? a : 0;
    a = (a & 128) ? ((a << 1) ^  0x11b) : (a << 1);
    product ^=  (b & 8) ? a : 0;
    a = (a & 128) ? ((a << 1) ^  0x11b) : (a << 1);
    product ^=  (b & 16) ? a : 0;
    a = (a & 128) ? ((a << 1) ^  0x11b) : (a << 1);
    product ^=  (b & 32) ? a : 0;
    a = (a & 128) ? ((a << 1) ^  0x11b) : (a << 1);
    product ^=  (b & 64) ? a : 0;
    // Optimise last bit: don't update a unless we need to
    return (b & 128) == 0 ? product :
	(product ^ ((a & 128) ? ((a << 1) ^  0x11b) : (a << 1)));
}
#endif

// Some alternative kernels to test lower-level functions?
// ...

// Main entry point
kernel void pivot_gf8(
    // inputs (all read-only)
           unsigned       i,
    global unsigned char *host_code,
    global unsigned char *host_sym,
    global unsigned char *coding,
    global unsigned char *symbol,
    global unsigned char *filled,

    // input-output (host allocates, we write)
    global unsigned char *code_swap,
    global unsigned char *sym_swap,

    // outputs
    global unsigned      *new_i,
    global unsigned char *new_code,
    global unsigned char *new_sym,
    global unsigned      *swaps,
    global unsigned      *rc

    // other inputs (lookup tables)

    // I'm putting these at the end so that I can use conditional
    // compilation to enable/disable them without messing up parameter
    // indices. Listing in order from most important to least. Note
    // the comma at the start of these blocks.

#ifndef SWITCH_TABLES
#ifdef SEND_LOG_EXP
    , global unsigned char *host_log
    , global unsigned char *host_exp
#endif
#ifdef SEND_INV
    , global unsigned char *host_inv
#endif
#endif
) {

  // private variables
  unsigned int  tries = 0, quitting = 0;
  signed   int  j, k;
  // allocating code[ALPHA] as a private array failed, so change it to
  // use global memory below:
  global   unsigned char *code;
   unsigned char sym[WORKSIZE];
#ifdef SEND_INV
  unsigned char inv[256];
#endif
  unsigned char bit, mask, temp;
  unsigned char cancelled, zero_sym, did_swap;
  unsigned int local_swaps = 0;
  unsigned int since_swap = 0;
  unsigned int ctz_row, ctz_code, clz_code;

  // offset-related stuff
  int id = get_global_id(0);
  int start_range = id * WORKSIZE;
  int next_range  = start_range + WORKSIZE;

  // host has to set up max_work_items copies of code so that each
  // thread can update its own code value independently.
  code = host_code + id * ALPHA;

  if (start_range >= BLOCKSIZE) return;
  if (next_range > BLOCKSIZE)   next_range = BLOCKSIZE;
    
  // Make sure #include worked (yes, no_such_thing gives an error)
  // cancelled = gf8_log(0);
  // cancelled = no_such_thing(0);

  // don't copy code since host should prepare it for us

  // copy a range of bytes from symbol
  for (j = start_range; j < next_range; ++j)
    sym[j - start_range] = host_sym[j];

  // Main loop
  while ( (++tries < GEN * 2) && (since_swap < GEN - 1) ) {

    // Check coding row to see if we need to swap
    ctz_code = ctz_row = 0;
    for ( j = ALPHA - 1;  j >= 0; --j ) {
      if ( code[j] != 0 ) break;
      ++ctz_code;
    }
    for (j = ALPHA - 1; j >= 0; --j ) {
      if ( coding[(i * ALPHA) + j ]  != 0 ) break;
      ++ctz_row;
    }

    did_swap = 0;
    if (ctz_code > ctz_row) {
      // We need to remember if we swapped
      did_swap = 1;

      // Store swapped values in code_swap and sym_swap
      // rotate code_swap row <- code <- coding row
      // low-numbered threads update one byte of code_swap each
      if (id < ALPHA) code_swap[(local_swaps * ALPHA) + id] = code[id];
      // and all of code
      j = 0;
      for (j = 0; j < ALPHA; ++j)
	code[j] = coding[(i * ALPHA) + j ];

      // Similar rotation for symbols:
      // rotate sym_swap row <- sym <- symbol row
      j = start_range;
      do {
	symbol[ (i * BLOCKSIZE) +j ] = sym   [ j - start_range ];
	sym   [ j - start_range ]    = symbol[ (i * BLOCKSIZE) +j ];
      } while (++j < next_range);

      // Actually, we also need to copy stuff to output buffers below:
      if (++local_swaps >= SWAPSIZE) ++quitting;
    }

    // subtract coding row (or swapped row) from code
    cancelled = zero_sym = 1;
    if (did_swap) {
      k = (local_swaps - 1) * ALPHA;
      for (j = 0; j < ALPHA; ++j)
	if (code[j] ^= code_swap[j + k])
	  cancelled = 0;
    } else {
      k = i * ALPHA;
      for (j = 0; j < ALPHA; ++j)
	if (code[j] ^= coding[j + k])
	  cancelled = 0;
    }

    // subtract our part of the symbol
    if (did_swap) {
      k = (local_swaps - 1) * BLOCKSIZE;
      for (j = start_range; j < next_range; ++j)
	if (sym[j - start_range] ^= sym_swap[j + k])
	  zero_sym = 0;
    } else {
      k = (i * BLOCKSIZE);
      for (j = start_range; j < next_range; ++j)
	if (sym[j - start_range] ^= sym_swap[j + k])
	  zero_sym = 0;
    }

    if (cancelled) {
      // zero_sym is going to have to be set in the host since this
      // thread only sees part of the symbol. To signal an error (ie,
      // any part of the symbol not being cancelled as it should be),
      // any/all threads may set this to 1. In the case of the symbol
      // cancelling correctly, the variable should not be written to.
      
      // how to send back proper code or raise error?
      if (zero_sym) return; // return remain; else error
    }

    // we've subtracted a coding row, but we need to normalise
    clz_code = 0;
    for (j = 0; j < ALPHA; ++j)
      if (code[j]) break; else ++clz_code;
    temp = gf8_inv(code[clz_code]);

    // can combine code vector multiplication with shift left
    for (j = 0; j < ALPHA - (clz_code + 1); ++j)
      code[j] = gf8_mul(temp, code[j + clz_code + 1]);
    for (j = j; j < ALPHA; ++j)
      code[j] = 0;

    // multiply our part of the symbol
    for (j = start_range; j < next_range; ++j)
      sym[j - start_range] = gf8_mul(temp, sym[j - start_range]);


    // checking whether this row is filled (moved from top of loop)
    
    return;
  }
}

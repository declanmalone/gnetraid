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
    unsigned tries = 0, quitting = 0;
    unsigned char code[ALPHA];
    unsigned char sym[WORKSIZE];
#ifdef SEND_INV
    unsigned char inv[256];
#endif
    unsigned char *cp, *rp, *bp, bit, mask;
    unsigned char cancelled, zero_sym;
    unsigned int local_swaps = 0;
    unsigned int since_swap = 0;
    unsigned int ctz_row, ctz_code, clz_code;

    // offset-related stuff
    int id = get_global_id(0);
    int start_range = id * WORKSIZE;
    int next_range  = start_range + WORKSIZE;

    if (start_range >= BLOCKSIZE) return;
    if (next_range > BLOCKSIZE)   next_range = BLOCKSIZE;
    
    // Make sure #include worked (yes, no_such_thing gives an error)
    // cancelled = gf8_log(0);
    // cancelled = no_such_thing(0);

    // copy full code into private storage
    cp = host_code;
    rp = code;
    bp = cp + ALPHA;
    while (cp < bp) *(rp++) = *(cp++);

    // copy a range of bytes from symbol
    j = start_range;
    while (j < next_range) sym[j - start_range] = host_sym[j];

    while ( (++tries < GEN * 2) && (since_swap < GEN - 1) ) {

      // Check coding row to see if we need to swap
      for (ctz_code = 0, cp=code + ALPHA - 1;
	   cp >= code;
	   --cp ) {
	if (*cp != 0) break;
	++ctz_code;
      }
      bp = coding + i * ALPHA;
      for (ctz_row = 0, cp = bp + ALPHA - 1;
	   cp >= bp;
	   --cp ) {
	if (*cp != 0) break;
	++ctz_row;
      }

      did_swap = 0;
      if (ctz_code > ctz_row) {
	// We need to remember if we swapped
	did_swap = 1;

	// Store swapped values in code_swap and sym_swap
	// rotate code_swap row <- code <- coding row
	bp = code_swap + (local_swaps * ALPHA);
	cp = code;
	rp = coding + (i * ALPHA);
	// low-numbered threads update one byte of code_swap each
	if (id < ALPHA) bp[id] = code[id];
	// and all of code
	j = 0;
	while (j++ < ALPHA) {
	  *(cp++) = *(rp++);
	}

	// Similar rotation for symbols:
	// rotate sym_swap row <- sym <- symbol row
	j = start_range;
	rp = symbol + (i * BLOCKSIZE);
	bp = sym_swap + (local_swaps * ALPHA);
	do {
	  bp[j]                = sym[j - start_range];
	  sym[j - start_range] = rp[j];
	} while (++j < next_range);

	// Actually, we also need to copy stuff to output buffers below:
	if (++local_swaps >= SWAPSIZE) ++quitting;
      }

      // subtract coding row (or swapped row, since we only "half-swapped") 
      cancelled = 1; zero_sym = 1;
      cp = code;
      rp = did_swap ? code_swap * (local_swaps - 1) : coding + i * ALPHA;
      bp = rp + ALPHA;
      while (rp < bp) {
	if (*(cp++) ^= *(rp++)) cancelled = 0;
      }

      cp = sym;
      rp = did_swap ?
	sym_swap + (local_swaps - 1) + start_range :
	symbol + (i * BLOCKSIZE) + start_range;
      bp = rp + next_range;
      while (rp < bp) {
	if (*(cp++) ^= *(rp++)) zero_sym = 0;
      }

      if (cancelled) {
	// how to send back proper code or raise error?
	if (zero_sym) return; // return remain; else error
      }
      
      return;
    }
}

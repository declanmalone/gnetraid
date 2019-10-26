/* OpenCL kernel for pivoting */


#define DO_SWAP 1

/* Sticking code into a proper .c file to get syntax highlighting, etc. */

// Only select one of SWITCH_TABLES, HOST_TABLES. LONG_MULTIPLY takes
// precedence for multiplication.

#ifdef LONG_MULTIPLY
#define GF8_MUL(a,b) (gf8_mul_long(((unsigned char) (a)),b))

// Apparently I can't inline this. Strange.
unsigned char gf8_mul_long(unsigned int a, unsigned char b) {

#ifdef OPERAND_CHECK
  // Checking if operands are 0 or 1 may (or may not) be faster
  // (I expect it not to be)
  if (a < 2) { return a ? b : 0; }
  if (b < 2) { return b ? a : 0; }
#endif

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

#ifdef HOST_TABLES

#define GF8_INV(a) (gf8_inv_host(a, host_log, host_exp))
inline unsigned char gf8_inv_host(unsigned char a,
				  global unsigned char *host_log,
				  global unsigned char *host_exp) {
  return host_exp[255-host_log[a]];
}

#ifndef LONG_MULTIPLY
#define GF8_MUL(a,b) (gf8_mul_host(a,b, host_log, host_exp))

inline unsigned char gf8_mul_host(unsigned char a, unsigned char b,
				  global unsigned char *host_log,
				  global unsigned char *host_exp) {
  unsigned sum;
  if ((a == 0) || (b == 0)) return 0;
  sum  = host_log[a] + host_log[b];
  sum -= (sum >= 255) ? 255 : 0;
  return host_exp[(unsigned char) sum];
}
#endif
#endif

#ifdef SWITCH_TABLES
// include switch-based table lookups (gf8_exp() and gf8_log())
#include "gf8_log_exp.c"

#define GF8_INV(a) (gf8_inv_switch((a)))

// Apparently "inline" is allowed
inline unsigned char gf8_inv_switch(unsigned char a) {
  return gf8_exp(255-gf8_log(a));
}

#ifndef LONG_MULTIPLY
#define GF8_MUL(a,b) (gf8_mul_switch((a),(b)))
inline unsigned char gf8_mul_switch(unsigned char a, unsigned char b) {
  unsigned sum;
  // tables can't handle case of a or b == 0
  if ((a == 0) || (b == 0)) return 0;
  sum  = gf8_log(a) + gf8_log(b);
  sum -= (sum >= 255) ? 255 : 0;
  return gf8_exp((unsigned char) sum);
}
#endif
#endif


// Some alternative kernels to test lower-level functions?
// ...

// Main entry point
//
// Notes on rc_vec
//
// rc_vec[0] is generic status; host should set to 0xff before calling
//
// 0: success   - host should pivot new_code, new_sym into table row new_i
// 1: cancelled - host needn't do anything (though do apply swapped rows)
// 2: memory    - would have overwritten r/o memory; apply swap and try again
// 3: stack     - out of stack space for swap; apply swap and try again
// 4: tries     - exceeded max tries (apply swap and abandon)
// ff: undefined
//
// rc_vec[1] is for symbol cancelling error; host should set to 0 before call
//
// If this value is set, then the value of rc_vec[0] is not reliable!
//
// rc_vec[2+] can be used for debugging

kernel void pivot_gf8(
    // inputs (all read-only)
 	   unsigned       i,
    global unsigned char *host_code, // actually, r/w: one copy per thread
    global unsigned char *host_sym,
    global unsigned char *coding,
    global unsigned char *symbol,
    global unsigned char *filled,

    // input-output (host allocates, we write)
    global unsigned int  *i_swap,
    global unsigned char *code_swap,
    global unsigned char *sym_swap,

    // outputs
    global unsigned      *new_i,
    global unsigned char *new_code,
    global unsigned char *new_sym,
    global unsigned      *swaps,
    global unsigned char *rc_vec

    // other inputs (lookup tables)

    // I'm putting these at the end so that I can use conditional
    // compilation to enable/disable them without messing up parameter
    // indices. Listing in order from most important to least. Note
    // the comma at the start of these blocks.

#ifndef SWITCH_TABLES
#ifdef HOST_TABLES
    , global unsigned char *host_log
    , global unsigned char *host_exp
#endif
#ifdef SEND_INV
    , global unsigned char *host_inv
#endif
#endif
) {

  // private variables
  unsigned int  tries = 0;
  signed   int  j, k;
  // allocating code[ALPHA] as a private array failed, so change it to
  // use global memory below:
  global unsigned char *code;
  // Also, sym[WORKSIZE] fails if WORKSIZE == 12 (and possible lower)
  global unsigned char *sym = new_sym;
#ifdef SEND_INV
  unsigned char inv[256];
#endif
  unsigned char temp, rc;
  unsigned char cancelled, zero_sym, did_swap;
  unsigned int  local_swaps = 0;
  unsigned int  since_swap = 0;
  unsigned int  ctz_row, ctz_code, clz_code;

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
    sym[j] = host_sym[j];

  // Sanity check maths
  if (id == 0) {
    if (GF8_INV(0x53) != 0xca) {
      rc_vec[6] = 1; return;
    }
    if (GF8_MUL(0x53,0xca) != 1) {
      rc_vec[6] = 2; return;
    }
    if (GF8_MUL(0x0b, 0xc0) != 1) {
      rc_vec[6] = 3; return;
    }
    if (GF8_MUL(0x9d,0xc0) != 0xd4) {
      rc_vec[6] = 4; return;
    }
  }
  
  // Main loop
  while ( ++tries < GEN * 2 ) {

    // Check coding row to see if we need to swap
    ctz_code = 0;
    for ( j = ALPHA - 1;  j >= 0; --j ) {
      if ( code[j] != 0 ) break;
      ++ctz_code;
    }
    ctz_row = 0;
    for (j = ALPHA - 1; j >= 0; --j ) {
      if ( coding[(i * ALPHA) + j ]  != 0 ) break;
      ++ctz_row;
    }
    if (id == 0) {
      rc_vec[3] = ctz_code;
      rc_vec[4] = ctz_row;
    }
    did_swap = 0;
    if ((DO_SWAP) && (ctz_code > ctz_row)) {

      // Host needs to know which rows to swap
      if (id == 0)
	i_swap[local_swaps] = i;

      // We only need to write to the swap arrays
      k = local_swaps * ALPHA;
      if (id < ALPHA)
	code_swap[k + id] = code[id];
      k = local_swaps * BLOCKSIZE;
      for (j = start_range; j < next_range; ++j) {
	sym_swap[ j + k ] = sym   [ j ];
      }

      // Set variable so we can update local_swaps later
      did_swap = 1;
    }

    // The code below doesn't care that we didn't actually swap code
    // with coding row or sym with symbol row
    
    // subtract coding row (or swapped row) from code
    cancelled = 1;
    // reuse zero_sym here to mean number of non-zero elements
    zero_sym = ALPHA - (did_swap? ctz_row : ctz_code);
    k = i * ALPHA;
    for (j = 0; j < zero_sym ; ++j)
      if (code[j] ^= coding[j + k])
	cancelled = 0;

    // subtract our part of the symbol
    zero_sym = 1;
    k = (i * BLOCKSIZE);
    for (j = start_range; j < next_range; ++j)
      if (sym[ j ] ^= symbol[j + k])
	zero_sym = 0;

    // I delayed updating this
    local_swaps += did_swap;

    if (cancelled) {
      if (zero_sym)
	rc = 1;			// cancelled (kind of success)
      else
	rc_vec[1] = 1;		// any thread can set this error flag
      break;
      // goto RETURN;
    }

    // we've subtracted a coding row, but we need to normalise
    clz_code = 0;
    for (j = 0; j < ALPHA; ++j)
      if (code[j]) break; else ++clz_code;
    temp = GF8_INV(code[clz_code]);
    if (id == 0) rc_vec[7] = temp;

    // can combine code vector multiplication with shift left
    k = clz_code + 1;
    for (j = 0; j < ALPHA - k; ++j)
      code[j] = GF8_MUL(temp, code[j + k]);
    for (j = j; j < ALPHA; ++j)
      code[j] = 0;

    // multiply our part of the symbol
    for (j = start_range; j < next_range; ++j)
      sym[ j ] = GF8_MUL(temp, sym[ j ]);

    i += k;
    i -= (i >= GEN) ? GEN : 0;

    // since_swap stays at zero until we swapped something
    since_swap += (local_swaps ? k : 0);
    
    if (since_swap >= GEN -1) {
      // We caught up with the first swap that we made, so return
      // and let host persist the changes
      rc = 2;		/* not yet (host will call us again) */
      break;
      // goto RETURN;
    }

    // checking whether this row is filled (moved from top of loop)
    temp = 1 << (i & 0x07);	/* bit mask from 1 .. 128 */
    if (id == 0) rc_vec[5] = temp;
    if (filled[(i >> 3)] & temp) {
      // debug: check how many (up to uchar) filled slots we encountered
      if (id == 0) rc_vec[2]++;
    } else {
      // not filled, so we can return. Host handles copying code,sym
      rc = 0;		/* 0: success, needs writing */
      break;
      // goto RETURN;
    }

    // Random (but still fine) place to check if our stack is full
    if (local_swaps >= SWAPSIZE) {
      rc = 3;
      break;
      // goto RETURN;
    }
  }

  if ( tries >= GEN * 2 )
    rc = 4;			/* failure: tries */

 RETURN:

  // only first thread updates these:
  if (id == 0) {
    *new_i = i;
    *swaps = local_swaps;
    rc_vec[0] = rc;
  }
  // threads cooperate on filling new_code (new_sym already done)
  if (id < ALPHA)
    new_code[id] = code[id];
  return;
}

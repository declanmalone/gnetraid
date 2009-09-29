/* Copyright (c) Declan Malone 2009 */

/* None of the usual aligned malloc routines (memalign, _malloc_align,
   posix_memalign) are available on my system, so I'm writing my own
   version here. I've inserted this (retroactively) into the malloc
   demo and tested it there.
*/

#ifndef SPU_ALLOC_H
#define SPU_ALLOC_H

// Aligned malloc routine
//
// The strategy is simply to allocate a block with malloc that's align
// bytes larger than the required size and to round the returned
// memory address up to align bytes. Since the original address needs
// to be used for the corresponding free call, the caller must pass
// pointers to two variable: one for the aligned memory address, the
// other to pass to free() when the memory is to be released.
//
// As with most other implementations, this assumes that align is a
// power of 2.
//
// Return value is 0 for success, -1 and errno set otherwise.

int malloc_aligned(unsigned size, unsigned align,
		   void **mem_ptr, void **free_ptr);

#endif




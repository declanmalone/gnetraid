/* Copyright (c) Declan Malone 2009 */


#include <stdlib.h>
#include <stdint.h>

#include "spu-alloc.h"

int malloc_aligned(unsigned size, unsigned align, 
		   void **mem_ptr, void **free_ptr) {

  if ((*free_ptr=malloc(size + align))==NULL)
    return -1;

  if (align) {
    *mem_ptr = *free_ptr + align - ((uint32_t) *free_ptr & (align -1));
  } else {
    *mem_ptr = *free_ptr;
  }

  return 0;
}


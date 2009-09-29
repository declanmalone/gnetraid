#include <spu_intrinsics.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

/* One way of getting access to malloc_align */
#ifdef HAVE_LIBMISC_H 

#include <libmisc.h> 

#endif

/* Another way */
#ifdef HAVE_MALLOC_ALIGN_H
#include <malloc_align.h>
#endif

// My implementation, since there's no standard library routine
// available

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



#define MAXALLOCS 256

int main(unsigned long long spe, 
	 unsigned long long argp, unsigned long long envp)
{

  void *memptr[MAXALLOCS];
  void *freeptr[MAXALLOCS];
  int i;
  int unaligned;


  printf("Going to alloc %d 1-byte areas using malloc\n",MAXALLOCS);

  //sleep(5);

  for (i=unaligned=0; i < MAXALLOCS; ++i) {
    memptr[i]=malloc(i);
    if (((uint64_t) memptr[i]) & 15) {
      ++unaligned;
    }
  }

  printf ("malloc returned %d unaligned addresses\n", unaligned);

  for (i=0; i < MAXALLOCS; ++i) {
    free(memptr[i]);
  }

#ifdef HAVE_LIBMISC_H

  printf("Going to alloc %d 1-byte areas using malloc_align\n",MAXALLOCS);

  for (i=unaligned=0; i < MAXALLOCS; ++i) {
    memptr[i]=malloc_align(1,4);
    if (((uint64_t) memptr[i]) & 15) {
      ++unaligned;
    }
  }

  printf ("malloc_align returned %d unaligned addresses\n", unaligned);

  for (i=0; i < MAXALLOCS; ++i) {
    free_align(memptr[i]);
  }

#else

  printf("Going to alloc %d 1-byte areas using my malloc\n",MAXALLOCS);

  for (i=unaligned=0; i < MAXALLOCS; ++i) {
    malloc_aligned(1,16,&memptr[i],&freeptr[i]);
    if (((uint64_t) memptr[i]) & 15) {
      ++unaligned;
    }
  }

  printf ("malloc_aligned (mine) returned %d unaligned addresses\n",
	  unaligned);

  for (i=0; i < MAXALLOCS; ++i) {
    free(freeptr[i]);
  }


#endif


  /* Looks like we need to code our own aligned malloc... */

  /* Though let's check to see how many blocks we can allocate */

  printf("Going to try to exhaust memory\n");

  i=0;
  while (1) {
    memptr[i]=malloc(1024);
    if (!memptr[i])
      break;
    ++i;
  }

  printf("Managed to allocate %d %d-byte blocks\n",i,1024);


  return 0;
}

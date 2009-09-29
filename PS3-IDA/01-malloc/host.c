/* Copyright (c) Declan Malone 2009 */

#include <libspe2.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

/* 
  Unfortunately, don't have these libraries on either PPE or
  SPE... See:

  http://www.ibm.com/developerworks/library/pa-specode1/?ca=drs-t3607

  for an alternative implementation
*/
#ifdef HAVE_RIGHT_H_FILES
#include <libmisc.h> 
#include <malloc_align.h>
#endif

const char *spu_task="spu-task";

int main (int ac, char *av[]) {

  void *ptr1, *ptr2;

  /* do we have posix_memalign? */
  ptr1=memalign(16,4);

  posix_memalign(&ptr2,2,4);

}

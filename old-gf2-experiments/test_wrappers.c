
#include <stdio.h>
#include <sys/time.h>
#include <stdlib.h>

#include "fast_gf2.h"
#include "fast_gf2_wrappers-albatross.h"

#define S_BUFSIZE (4096) 

void test_gf2_fast_u32(void) {
  struct gf2_fast_maths *obj;
  gf2_u32  poly,x,y,z;
  int      rc;
  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u32  values[]={0,1,2,3,140,252,255,256,257,1024,32768,
		     49152,44732,65535,65536,0x0023544b,0xc04faced,
		     0xf0d1cebd,0xffffffff,0xffffffff};
  gf2_u32  last_x,last_y;
  int      errors, count;

  printf("\nTesting fast u32 arithmetic\n");

  poly=0x00000086;

  printf ("Create lookup tables? ");
  rc=gf2_fast_u32_init(obj,poly,0);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    /* multiply sample values using long multiply and fast multiply */
    printf ("Comparing results with long multiplication: ");
    last_x=0xffffffff; last_y=0xffffffff; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u32_mul(obj,values[x],values[y]);
	if (rc != gf2_long_mod_multiply_u32(values[x],values[y],poly)) {
	  ++errors; 
	  printf ("not ok: wrong result for %u x %u (got %u)\n",
		  (unsigned) values[x], (unsigned) values[y], (unsigned) rc);
	}
	++count;
	last_y=values[y]; 
      }
      last_x=values[x];
    }
    if (!errors) printf("ok (%d trials)\n",count);
    printf("Freeing table memory.\n");
    gf2_fast_u32_deinit(obj);
  }
  printf("Leaving test routine\n");
}

void benchmark_u32_methods(void) {

  gf2_u32   *b1, *b2;
  long long top=0x100000000ll;
  unsigned  i;
  struct timeval t1, t2;
  struct timezone tz;
  long t0, now;
  double total, tsec;
  int mtype=0;

  /* arbitrary-precision numbers are big endian */
  char scratch[]={0,0,0,0, 0,0,0,0x86, 0,0,0,0};
  char *poly_str=scratch+4;
  char *result=scratch+8;

  char * testnames[]=
    {
      "long multiply (u32 version)", 
      "optimised method + init", "optimised method w/o init",
      "arbitrary-precision u32 multiply",
    };
     
  struct gf2_fast_maths *obj=NULL;
  gf2_u32 poly=0x00000086;


  printf("\nBenchmarking u32 multiply routines.\n");
  printf("All tests run for 10 seconds. M*/s == 1048576 multiplies/sec\n");

  b1 = (gf2_u32 *) malloc(sizeof(gf2_u32) * S_BUFSIZE);
  b2 = (gf2_u32 *) malloc(sizeof(gf2_u32) * S_BUFSIZE);

  for (i = 0; i < S_BUFSIZE; i++) b1[i] = lrand48() % top;
  for (i = 0; i < S_BUFSIZE; i++) b2[i] = lrand48() % top;

  for (mtype=0; mtype < 4; ++mtype) {

    printf("Test %d: %s\n",mtype,testnames[mtype]);
    t0 = time(0);

    /* start timer */
    gettimeofday(&t1, &tz);
    total = 0;
    while (time(0) - t0 < 10) {
      switch (mtype) {
      case 0: 
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_long_mod_multiply_u32(b1[i],b2[i], poly); 
	break;

      case 1:
	if (obj == NULL)
	  gf2_fast_u32_init(obj,poly,0);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u32_mul(obj, b1[i], b2[i]); 
	break;

      case 2:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u32_mul(obj, b1[i], b2[i]); 
	break;

      case 3:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_multiply(result,
		       &b1[i], &b2[i],
		       poly_str,1,scratch);
	break;

      default:
	printf("No tests defined for %d\r", mtype);
	break;
      }
      total++;
    }

    /* end timer */
    gettimeofday(&t2, &tz);

    tsec = 0;
    tsec += t2.tv_usec;
    tsec -= t1.tv_usec;
    tsec /= 1000000.0;
    tsec += t2.tv_sec;
    tsec -= t1.tv_sec;
    total *= S_BUFSIZE;
    printf("Test %d: -> %.5lf M*/s\n", mtype,
	   total/tsec/1024.0/1024.0);

    if (mtype==2) {
      gf2_fast_u32_deinit(obj);
    }
  }

}

int main (int ac, char * av[]) {

  test_gf2_fast_u32();
  benchmark_u32_methods();
}

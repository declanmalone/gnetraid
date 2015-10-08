#include <stdio.h>
#include "fast_gf2.h"
#include <sys/time.h>
#include <stdlib.h>
#include <assert.h>

/* Compile command:

  gcc  -o arm_simd_fast_gf2 -DGF2_UNROLL_LOOPS -Os arm_simd_fast_gf2.s \
    fast_gf2.c test_arm_simd_fast_gf2.c rabin-ida.c

*/


/* prototype for assembly, which is stored in arm_simd_fast_gf2.s */
extern gf2_u32 gf2_long_mod_multiply_u8_arm_simd(gf2_u32 a, gf2_u32 b,
						 gf2_u32 poly);

/*
  Quite a lot of the following is adapted from test_fast_gf2.c since
  that code already has a main() and I want to duplicate its
  functionality without including any conditional compilation based on
  whether I'm on an ARM host or not.
*/

void test_sizes(void) {

  printf("\nTesting word sizes\n");
  printf("u8 is 1 byte? %s\n", (sizeof(gf2_u8) == 1)? "ok" : "not ok");
  printf("u16 is 2 bytes? %s\n", (sizeof(gf2_u16) == 2)? "ok" : "not ok");
  printf("u32 is 4 bytes? %s\n", (sizeof(gf2_u32) == 4)? "ok" : "not ok");
  printf("s8 is 1 byte? %s\n", (sizeof(gf2_s8) == 1)? "ok" : "not ok");
  printf("s16 is 2 bytes? %s\n", (sizeof(gf2_s16) == 2)? "ok" : "not ok");
  printf("s32 is 4 bytes? %s\n", (sizeof(gf2_s32) == 4)? "ok" : "not ok");

}

/* test old, non-SIMD code */
void test_gf2_long_mod_multiply(void) {

  gf2_u8 a=0x53;
  gf2_u8 b=0xca;
  gf2_u8 poly=0x1b;
  gf2_u8 result_u8;

  gf2_u16 a_u16=0x53;
  gf2_u16 b_u16=0xca;
  gf2_u16 poly_u16=0x11b;
  gf2_u16 result_u16;

  printf("\nTesting basic long multiplication (non-SIMD)\n");

  /* actually, this is a pretty paltry test, but I can live with that */
  printf ("Is {53} x {CA} == 1 mod {11b}? (8-bit): ");
  result_u8=gf2_long_mod_multiply_u8(a,b,poly);
  if (result_u8 == 1) {
    printf("ok\n");
  } else {
    printf("not ok. Got {%02x}\n", (int) result_u8);
  }

  /* 
    using larger-sized words than required by the polynomial will
    cause errors. Don't do things like this.
  */
  printf ("Is {53} x {CA} == 1 mod {11b}? (16-bit): ");
  result_u16=gf2_long_mod_multiply_u16(a_u16,b_u16,poly_u16);
  if (result_u16 == 1) {
    printf("succeeded, even when it shouldn't have\n");
  } else {
    printf("failed (as expected). Got {%04x}\n", (int) result_u16);
  }

  /* test a semi-random 16-bit multiply. These values were checked
     against James S. Planck's galois library, which uses different
     polynomials than mine for each field. */
  a_u16=0x01B1;			/* 433 */
  b_u16=0xC350;			/* 50000 */
  poly_u16=0x100B;
  printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? (16-bit): ");
  result_u16=gf2_long_mod_multiply_u16(a_u16,b_u16,poly_u16);
  if (result_u16 == 0xb07f) {
    printf("ok\n");
  } else {
    printf("not ok. Got {%04x}\n", (int) result_u16);
  }
}


/* specific tests on new SIMD code */
void test_gf2_long_mod_multiply_u8_arm_simd(void) {

  /*
    Doing a more thorough test on the SIMD code. This code is based on
    the code for testing the optimised exp/log method, except modified
    so that we assume that method is correct and we just use it as a
    check against the values returned by our new SIMD code.
  */

  gf2_s16 *log_table;
  gf2_u8  *exp_table;

  gf2_u8  poly,x,y,z;
  gf2_u32 poly_32,x_32,y_32,z_32;

  int     rc;
  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u8  values[]={0,1,2,3,4,26,27,28,32,64,99,128,140,252,253,254,255,255};
  gf2_u8  last_x,last_y;
  int     errors, count;

  gf2_u32 values_32[18];
  gf2_u32 last_x_32,last_y_32;

  assert (sizeof(values) * 4 == sizeof(values_32));

  printf("\nTesting SIMD long multiplication\n");

  poly=0x1b;
  poly_32=0x1b1b1b1bl;

  printf ("Create validation tables? ");
  rc=gf2_fast_u8_init_m3(poly,3,&log_table, &exp_table);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {53535353} x {CACACACA} == {01010101} mod {11b}? : ");
    z_32=gf2_long_mod_multiply_u8_arm_simd(0x53535353l,0xcacacacal,poly_32);
    if (z_32 == 0x01010101l) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%08lx} (low byte %02x)\n",
	     (unsigned long) z_32, (unsigned int) (gf2_u8) z_32);
    }

    printf ("Is {5301CA01} x {CA5353CA} == {015301CA} mod {11b}? : ");
    z_32=gf2_long_mod_multiply_u8_arm_simd(0x5301CA01l,0xCA5353CAl,poly_32);
    if (z_32 == 0x015301CAl) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%08lx} (low byte %02x)\n",
	     (unsigned long) z_32, (unsigned int) (gf2_u8) z_32);
    }

    /* multiply sample values using SIMD and exp/log lookups */
    printf ("Comparing results with exp/log tables: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      x_32 = values[x]; x_32 |= x_32 << 8; x_32 |= x_32 << 16;

      for (y=0; values[y] != last_y; ++y) {
	y_32 = values[y]; ; y_32 |= y_32 << 8; y_32 |= y_32 << 16;

	z=gf2_fast_u8_mul_m3(log_table,exp_table,values[x],values[y]);
	z_32 = z; z_32 |= z_32 << 8; z_32 |= z_32 << 16;

	if (z_32 != gf2_long_mod_multiply_u8_arm_simd(x_32,y_32,poly_32)) {
	  ++errors; 
	  printf ("not ok: wrong result for %02x x %02x (got %08lx)\n",
		  (unsigned) values[x], (unsigned) values[y], 
		  (unsigned long) z_32 );
	}
	++count;
	last_y=values[y]; 
      }
      last_x=values[x];
    }
    if (!errors) printf("ok (%d trials)\n",count);
    printf("Freeing table memory.\n");
    gf2_fast_u8_deinit_m3(log_table, exp_table);
  }

}


/*
  I've lifted this benchmarking code is directly from James
  S. Planck's galois library to enable me to get comparable speed
  measurements for our two implementations.
 */

#define S_BUFSIZE (4096) 
void benchmark_u8_methods(void) {

  gf2_u8  *b1, *b2;
  gf2_u32 *w1, *w2;
  unsigned int top=1<<8;
  unsigned int i;
  struct timeval t1, t2;
  struct timezone tz;
  long t0, now;
  double total, tsec;
  int mtype=0;

  char scratch[]={0x00,0x1b,0};
  char *poly_str=scratch+1;
  char *result=scratch+2;

  char * testnames[]=
    {
      "long multiply (non-SIMD)", 
      "long multiply (SIMD)",
      "full multiply tables + init", 
      "unoptimised log/exp tables + init",
      "optimised log/exp tables + init",
      "arbitrary-precision multiply",
    };
     
  gf2_u8 *mul_table_m1=NULL;
  gf2_u8 *inv_table_m1=NULL;
  gf2_u8 *log_table_m2=NULL;
  gf2_u8 *exp_table_m2=NULL;
  gf2_s16 *log_table_m3=NULL;
  gf2_u8  *exp_table_m3=NULL;

  gf2_u8   poly=0x1b;
  gf2_u32  poly_simd=0x1b1b1b1bl;

  b1 = (gf2_u8 *) malloc(sizeof(unsigned int) * S_BUFSIZE);
  b2 = (gf2_u8 *) malloc(sizeof(unsigned int) * S_BUFSIZE);

  for (i = 0; i < S_BUFSIZE; i++) b1[i] = lrand48() % top;
  for (i = 0; i < S_BUFSIZE; i++) b2[i] = lrand48() % top;

  w1 = (gf2_u32 *) malloc(sizeof(gf2_u32) * S_BUFSIZE);
  w2 = (gf2_u32 *) malloc(sizeof(gf2_u32) * S_BUFSIZE);

  /* Use the same values for SIMD test, but spread across whole word */
  for (i = 0; i < S_BUFSIZE; i++) {
    w1[i] = (gf2_u32) b1[i];
    w1[i] |= ( w1[i] << 8);
    w1[i] |= ( w1[i] << 16);
  }
  for (i = 0; i < S_BUFSIZE; i++) {
    w2[i] = (gf2_u32) b1[i];
    w2[i] |= ( w2[i] << 8);
    w2[i] |= ( w2[i] << 16);
  }

  for (mtype=0; mtype < 6; ++mtype) {

    printf("Speed Test %d: %s (10s)\n",mtype,testnames[mtype]);
    t0 = time(0);

    /* start timer */
    gettimeofday(&t1, &tz);
    total = 0;
    while (time(0) - t0 < 10) {
      switch (mtype) {
      case 0: 
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_long_mod_multiply_u8(b1[i], b2[i], poly); 
	break;
      case 1: 
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_long_mod_multiply_u8_arm_simd(w1[i],w2[i],poly_simd);
	break;
      case 2: 
	if (mul_table_m1 == NULL)
	  gf2_fast_u8_init_m1(poly,&mul_table_m1, &inv_table_m1);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u8_mul_m1(mul_table_m1,
			     (gf2_u8)b1[i], (gf2_u8)b2[i]);
	break;
      case 3: 
	if (log_table_m2 == NULL)
	  gf2_fast_u8_init_m2(poly,3,&log_table_m2, &exp_table_m2);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u8_mul_m2(log_table_m2,exp_table_m2,
			     (gf2_u8)b1[i], (gf2_u8)b2[i]); 
	break;
      case 4: 
	if (log_table_m3 == NULL)
	  gf2_fast_u8_init_m3(poly,3,&log_table_m3, &exp_table_m3);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u8_mul_m3(log_table_m3,exp_table_m3,
			     (gf2_u8)b1[i], (gf2_u8)b2[i]); 
	break;
      case 5:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_multiply(result, 
		       ((gf2_u8*)b1)+i, ((gf2_u8*)b2)+i,
		       poly_str,1,scratch);
	/*	*result^=*scratch; */
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
    printf("Speed Test %d: -> %.5lf M*/s\n", mtype,
	   total/tsec/1024.0/1024.0);
  }

}

main () {

  test_sizes();

  test_gf2_long_mod_multiply();
  test_gf2_long_mod_multiply_u8_arm_simd();

  printf("\n");

  benchmark_u8_methods(); 

  /*  benchmark_u16_methods();	 */
  /* 
  test_gf2_fast_u32_m1();
  test_gf2_fast_u32_m2(); 
  test_gf2_fast_u32_m3(); 

  benchmark_u32_methods();
 */
}

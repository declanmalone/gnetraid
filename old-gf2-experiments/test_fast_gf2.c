#include <stdio.h>
#include "fast_gf2.h"
#include <sys/time.h>
#include <stdlib.h>

void test_sizes(void) {

  printf("\nTesting word sizes\n");
  printf("u8 is 1 byte? %s\n", (sizeof(gf2_u8) == 1)? "ok" : "not ok");
  printf("u16 is 2 bytes? %s\n", (sizeof(gf2_u16) == 2)? "ok" : "not ok");
  printf("u32 is 4 bytes? %s\n", (sizeof(gf2_u32) == 4)? "ok" : "not ok");
  printf("s8 is 1 byte? %s\n", (sizeof(gf2_s8) == 1)? "ok" : "not ok");
  printf("s16 is 2 bytes? %s\n", (sizeof(gf2_s16) == 2)? "ok" : "not ok");
  printf("s32 is 4 bytes? %s\n", (sizeof(gf2_s32) == 4)? "ok" : "not ok");

}

void test_gf2_long_mod_multiply(void) {

  gf2_u8 a=0x53;
  gf2_u8 b=0xca;
  gf2_u8 poly=0x1b;
  gf2_u8 result_u8;

  gf2_u16 a_u16=0x53;
  gf2_u16 b_u16=0xca;
  gf2_u16 poly_u16=0x11b;
  gf2_u16 result_u16;

  printf("\nTesting basic long multiplication\n");

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
  
  /* */

  
}


void test_gf2_long_mod_inverse (void) {

  gf2_u8 a;
  gf2_u8 poly=0x1b;
  gf2_u8 result;

  gf2_u16 a16;
  gf2_u16 poly16=0x2b;
  gf2_u16 result16;

  int errors=0;
  int count=0;

  /* 
    assuming our multiply function works, we can just loop through all
    non-zero values and see if multiplying the number by its inverse
    is equal to one.
  */

  printf("\nTesting basic long inverse\n");

  /* but we'll check that inv {53} == {CA} and vice-versa first */
  printf("Is inv({CA}) == {53} mod {11b}? : ");
  printf((gf2_long_mod_inverse_u8(0xca,0x1b)==0x53) ? "ok\n" : "not ok\n");

  printf("Is inv({53}) == {CA} mod {11b}? : ");
  printf((gf2_long_mod_inverse_u8(0x53,0x1b)==0xca) ? "ok\n" : "not ok\n");

  printf("Checking all a x inv(a) == 1 : ");
  for (a=1; a; ++a) {		/* relies on overflow of 255 + 1 == 0 */
    result=gf2_long_mod_inverse_u8(a,poly);
    if (gf2_long_mod_multiply_u8(a,result,poly) != 1) {
      printf("Failed a=%u x %u != 1\n", a, result);
      ++errors;
    }
    count++;
  }
  if (errors==0) 
    printf("ok (%d values tested)\n",count);
  else 
    printf("not ok (failed %d/255 tests)\n", errors);

  /* 16-bit */
  errors=0; count=0;
  printf("Checking all a x inv(a) == 1 : ");
  for (a16=1; a16; ++a16) {
    result16=gf2_long_mod_inverse_u16(a16,poly16);
    if (gf2_long_mod_multiply_u16(a16,result16,poly16) != 1) {
      printf("Failed a=%u x %u != 1\n", a16, result16);
      ++errors;
    }
    count++;
  }
  if (errors==0) 
    printf("ok (%d values tested)\n",count);
  else 
    printf("not ok (failed %d/65535 tests)\n", errors);
}

void test_gf2_long_mod_power(void) {

  gf2_u8 x,y,z;

  x=0xca;

  printf("\nTesting long power modulo a polynomial\n");

  y=gf2_long_mod_multiply_u8(x,x,0x1b);
  printf("Squaring {0xca} == {%02x} mod {11b} ? : ", 
	 (unsigned) y);
  if ((z=gf2_long_mod_power_u8(x,2,0x1b)) == y) {
    printf ("ok\n");
  } else {
    printf ("not ok (got %u\n",(unsigned) z);
  }

  y=gf2_long_mod_multiply_u8(x,y,0x1b);
  printf("Cubing {0xca} == {%02x} mod {11b} ? : ", 
	 (unsigned) y);
  if ((z=gf2_long_mod_power_u8(x,3,0x1b)) == y) {
    printf ("ok\n");
  } else {
    printf ("not ok (got %u\n",(unsigned) z);
  }

  y=gf2_long_mod_inverse_u8(x,0x1b);
  printf("Inverse {0xca} == {%02x} mod {11b} ? : ", 
	 (unsigned) y);
  if ((z=gf2_long_mod_power_u8(x,254,0x1b)) == y) {
    printf ("ok\n");
  } else {
    printf ("not ok (got %u\n",(unsigned) z);
  }

}


void test_gf2_fast_u8_m1(void) {
  gf2_u8 *mul_table;
  gf2_u8 *inv_table;
  gf2_u8 poly,x,y,z;
  int    rc;
  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u8 values[]={0,1,2,3,4,26,27,28,32,64,99,128,140,252,253,254,255,255};
  gf2_u8 last_x,last_y;
  int    errors, count;

  printf("\nTesting fast u8 arithmetic, method 1\n");

  poly=0x1b;

  printf ("Create lookup tables? ");
  rc=gf2_fast_u8_init_m1(poly,&mul_table, &inv_table);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {53} x {CA} == 1 mod {11b}? : ");
    z=gf2_fast_u8_mul_m1(mul_table,0x53,0xca);
    if (z == 1) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%02x}\n", (int) z);
    }

    /* multiply sample values using long multiply and fast multiply */
    printf ("Comparing results with long multiplication: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_long_mod_multiply_u8(values[x],values[y],poly);
	if (rc != gf2_fast_u8_mul_m1(mul_table,values[x],values[y])) {
	  ++errors; 
	  printf ("not ok: wrong result for %u x %u\n",
		  (unsigned) values[x], (unsigned) values[y]);
	}
	++count;
	last_y=values[y]; 
      }
      last_x=values[x];
    }
    if (!errors) printf("ok (%d trials)\n",count);

    printf("Freeing table memory.\n");
    gf2_fast_u8_deinit_m1(mul_table, inv_table);

  }
}

void test_gf2_fast_u8_m2(void) {
  gf2_u8 *log_table;
  gf2_u8 *exp_table;

  gf2_u8 poly,x,y,z;
  int    rc;
  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u8 values[]={0,1,2,3,4,26,27,28,32,64,99,128,140,252,253,254,255,255};
  gf2_u8 last_x,last_y;
  int    errors, count;

  printf("\nTesting fast u8 arithmetic: unoptimised log/exp tables\n");

  poly=0x1b;

  printf ("Create lookup tables? ");
  rc=gf2_fast_u8_init_m2(poly,3,&log_table, &exp_table);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {53} x {CA} == 1 mod {11b}? : ");
    z=gf2_fast_u8_mul_m2(log_table,exp_table,0x53,0xca);
    if (z == 1) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%02x}\n", (int) z);
    }

    /* multiply sample values using long multiply and fast multiply */
    printf ("Comparing results with long multiplication: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_long_mod_multiply_u8(values[x],values[y],poly);
	if (rc != 
	    gf2_fast_u8_mul_m2(log_table,exp_table,values[x],values[y])) {
	  ++errors; 
	  printf ("not ok: wrong result for %u x %u\n",
		  (unsigned) values[x], (unsigned) values[y]);
	}
	++count;
	last_y=values[y]; 
      }
      last_x=values[x];
    }
    if (!errors) printf("ok (%d trials)\n",count);
    printf("Freeing table memory.\n");
    gf2_fast_u8_deinit_m2(log_table,exp_table);
  }
}


void test_gf2_fast_u8_m3(void) {
  gf2_s16 *log_table;
  gf2_u8  *exp_table;

  gf2_u8  poly,x,y,z;
  int     rc;
  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u8  values[]={0,1,2,3,4,26,27,28,32,64,99,128,140,252,253,254,255,255};
  gf2_u8  last_x,last_y;
  int     errors, count;

  printf("\nTesting fast u8 arithmetic: optimised log/exp tables\n");

  poly=0x1b;

  printf ("Create lookup tables? ");
  rc=gf2_fast_u8_init_m3(poly,3,&log_table, &exp_table);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {53} x {CA} == 1 mod {11b}? : ");
    z=gf2_fast_u8_mul_m3(log_table,exp_table,0x53,0xca);
    if (z == 1) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%02x}\n", (int) z);
    }

    /* multiply sample values using long multiply and fast multiply */
    printf ("Comparing results with long multiplication: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u8_mul_m3(log_table,exp_table,values[x],values[y]);
	if (rc != gf2_long_mod_multiply_u8(values[x],values[y],poly)) {
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

  unsigned int *b1, *b2;
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
      "long multiply", 
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

  gf2_u8 poly=0x1b;

  b1 = (unsigned int *) malloc(sizeof(unsigned int) * S_BUFSIZE);
  b2 = (unsigned int *) malloc(sizeof(unsigned int) * S_BUFSIZE);

  for (i = 0; i < S_BUFSIZE; i++) b1[i] = lrand48() % top;
  for (i = 0; i < S_BUFSIZE; i++) b2[i] = lrand48() % top;

  for (mtype=0; mtype < 5; ++mtype) {

    printf("Speed Test %d: %s (10s)\n",mtype,testnames[mtype]);
    t0 = time(0);

    /* start timer */
    gettimeofday(&t1, &tz);
    total = 0;
    while (time(0) - t0 < 10) {
      switch (mtype) {
      case 0: 
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_long_mod_multiply_u8((gf2_u8)b1[i], (gf2_u8)b2[i], 0x1b); 
	break;
      case 1: 
	if (mul_table_m1 == NULL)
	  gf2_fast_u8_init_m1(poly,&mul_table_m1, &inv_table_m1);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u8_mul_m1(mul_table_m1,
			     (gf2_u8)b1[i], (gf2_u8)b2[i]);
	break;
      case 2: 
	if (log_table_m2 == NULL)
	  gf2_fast_u8_init_m2(poly,3,&log_table_m2, &exp_table_m2);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u8_mul_m2(log_table_m2,exp_table_m2,
			     (gf2_u8)b1[i], (gf2_u8)b2[i]); 
	break;
      case 3: 
	if (log_table_m3 == NULL)
	  gf2_fast_u8_init_m3(poly,3,&log_table_m3, &exp_table_m3);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u8_mul_m3(log_table_m3,exp_table_m3,
			     (gf2_u8)b1[i], (gf2_u8)b2[i]); 
	break;
      case 4:
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

void test_gf2_fast_u16_m1(void) {
  gf2_u16 a_u16,b_u16;
  gf2_u16 poly_u16;
  gf2_u16 *logs_u16;
  gf2_u16 *exps_u16;
  gf2_u16 result_u16;
  int rc;

  a_u16=0x01B1;			/* 433 */
  b_u16=0xC350;			/* 50000 */
  poly_u16=0x100B;

  printf("\nTesting fast u16 arithmetic, method 1\n");

  printf("Create lookup tables? "); 

  /* 
    Since the above polynomial is primitive, it seems like any field
    element other than 0, 1 can be used as a generator. Must check
    that some time.
  */
  rc=gf2_fast_u16_init_m1(poly_u16,3,&logs_u16,&exps_u16);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? (16-bit): ");
    result_u16=gf2_fast_u16_mul_m1(logs_u16,exps_u16,a_u16,b_u16);
    if (result_u16 == 0xb07f) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%04x}\n", (int) result_u16);
    }

    printf("Freeing table memory.\n");
    gf2_fast_u16_deinit_m1(logs_u16,exps_u16);

  }
}

void test_gf2_fast_u16_m2(void) {
  gf2_u16 a_u16,b_u16;
  gf2_u16 poly_u16;
  gf2_u16 *lmul_u16;
  gf2_u16 *rmul_u16;
  gf2_u16 *inv_u16;
  gf2_u16 result_u16;
  int rc;

  a_u16=0x01B1;			/* 433 */
  b_u16=0xC350;			/* 50000 */
  poly_u16=0x100B;

  printf("\nTesting fast u16 arithmetic, method 2a (no generator)\n");

  printf("Create lookup tables? "); 

  /* 3 is a generator for this field */
  rc=gf2_fast_u16_init_m2(poly_u16,0,&lmul_u16,&rmul_u16,&inv_u16);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? (16-bit): ");
    result_u16=gf2_fast_u16_mul_m2(lmul_u16,rmul_u16,a_u16,b_u16);
    if (result_u16 == 0xb07f) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%04x}\n", (int) result_u16);
    }

    printf("Freeing table memory.\n");
    gf2_fast_u16_deinit_m2(lmul_u16,rmul_u16,inv_u16);

  }
  printf("\nTesting fast u16 arithmetic, method 2b (with generator)\n");

  printf("Create lookup tables? "); 

  /* 3 is a generator for this field */
  rc=gf2_fast_u16_init_m2(poly_u16,3,&lmul_u16,&rmul_u16,&inv_u16);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? (16-bit): ");
    result_u16=gf2_fast_u16_mul_m2(lmul_u16,rmul_u16,a_u16,b_u16);
    if (result_u16 == 0xb07f) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%04x}\n", (int) result_u16);
    }

    printf("Freeing table memory.\n");
    gf2_fast_u16_deinit_m2(lmul_u16,rmul_u16,inv_u16);

  }
}

void test_gf2_fast_u16_m3(void) {
  gf2_s32 *log_table;
  gf2_u16 *exp_table;

  gf2_u16  poly,x,y,z;
  int      rc;
  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u16  values[]={0,1,2,3,140,252,255,256,257,1024,32768,44732,65535,65535};
  gf2_u16  last_x,last_y;
  int      errors, count;

  printf("\nTesting fast u8 arithmetic, method 3\n");

  poly=0x100b;

  printf ("Create lookup tables? ");
  rc=gf2_fast_u16_init_m3(poly,3,&log_table, &exp_table);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? : ");
    z=gf2_fast_u16_mul_m3(log_table,exp_table,0x01b1,0xc350);
    if (z == 0xb07f) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%04x}\n", (unsigned) z);
    }

    /* multiply sample values using long multiply and fast multiply */
    printf ("Comparing results with long multiplication: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u16_mul_m3(log_table,exp_table,values[x],values[y]);
	if (rc != gf2_long_mod_multiply_u16(values[x],values[y],poly)) {
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
    gf2_fast_u16_deinit_m3(log_table, exp_table);
  }
}

void test_gf2_fast_u16_m4(void) {
  gf2_u16 a_u16,b_u16;
  gf2_u16 poly_u16,x,y,z;
  gf2_u16 *mul_tab;
  gf2_u16 *inv_u16;
  gf2_u16 result_u16;
  int rc;

  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u16  values[]={0,1,2,3,140,252,255,256,257,1024,32768,44732,65535,65535};
  gf2_u16  last_x,last_y;
  int      errors, count;

  a_u16=0x01B1;			/* 433 */
  b_u16=0xC350;			/* 50000 */
  poly_u16=0x100B;

  printf("\nTesting fast u16 arithmetic, method 4 (8-bit x 8-bit)\n");

  printf("Create lookup tables? "); 

  rc=gf2_fast_u16_init_m4(poly_u16, &mul_tab, &inv_u16);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? (16-bit): ");
    result_u16=gf2_fast_u16_mul_m4(mul_tab, a_u16,b_u16);
    if (result_u16 == 0xb07f) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%04x}\n", (int) result_u16);
    }

    printf ("Comparing results with long multiplication: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u16_mul_m4(mul_tab,
			       values[x],values[y]);
	if (rc != gf2_long_mod_multiply_u16(values[x],values[y],poly_u16)) {
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
    gf2_fast_u16_deinit_m4(mul_tab,inv_u16);
  }
}

void test_gf2_fast_u16_m5(void) {
  gf2_u16 a_u16,b_u16;
  gf2_u16 poly_u16,x,y,z;
  gf2_u16 *m1_tab_m5,*m2_tab_m5,*m3_tab_m5,*m4_tab_m5;
  gf2_u16 *inv_u16;
  gf2_u16 result_u16;
  int rc;

  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u16  values[]={0,1,2,3,140,252,255,256,257,1024,32768,44732,65535,65535};
  gf2_u16  last_x,last_y;
  int      errors, count;

  a_u16=0x01B1;			/* 433 */
  b_u16=0xC350;			/* 50000 */
  poly_u16=0x100B;

  printf("\nTesting fast u16 arithmetic, method 4 (8-bit x 8-bit)\n");

  printf("Create lookup tables? "); 

  rc=gf2_fast_u16_init_m5(poly_u16,
			  &m1_tab_m5,&m2_tab_m5,&m3_tab_m5, &m4_tab_m5,
			  &inv_u16);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? (16-bit): ");
    result_u16=gf2_fast_u16_mul_m5(m1_tab_m5,m2_tab_m5,m3_tab_m5,m4_tab_m5,
				   a_u16,b_u16);
    if (result_u16 == 0xb07f) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%04x}\n", (int) result_u16);
    }

    printf ("Comparing results with long multiplication: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u16_mul_m5(m1_tab_m5,m2_tab_m5,m3_tab_m5,m4_tab_m5,
			       values[x],values[y]);
	if (rc != gf2_long_mod_multiply_u16(values[x],values[y],poly_u16)) {
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
    gf2_fast_u16_deinit_m5(m1_tab_m5,inv_u16);
  }
}

void test_gf2_fast_u16_m6(void) {
  gf2_u16 a_u16,b_u16;
  gf2_u16 poly_u16,x,y,z;
  gf2_u16 *mul_tab;
  gf2_u16 *inv_u16;
  gf2_u16 result_u16;
  int rc;

  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u16  values[]={0,1,2,3,140,252,255,256,257,1024,32768,44732,65535,65535};
  gf2_u16  last_x,last_y;
  int      errors, count;

  a_u16=0x01B1;			/* 433 */
  b_u16=0xC350;			/* 50000 */
  poly_u16=0x100B;

  printf("\nTesting fast u16 arithmetic, method 4 (8-bit x 8-bit)\n");

  printf("Create lookup tables? "); 

  rc=gf2_fast_u16_init_m6(poly_u16, &mul_tab, &inv_u16);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? (16-bit): ");
    result_u16=gf2_fast_u16_mul_m6(mul_tab, a_u16,b_u16,poly_u16);
    if (result_u16 == 0xb07f) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%04x}\n", (int) result_u16);
    }

    printf ("Comparing results with long multiplication: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u16_mul_m6(mul_tab,
			       values[x],values[y],poly_u16);
	if (rc != gf2_long_mod_multiply_u16(values[x],values[y],poly_u16)) {
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
    gf2_fast_u16_deinit_m6(mul_tab,inv_u16);
  }
}

void test_gf2_fast_u16_m7(void) {
  gf2_u16 a_u16,b_u16;
  gf2_u16 poly_u16,x,y,z;
  gf2_u16 *mul_tab;
  gf2_u16 *inv_u16;
  gf2_u16 *shift_tab;
  gf2_u16 result_u16;
  int rc;

  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u16  values[]={0,1,2,3,140,252,255,256,257,1024,32768,44732,65535,65535};
  gf2_u16  last_x,last_y;
  int      errors, count;

  a_u16=0x01B1;			/* 433 */
  b_u16=0xC350;			/* 50000 */
  poly_u16=0x100b;

  printf("\nTesting fast u16 (8-bit x 8-bit, fast shift)\n");

  printf("Create lookup tables? "); 

  rc=gf2_fast_u16_init_m7(poly_u16, &mul_tab, &inv_u16,&shift_tab);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? (16-bit): ");
    result_u16=gf2_fast_u16_mul_m7(mul_tab, shift_tab, a_u16, b_u16);
    if (result_u16 == 0xb07f) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%04x}\n", (int) result_u16);
    }

    printf ("Comparing results with long multiplication: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u16_mul_m7(mul_tab,shift_tab,
			       values[x],values[y]);
	if (rc != gf2_long_mod_multiply_u16(values[x],values[y],poly_u16)) {
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
    gf2_fast_u16_deinit_m7(mul_tab,inv_u16,shift_tab);
  }
}


void test_gf2_fast_u16_m8(void) {
  gf2_u16 a_u16,b_u16;
  gf2_u16 poly_u16,x,y,z;
  gf2_u16 *lmul_tab;
  gf2_u16 *rmul_tab;
  gf2_u16 *inv_u16;
  gf2_u16 *shift_tab;
  gf2_u16 result_u16;
  int rc;

  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u16  values[]={0,1,2,3,140,252,255,256,257,1024,32768,44732,65535,65535};
  gf2_u16  last_x,last_y;
  int      errors, count;

  a_u16=0x01B1;			/* 433 */
  b_u16=0xC350;			/* 50000 */
  poly_u16=0x100b;

  printf("\nTesting fast u16 (8/4 split l-r for nibbles, fast shift)\n");

  printf("Create lookup tables? "); 

  rc=gf2_fast_u16_init_m8(poly_u16, &lmul_tab, &rmul_tab, &shift_tab,&inv_u16);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    printf ("Is {01B1} x {C350} == {B07F} mod {1100B}? (16-bit): ");
    result_u16=gf2_fast_u16_mul_m8(lmul_tab, rmul_tab, shift_tab, a_u16, b_u16);
    if (result_u16 == 0xb07f) {
      printf("ok\n");
    } else {
      printf("not ok. Got {%04x}\n", (int) result_u16);
    }

    printf ("Comparing results with long multiplication: ");
    last_x=255; last_y=255; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u16_mul_m8(lmul_tab,rmul_tab,shift_tab,
			       values[x],values[y]);
	if (rc != gf2_long_mod_multiply_u16(values[x],values[y],poly_u16)) {
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
    gf2_fast_u16_deinit_m8(lmul_tab,rmul_tab,inv_u16,shift_tab);
  }
}

void benchmark_u16_methods(void) {

  unsigned int *b1, *b2;
  unsigned int top=1<<16;
  unsigned int i;
  struct timeval t1, t2;
  struct timezone tz;
  long t0, now;
  double total, tsec;
  int mtype=0;

  /* arbitrary-precision numbers are big endian */
  char scratch[]={0,0, 0x10,0x0b, 0,0};
  char *poly_str=scratch+2;
  char *result=scratch+4;

  char * testnames[]=
    {
      "long multiply (u16 version)", 
      "log/exp tables + init", "log/exp tables w/o init",
      "l-r tables + init (with generator)", "l-r tables w/o init",
      "optimised log/exp tables + init",
      "optimised log/exp tables w/o init",
      "8-bit x 8-bit blocks (m1) + init", "8-bit x 8-bit blocks (m1) w/o init",
      "8-bit x 8-bit blocks (m2) + init", "8-bit x 8-bit blocks (m2) w/o init",
      "8-bit x 8-bit straight *, manual shift + init",
      "8-bit x 8-bit straight *, manual shift w/o init",
      "8-bit x 8-bit straight *, fast shift + init",
      "8-bit x 8-bit straight *, fast shift w/o init",
      "8-bit x 4-bit straight *, l-r on nibbles, fast shift + init",
      "8-bit x 4-bit straight *, l-r on nibbles, fast shift w/o init",
      "arbitrary-precision u16 multiply",
    };
     
  gf2_u16 *log_table_m1=NULL;
  gf2_u16 *exp_table_m1=NULL;
  gf2_u16 *lmul_table_m2=NULL;
  gf2_u16 *rmul_table_m2=NULL;
  gf2_u16 *inv_table_m2=NULL;
  gf2_s32 *log_table_m3=NULL;
  gf2_u16 *exp_table_m3=NULL;
  gf2_u16 *mul_table_m4=NULL;
  gf2_u16 *inv_table_m4=NULL;
  gf2_u16 *m1_tab_m5=NULL;
  gf2_u16 *m2_tab_m5=NULL;
  gf2_u16 *m3_tab_m5=NULL;
  gf2_u16 *m4_tab_m5=NULL;
  gf2_u16 *inv_table_m5=NULL;
  gf2_u16 *mul_table_m6=NULL;
  gf2_u16 *inv_table_m6=NULL;
  gf2_u16 *mul_table_m7=NULL;
  gf2_u16 *inv_table_m7=NULL;
  gf2_u16 *shift_tab_m7=NULL;
  gf2_u16 *lmul_table_m8=NULL;
  gf2_u16 *rmul_table_m8=NULL;
  gf2_u16 *shift_tab_m8=NULL;
  gf2_u16 *inv_table_m8=NULL;

  gf2_u16 poly=0x2b;

  printf("\nBenchmarking u16 multiply routines.\n");
  printf("All tests run for 10 seconds. M*/s == 1048576 multiplies/sec\n");

  b1 = (unsigned int *) malloc(sizeof(unsigned int) * S_BUFSIZE);
  b2 = (unsigned int *) malloc(sizeof(unsigned int) * S_BUFSIZE);

  for (i = 0; i < S_BUFSIZE; i++) b1[i] = lrand48() % top;
  for (i = 0; i < S_BUFSIZE; i++) b2[i] = lrand48() % top;

  for (mtype=0; mtype < 18; ++mtype) {

    printf("Test %d: %s\n",mtype,testnames[mtype]);
    t0 = time(0);

    /* start timer */
    gettimeofday(&t1, &tz);
    total = 0;
    while (time(0) - t0 < 10) {
      switch (mtype) {
      case 0: 
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_long_mod_multiply_u16((gf2_u16)b1[i], (gf2_u16)b2[i], 0x2b); 
	break;

      case 1: 
	if (log_table_m1 == NULL)
	  gf2_fast_u16_init_m1(poly,3,&log_table_m1, &exp_table_m1);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m1(log_table_m1,exp_table_m1,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]);
	break;

      case 2: 
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m1(log_table_m1,exp_table_m1,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]);
	break;

      case 3:
	if (lmul_table_m2 == NULL)
	  gf2_fast_u16_init_m2(poly,3,
			       &lmul_table_m2, &rmul_table_m2,
			       &inv_table_m2);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m2(lmul_table_m2,rmul_table_m2,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 4: 
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m2(lmul_table_m2,rmul_table_m2,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 5:
	if (log_table_m3 == NULL)
	  gf2_fast_u16_init_m3(poly,3,&log_table_m3, &exp_table_m3);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m3(log_table_m3,exp_table_m3,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]);
	break;

      case 6:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m3(log_table_m3,exp_table_m3,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]);
	break;

      case 7:
	if (mul_table_m4 == NULL)
	  gf2_fast_u16_init_m4(poly, &mul_table_m4, &inv_table_m4);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m4(mul_table_m4,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 8: 
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m4(mul_table_m4,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 9:
	if (m1_tab_m5 == NULL)
	  gf2_fast_u16_init_m5(poly, &m1_tab_m5, &m2_tab_m5, 
			       &m3_tab_m5, &m4_tab_m5, &inv_table_m5);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m5(m1_tab_m5,m2_tab_m5,m3_tab_m5,m4_tab_m5,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 10: 
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m5(m1_tab_m5,m2_tab_m5,m3_tab_m5,m4_tab_m5,
			     (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 11:
	if (mul_table_m6 == NULL)
	  gf2_fast_u16_init_m6(poly, &mul_table_m6, &inv_table_m6);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m6(mul_table_m6,
			      (gf2_u16)b1[i], (gf2_u16)b2[i],poly); 
	break;

      case 12:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m6(mul_table_m6,
			      (gf2_u16)b1[i], (gf2_u16)b2[i],poly); 
	break;

      case 13:
	if (mul_table_m7 == NULL)
	  gf2_fast_u16_init_m7(poly, &mul_table_m7, &inv_table_m7,
			       &shift_tab_m7);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m7(mul_table_m6,shift_tab_m7,
			      (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 14:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m7(mul_table_m7,shift_tab_m7,
			      (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 15:
	if (lmul_table_m8 == NULL)
	  gf2_fast_u16_init_m8(poly, &lmul_table_m8, &rmul_table_m8, 
			       &shift_tab_m8, &inv_table_m8);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m8(lmul_table_m8,rmul_table_m8,shift_tab_m8,
			      (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 16:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u16_mul_m8(lmul_table_m8,rmul_table_m8,shift_tab_m8,
			      (gf2_u16)b1[i], (gf2_u16)b2[i]); 
	break;

      case 17:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_multiply(result,
		       ((gf2_u16*)b1)+i, ((gf2_u16*)b2)+i,
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
      gf2_fast_u16_deinit_m1(log_table_m1, exp_table_m1);
    } else if (mtype==4) {
      gf2_fast_u16_deinit_m2(lmul_table_m2, rmul_table_m2, inv_table_m2);
    } else if (mtype==6) {
      gf2_fast_u16_deinit_m3(log_table_m3,exp_table_m3);
    } else if (mtype==8) {
      gf2_fast_u16_deinit_m4(mul_table_m4,inv_table_m4);
    } else if (mtype==10) {
      gf2_fast_u16_deinit_m5(m1_tab_m5,inv_table_m5);
    } else if (mtype==12) {
      gf2_fast_u16_deinit_m6(mul_table_m6,inv_table_m6);
    } else if (mtype==14) {
      gf2_fast_u16_deinit_m7(mul_table_m7,inv_table_m7,shift_tab_m7);
    } else if (mtype==16) {
      gf2_fast_u16_deinit_m8(lmul_table_m8,rmul_table_m8,shift_tab_m8,inv_table_m8);
    }

  }

}

void test_gf2_fast_u32_m1(void) {
  gf2_u32 *mul_table;
  gf2_u32 *shift_tab;

  gf2_u32  poly,x,y,z;
  int      rc;
  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u32  values[]={0,1,2,3,140,252,255,256,257,1024,32768,
		     49152,44732,65535,65536,0x0023544b,0xc04faced,
		     0xf0d1cebd,0xffffffff,0xffffffff};
  gf2_u32  last_x,last_y;
  int      errors, count;

  printf("\nTesting fast u32 arithmetic, method 1\n");

  poly=0x00000086;

  printf ("Create lookup tables? ");
  rc=gf2_fast_u32_init_m1(poly,&mul_table, &shift_tab);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    /* multiply sample values using long multiply and fast multiply */
    printf ("Comparing results with long multiplication: ");
    last_x=0xffffffff; last_y=0xffffffff; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u32_mul_m1(mul_table,shift_tab,values[x],values[y]);
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
    gf2_fast_u32_deinit_m1(mul_table,shift_tab);
  }
}

void test_gf2_fast_u32_m2(void) {
  gf2_u16 *mul_table;
  gf2_u32 *shift_tab;

  gf2_u32  poly,x,y,z;
  int      rc;
  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u32  values[]={0,1,2,3,140,252,255,256,257,1024,32768,
		     49152,44732,65535,65536,0x0023544b,0xc04faced,
		     0xf0d1cebd,0xffffffff,0xffffffff};
  gf2_u32  last_x,last_y;
  int      errors, count;

  printf("\nTesting fast u32 arithmetic, method 2\n");

  poly=0x00000086;

  printf ("Create lookup tables? ");
  rc=gf2_fast_u32_init_m2(poly,&mul_table, &shift_tab);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    /* multiply sample values using long multiply and fast multiply */
    printf ("Comparing results with long multiplication: ");
    last_x=0xffffffff; last_y=0xffffffff; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u32_mul_m2(mul_table,shift_tab,values[x],values[y]);
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
    gf2_fast_u32_deinit_m2(mul_table,shift_tab);
  }
}

void test_gf2_fast_u32_m3(void) {
  gf2_u16 *lmul_table;
  gf2_u16 *rmul_table;
  gf2_u32 *shift_tab;

  gf2_u32  poly,x,y,z;
  int      rc;
  /* list of sample values to multiply. Repeated value signifies end of list */
  gf2_u32  values[]={0,1,2,3,140,252,255,256,257,1024,32768,
		     49152,44732,65535,65536,0x0023544b,0xc04faced,
		     0xf0d1cebd,0xffffffff,0xffffffff};
  gf2_u32  last_x,last_y;
  int      errors, count;

  printf("\nTesting fast u32 arithmetic, method 3\n");

  poly=0x00000086;

  printf ("Create lookup tables? ");
  rc=gf2_fast_u32_init_m3(poly,&lmul_table, &rmul_table, &shift_tab);
  if (rc) {
    printf("not ok. skipping further tests.\n");
  } else {
    printf("ok\n");

    /* multiply sample values using long multiply and fast multiply */
    printf ("Comparing results with long multiplication: ");
    last_x=0xffffffff; last_y=0xffffffff; errors=0; count=0;
    for (x=0; values[x] != last_x; ++x) {
      for (y=0; values[y] != last_y; ++y) {
	rc=gf2_fast_u32_mul_m3(lmul_table,rmul_table,
			       shift_tab,values[x],values[y]);
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
    gf2_fast_u32_deinit_m3(lmul_table,rmul_table,shift_tab);
  }
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
      "2/4 split, fast shift + init", "2/4 split, fast shift w/o init",
      "4/4 split, fast shift + init", "4/4 split, fast shift w/o init",
      "4/8 split, fast shift + init", "4/8 split, fast shift w/o init",
      "arbitrary-precision u32 multiply",
    };
     
  gf2_u32 *mul_table_m1=NULL;
  gf2_u32 *shift_tab_m1=NULL;
  gf2_u16 *mul_table_m2=NULL;
  gf2_u32 *shift_tab_m2=NULL;
  gf2_u16 *lmul_table_m3=NULL;
  gf2_u16 *rmul_table_m3=NULL;
  gf2_u32 *shift_tab_m3=NULL;

  gf2_u32 poly=0x00000086;


  printf("\nBenchmarking u32 multiply routines.\n");
  printf("All tests run for 10 seconds. M*/s == 1048576 multiplies/sec\n");

  b1 = (gf2_u32 *) malloc(sizeof(gf2_u32) * S_BUFSIZE);
  b2 = (gf2_u32 *) malloc(sizeof(gf2_u32) * S_BUFSIZE);

  for (i = 0; i < S_BUFSIZE; i++) b1[i] = lrand48() % top;
  for (i = 0; i < S_BUFSIZE; i++) b2[i] = lrand48() % top;

  for (mtype=0; mtype < 8; ++mtype) {

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
	if (mul_table_m1 == NULL)
	  gf2_fast_u32_init_m1(poly, &mul_table_m1, &shift_tab_m1);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u32_mul_m1(mul_table_m1,shift_tab_m1,
			      b1[i], b2[i]); 
	break;

      case 2:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u32_mul_m1(mul_table_m1,shift_tab_m1,
			      b1[i], b2[i]); 
	break;

      case 3:
	if (mul_table_m2 == NULL)
	  gf2_fast_u32_init_m2(poly, &mul_table_m2, &shift_tab_m2);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u32_mul_m2(mul_table_m2,shift_tab_m2,
			      b1[i], b2[i]); 
	break;

      case 4:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u32_mul_m2(mul_table_m2,shift_tab_m2,
			      b1[i], b2[i]); 
	break;

      case 5:
	if (lmul_table_m3 == NULL)
	  gf2_fast_u32_init_m3(poly, &lmul_table_m3, &rmul_table_m3,
			       &shift_tab_m3);
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u32_mul_m3(lmul_table_m3,rmul_table_m3,shift_tab_m3,
			      b1[i], b2[i]); 
	break;

      case 6:
	for (i = 0; i < S_BUFSIZE; i++) 
	  gf2_fast_u32_mul_m3(lmul_table_m3,rmul_table_m3,shift_tab_m3,
			      b1[i], b2[i]); 
	break;

      case 7:
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
      gf2_fast_u32_deinit_m1(mul_table_m1,shift_tab_m1);
    } else if (mtype==4) {
      gf2_fast_u32_deinit_m2(mul_table_m2,shift_tab_m2);
    } else if (mtype==6) {
      gf2_fast_u32_deinit_m3(lmul_table_m3,rmul_table_m3,shift_tab_m3);
    }

  }
}


main () {

  test_sizes();

  test_gf2_long_mod_multiply();
  test_gf2_long_mod_inverse();
  test_gf2_long_mod_power();

  test_gf2_fast_u8_m1();
  test_gf2_fast_u8_m2();
  test_gf2_fast_u8_m3();

  test_gf2_fast_u16_m1();
  test_gf2_fast_u16_m2();
  test_gf2_fast_u16_m3();
  test_gf2_fast_u16_m4();
  test_gf2_fast_u16_m5();
  test_gf2_fast_u16_m6();
  test_gf2_fast_u16_m7();
  test_gf2_fast_u16_m7();
  test_gf2_fast_u16_m8();

  benchmark_u8_methods(); 

  benchmark_u16_methods();

  test_gf2_fast_u32_m1();
  test_gf2_fast_u32_m2(); 
  test_gf2_fast_u32_m3(); 

  benchmark_u32_methods();
}

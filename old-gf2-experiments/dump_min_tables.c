/* (c) Declan Malone 2009 */
/* Licensed under version 3 of the GPL */

/* 
  Of all the various possible optimisation techniques available for
  GF(2) arithmetic, the versions with the lowest memory footprints
  have surprisingly good performance. This program calls the
  initialisation routine for each of them in turn, with specified
  polynomials (and generators, where required) and outputs the lookup
  tables in a form suitable for inclusion in other C programs.
*/

#include <stdio.h>
#include <stdlib.h>
#include "fast_gf2.h"

void dump_u8_m3(void) {

  gf2_u8  poly=0x1b;
  gf2_u8  g=3; 
  gf2_s16 *log_table;
  gf2_u8  *exp_table;

  int i,rc;

  rc=gf2_fast_u8_init_m3(poly,g,&log_table,&exp_table);

  if (rc) {
    fprintf(stderr, "Failed to init u8 accelerated method\n");
    exit(1);
  }

  fprintf (stderr,"Testing {53} x {CA} = {%02x}\n", 
	   gf2_fast_u8_mul_m3(log_table,exp_table,0x53,0xca));

  /* print log table */
  printf ("static const gf2_s16 fast_gf2_log[] = {");
  for (i=0; i < 256; ++i) {
    if (i%8 == 0)
      printf("\n  ");
    printf("%d, ",log_table[i]);
  }
  printf ("\n};\n\n");

  /* print exp table (includes negative indices) */
  printf ("static const gf2_u16 fast_gf2_exp[] = {");
  for (i=-512; i < 512; ++i) {
    if (i%8 == 0)
      printf("\n  ");
    printf("%d, ",exp_table[i]);
  }
  printf ("\n};\n\n");

}

gf2_u16 *lmul_table_16;
gf2_u16 *rmul_table_16;

void dump_u16_m8(void) {
  gf2_u16  poly=0x2b;
  gf2_u16 *shift_tab;
  gf2_u16 *inv_table;

  int i,rc;

  rc=gf2_fast_u16_init_m8(poly,&lmul_table_16,&rmul_table_16,
			  &shift_tab,&inv_table);

  if (rc) {
    fprintf(stderr, "Failed to init u16 accelerated method\n");
    exit(1);
  }

  fprintf (stderr,"Testing {01b1} x {C350} = {%04x}\n", 
	   gf2_fast_u16_mul_m8(lmul_table_16,rmul_table_16,shift_tab
			       ,0x01b1,0xc350));

  /* print lmul table */
  printf ("static const gf2_u16 fast_gf2_lmul[] = {");
  for (i=0; i < 16 * 256; ++i) {
    if (i%8 == 0)
      printf("\n  ");
    printf("%d, ",lmul_table_16[i]);
  }
  printf ("\n};\n\n");

  /* print lmul table */
  printf ("static const gf2_u16 fast_gf2_rmul[] = {");
  for (i=0; i < 16 * 256; ++i) {
    if (i%8 == 0)
      printf("\n  ");
    printf("%d, ",rmul_table_16[i]);
  }
  printf ("\n};\n\n");

  /* print shift_u16 table */
  printf ("static const gf2_u16 fast_gf2_shift_u16[] = {");
  for (i=0; i < 256; ++i) {
    if (i%8 == 0)
      printf("\n  ");
    printf("%d, ",shift_tab[i]);
  }
  printf ("\n};\n\n");

}

void dump_u32_m3(void) {
  gf2_u32  poly=0x8d;
  gf2_u16 *lmul_table;
  gf2_u16 *rmul_table;
  gf2_u32 *shift_tab;

  int i,j,rc;
  fprintf(stderr, "poly is %lu\n", poly);
  rc=gf2_fast_u32_init_m3(poly,&lmul_table,&rmul_table,&shift_tab);

  if (rc) {
    fprintf(stderr, "Failed to init u16 accelerated method\n");
    exit(1);
  }

  /* fails on 0x54451368? (1413813096 in decimal) */
  fprintf (stderr,"Testing inv {54451368} == {%08lx}\n", 
	   gf2_long_mod_inverse_u32(1413813096l,poly));

  fprintf (stderr,"Testing {facecafe} x {deadbeef} = {%08lx}\n", 
	   gf2_fast_u32_mul_m3(lmul_table_16,rmul_table_16,shift_tab
			       ,0xfacecafe,0xdeadbeef));

  /* we use the same lmul, rmul tables as in u16 */
  /* check that, to be sure */
  for (i=0; i < 16 * 256; ++i) {
    if (lmul_table_16[i] != lmul_table[i]) {
      printf("Sorry; u16 straight multiply doesn't give same values as u32");
      exit(1);
    }
    if (rmul_table_16[i] != rmul_table[i]) {
      printf("Sorry; u16 straight multiply doesn't give same values as u32");
      exit(1);
    }
  }

  /* print shift_u32 table */
  printf ("static const gf2_u32 fast_gf2_shift_u32[] = {");
  for (i=0; i < 256; ++i) {
    if (i%8 == 0)
      printf("\n  ");
    printf("%ld, ",shift_tab[i]);
  }
  printf ("\n};\n\n");

} 

int main (int c, char *v[]) {

  printf("/* change these if your system has different word sizes */\n"
	 "typedef unsigned char    gf2_u8;\n"
	 "typedef unsigned short   gf2_u16;\n"
	 "typedef unsigned long    gf2_u32;\n"
	 "typedef signed char      gf2_s8;\n"
	 "typedef signed short     gf2_s16;\n"
	 "typedef signed long      gf2_s32;\n\n");


  dump_u8_m3();

  dump_u16_m8();

  dump_u32_m3();

}

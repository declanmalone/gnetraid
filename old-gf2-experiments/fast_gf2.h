
/* 
  Map various word sizes to native C types. These may need to be
  changed for different platforms. Ideally, I'll have a program test
  for things like this and byte order and spit out an appropriate
  header file before running make.  These values are appropriate for
  gcc on an x86 platform.  Note that in the event that the C types are
  larger than 8, 16 or 32 bits then various things will fail, since I
  assume in some cases that bits shifted off the end of the word are
  actually gone, or that additions/subtractions will wrap around on
  reaching max/min values.
*/
#include <stdint.h>

typedef unsigned char    gf2_u8;
typedef uint16_t         gf2_u16;
typedef uint32_t         gf2_u32;
typedef unsigned char*   gf2_apn; /* arbitrary-precision number */
typedef signed char      gf2_s8;
typedef int16_t          gf2_s16;
typedef int32_t          gf2_s32;

#define GF2_LITTLE_ENDIAN 1
#define GF2_BIG_ENDIAN    2
#define GF2_BYTE_ORDER    GF2_LITTLE_ENDIAN

#define HIGH_BIT_gf2_u8  0x80
#define HIGH_BIT_gf2_u16 0x8000
#define HIGH_BIT_gf2_u32 0x80000000l
#define ALL_BITS_gf2_u8  0xff
#define ALL_BITS_gf2_u16 0xffff
#define ALL_BITS_gf2_u32 0xffffffffl
#define ORDER_u8    8
#define ORDER_u16   16
#define ORDER_u32   32

/* "long" operators */
gf2_u8  gf2_long_mod_multiply_u8 (gf2_u8  a, gf2_u8  b, gf2_u8  poly);
gf2_u16 gf2_long_mod_multiply_u16(gf2_u16 a, gf2_u16 b, gf2_u16 poly);
gf2_u32 gf2_long_mod_multiply_u32(gf2_u32 a, gf2_u32 b, gf2_u32 poly);

gf2_u16 gf2_long_straight_multiply_u8  (gf2_u8  a,gf2_u8  b);
gf2_u32 gf2_long_straight_multiply_u16 (gf2_u16 a,gf2_u16 b);

gf2_u8  gf2_long_mod_inverse_u8  (gf2_u8  x, gf2_u8  poly);
gf2_u16 gf2_long_mod_inverse_u16 (gf2_u16 x, gf2_u16 poly);
gf2_u32 gf2_long_mod_inverse_u32 (gf2_u32 x, gf2_u32 poly);

gf2_u8  gf2_long_mod_power_u8  (gf2_u8  x, gf2_u8  y, gf2_u8  poly);
gf2_u16 gf2_long_mod_power_u16 (gf2_u16 x, gf2_u16 y, gf2_u16 poly);
gf2_u32 gf2_long_mod_power_u32 (gf2_u32 x, gf2_u32 y, gf2_u32 poly);

/* 8-bit, method 1 */
int gf2_fast_u8_init_m1(gf2_u8 poly, 
			gf2_u8 **mul_table, gf2_u8 **inv_table);
void gf2_fast_u8_deinit_m1(gf2_u8 *mul_table, gf2_u8 *inv_table);
gf2_u8 gf2_fast_u8_mul_m1(gf2_u8 *mul_table, gf2_u8 a, gf2_u8 b);
gf2_u8 gf2_fast_u8_inv_m1(gf2_u8 *inv_table, gf2_u8 a);
gf2_u8 gf2_fast_u8_div_m1(gf2_u8 *mul_table, gf2_u8 *inv_table,
			  gf2_u8 a, gf2_u8 b);
gf2_u8 gf2_fast_u8_dpc_m1(gf2_u8 *mul_table, gf2_u8 *a, gf2_u8 *b, 
			  int len);
gf2_u8 gf2_fast_u8_dpd_m1(gf2_u8 *mul_table,
			  gf2_u8 *a, int da,
			  gf2_u8 *b, int db,
			  int len);

/* 8-bit, method 2 */
int gf2_fast_u8_init_m2(gf2_u8 poly, gf2_u8 g, 
			gf2_u8 **log_table, gf2_u8 **exp_table);
void gf2_fast_u8_deinit_m2(gf2_u8 *log_table, gf2_u8 *exp_table);
gf2_u8 gf2_fast_u8_mul_m2(gf2_u8 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b);
gf2_u8 gf2_fast_u8_inv_m2(gf2_u8 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a);
gf2_u8 gf2_fast_u8_div_m2(gf2_u8 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b);

/* 8-bit, method 3 */
int gf2_fast_u8_init_m3(gf2_u8 poly, gf2_u8 g, 
			gf2_s16 **log_table, gf2_u8 **exp_table);
void gf2_fast_u8_deinit_m3(gf2_s16 *log_table, gf2_u8 *exp_table);
gf2_u8 gf2_fast_u8_mul_m3(gf2_s16 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b);
gf2_u8 gf2_fast_u8_inv_m3(gf2_s16 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a);
gf2_u8 gf2_fast_u8_div_m3(gf2_s16 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b);
gf2_u8 gf2_fast_u8_pow_m3(gf2_s16 *log_table, gf2_u8 *exp_table,
			  gf2_u8 a, gf2_u8 b);


/* 16-bit, method 1 */
int gf2_fast_u16_init_m1(gf2_u16 poly, gf2_u16 g, 
			 gf2_u16 **log_table, gf2_u16 **exp_table);
void gf2_fast_u16_deinit_m1(gf2_u16 *log_table, gf2_u16 *exp_table);
gf2_u16 gf2_fast_u16_mul_m1(gf2_u16 *log_table, gf2_u16 *exp_table,
			    gf2_u16 a, gf2_u16 b);
gf2_u16 gf2_fast_u16_inv_m1(gf2_u16 *log_table, gf2_u16 *exp_table,
			    gf2_u16 a);
gf2_u16 gf2_fast_u16_div_m1(gf2_u16 *log_table, gf2_u16 *exp_table,
			    gf2_u16 a, gf2_u16 b);



/* 16-bit, method 2: l-r multiplication tables */
int gf2_fast_u16_init_m2(gf2_u16 poly, gf2_u16 g, 
			 gf2_u16 **lmul_table,
			 gf2_u16 **rmul_table,
			 gf2_u16 **inv_table);
void gf2_fast_u16_deinit_m2(gf2_u16 *lmul_table,
			    gf2_u16 *rmul_table,
			    gf2_u16 *inv_table);
gf2_u16 gf2_fast_u16_mul_m2(gf2_u16 *lmul_table,
			    gf2_u16 *rmul_table, 
			    gf2_u16 a, gf2_u16 b);
gf2_u16 gf2_fast_u16_inv_m2(gf2_u16 *inv_table, gf2_u16 a);
gf2_u16 gf2_fast_u16_div_m2(gf2_u16 *lmul_table,
			    gf2_u16 *rmul_table, 
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b);

/* 16-bit, method 3: optimised log/exp tables */
int gf2_fast_u16_init_m3(gf2_u16 poly, gf2_u16 g, 
			 gf2_s32 **log_table, gf2_u16 **exp_table);
void gf2_fast_u16_deinit_m3(gf2_s32 *log_table, gf2_u16 *exp_table);
gf2_u16 gf2_fast_u16_mul_m3(gf2_s32 *log_table, gf2_u16 *exp_table,
			    gf2_u16 a, gf2_u16 b);
gf2_u16 gf2_fast_u16_inv_m3(gf2_s32 *log_table, gf2_u16 *exp_table,
			    gf2_u16 a);
gf2_u16 gf2_fast_u16_div_m3(gf2_s32 *log_table, gf2_u16 *exp_table,
			    gf2_u16 a, gf2_u16 b);
gf2_u16 gf2_fast_u16_pow_m3(gf2_s32 *log_table, gf2_u16 *exp_table,
			    gf2_u16 a, gf2_u16 b);

/* u16, method 4: 8-bit x 8-bit chunks */
int gf2_fast_u16_init_m4(gf2_u16 poly, 
			 gf2_u16 **mul_table, gf2_u16 **inv_table);
gf2_u16 gf2_fast_u16_mul_m5(gf2_u16 *m1_tab,
			    gf2_u16 *m2_tab,
			    gf2_u16 *m3_tab,
			    gf2_u16 *m4_tab, 
			    gf2_u16 a, gf2_u16 b);
gf2_u16 gf2_fast_u16_mul_m4(gf2_u16 *mul_table, 
			    gf2_u16 a, gf2_u16 b);
gf2_u16 gf2_fast_u16_inv_m4(gf2_u16 *inv_table, gf2_u16 a);
gf2_u16 gf2_fast_u16_div_m4(gf2_u16 *mul_table, 
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b);

/* u6, method 5: 8-bit x 8-bit chunks, four multiplication tables */
int gf2_fast_u16_init_m5(gf2_u16 poly, 
			 gf2_u16 **m1_tab,
			 gf2_u16 **m2_tab,
			 gf2_u16 **m3_tab,
			 gf2_u16 **m4_tab,
			 gf2_u16 **inv_table);
void gf2_fast_u16_deinit_m5(gf2_u16 *m1_tab, gf2_u16 *inv_table);
gf2_u16 gf2_fast_u16_mul_m5(gf2_u16 *m1_tab,
			    gf2_u16 *m2_tab,
			    gf2_u16 *m3_tab,
			    gf2_u16 *m4_tab, 
			    gf2_u16 a, gf2_u16 b);
gf2_u16 gf2_fast_u16_inv_m5(gf2_u16 *inv_table, gf2_u16 a);
gf2_u16 gf2_fast_u16_div_m5(gf2_u16 *m1_tab,
			    gf2_u16 *m2_tab,
			    gf2_u16 *m3_tab,
			    gf2_u16 *m4_tab,
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b);

/* u16, method 6: 8-bit x 8-bit straight multiply, with manual shift */
int gf2_fast_u16_init_m6(gf2_u16 poly, 
			 gf2_u16 **mul_table, gf2_u16 **inv_table);
void gf2_fast_u16_deinit_m6(gf2_u16 *mul_table, gf2_u16 *inv_table);
gf2_u16 gf2_fast_u16_mul_m6(gf2_u16 *mul_table, 
			    gf2_u16 a, gf2_u16 b, gf2_u16 poly);
gf2_u16 gf2_fast_u16_inv_m6(gf2_u16 *inv_table, gf2_u16 a);
gf2_u16 gf2_fast_u16_div_m6(gf2_u16 *mul_table, 
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b, gf2_u16 poly);


/* u16, method 7: 8-bit x 8-bit straight multiply, fast shift */
int gf2_fast_u16_init_m7(gf2_u16 poly, 
			 gf2_u16 **mul_table, gf2_u16 **inv_table,
			 gf2_u16 **shift_tab);
void gf2_fast_u16_deinit_m7(gf2_u16 *mul_table, gf2_u16 *inv_table,
			    gf2_u16 *shift_tab);
gf2_u16 gf2_fast_u16_mul_m7(gf2_u16 *mul_table, gf2_u16 *shift_tab,
			    gf2_u16 a, gf2_u16 b);
gf2_u16 gf2_fast_u16_inv_m7(gf2_u16 *inv_table, gf2_u16 a);
gf2_u16 gf2_fast_u16_div_m7(gf2_u16 *mul_table, 
			    gf2_u16 *inv_table,
			    gf2_u16 *shift_tab,
			    gf2_u16 a, gf2_u16 b);

/* u32, method 8: 4-bit/8-bit split, fast 8-bit shift */
int gf2_fast_u16_init_m8(gf2_u16 poly, 
			 gf2_u16 **lmul_table,
			 gf2_u16 **rmul_table,
			 gf2_u16 **shift_tab,
			 gf2_u16 **inv_table);
void gf2_fast_u16_deinit_m8(gf2_u16 *lmul_table, gf2_u16 *rmul_table, 
			    gf2_u16 *shift_tab, gf2_u16 *inv_table);
gf2_u16 gf2_fast_u16_mul_m8(gf2_u16 *lmul_table, gf2_u16 *rmul_table, 
			    gf2_u16 *shift_tab,
			    gf2_u16 a, gf2_u16 b);
gf2_u16 gf2_fast_u16_inv_m8(gf2_u16 *inv_table, gf2_u16 a);
gf2_u16 gf2_fast_u16_div_m8(gf2_u16 *lmul_table, 
			    gf2_u16 *rmul_table, 
			    gf2_u16 *shift_tab,
			    gf2_u16 *inv_table,
			    gf2_u16 a, gf2_u16 b);

/* u32, method 1: 16-bit/8-bit split, fast shift */
int gf2_fast_u32_init_m1(gf2_u32 poly, 
			 gf2_u32 **mul_table,
			 gf2_u32 **shift_tab);
void gf2_fast_u32_deinit_m1(gf2_u32 *mul_table, gf2_u32 *shift_tab);
gf2_u32 gf2_fast_u32_mul_m1(gf2_u32 *mul_table, gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b);
gf2_u32 gf2_fast_u32_inv_m1(gf2_u32 a,gf2_u32 poly);
gf2_u32 gf2_fast_u32_div_m1(gf2_u32 *mul_table, 
			    gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b,gf2_u32 poly);

/* u32, method 2: 8-bit/8-bit split, fast shift */
int gf2_fast_u32_init_m2(gf2_u32 poly, 
			 gf2_u16 **mul_table,
			 gf2_u32 **shift_tab);
void gf2_fast_u32_deinit_m2(gf2_u16 *mul_table, gf2_u32 *shift_tab);
gf2_u32 gf2_fast_u32_mul_m2(gf2_u16 *mul_table, gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b);
gf2_u32 gf2_fast_u32_inv_m2(gf2_u32 a, gf2_u32 poly);
gf2_u32 gf2_fast_u32_div_m2(gf2_u16 *mul_table, 
			    gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b, gf2_u32 poly);

/* u32, method 3: 4-bit/8-bit split, fast 8-bit shift */
int gf2_fast_u32_init_m3(gf2_u32 poly, 
			 gf2_u16 **lmul_table,
			 gf2_u16 **rmul_table,
			 gf2_u32 **shift_tab);
void gf2_fast_u32_deinit_m3(gf2_u16 *lmul_table, gf2_u16 *rmul_table, 
			    gf2_u32 *shift_tab);
gf2_u32 gf2_fast_u32_mul_m3(gf2_u16 *lmul_table, gf2_u16 *rmul_table, 
			    gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b);
gf2_u32 gf2_fast_u32_inv_m3(gf2_u32 a, gf2_u32 poly);
gf2_u32 gf2_fast_u32_div_m3(gf2_u16 *lmul_table, 
			    gf2_u16 *rmul_table, 
			    gf2_u32 *shift_tab,
			    gf2_u32 a, gf2_u32 b, gf2_u32 poly);


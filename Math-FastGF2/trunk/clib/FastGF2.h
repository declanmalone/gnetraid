/* Fast GF(2^m) library routines */
/*
  Copyright (c) by Declan Malone 2009.
  Licensed under the terms of the GNU General Public License and
  the GNU Lesser (Library) General Public License.
*/

/*
  These may need to be changed to suit word sizes on your platform. If
  you change them, be sure to also change any function prototypes
  below.
*/
typedef unsigned char    gf2_u8;
typedef unsigned short   gf2_u16;
typedef unsigned long    gf2_u32;
typedef signed char      gf2_s8;
typedef signed short     gf2_s16;
typedef signed long      gf2_s32;

/* Public interface routines */

unsigned long gf2_mul (int width, unsigned long a, unsigned long b);
unsigned long gf2_inv (int width, unsigned long a);
unsigned long gf2_div (int width, unsigned long a, unsigned long b);
unsigned long gf2_info(int bits);


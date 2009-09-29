/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

#ifndef SPU_MATH_H
#define SPU_MATH_H

#include <stdint.h>		/* for uint16_t, uint32_t */

/* types */
typedef uint8_t  gf2_u8;
typedef uint16_t gf2_u16;
typedef uint32_t gf2_u32;
typedef int8_t   gf2_s8;
typedef int16_t  gf2_s16;
typedef int32_t  gf2_s32;

/* function declarations */
gf2_u32 gf2_mul (int width, gf2_u32 a, gf2_u32 b);
gf2_u32 gf2_inv (int width, gf2_u32 a);
gf2_u32 gf2_div (int width, gf2_u32 a, gf2_u32 b);
gf2_u32 gf2_pow (int width, gf2_u32 a, gf2_u32 b);
gf2_u32 gf2_info(int bits);

#endif

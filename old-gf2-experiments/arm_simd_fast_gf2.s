@ boilerplate code taken from gcc output

	.arch armv6
	.eabi_attribute 27, 3
	.eabi_attribute 28, 1
	.fpu vfp
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 4
	.eabi_attribute 18, 4
@	.file	"fast_gf2.c"
	.text
	.align	2

	.global gf2_long_mod_multiply_u8_arm_simd
	.type	gf2_long_mod_multiply_u8_arm_simd, %function
	
gf2_long_mod_multiply_u8_arm_simd:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.

	@ register usage:
	@ r0     a
	@ r1     b
	@ r2     poly
	@ r3     result
	@ r4,r5  temp1, temp2
	
	@ save r4, r5
	stmfd   sp!, {r4}

	@ result = (b & 1) ? a : 0;
	mov    r3, #0
	mov    r4, r1, lsl #7
	uadd8  r4, r4, r4
	sel    r3, r0, r3

	@ if (a & 0x80) { a = (a << 1) ^ poly; } else { a <<= 1; }
	uadd8  r0, r0, r0
	eor    r4, r0, r2
	sel    r0, r4, r0

	@ if (b & 2) { result ^= a; }
	mov    r4, r1, lsl #6
	uadd8  r4, r4, r4
	eor    r4, r3, r0
	sel    r3, r4, r3

	@ if (a & 0x80) { a = (a << 1) ^ poly; } else { a <<= 1; }
	uadd8  r0, r0, r0
	eor    r4, r0, r2
	sel    r0, r4, r0

	@ if (b & 4) { result ^= a; }
	mov    r4, r1, lsl #5
	uadd8  r4, r4, r4
	eor    r4, r3, r0
	sel    r3, r4, r3

	@ if (a & 0x80) { a = (a << 1) ^ poly; } else { a <<= 1; }
	uadd8  r0, r0, r0
	eor    r4, r0, r2
	sel    r0, r4, r0

	@ if (b & 8) { result ^= a; }
	mov    r4, r1, lsl #4
	uadd8  r4, r4, r4
	eor    r4, r3, r0
	sel    r3, r4, r3

	@ if (a & 0x80) { a = (a << 1) ^ poly; } else { a <<= 1; }
	uadd8  r0, r0, r0
	eor    r4, r0, r2
	sel    r0, r4, r0

	@ if (b & 16) { result ^= a; }
	mov    r4, r1, lsl #3
	uadd8  r4, r4, r4
	eor    r4, r3, r0
	sel    r3, r4, r3

	@ if (a & 0x80) { a = (a << 1) ^ poly; } else { a <<= 1; }
	uadd8  r0, r0, r0
	eor    r4, r0, r2
	sel    r0, r4, r0

	@ if (b & 32) { result ^= a; }
	mov    r4, r1, lsl #2
	uadd8  r4, r4, r4
	eor    r4, r3, r0
	sel    r3, r4, r3

	@ if (a & 0x80) { a = (a << 1) ^ poly; } else { a <<= 1; }
	uadd8  r0, r0, r0
	eor    r4, r0, r2
	sel    r0, r4, r0

	@ if (b & 64) { result ^= a; }
	mov    r4, r1, lsl #1
	uadd8  r4, r4, r4
	eor    r4, r3, r0
	sel    r3, r4, r3

	@ if (a & 0x80) { a = (a << 1) ^ poly; } else { a <<= 1; }
	uadd8  r0, r0, r0
	eor    r4, r0, r2
	sel    r0, r4, r0

	@ for the final bit of b, we can omit the lsl and do some
	@ register reording to return a value in r0. We also have 
	@ slightly different code in the original, but we remove that
	@ change to make all the iterations the same.

	@ if (b & 128) { result ^= a; } /* revised source code */

	uadd8  r4, r1, r1
	eor    r4, r3, r0
	sel    r0, r4, r3
		
	ldmfd   sp!, {r4}
	bx	lr

@ the following directives are probably not needed since there's
@ no other code after them.
	.size	gf2_long_mod_multiply_u8_arm_simd, .-gf2_long_mod_multiply_u8_arm_simd
	.align	2


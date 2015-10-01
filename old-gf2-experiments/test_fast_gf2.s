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
	.file	"test_fast_gf2.c"
	.text
	.align	2
	.global	test_sizes
	.type	test_sizes, %function
test_sizes:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	ldr	r4, .L2
	ldr	r0, .L2+4
	bl	puts
	mov	r1, r4
	ldr	r0, .L2+8
	bl	printf
	mov	r1, r4
	ldr	r0, .L2+12
	bl	printf
	mov	r1, r4
	ldr	r0, .L2+16
	bl	printf
	mov	r1, r4
	ldr	r0, .L2+20
	bl	printf
	mov	r1, r4
	ldr	r0, .L2+24
	bl	printf
	ldr	r0, .L2+28
	mov	r1, r4
	ldmfd	sp!, {r4, lr}
	b	printf
.L3:
	.align	2
.L2:
	.word	.LC39
	.word	.LC37
	.word	.LC38
	.word	.LC40
	.word	.LC41
	.word	.LC42
	.word	.LC43
	.word	.LC44
	.size	test_sizes, .-test_sizes
	.align	2
	.global	test_gf2_long_mod_multiply
	.type	test_gf2_long_mod_multiply, %function
test_gf2_long_mod_multiply:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r3, lr}
	ldr	r0, .L10
	bl	puts
	ldr	r0, .L10+4
	bl	printf
	mov	r1, #202
	mov	r0, #83
	mov	r2, #27
	bl	gf2_long_mod_multiply_u8
	cmp	r0, #1
	mov	r1, r0
	bne	.L5
	ldr	r0, .L10+8
	bl	puts
	b	.L6
.L5:
	ldr	r0, .L10+12
	bl	printf
.L6:
	ldr	r0, .L10+16
	bl	printf
	mov	r1, #202
	mov	r0, #83
	ldr	r2, .L10+20
	bl	gf2_long_mod_multiply_u16
	cmp	r0, #1
	mov	r1, r0
	bne	.L7
	ldr	r0, .L10+24
	bl	puts
	b	.L8
.L7:
	ldr	r0, .L10+28
	bl	printf
.L8:
	ldr	r0, .L10+32
	bl	printf
	ldr	r1, .L10+36
	ldr	r0, .L10+40
	ldr	r2, .L10+44
	bl	gf2_long_mod_multiply_u16
	ldr	r3, .L10+48
	cmp	r0, r3
	mov	r1, r0
	bne	.L9
	ldr	r0, .L10+8
	ldmfd	sp!, {r3, lr}
	b	puts
.L9:
	ldr	r0, .L10+52
	ldmfd	sp!, {r3, lr}
	b	printf
.L11:
	.align	2
.L10:
	.word	.LC45
	.word	.LC46
	.word	.LC39
	.word	.LC47
	.word	.LC48
	.word	283
	.word	.LC49
	.word	.LC50
	.word	.LC51
	.word	50000
	.word	433
	.word	4107
	.word	45183
	.word	.LC52
	.size	test_gf2_long_mod_multiply, .-test_gf2_long_mod_multiply
	.align	2
	.global	test_gf2_long_mod_inverse
	.type	test_gf2_long_mod_inverse, %function
test_gf2_long_mod_inverse:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, lr}
	ldr	r0, .L28
	bl	puts
	ldr	r0, .L28+4
	bl	printf
	mov	r1, #27
	mov	r0, #202
	bl	gf2_long_mod_inverse_u8
	ldr	r5, .L28+8
	ldr	r4, .L28+12
	cmp	r0, #83
	movne	r0, r5
	moveq	r0, r4
	bl	printf
	ldr	r0, .L28+16
	bl	printf
	mov	r1, #27
	mov	r0, #83
	bl	gf2_long_mod_inverse_u8
	cmp	r0, #202
	movne	r0, r5
	moveq	r0, r4
	bl	printf
	ldr	r0, .L28+20
	bl	printf
	mov	r5, #0
	mov	r4, #1
.L18:
	mov	r1, #27
	mov	r0, r4
	bl	gf2_long_mod_inverse_u8
	mov	r2, #27
	mov	r6, r0
	mov	r1, r6
	mov	r0, r4
	bl	gf2_long_mod_multiply_u8
	cmp	r0, #1
	beq	.L17
	ldr	r0, .L28+24
	mov	r1, r4
	mov	r2, r6
	bl	printf
	add	r5, r5, #1
.L17:
	add	r4, r4, #1
	uxtb	r4, r4
	cmp	r4, #0
	bne	.L18
	cmp	r5, #0
	movne	r1, r5
	ldreq	r0, .L28+28
	moveq	r1, #255
	ldrne	r0, .L28+32
	bl	printf
	ldr	r0, .L28+20
	bl	printf
	mov	r5, #0
	mov	r4, #1
.L22:
	mov	r1, #43
	mov	r0, r4
	bl	gf2_long_mod_inverse_u16
	mov	r2, #43
	mov	r6, r0
	mov	r1, r6
	mov	r0, r4
	bl	gf2_long_mod_multiply_u16
	cmp	r0, #1
	beq	.L21
	ldr	r0, .L28+24
	mov	r1, r4
	mov	r2, r6
	bl	printf
	add	r5, r5, #1
.L21:
	add	r4, r4, #1
	uxth	r4, r4
	cmp	r4, #0
	bne	.L22
	cmp	r5, #0
	movne	r1, r5
	ldreq	r0, .L28+28
	ldreq	r1, .L28+36
	ldrne	r0, .L28+40
	ldmfd	sp!, {r4, r5, r6, lr}
	b	printf
.L29:
	.align	2
.L28:
	.word	.LC53
	.word	.LC54
	.word	.LC56
	.word	.LC55
	.word	.LC57
	.word	.LC58
	.word	.LC59
	.word	.LC60
	.word	.LC61
	.word	65535
	.word	.LC62
	.size	test_gf2_long_mod_inverse, .-test_gf2_long_mod_inverse
	.align	2
	.global	test_gf2_long_mod_power
	.type	test_gf2_long_mod_power, %function
test_gf2_long_mod_power:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	ldr	r0, .L36
	bl	puts
	mov	r0, #202
	mov	r2, #27
	mov	r1, r0
	bl	gf2_long_mod_multiply_u8
	mov	r4, r0
	mov	r1, r4
	ldr	r0, .L36+4
	bl	printf
	mov	r1, #2
	mov	r0, #202
	mov	r2, #27
	bl	gf2_long_mod_power_u8
	cmp	r0, r4
	mov	r1, r0
	bne	.L31
	ldr	r0, .L36+8
	bl	puts
	b	.L32
.L31:
	ldr	r0, .L36+12
	bl	printf
.L32:
	mov	r1, r4
	mov	r2, #27
	mov	r0, #202
	bl	gf2_long_mod_multiply_u8
	mov	r4, r0
	mov	r1, r4
	ldr	r0, .L36+16
	bl	printf
	mov	r1, #3
	mov	r0, #202
	mov	r2, #27
	bl	gf2_long_mod_power_u8
	cmp	r0, r4
	mov	r1, r0
	bne	.L33
	ldr	r0, .L36+8
	bl	puts
	b	.L34
.L33:
	ldr	r0, .L36+12
	bl	printf
.L34:
	mov	r1, #27
	mov	r0, #202
	bl	gf2_long_mod_inverse_u8
	mov	r4, r0
	mov	r1, r4
	ldr	r0, .L36+20
	bl	printf
	mov	r1, #254
	mov	r0, #202
	mov	r2, #27
	bl	gf2_long_mod_power_u8
	cmp	r0, r4
	mov	r1, r0
	bne	.L35
	ldr	r0, .L36+8
	ldmfd	sp!, {r4, lr}
	b	puts
.L35:
	ldr	r0, .L36+12
	ldmfd	sp!, {r4, lr}
	b	printf
.L37:
	.align	2
.L36:
	.word	.LC63
	.word	.LC64
	.word	.LC39
	.word	.LC65
	.word	.LC66
	.word	.LC67
	.size	test_gf2_long_mod_power, .-test_gf2_long_mod_power
	.align	2
	.global	test_gf2_fast_u8_m1
	.type	test_gf2_fast_u8_m1, %function
test_gf2_fast_u8_m1:
	@ args = 0, pretend = 0, frame = 32
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, lr}
	sub	sp, sp, #32
	ldr	r1, .L49
	mov	r2, #18
	add	r0, sp, #4
	bl	memcpy
	ldr	r0, .L49+4
	bl	puts
	ldr	r0, .L49+8
	bl	printf
	mov	r0, #27
	add	r1, sp, #24
	add	r2, sp, #28
	bl	gf2_fast_u8_init_m1
	cmp	r0, #0
	beq	.L39
	ldr	r0, .L49+12
	bl	puts
	b	.L38
.L39:
	ldr	r0, .L49+16
	bl	puts
	ldr	r0, .L49+20
	bl	printf
	mov	r1, #83
	ldr	r0, [sp, #24]
	mov	r2, #202
	bl	gf2_fast_u8_mul_m1
	cmp	r0, #1
	mov	r1, r0
	bne	.L41
	ldr	r0, .L49+16
	bl	puts
	b	.L42
.L41:
	ldr	r0, .L49+24
	bl	printf
.L42:
	ldr	r0, .L49+28
	bl	printf
	mov	r4, #0
	mov	r3, #255
	mov	r9, r4
	mov	r2, r3
	mov	r7, r4
	b	.L43
.L45:
	mov	r1, r6
	mov	r2, #27
	mov	r0, r5
	bl	gf2_long_mod_multiply_u8
	mov	r1, r5
	mov	r2, r6
	mov	sl, r0
	ldr	r0, [sp, #24]
	bl	gf2_fast_u8_mul_m1
	cmp	sl, r0
	beq	.L44
	ldr	r0, .L49+32
	mov	r1, r5
	mov	r2, r6
	add	r9, r9, #1
	bl	printf
.L44:
	add	r8, r8, #1
	add	r4, r4, #1
	uxtb	r8, r8
	mov	r3, r6
	b	.L46
.L48:
	mov	r8, #0
.L46:
	add	r0, sp, #32
	add	r2, r0, r8
	ldrb	r6, [r2, #-28]	@ zero_extendqisi2
	cmp	r6, r3
	bne	.L45
	add	r7, r7, #1
	mov	r2, r5
	uxtb	r7, r7
.L43:
	add	r0, sp, #32
	add	r1, r0, r7
	ldrb	r5, [r1, #-28]	@ zero_extendqisi2
	cmp	r5, r2
	bne	.L48
	cmp	r9, #0
	bne	.L47
	ldr	r0, .L49+36
	mov	r1, r4
	bl	printf
.L47:
	ldr	r0, .L49+40
	bl	puts
	ldr	r0, [sp, #24]
	ldr	r1, [sp, #28]
	bl	gf2_fast_u8_deinit_m1
.L38:
	add	sp, sp, #32
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L50:
	.align	2
.L49:
	.word	.LANCHOR0
	.word	.LC68
	.word	.LC69
	.word	.LC70
	.word	.LC39
	.word	.LC71
	.word	.LC47
	.word	.LC72
	.word	.LC73
	.word	.LC74
	.word	.LC75
	.size	test_gf2_fast_u8_m1, .-test_gf2_fast_u8_m1
	.align	2
	.global	test_gf2_fast_u8_m2
	.type	test_gf2_fast_u8_m2, %function
test_gf2_fast_u8_m2:
	@ args = 0, pretend = 0, frame = 32
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, lr}
	sub	sp, sp, #32
	ldr	r1, .L62
	mov	r2, #18
	add	r0, sp, #4
	bl	memcpy
	ldr	r0, .L62+4
	bl	puts
	ldr	r0, .L62+8
	bl	printf
	mov	r0, #27
	mov	r1, #3
	add	r2, sp, #24
	add	r3, sp, #28
	bl	gf2_fast_u8_init_m2
	cmp	r0, #0
	beq	.L52
	ldr	r0, .L62+12
	bl	puts
	b	.L51
.L52:
	ldr	r0, .L62+16
	bl	puts
	ldr	r0, .L62+20
	bl	printf
	ldr	r1, [sp, #28]
	ldr	r0, [sp, #24]
	mov	r2, #83
	mov	r3, #202
	bl	gf2_fast_u8_mul_m2
	cmp	r0, #1
	mov	r1, r0
	bne	.L54
	ldr	r0, .L62+16
	bl	puts
	b	.L55
.L54:
	ldr	r0, .L62+24
	bl	printf
.L55:
	ldr	r0, .L62+28
	bl	printf
	mov	r4, #0
	mov	r3, #255
	mov	r9, r4
	mov	r2, r3
	mov	sl, r4
	b	.L56
.L58:
	mov	r1, r6
	mov	r2, #27
	mov	r0, r5
	bl	gf2_long_mod_multiply_u8
	ldr	r1, [sp, #28]
	mov	r2, r5
	mov	r3, r6
	mov	r7, r0
	ldr	r0, [sp, #24]
	bl	gf2_fast_u8_mul_m2
	cmp	r7, r0
	beq	.L57
	ldr	r0, .L62+32
	mov	r1, r5
	mov	r2, r6
	add	r9, r9, #1
	bl	printf
.L57:
	add	r8, r8, #1
	add	r4, r4, #1
	uxtb	r8, r8
	mov	r3, r6
	b	.L59
.L61:
	mov	r8, #0
.L59:
	add	r0, sp, #32
	add	r2, r0, r8
	ldrb	r6, [r2, #-28]	@ zero_extendqisi2
	cmp	r6, r3
	bne	.L58
	add	sl, sl, #1
	mov	r2, r5
	uxtb	sl, sl
.L56:
	add	r0
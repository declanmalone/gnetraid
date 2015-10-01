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
	.file	"fast_gf2.c"
	.text
	.align	2
	.global	gf2_swab_u16
	.type	gf2_swab_u16, %function
gf2_swab_u16:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r3, r0, lsr #8
	orr	r0, r3, r0, asl #8
	uxth	r0, r0
	bx	lr
	.size	gf2_swab_u16, .-gf2_swab_u16
	.align	2
	.global	gf2_swab_u32
	.type	gf2_swab_u32, %function
gf2_swab_u32:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	rev	r0, r0
	bx	lr
	.size	gf2_swab_u32, .-gf2_swab_u32
	.align	2
	.global	gf2_long_mod_multiply_u8
	.type	gf2_long_mod_multiply_u8, %function
gf2_long_mod_multiply_u8:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ands	r3, r1, #1
	movne	r3, r0
	tst	r0, #128
	mov	r0, r0, asl #1
	eorne	r0, r2, r0
	tst	r1, #2
	uxtb	r0, r0
	eorne	r3, r0, r3
	tst	r0, #128
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #4
	uxtb	r0, r0
	eorne	r3, r0, r3
	tst	r0, #128
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #8
	uxtb	r0, r0
	eorne	r3, r0, r3
	tst	r0, #128
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #16
	uxtb	r0, r0
	eorne	r3, r0, r3
	tst	r0, #128
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #32
	uxtb	r0, r0
	eorne	r3, r0, r3
	tst	r0, #128
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #64
	uxtb	r0, r0
	eorne	r3, r0, r3
	tst	r1, #128
	beq	.L23
	tst	r0, #128
	mov	r0, r0, asl #1
	eorne	r2, r0, r2
	uxtb	r3, r3
	uxtbne	r2, r2
	uxtbeq	r2, r0
	eor	r3, r2, r3
.L23:
	mov	r0, r3
	bx	lr
	.size	gf2_long_mod_multiply_u8, .-gf2_long_mod_multiply_u8
	.align	2
	.global	gf2_long_mod_multiply_u16
	.type	gf2_long_mod_multiply_u16, %function
gf2_long_mod_multiply_u16:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ands	r3, r1, #1
	movne	r3, r0
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r2, r0
	tst	r1, #2
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #4
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #8
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #16
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #32
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #64
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #128
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #256
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #512
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #1024
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #2048
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #4096
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #8192
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r0, r0, r2
	tst	r1, #16384
	uxth	r0, r0
	eorne	r3, r0, r3
	tst	r1, #32768
	beq	.L71
	tst	r0, #32768
	mov	r0, r0, asl #1
	eorne	r2, r0, r2
	uxth	r3, r3
	uxthne	r2, r2
	uxtheq	r2, r0
	eor	r3, r2, r3
.L71:
	mov	r0, r3
	bx	lr
	.size	gf2_long_mod_multiply_u16, .-gf2_long_mod_multiply_u16
	.align	2
	.global	gf2_long_mod_multiply_u32
	.type	gf2_long_mod_multiply_u32, %function
gf2_long_mod_multiply_u32:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ands	r3, r1, #1
	movne	r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r2, r0
	tst	r1, #2
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #4
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #8
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #16
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #32
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #64
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #128
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #256
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #512
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #1024
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #2048
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #4096
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #8192
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #16384
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #32768
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #65536
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #131072
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #262144
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #524288
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #1048576
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #2097152
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #4194304
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #8388608
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #16777216
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #33554432
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #67108864
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #134217728
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #268435456
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #536870912
	eorne	r3, r3, r0
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	tst	r1, #1073741824
	eorne	r3, r3, r0
	cmp	r1, #0
	bge	.L167
	cmp	r0, #0
	mov	r0, r0, asl #1
	eorlt	r0, r0, r2
	eor	r3, r3, r0
.L167:
	mov	r0, r3
	bx	lr
	.size	gf2_long_mod_multiply_u32, .-gf2_long_mod_multiply_u32
	.align	2
	.global	gf2_long_straight_multiply_u8
	.type	gf2_long_straight_multiply_u8, %function
gf2_long_straight_multiply_u8:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ands	r3, r1, #1
	movne	r3, r0
	mov	ip, #7
	mov	r2, #2
.L174:
	mov	r0, r0, asl #1
	tst	r2, r1
	uxth	r0, r0
	mov	r2, r2, asl #1
	eorne	r3, r0, r3
	subs	ip, ip, #1
	uxtb	r2, r2
	bne	.L174
	mov	r0, r3
	bx	lr
	.size	gf2_long_straight_multiply_u8, .-gf2_long_straight_multiply_u8
	.align	2
	.global	gf2_long_straight_multiply_u16
	.type	gf2_long_straight_multiply_u16, %function
gf2_long_straight_multiply_u16:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ands	r3, r1, #1
	movne	r3, r0
	mov	ip, #15
	mov	r2, #2
.L180:
	tst	r2, r1
	mov	r0, r0, asl #1
	mov	r2, r2, asl #1
	eorne	r3, r3, r0
	subs	ip, ip, #1
	uxth	r2, r2
	bne	.L180
	mov	r0, r3
	bx	lr
	.size	gf2_long_straight_multiply_u16, .-gf2_long_straight_multiply_u16
	.align	2
	.global	size_in_bits_u8
	.type	size_in_bits_u8, %function
size_in_bits_u8:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldr	r3, .L184
	ldrb	r0, [r3, r0]	@ zero_extendqisi2
	bx	lr
.L185:
	.align	2
.L184:
	.word	.LANCHOR0
	.size	size_in_bits_u8, .-size_in_bits_u8
	.align	2
	.global	size_in_bits_u16
	.type	size_in_bits_u16, %function
size_in_bits_u16:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldr	r3, .L189
	tst	r0, #65280
	ldrneb	r0, [r3, r0, lsr #8]	@ zero_extendqisi2
	ldreqb	r0, [r3, r0]	@ zero_extendqisi2
	addne	r0, r0, #8
	bx	lr
.L190:
	.align	2
.L189:
	.word	.LANCHOR0
	.size	size_in_bits_u16, .-size_in_bits_u16
	.align	2
	.global	size_in_bits_u32
	.type	size_in_bits_u32, %function
size_in_bits_u32:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldr	r3, .L197
	tst	r0, #-16777216
	ldrneb	r0, [r3, r0, lsr #24]	@ zero_extendqisi2
	addne	r0, r0, #24
	bxne	lr
	tst	r0, #16711680
	ldrneb	r0, [r3, r0, lsr #16]	@ zero_extendqisi2
	addne	r0, r0, #16
	bxne	lr
	tst	r0, #65280
	ldrneb	r0, [r3, r0, lsr #8]	@ zero_extendqisi2
	ldreqb	r0, [r3, r0]	@ zero_extendqisi2
	addne	r0, r0, #8
	bx	lr
.L198:
	.align	2
.L197:
	.word	.LANCHOR0
	.size	size_in_bits_u32, .-size_in_bits_u32
	.align	2
	.global	gf2_long_mod_inverse_u8
	.type	gf2_long_mod_inverse_u8, %function
gf2_long_mod_inverse_u8:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	cmp	r0, #1
	stmfd	sp!, {r4, r5, lr}
	ldmlsfd	sp!, {r4, r5, pc}
	ldr	r4, .L205
	mov	ip, #1
	ldrb	r3, [r4, r0]	@ zero_extendqisi2
	rsb	r3, r3, #9
	eor	r1, r1, r0, asl r3
	mov	r3, ip, asl r3
	uxtb	r1, r1
	b	.L204
.L203:
	ldrb	r5, [r4, r1]	@ zero_extendqisi2
	ldrb	r2, [r4, r0]	@ zero_extendqisi2
	subs	r2, r5, r2
	bpl	.L202
	mov	r5, r3
	mov	r3, ip
	mov	ip, r5
	mov	r5, r1
	rsb	r2, r2, #0
	mov	r1, r0
	mov	r0, r5
.L202:
	eor	r1, r1, r0, asl r2
	eor	r3, r3, ip, asl r2
	uxtb	r1, r1
.L204:
	cmp	r1, #1
	uxtb	r3, r3
	bne	.L203
	mov	r0, r3
	ldmfd	sp!, {r4, r5, pc}
.L206:
	.align	2
.L205:
	.word	.LANCHOR0
	.size	gf2_long_mod_inverse_u8, .-gf2_long_mod_inverse_u8
	.align	2
	.global	gf2_long_mod_inverse_u16
	.type	gf2_long_mod_inverse_u16, %function
gf2_long_mod_inverse_u16:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	cmp	r0, #1
	stmfd	sp!, {r4, r5, r6, r7, r8, lr}
	mov	r4, r0
	mov	r5, r1
	bls	.L208
	bl	size_in_bits_u16
	mov	r7, #1
	rsb	r0, r0, #17
	eor	r5, r5, r4, asl r0
	mov	r6, r7, asl r0
	uxth	r5, r5
	b	.L212
.L211:
	mov	r0, r5
	bl	size_in_bits_u16
	mov	r8, r0
	mov	r0, r4
	bl	size_in_bits_u16
	subs	r8, r8, r0
	bpl	.L210
	mov	r3, r6
	mov	r6, r7
	mov	r7, r3
	mov	r3, r5
	rsb	r8, r8, #0
	mov	r5, r4
	mov	r4, r3
.L210:
	eor	r5, r5, r4, asl r8
	eor	r6, r6, r7, asl r8
	uxth	r5, r5
.L212:
	cmp	r5, #1
	uxth	r6, r6
	bne	.L211
	mov	r4, r6
.L208:
	mov	r0, r4
	ldmfd	sp!, {r4, r5, r6, r7, r8, pc}
	.size	gf2_long_mod_inverse_u16, .-gf2_long_mod_inverse_u16
	.align	2
	.global	gf2_long_mod_inverse_u32
	.type	gf2_long_mod_inverse_u32, %function
gf2_long_mod_inverse_u32:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	cmp	r0, #1
	stmfd	sp!, {r4, r5, r6, r7, r8, lr}
	mov	r4, r0
	mov	r5, r1
	bls	.L214
	bl	size_in_bits_u32
	mov	r7, #1
	rsb	r0, r0, #33
	eor	r5, r5, r4, asl r0
	mov	r6, r7, asl r0
	b	.L215
.L217:
	mov	r0, r5
	bl	size_in_bits_u32
	mov	r8, r0
	mov	r0, r4
	bl	size_in_bits_u32
	subs	r0, r8, r0
	bpl	.L216
	mov	r3, r6
	mov	r6, r7
	mov	r7, r3
	mov	r3, r5
	rsb	r0, r0, #0
	mov	r5, r4
	mov	r4, r3
.L216:
	eor	r5, r5, r4, asl r0
	eor	r6, r6, r7, asl r0
.L215:
	cmp	r5, #1
	bne	.L217
	mov	r4, r6
.L214:
	mov	r0, r4
	ldmfd	sp!, {r4, r5, r6, r7, r8, pc}
	.size	gf2_long_mod_inverse_u32, .-gf2_long_mod_inverse_u32
	.align	2
	.global	gf2_long_mod_power_u8
	.type	gf2_long_mod_power_u8, %function
gf2_long_mod_power_u8:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r3, r4, r5, r6, r7, lr}
	sub	r3, r1, #1
	mov	r5, r1
	uxtb	r3, r3
	cmp	r3, #253
	mov	r6, r0
	mov	r7, r2
	movhi	r1, #1
	bhi	.L219
	ldr	r3, .L227
	mov	r1, r0
	ldrb	r4, [r3, r5]	@ zero_extendqisi2
	mov	r3, #128
	rsb	r4, r4, #8
	mov	r4, r3, asr r4
	uxtb	r4, r4
	b	.L226
.L222:
	mov	r0, r1
	mov	r2, r7
	bl	gf2_long_mod_multiply_u8
	tst	r4, r5
	mov	r1, r0
	beq	.L226
	mov	r0, r6
	mov	r2, r7
	bl	gf2_long_mod_multiply_u8
	mov	r1, r0
.L226:
	movs	r4, r4, lsr #1
	bne	.L222
.L219:
	mov	r0, r1
	ldmfd	sp!, {r3, r4, r5, r6, r7, pc}
.L228:
	.align	2
.L227:
	.word	.LANCHOR0
	.size	gf2_long_mod_power_u8, .-gf2_long_mod_power_u8
	.align	2
	.global	gf2_long_mod_power_u16
	.type	gf2_long_mod_power_u16, %function
gf2_long_mod_power_u16:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r3, r4, r5, r6, r7, lr}
	mov	r7, r2
	sub	r2, r1, #1
	ldr	r3, .L238
	uxth	r2, r2
	cmp	r2, r3
	mov	r5, r1
	mov	r6, r0
	movhi	r1, #1
	bhi	.L230
	mov	r0, r5
	bl	size_in_bits_u16
	mov	r4, #32768
	mov	r1, r6
	rsb	r0, r0, #16
	mov	r4, r4, asr r0
	uxth	r4, r4
	b	.L237
.L233:
	mov	r0, r1
	mov	r2, r7
	bl	gf2_long_mod_multiply_u16
	tst	r4, r5
	mov	r1, r0
	beq	.L237
	mov	r0, r6
	mov	r2, r7
	bl	gf2_long_mod_multiply_u16
	mov	r1, r0
.L237:
	movs	r4, r4, lsr #1
	bne	.L233
.L230:
	mov	r0, r1
	ldmfd	sp!, {r3, r4, r5, r6, r7, pc}
.L239:
	.align	2
.L238:
	.word	65533
	.size	gf2_long_mod_power_u16, .-gf2_long_mod_power_u16
	.align	2
	.global	gf2_long_mod_power_u32
	.type	gf2_long_mod_power_u32, %function
gf2_long_mod_power_u32:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r3, r4, r5, r6, r7, lr}
	sub	r3, r1, #1
	cmn	r3, #3
	mov	r5, r1
	mov	r6, r0
	mov	r7, r2
	movhi	r1, #1
	bhi	.L241
	mov	r0, r5
	bl	size_in_bits_u32
	mov	r4, #-2147483648
	mov	r1, r6
	rsb	r0, r0, #32
	mov	r4, r4, lsr r0
	b	.L248
.L244:
	mov	r0, r1
	mov	r2, r7
	bl	gf2_long_mod_multiply_u32
	tst	r4, r5
	mov	r1, r0
	beq	.L248
	mov	r0, r6
	mov	r2, r7
	bl	gf2_long_mod_multiply_u32
	mov	r1, r0
.L248:
	movs	r4, r4, lsr #1
	bne	.L244
.L241:
	mov	r0, r1
	ldmfd	sp!, {r3, r4, r5, r6, r7, pc}
	.size	gf2_long_mod_power_u32, .-gf2_long_mod_power_u32
	.align	2
	.global	gf2_fast_u8_init_m1
	.type	gf2_fast_u8_init_m1, %function
gf2_fast_u8_init_m1:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r0, r1, r2, r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r4, r1
	str	r0, [sp, #4]
	mov	r0, #65536
	mov	r7, r2
	bl	malloc
	str	r0, [r4, #0]
	mov	r0, #256
	bl	malloc
	str	r0, [r7, #0]
	ldr	r3, [r4, #0]
	cmp	r3, #0
	beq	.L250
	cmp	r0, #0
	movne	r2, #0
	strneb	r2, [r3, #0]
	movne	r3, #1
	bne	.L253
	mov	r0, r3
	bl	free
.L250:
	ldr	r0, [r7, #0]
	cmp	r0, #0
	beq	.L258
	bl	free
	b	.L258
.L253:
	ldr	r1, [r4, #0]
	strb	r2, [r1, r3]
	ldr	r1, [r4, #0]
	strb	r2, [r1, r3, asl #8]
	add	r3, r3, #1
	cmp	r3, #256
	bne	.L253
	ldr	r3, [r4, #0]
	mov	r2, #1
	strb	r2, [r3, #257]
	ldr	r3, .L263
.L254:
	ldr	r1, [r4, #0]
	uxtb	r2, r3
	sub	r0, r3, #256
	strb	r2, [r1, r3]
	ldr	r1, [r4, #0]
	add	r3, r3, #1
	add	r1, r1, r0, asl #8
	cmp	r3, #512
	strb	r2, [r1, #1]
	bne	.L254
	ldr	r3, [r7, #0]
	mov	r2, #0
	mov	r5, #2
	strb	r2, [r3, #0]
	ldr	r3, [r7, #0]
	mov	r2, #1
	strb	r2, [r3, #1]
	b	.L255
.L257:
	uxtb	sl, r6
	mov	r0, r8
	mov	r1, sl
	ldr	r2, [sp, #4]
	bl	gf2_long_mod_multiply_u8
	ldr	r3, [r4, #0]
	add	r3, r3, fp
	strb	r0, [r3, r6]
	ldr	r3, [r4, #0]
	cmp	r0, #1
	add	r3, r3, r5
	strb	r0, [r3, r6, asl #8]
	ldreq	r3, [r7, #0]
	streqb	sl, [r3, r5]
	ldreq	r3, [r7, #0]
	streqb	r8, [r3, r6]
	add	r6, r6, #1
	uxth	r6, r6
	cmp	r6, r9
	bls	.L257
	add	r5, r5, #1
	cmp	r5, #256
	beq	.L259
.L255:
	uxth	r9, r5
	mov	fp, r5, asl #8
	mov	r6, #2
	uxtb	r8, r5
	b	.L257
.L258:
	mvn	r0, #0
	b	.L252
.L259:
	mov	r0, #0
.L252:
	ldmfd	sp!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, pc}
.L264:
	.align	2
.L263:
	.word	258
	.size	gf2_fast_u8_init_m1, .-gf2_fast_u8_init_m1
	.align	2
	.global	gf2_fast_u8_deinit_m1
	.type	gf2_fast_u8_deinit_m1, %function
gf2_fast_u8_deinit_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	mov	r0, r4
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u8_deinit_m1, .-gf2_fast_u8_deinit_m1
	.align	2
	.global	gf2_fast_u8_mul_m1
	.type	gf2_fast_u8_mul_m1, %function
gf2_fast_u8_mul_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	add	r2, r0, r2
	ldrb	r0, [r2, r1, asl #8]	@ zero_extendqisi2
	bx	lr
	.size	gf2_fast_u8_mul_m1, .-gf2_fast_u8_mul_m1
	.align	2
	.global	gf2_fast_u8_inv_m1
	.type	gf2_fast_u8_inv_m1, %function
gf2_fast_u8_inv_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldrb	r0, [r0, r1]	@ zero_extendqisi2
	bx	lr
	.size	gf2_fast_u8_inv_m1, .-gf2_fast_u8_inv_m1
	.align	2
	.global	gf2_fast_u8_div_m1
	.type	gf2_fast_u8_div_m1, %function
gf2_fast_u8_div_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldrb	r3, [r1, r3]	@ zero_extendqisi2
	add	r2, r0, r2, asl #8
	ldrb	r0, [r2, r3]	@ zero_extendqisi2
	bx	lr
	.size	gf2_fast_u8_div_m1, .-gf2_fast_u8_div_m1
	.align	2
	.global	gf2_fast_u8_dpc_m1
	.type	gf2_fast_u8_dpc_m1, %function
gf2_fast_u8_dpc_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	mov	ip, r0
	ldrb	r0, [r2, #0]	@ zero_extendqisi2
	stmfd	sp!, {r4, r5, r6, lr}
	cmp	r3, #0
	ldrb	r4, [r1, #0]	@ zero_extendqisi2
	add	r0, r0, #8
	mov	r0, r4, asl r0
	movne	r4, #0
	ldrb	r0, [ip, r0]	@ zero_extendqisi2
	bne	.L271
	b	.L274
.L272:
	add	r5, r1, r4
	ldrb	r6, [r5, #1]	@ zero_extendqisi2
	add	r5, r2, r4
	add	r4, r4, #1
	ldrb	r5, [r5, #1]	@ zero_extendqisi2
	add	r5, r5, #8
	mov	r5, r6, asl r5
	ldrb	r5, [ip, r5]	@ zero_extendqisi2
	eor	r0, r0, r5
	uxtb	r0, r0
.L271:
	subs	r3, r3, #1
	bne	.L272
	ldmfd	sp!, {r4, r5, r6, pc}
.L274:
	mov	r0, r3
	ldmfd	sp!, {r4, r5, r6, pc}
	.size	gf2_fast_u8_dpc_m1, .-gf2_fast_u8_dpc_m1
	.align	2
	.global	gf2_fast_u8_dpd_m1
	.type	gf2_fast_u8_dpd_m1, %function
gf2_fast_u8_dpd_m1:
	@ args = 8, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	mov	ip, r0
	ldrb	r0, [r3, #0]	@ zero_extendqisi2
	stmfd	sp!, {r4, r5, r6, r7, lr}
	ldrb	r5, [r1, #0]	@ zero_extendqisi2
	add	r0, r0, #8
	ldr	r4, [sp, #24]
	ldr	r6, [sp, #20]
	mov	r0, r5, asl r0
	cmp	r4, #0
	ldrb	r0, [ip, r0]	@ zero_extendqisi2
	bne	.L277
	b	.L279
.L278:
	ldrb	r5, [r3, r6]!	@ zero_extendqisi2
	ldrb	r7, [r1, r2]!	@ zero_extendqisi2
	add	r5, r5, #8
	mov	r5, r7, asl r5
	ldrb	r5, [ip, r5]	@ zero_extendqisi2
	eor	r0, r0, r5
	uxtb	r0, r0
.L277:
	subs	r4, r4, #1
	bne	.L278
	ldmfd	sp!, {r4, r5, r6, r7, pc}
.L279:
	mov	r0, r4
	ldmfd	sp!, {r4, r5, r6, r7, pc}
	.size	gf2_fast_u8_dpd_m1, .-gf2_fast_u8_dpd_m1
	.align	2
	.global	gf2_fast_u8_init_m2
	.type	gf2_fast_u8_init_m2, %function
gf2_fast_u8_init_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	cmp	r0, #0
	cmpne	r1, #0
	stmfd	sp!, {r4, r5, r6, r7, r8, lr}
	mov	r6, r2
	mov	r5, r3
	mov	r7, r1
	mov	r8, r0
	movne	r4, #0
	moveq	r4, #1
	beq	.L286
	mov	r0, #256
	bl	malloc
	str	r0, [r6, #0]
	mov	r0, #256
	bl	malloc
	str	r0, [r5, #0]
	ldr	r3, [r6, #0]
	cmp	r3, #0
	beq	.L282
	cmp	r0, #0
	bne	.L283
	mov	r0, r3
	bl	free
.L282:
	ldr	r0, [r5, #0]
	cmp	r0, #0
	beq	.L287
	bl	free
	b	.L286
.L283:
	mov	r2, #1
	strb	r2, [r0, #0]
	strb	r4, [r3, #0]
	ldr	r3, [r5, #0]
	mov	r4, #2
	strb	r7, [r3, #1]
	ldr	r3, [r6, #0]
	strb	r2, [r3, r7]
	mov	r2, r7
.L285:
	cmp	r2, #1
	bne	.L284
	ldr	r3, .L289
	ldr	r1, .L289+4
	ldr	r0, [r3, #0]
	mov	r3, r4
	bl	fprintf
	ldr	r0, [r6, #0]
	bl	free
	ldr	r0, [r5, #0]
	bl	free
	rsb	r0, r4, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, pc}
.L284:
	mov	r0, r2
	mov	r1, r7
	mov	r2, r8
	bl	gf2_long_mod_multiply_u8
	ldr	r3, [r5, #0]
	strb	r0, [r3, r4]
	ldr	r3, [r6, #0]
	mov	r2, r0
	strb	r4, [r3, r0]
	add	r4, r4, #1
	uxtb	r4, r4
	cmp	r4, #0
	bne	.L285
	mov	r0, r4
	ldmfd	sp!, {r4, r5, r6, r7, r8, pc}
.L286:
	mvn	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, pc}
.L287:
	mvn	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, pc}
.L290:
	.align	2
.L289:
	.word	stderr
	.word	.LC0
	.size	gf2_fast_u8_init_m2, .-gf2_fast_u8_init_m2
	.align	2
	.global	gf2_fast_u8_deinit_m2
	.type	gf2_fast_u8_deinit_m2, %function
gf2_fast_u8_deinit_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	mov	r0, r4
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u8_deinit_m2, .-gf2_fast_u8_deinit_m2
	.align	2
	.global	gf2_fast_u8_mul_m2
	.type	gf2_fast_u8_mul_m2, %function
gf2_fast_u8_mul_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	cmp	r2, #0
	cmpne	r3, #0
	moveq	r0, #0
	ldrneb	ip, [r0, r3]	@ zero_extendqisi2
	ldrneb	r3, [r0, r2]	@ zero_extendqisi2
	addne	r3, ip, r3
	movne	r2, r3, lsr #8
	uxtabne	r3, r2, r3
	ldrneb	r0, [r1, r3]	@ zero_extendqisi2
	bx	lr
	.size	gf2_fast_u8_mul_m2, .-gf2_fast_u8_mul_m2
	.align	2
	.global	gf2_fast_u8_inv_m2
	.type	gf2_fast_u8_inv_m2, %function
gf2_fast_u8_inv_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldrb	r3, [r0, r2]	@ zero_extendqisi2
	rsb	r3, r3, #255
	ldrb	r0, [r1, r3]	@ zero_extendqisi2
	bx	lr
	.size	gf2_fast_u8_inv_m2, .-gf2_fast_u8_inv_m2
	.align	2
	.global	gf2_fast_u8_div_m2
	.type	gf2_fast_u8_div_m2, %function
gf2_fast_u8_div_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldrb	r2, [r0, r2]	@ zero_extendqisi2
	ldrb	r3, [r0, r3]	@ zero_extendqisi2
	cmp	r2, r3
	addcc	r2, r2, #255
	rsbcs	r2, r3, r2
	rsbcc	r3, r3, r2
	ldrcsb	r0, [r1, r2]	@ zero_extendqisi2
	ldrccb	r0, [r1, r3]	@ zero_extendqisi2
	bx	lr
	.size	gf2_fast_u8_div_m2, .-gf2_fast_u8_div_m2
	.align	2
	.global	gf2_fast_u8_init_m3
	.type	gf2_fast_u8_init_m3, %function
gf2_fast_u8_init_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	cmp	r0, #0
	cmpne	r1, #0
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, sl, lr}
	mov	r5, r2
	mov	r4, r3
	mov	r7, r1
	mov	sl, r0
	movne	r6, #0
	moveq	r6, #1
	beq	.L306
	mov	r0, #512
	bl	malloc
	str	r0, [r5, #0]
	mov	r0, #1024
	bl	malloc
	str	r0, [r4, #0]
	ldr	r3, [r5, #0]
	cmp	r3, #0
	beq	.L301
	cmp	r0, #0
	addne	r0, r0, #512
	strne	r0, [r4, #0]
	ldrne	r3, .L310
	bne	.L303
	mov	r0, r3
	bl	free
.L301:
	ldr	r0, [r4, #0]
	cmp	r0, #0
	beq	.L307
	bl	free
	b	.L306
.L303:
	ldr	r2, [r4, #0]
	strb	r6, [r2, r3]
	adds	r3, r3, #1
	bne	.L303
	ldr	r2, [r5, #0]
	mov	r1, #65280
	mov	r8, #2
	strh	r1, [r2, #0]	@ movhi
	ldr	r1, [r4, #0]
	mov	r2, #1
	strb	r2, [r1, #0]
	mov	r1, r7, asl r2
	ldr	r0, [r5, #0]
	strh	r2, [r0, r1]	@ movhi
	ldr	r1, [r4, #0]
	strb	r7, [r1, #1]
	ldr	r1, [r4, #0]
	strb	r2, [r1, #255]
	ldr	r2, [r4, #0]
	strb	r7, [r2, #256]
	ldr	r2, [r4, #0]
	strb	r3, [r2, #511]
	mov	r2, r7
.L305:
	cmp	r2, #1
	uxth	r6, r8
	bne	.L304
	ldr	r3, .L310+4
	sxth	r6, r6
	ldr	r1, .L310+8
	ldr	r0, [r3, #0]
	mov	r3, r6
	bl	fprintf
	ldr	r0, [r5, #0]
	bl	free
	ldr	r0, [r4, #0]
	sub	r0, r0, #512
	bl	free
	rsb	r0, r6, #0
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, sl, pc}
.L304:
	mov	r0, r2
	mov	r1, r7
	mov	r2, sl
	bl	gf2_long_mod_multiply_u8
	ldr	r3, [r4, #0]
	strb	r0, [r3, r8]
	ldr	r3, [r4, #0]
	mov	r2, r0
	add	r3, r3, r8
	add	r8, r8, #1
	strb	r0, [r3, #255]
	ldr	r1, [r5, #0]
	mov	r3, r0, asl #1
	cmp	r8, #256
	strh	r6, [r1, r3]	@ movhi
	bne	.L305
	mov	r0, #0
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, sl, pc}
.L306:
	mvn	r0, #0
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, sl, pc}
.L307:
	mvn	r0, #0
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, sl, pc}
.L311:
	.align	2
.L310:
	.word	-512
	.word	stderr
	.word	.LC0
	.size	gf2_fast_u8_init_m3, .-gf2_fast_u8_init_m3
	.align	2
	.global	gf2_fast_u8_deinit_m3
	.type	gf2_fast_u8_deinit_m3, %function
gf2_fast_u8_deinit_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	sub	r0, r4, #512
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u8_deinit_m3, .-gf2_fast_u8_deinit_m3
	.align	2
	.global	gf2_fast_u8_mul_m3
	.type	gf2_fast_u8_mul_m3, %function
gf2_fast_u8_mul_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r2, r2, asl #1
	mov	r3, r3, asl #1
	ldrsh	r2, [r0, r2]
	ldrsh	r3, [r0, r3]
	add	r2, r1, r2
	ldrb	r0, [r2, r3]	@ zero_extendqisi2
	bx	lr
	.size	gf2_fast_u8_mul_m3, .-gf2_fast_u8_mul_m3
	.align	2
	.global	gf2_fast_u8_inv_m3
	.type	gf2_fast_u8_inv_m3, %function
gf2_fast_u8_inv_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r2, r2, asl #1
	ldrsh	r3, [r0, r2]
	rsb	r3, r3, #255
	ldrb	r0, [r1, r3]	@ zero_extendqisi2
	bx	lr
	.size	gf2_fast_u8_inv_m3, .-gf2_fast_u8_inv_m3
	.align	2
	.global	gf2_fast_u8_div_m3
	.type	gf2_fast_u8_div_m3, %function
gf2_fast_u8_div_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r2, r2, asl #1
	mov	r3, r3, asl #1
	ldrsh	r2, [r0, r2]
	ldrsh	r3, [r0, r3]
	add	r2, r2, #255
	rsb	r2, r3, r2
	ldrb	r0, [r1, r2]	@ zero_extendqisi2
	bx	lr
	.size	gf2_fast_u8_div_m3, .-gf2_fast_u8_div_m3
	.global	__aeabi_idivmod
	.align	2
	.global	gf2_fast_u8_pow_m3
	.type	gf2_fast_u8_pow_m3, %function
gf2_fast_u8_pow_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	mov	r2, r2, asl #1
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	ldrsh	r0, [r0, r2]
	mov	r1, #255
	mul	r0, r3, r0
	bl	__aeabi_idivmod
	ldrb	r0, [r4, r1]	@ zero_extendqisi2
	ldmfd	sp!, {r4, pc}
	.size	gf2_fast_u8_pow_m3, .-gf2_fast_u8_pow_m3
	.align	2
	.global	gf2_fast_u16_init_m1
	.type	gf2_fast_u16_init_m1, %function
gf2_fast_u16_init_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	cmp	r0, #0
	cmpne	r1, #0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, lr}
	mov	r6, r2
	mov	r5, r3
	mov	r7, r1
	mov	r9, r0
	movne	r4, #0
	moveq	r4, #1
	beq	.L323
	mov	r0, #131072
	bl	malloc
	str	r0, [r6, #0]
	mov	r0, #131072
	bl	malloc
	str	r0, [r5, #0]
	ldr	r8, [r6, #0]
	mov	sl, r0
	cmp	r8, #0
	beq	.L319
	cmp	r0, #0
	bne	.L320
	mov	r0, r8
	bl	free
.L319:
	ldr	r0, [r5, #0]
	cmp	r0, #0
	beq	.L324
	bl	free
	b	.L323
.L320:
	mov	r3, #1
	strh	r3, [r0, #0]	@ movhi
	mov	r2, r7, asl r3
	strh	r4, [r8, #0]	@ movhi
	strh	r7, [r0, #2]	@ movhi
	mov	r4, #2
	strh	r3, [r8, r2]	@ movhi
	mov	r2, r7
.L322:
	cmp	r2, #1
	bne	.L321
	ldr	r3, .L326
	ldr	r1, .L326+4
	ldr	r0, [r3, #0]
	mov	r3, r4
	bl	fprintf
	ldr	r0, [r6, #0]
	bl	free
	ldr	r0, [r5, #0]
	bl	free
	rsb	r0, r4, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L321:
	mov	r0, r2
	mov	r1, r7
	mov	r2, r9
	bl	gf2_long_mod_multiply_u16
	mov	r3, r4, asl #1
	strh	r0, [sl, r3]	@ movhi
	mov	r3, r0, asl #1
	mov	r2, r0
	strh	r4, [r8, r3]	@ movhi
	add	r4, r4, #1
	uxth	r4, r4
	cmp	r4, #0
	bne	.L322
	mov	r0, r4
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L323:
	mvn	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L324:
	mvn	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L327:
	.align	2
.L326:
	.word	stderr
	.word	.LC0
	.size	gf2_fast_u16_init_m1, .-gf2_fast_u16_init_m1
	.align	2
	.global	gf2_fast_u16_deinit_m1
	.type	gf2_fast_u16_deinit_m1, %function
gf2_fast_u16_deinit_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	mov	r0, r4
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u16_deinit_m1, .-gf2_fast_u16_deinit_m1
	.align	2
	.global	gf2_fast_u16_mul_m1
	.type	gf2_fast_u16_mul_m1, %function
gf2_fast_u16_mul_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	cmp	r2, #0
	cmpne	r3, #0
	beq	.L331
	mov	r2, r2, asl #1
	mov	r3, r3, asl #1
	ldrh	r2, [r0, r2]
	ldrh	r3, [r0, r3]
	add	r3, r2, r3
	mov	r2, r3, lsr #16
	uxtah	r3, r2, r3
	mov	r3, r3, asl #1
	ldrh	r0, [r1, r3]
	bx	lr
.L331:
	mov	r0, #0
	bx	lr
	.size	gf2_fast_u16_mul_m1, .-gf2_fast_u16_mul_m1
	.align	2
	.global	gf2_fast_u16_inv_m1
	.type	gf2_fast_u16_inv_m1, %function
gf2_fast_u16_inv_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r2, r2, asl #1
	ldrh	r3, [r0, r2]
	rsb	r3, r3, #65280
	add	r3, r3, #255
	mov	r3, r3, asl #1
	ldrh	r0, [r1, r3]
	bx	lr
	.size	gf2_fast_u16_inv_m1, .-gf2_fast_u16_inv_m1
	.align	2
	.global	gf2_fast_u16_div_m1
	.type	gf2_fast_u16_div_m1, %function
gf2_fast_u16_div_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r2, r2, asl #1
	mov	r3, r3, asl #1
	ldrh	r2, [r0, r2]
	ldrh	r3, [r0, r3]
	cmp	r2, r3
	addcc	r2, r2, #65280
	addcc	r2, r2, #255
	rsbcs	r3, r3, r2
	rsbcc	r3, r3, r2
	movcs	r3, r3, asl #1
	movcc	r3, r3, asl #1
	ldrcsh	r0, [r1, r3]
	ldrcch	r0, [r1, r3]
	bx	lr
	.size	gf2_fast_u16_div_m1, .-gf2_fast_u16_div_m1
	.align	2
	.global	gf2_fast_u16_init_m2
	.type	gf2_fast_u16_init_m2, %function
gf2_fast_u16_init_m2:
	@ args = 4, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	fp, r0
	sub	sp, sp, #20
	mov	r0, #33554432
	mov	r9, r2
	mov	r6, r3
	mov	r4, r1
	bl	malloc
	str	r0, [r9, #0]
	mov	r0, #33554432
	bl	malloc
	str	r0, [r6, #0]
	mov	r0, #131072
	bl	malloc
	ldr	r3, [sp, #56]
	str	r0, [r3, #0]
	ldr	r7, [r9, #0]
	cmp	r7, #0
	beq	.L337
	ldr	r5, [r6, #0]
	cmp	r5, #0
	beq	.L338
	cmp	r0, #0
	bne	.L339
.L338:
	mov	r0, r7
	bl	free
.L337:
	ldr	r0, [r6, #0]
	cmp	r0, #0
	beq	.L340
	bl	free
.L340:
	ldr	r4, [sp, #56]
	ldr	r0, [r4, #0]
	cmp	r0, #0
	beq	.L356
	bl	free
	b	.L356
.L339:
	cmp	r4, #0
	beq	.L342
	mov	r3, #0
	strh	r3, [r5, #0]	@ movhi
	mov	r2, #131072
	mov	r3, #1
	strh	r3, [r5, r2]	@ movhi
	mov	r2, r4, asl r3
	add	r8, r5, #131072
	strh	r3, [r5, r2]	@ movhi
	ldr	r3, .L366
	mov	ip, r7
	mov	r0, r4
	strh	r4, [r5, r3]	@ movhi
	add	r3, r8, #2
	mov	sl, #2
	mov	r7, r3
.L344:
	cmp	r0, #1
	bne	.L343
	ldr	r3, .L366+4
	ldr	r0, .L366+8
	ldr	r1, [r3, #0]
	bl	fputs
	b	.L342
.L343:
	mov	r2, fp
	mov	r1, r4
	str	ip, [sp, #0]
	bl	gf2_long_mod_multiply_u16
	ldr	ip, [sp, #0]
	mov	r2, r0, asl #1
	strh	r0, [r7, #2]!	@ movhi
	strh	sl, [r5, r2]	@ movhi
	add	sl, sl, #1
	cmp	sl, #65536
	bne	.L344
	mov	r7, ip
	ldr	ip, .L366+12
	mov	r3, #2
	mov	lr, #0
.L348:
	mov	r2, r3, asl #17
	mov	sl, r3, asl #16
	strh	lr, [r7, r2]	@ movhi
	mov	r0, r5
	strh	lr, [r5, r2]	@ movhi
	mov	r1, r5
	mov	r2, #2
	mov	r9, r3, asl #9
	mov	r4, r3, asl #1
	str	r9, [sp, #8]
	str	r4, [sp, #12]
.L347:
	ldr	r4, [sp, #8]
	ldrh	r9, [r5, r4]
	ldrh	r4, [r1, #4]
	add	r9, r9, r4
	cmp	r9, ip
	subhi	r9, r9, #65280
	subhi	r9, r9, #255
	orr	r4, r2, sl
	mov	r9, r9, asl #1
	mov	r4, r4, asl #1
	ldrh	r9, [r8, r9]
	add	r2, r2, #1
	strh	r9, [r7, r4]	@ movhi
	ldr	r9, [sp, #12]
	ldrh	fp, [r5, r9]
	ldrh	r9, [r1, #4]
	add	r1, r1, #2
	add	r9, fp, r9
	cmp	r9, ip
	subhi	r9, r9, #65280
	subhi	r9, r9, #255
	cmp	r2, #65536
	mov	r9, r9, asl #1
	ldrh	r9, [r8, r9]
	strh	r9, [r5, r4]	@ movhi
	bne	.L347
	add	r3, r3, #1
	cmp	r3, #256
	bne	.L348
	ldr	r1, .L366+12
	mov	r2, #0
	mov	ip, #512
.L350:
	ldrh	lr, [r5, ip]
	ldrh	r3, [r0], #2
	add	r3, lr, r3
	cmp	r3, r1
	subhi	r3, r3, #65280
	subhi	r3, r3, #255
	mov	r3, r3, asl #1
	ldrh	lr, [r8, r3]
	orr	r3, r2, #65536
	add	r2, r2, #1
	mov	r3, r3, asl #1
	cmp	r2, #65536
	strh	lr, [r7, r3]	@ movhi
	bne	.L350
	mov	r1, #0
	mov	r2, #131072
	mov	r0, r7
	bl	memset
	mov	r2, #131072
	ldr	r0, [r6, #0]
	mov	r1, #0
	bl	memset
	ldr	r2, [r6, #0]
	mov	r3, #0
.L351:
	orr	r1, r3, #65536
	mov	r1, r1, asl #1
	strh	r3, [r2, r1]	@ movhi
	add	r3, r3, #1
	cmp	r3, #65536
	bne	.L351
	b	.L357
.L342:
	ldr	r0, .L366+16
	bl	puts
	ldr	r3, [sp, #56]
	ldr	r7, [r9, #0]
	ldr	r6, [r6, #0]
	ldr	r2, [r3, #0]
	mov	r3, #0
	mov	r1, r3
	strh	r3, [r2, #0]	@ movhi
.L352:
	strh	r1, [r7, r3]	@ movhi
	strh	r1, [r6, r3]	@ movhi
	add	r3, r3, #131072
	cmp	r3, #33554432
	bne	.L352
	mov	r9, r2
	mov	sl, r7
	mov	r8, r6
	mov	r4, #1
	mov	r5, #0
.L353:
	uxth	r0, r4
	mov	r1, fp
	bl	gf2_long_mod_inverse_u16
	add	r4, r4, #1
	cmp	r4, #65536
	strh	r0, [r9, #2]!	@ movhi
	strh	r5, [sl, #2]!	@ movhi
	strh	r5, [r8, #2]!	@ movhi
	bne	.L353
	mov	r4, #1
	mov	sl, r7
	b	.L354
.L355:
	uxth	r8, r5
	mov	r0, ip
	mov	r1, r8
	mov	r2, fp
	orr	r7, r5, r3
	str	r3, [sp, #4]
	str	ip, [sp, #0]
	bl	gf2_long_mod_multiply_u16
	mov	r7, r7, asl #1
	mov	r1, r8
	mov	r2, fp
	add	r5, r5, #1
	strh	r0, [sl, r7]	@ movhi
	mov	r0, r9
	bl	gf2_long_mod_multiply_u16
	cmp	r5, #65536
	ldr	r3, [sp, #4]
	ldr	ip, [sp, #0]
	strh	r0, [r6, r7]	@ movhi
	bne	.L355
	add	r4, r4, #1
	cmp	r4, #256
	beq	.L357
.L354:
	uxth	r9, r4
	mov	r3, r4, asl #16
	mov	ip, r9, asl #8
	mov	r5, #1
	uxth	ip, ip
	b	.L355
.L356:
	mvn	r0, #0
	b	.L341
.L357:
	mov	r0, #0
.L341:
	add	sp, sp, #20
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, pc}
.L367:
	.align	2
.L366:
	.word	131074
	.word	stderr
	.word	.LC1
	.word	65535
	.word	.LC2
	.size	gf2_fast_u16_init_m2, .-gf2_fast_u16_init_m2
	.align	2
	.global	gf2_fast_u16_deinit_m2
	.type	gf2_fast_u16_deinit_m2, %function
gf2_fast_u16_deinit_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r3, r4, r5, lr}
	mov	r4, r1
	mov	r5, r2
	bl	free
	mov	r0, r4
	bl	free
	mov	r0, r5
	ldmfd	sp!, {r3, r4, r5, lr}
	b	free
	.size	gf2_fast_u16_deinit_m2, .-gf2_fast_u16_deinit_m2
	.align	2
	.global	gf2_fast_u16_mul_m2
	.type	gf2_fast_u16_mul_m2, %function
gf2_fast_u16_mul_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	uxtb	ip, r2
	and	r2, r2, #65280
	orr	ip, r3, ip, asl #16
	orr	r3, r3, r2, asl #8
	mov	ip, ip, asl #1
	mov	r3, r3, asl #1
	ldrh	r2, [r1, ip]
	ldrh	r0, [r0, r3]
	eor	r0, r2, r0
	bx	lr
	.size	gf2_fast_u16_mul_m2, .-gf2_fast_u16_mul_m2
	.align	2
	.global	gf2_fast_u16_inv_m2
	.type	gf2_fast_u16_inv_m2, %function
gf2_fast_u16_inv_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r1, r1, asl #1
	ldrh	r0, [r0, r1]
	bx	lr
	.size	gf2_fast_u16_inv_m2, .-gf2_fast_u16_inv_m2
	.align	2
	.global	gf2_fast_u16_div_m2
	.type	gf2_fast_u16_div_m2, %function
gf2_fast_u16_div_m2:
	@ args = 4, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldrh	ip, [sp, #0]
	mov	ip, ip, asl #1
	ldrh	r2, [r2, ip]
	uxtb	ip, r3
	and	r3, r3, #65280
	orr	ip, r2, ip, asl #16
	orr	r2, r2, r3, asl #8
	mov	ip, ip, asl #1
	mov	r2, r2, asl #1
	ldrh	r3, [r1, ip]
	ldrh	r0, [r0, r2]
	eor	r0, r3, r0
	bx	lr
	.size	gf2_fast_u16_div_m2, .-gf2_fast_u16_div_m2
	.align	2
	.global	gf2_fast_u16_init_m3
	.type	gf2_fast_u16_init_m3, %function
gf2_fast_u16_init_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	cmp	r0, #0
	cmpne	r1, #0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, lr}
	mov	r6, r2
	mov	r5, r3
	mov	r7, r1
	mov	r9, r0
	movne	r4, #0
	moveq	r4, #1
	beq	.L379
	mov	r0, #262144
	bl	malloc
	str	r0, [r6, #0]
	mov	r0, #524288
	bl	malloc
	mov	r8, r0
	str	r0, [r5, #0]
	ldr	r0, [r6, #0]
	cmp	r0, #0
	beq	.L374
	cmp	r8, #0
	addne	r3, r8, #262144
	strne	r3, [r5, #0]
	movne	r3, r4
	bne	.L376
	bl	free
.L374:
	ldr	r0, [r5, #0]
	cmp	r0, #0
	beq	.L380
	bl	free
	b	.L379
.L376:
	strh	r3, [r8, r4]	@ movhi
	add	r4, r4, #2
	cmp	r4, #262144
	bne	.L376
	ldr	sl, [r6, #0]
	ldr	r3, .L383
	ldr	r2, .L383+4
	str	r3, [sl, #0]
	mov	r3, #1
	strh	r3, [r8, r4]	@ movhi
	str	r3, [sl, r7, asl #2]
	strh	r7, [r8, r2]	@ movhi
	ldr	r2, .L383+8
	mov	r4, #2
	strh	r3, [r8, r2]	@ movhi
	mov	r3, #393216
	mov	r2, #0
	strh	r7, [r8, r3]	@ movhi
	ldr	r3, .L383+12
	strh	r2, [r8, r3]	@ movhi
	add	r8, r8, #262144
	add	r8, r8, #2
	mov	r2, r7
.L378:
	cmp	r2, #1
	bne	.L377
	ldr	r3, .L383+16
	ldr	r1, .L383+20
	ldr	r0, [r3, #0]
	mov	r3, r4
	bl	fprintf
	ldr	r0, [r6, #0]
	bl	free
	ldr	r0, [r5, #0]
	sub	r0, r0, #262144
	bl	free
	rsb	r0, r4, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L377:
	mov	r0, r2
	mov	r1, r7
	mov	r2, r9
	bl	gf2_long_mod_multiply_u16
	ldr	r3, .L383+24
	strh	r0, [r8, #2]!	@ movhi
	add	r3, r8, r3
	mov	r2, r0
	strh	r0, [r3, #0]	@ movhi
	str	r4, [sl, r0, asl #2]
	add	r4, r4, #1
	cmp	r4, #65536
	bne	.L378
	mov	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L379:
	mvn	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L380:
	mvn	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L384:
	.align	2
.L383:
	.word	-65536
	.word	262146
	.word	393214
	.word	524286
	.word	stderr
	.word	.LC0
	.word	131070
	.size	gf2_fast_u16_init_m3, .-gf2_fast_u16_init_m3
	.align	2
	.global	gf2_fast_u16_deinit_m3
	.type	gf2_fast_u16_deinit_m3, %function
gf2_fast_u16_deinit_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	sub	r0, r4, #262144
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u16_deinit_m3, .-gf2_fast_u16_deinit_m3
	.align	2
	.global	gf2_fast_u16_mul_m3
	.type	gf2_fast_u16_mul_m3, %function
gf2_fast_u16_mul_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldr	r2, [r0, r2, asl #2]
	ldr	r3, [r0, r3, asl #2]
	add	r2, r2, r3
	mov	r2, r2, asl #1
	ldrh	r0, [r1, r2]
	bx	lr
	.size	gf2_fast_u16_mul_m3, .-gf2_fast_u16_mul_m3
	.align	2
	.global	gf2_fast_u16_inv_m3
	.type	gf2_fast_u16_inv_m3, %function
gf2_fast_u16_inv_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldr	r3, [r0, r2, asl #2]
	rsb	r3, r3, #65280
	add	r3, r3, #255
	mov	r3, r3, asl #1
	ldrh	r0, [r1, r3]
	bx	lr
	.size	gf2_fast_u16_inv_m3, .-gf2_fast_u16_inv_m3
	.align	2
	.global	gf2_fast_u16_div_m3
	.type	gf2_fast_u16_div_m3, %function
gf2_fast_u16_div_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldr	r2, [r0, r2, asl #2]
	ldr	r3, [r0, r3, asl #2]
	add	r2, r2, #65280
	add	r2, r2, #255
	rsb	r2, r3, r2
	mov	r2, r2, asl #1
	ldrh	r0, [r1, r2]
	bx	lr
	.size	gf2_fast_u16_div_m3, .-gf2_fast_u16_div_m3
	.align	2
	.global	gf2_fast_u16_pow_m3
	.type	gf2_fast_u16_pow_m3, %function
gf2_fast_u16_pow_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	ldr	r0, [r0, r2, asl #2]
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	mul	r0, r0, r3
	ldr	r1, .L390
	bl	__aeabi_idivmod
	mov	r1, r1, asl #1
	ldrh	r0, [r4, r1]
	ldmfd	sp!, {r4, pc}
.L391:
	.align	2
.L390:
	.word	65535
	.size	gf2_fast_u16_pow_m3, .-gf2_fast_u16_pow_m3
	.align	2
	.global	gf2_fast_u16_init_m4
	.type	gf2_fast_u16_init_m4, %function
gf2_fast_u16_init_m4:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r7, r0
	sub	sp, sp, #20
	mov	r0, #524288
	mov	r5, r1
	mov	r6, r2
	bl	malloc
	str	r0, [r5, #0]
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	str	r0, [r6, #0]
	ldr	r0, [r5, #0]
	cmp	r0, #0
	beq	.L393
	cmp	r3, #0
	bne	.L394
	bl	free
.L393:
	ldr	r0, [r6, #0]
	cmp	r0, #0
	beq	.L399
	bl	free
	b	.L399
.L394:
	mov	r1, #0
	strh	r1, [r3, #0]	@ movhi
	mov	r2, #8
	bl	memset
	mov	r4, #1
.L396:
	uxth	r0, r4
	mov	r1, r7
	bl	gf2_long_mod_inverse_u16
	ldr	sl, [r6, #0]
	mov	r8, r4, asl #1
	mov	r1, #0
	mov	r2, #8
	strh	r0, [sl, r8]	@ movhi
	ldr	r0, [r5, #0]
	add	r0, r0, r4, asl #3
	bl	memset
	ldr	r0, [r5, #0]
	mov	r1, #0
	add	r0, r0, r4, asl #11
	mov	r2, #8
	add	r4, r4, #1
	bl	memset
	cmp	r4, #256
	bne	.L396
	ldr	r6, [r5, #0]
	mov	r4, #1
	b	.L397
.L398:
	uxtb	r1, r5
	mov	r0, sl
	bl	gf2_long_straight_multiply_u8
	orr	r4, r9, r5, asl #2
	uxth	ip, r5
	mov	r8, r4, asl #1
	mov	r1, ip
	mov	r2, r7
	add	r5, r5, #1
	strh	r0, [r6, r8]	@ movhi
	ldr	r0, [sp, #8]
	str	ip, [sp, #4]
	bl	gf2_long_mod_multiply_u16
	ldr	ip, [sp, #4]
	orr	r8, r4, #1
	orr	r2, r4, #2
	mov	ip, ip, asl #8
	mov	r8, r8, asl #1
	mov	r3, r2, asl #1
	mov	r2, r7
	orr	r4, r4, #3
	mov	r4, r4, asl #1
	strh	r0, [r6, r8]	@ movhi
	uxth	r8, ip
	mov	r1, r8
	mov	r0, fp
	str	r3, [sp, #4]
	bl	gf2_long_mod_multiply_u16
	ldr	r3, [sp, #4]
	mov	r1, r8
	mov	r2, r7
	strh	r0, [r6, r3]	@ movhi
	ldr	r0, [sp, #8]
	bl	gf2_long_mod_multiply_u16
	cmp	r5, #256
	strh	r0, [r6, r4]	@ movhi
	bne	.L398
	ldr	r4, [sp, #12]
	add	r4, r4, #1
	cmp	r4, #256
	beq	.L400
.L397:
	uxth	fp, r4
	mov	r3, r4, asl #10
	mov	r2, fp, asl #8
	uxtb	ip, r4
	uxth	r2, r2
	str	r2, [sp, #8]
	mov	r5, #1
	mov	r9, r3
	str	r4, [sp, #12]
	mov	sl, ip
	b	.L398
.L399:
	mvn	r0, #0
	b	.L395
.L400:
	mov	r0, #0
.L395:
	add	sp, sp, #20
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, pc}
	.size	gf2_fast_u16_init_m4, .-gf2_fast_u16_init_m4
	.align	2
	.global	gf2_fast_u16_deinit_m4
	.type	gf2_fast_u16_deinit_m4, %function
gf2_fast_u16_deinit_m4:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	mov	r0, r4
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u16_deinit_m4, .-gf2_fast_u16_deinit_m4
	.align	2
	.global	gf2_fast_u16_mul_m4
	.type	gf2_fast_u16_mul_m4, %function
gf2_fast_u16_mul_m4:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	uxtb	r3, r1
	and	r1, r1, #65280
	uxtb	ip, r2
	mov	r1, r1, asl #2
	and	r2, r2, #65280
	stmfd	sp!, {r4, lr}
	mov	r3, r3, asl #10
	mov	ip, ip, asl #2
	orr	r4, r1, #1
	mov	r2, r2, asr #6
	orr	r4, r4, ip
	orr	ip, ip, r3
	orr	r3, r3, #2
	orr	r3, r3, r2
	mov	r4, r4, asl #1
	mov	ip, ip, asl #1
	orr	r1, r1, #3
	mov	r3, r3, asl #1
	ldrh	r4, [r0, r4]
	ldrh	ip, [r0, ip]
	orr	r2, r1, r2
	ldrh	r3, [r0, r3]
	mov	r2, r2, asl #1
	eor	ip, r4, ip
	eor	ip, ip, r3
	ldrh	r3, [r0, r2]
	eor	r0, ip, r3
	ldmfd	sp!, {r4, pc}
	.size	gf2_fast_u16_mul_m4, .-gf2_fast_u16_mul_m4
	.align	2
	.global	gf2_fast_u16_inv_m4
	.type	gf2_fast_u16_inv_m4, %function
gf2_fast_u16_inv_m4:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r1, r1, asl #1
	ldrh	r0, [r0, r1]
	bx	lr
	.size	gf2_fast_u16_inv_m4, .-gf2_fast_u16_inv_m4
	.align	2
	.global	gf2_fast_u16_div_m4
	.type	gf2_fast_u16_div_m4, %function
gf2_fast_u16_div_m4:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r3, r3, asl #1
	ldrh	r3, [r1, r3]
	mov	r1, r2
	mov	r2, r3
	b	gf2_fast_u16_mul_m4
	.size	gf2_fast_u16_div_m4, .-gf2_fast_u16_div_m4
	.align	2
	.global	gf2_fast_u16_init_m5
	.type	gf2_fast_u16_init_m5, %function
gf2_fast_u16_init_m5:
	@ args = 8, pretend = 0, frame = 32
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, lr}
	sub	sp, sp, #36
	mov	r4, r1
	str	r0, [sp, #0]
	mov	r0, #524288
	mov	r8, r3
	mov	r6, r2
	ldr	r5, [sp, #76]
	bl	malloc
	str	r0, [r4, #0]
	mov	r0, #131072
	bl	malloc
	str	r0, [r5, #0]
	ldr	r3, [r4, #0]
	cmp	r3, #0
	beq	.L408
	cmp	r0, #0
	bne	.L409
	mov	r0, r3
	bl	free
.L408:
	ldr	r0, [r5, #0]
	cmp	r0, #0
	beq	.L414
	bl	free
	b	.L414
.L409:
	add	r2, r3, #131072
	str	r2, [r6, #0]
	add	r2, r3, #262144
	str	r2, [r8, #0]
	ldr	r2, [sp, #72]
	add	fp, r3, #393216
	str	fp, [r2, #0]
	ldr	sl, [r5, #0]
	ldr	r9, [r4, #0]
	mov	r5, #0
	ldr	r7, [r6, #0]
	ldr	r8, [r8, #0]
	mov	r2, #393216
	mov	r6, #1
	mov	r4, r5
	strh	r5, [sl, #0]	@ movhi
	strh	r5, [r9, #0]	@ movhi
	strh	r5, [r7, #0]	@ movhi
	strh	r5, [r8, #0]	@ movhi
	strh	r5, [r3, r2]	@ movhi
.L411:
	uxth	r0, r6
	ldr	r1, [sp, #0]
	bl	gf2_long_mod_inverse_u16
	add	r5, r5, #2
	mov	r3, r6, asl #9
	add	r6, r6, #1
	cmp	r6, #256
	strh	r0, [sl, #2]!	@ movhi
	strh	r4, [r9, r5]	@ movhi
	strh	r4, [r9, r3]	@ movhi
	strh	r4, [r7, r5]	@ movhi
	strh	r4, [r7, r3]	@ movhi
	strh	r4, [r8, r5]	@ movhi
	strh	r4, [r8, r3]	@ movhi
	strh	r4, [fp, r5]	@ movhi
	strh	r4, [fp, r3]	@ movhi
	bne	.L411
	mov	r4, #1
	b	.L412
.L413:
	uxtb	r1, r5
	mov	r0, r8
	bl	gf2_long_straight_multiply_u8
	ldr	r3, [sp, #12]
	mov	r2, r5, asl #1
	uxth	r7, r5
	mov	r1, r7
	mov	r7, r7, asl #8
	add	r6, r6, #2
	uxth	r7, r7
	add	r5, r5, #1
	strh	r0, [r3, r2]	@ movhi
	ldr	r2, [sp, #0]
	ldr	r0, [sp, #8]
	bl	gf2_long_mod_multiply_u16
	ldr	r3, [sp, #16]
	mov	r1, r7
	ldr	r2, [sp, #0]
	strh	r0, [r3, r6]	@ movhi
	ldr	r0, [sp, #4]
	bl	gf2_long_mod_multiply_u16
	ldr	r3, [sp, #20]
	mov	r1, r7
	ldr	r2, [sp, #0]
	strh	r0, [r3, r6]	@ movhi
	ldr	r0, [sp, #8]
	bl	gf2_long_mod_multiply_u16
	cmp	r5, #256
	strh	r0, [sl, r6]	@ movhi
	bne	.L413
	add	r4, r4, #1
	cmp	r4, #256
	mov	r7, fp
	mov	r8, r9
	ldr	fp, [sp, #24]
	ldr	r9, [sp, #28]
	beq	.L415
.L412:
	uxth	r3, r4
	mov	ip, r4, asl #9
	str	r3, [sp, #4]
	mov	r3, r3, asl #8
	add	r2, r9, ip
	uxth	r3, r3
	str	r2, [sp, #12]
	add	r2, r7, ip
	str	r3, [sp, #8]
	str	r2, [sp, #16]
	uxtb	r3, r4
	add	r2, r8, ip
	add	ip, fp, ip
	str	fp, [sp, #24]
	str	r9, [sp, #28]
	mov	r6, #0
	mov	r9, r8
	mov	r5, #1
	str	r2, [sp, #20]
	mov	fp, r7
	mov	r8, r3
	mov	sl, ip
	b	.L413
.L414:
	mvn	r0, #0
	b	.L410
.L415:
	mov	r0, #0
.L410:
	add	sp, sp, #36
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, pc}
	.size	gf2_fast_u16_init_m5, .-gf2_fast_u16_init_m5
	.align	2
	.global	gf2_fast_u16_deinit_m5
	.type	gf2_fast_u16_deinit_m5, %function
gf2_fast_u16_deinit_m5:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	mov	r0, r4
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u16_deinit_m5, .-gf2_fast_u16_deinit_m5
	.align	2
	.global	gf2_fast_u16_mul_m5
	.type	gf2_fast_u16_mul_m5, %function
gf2_fast_u16_mul_m5:
	@ args = 8, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, lr}
	ldrh	r7, [sp, #20]
	ldrh	ip, [sp, #24]
	mov	r4, r7, asl #8
	uxtb	r5, ip
	and	r7, r7, #65280
	uxth	r4, r4
	orr	r6, r5, r7
	orr	r5, r5, r4
	mov	ip, ip, lsr #8
	mov	r6, r6, asl #1
	mov	r5, r5, asl #1
	orr	r4, ip, r4
	orr	ip, ip, r7
	ldrh	r0, [r0, r5]
	ldrh	r1, [r1, r6]
	mov	r4, r4, asl #1
	mov	ip, ip, asl #1
	ldrh	r2, [r2, r4]
	eor	r1, r1, r0
	ldrh	r0, [r3, ip]
	eor	r1, r1, r2
	eor	r0, r1, r0
	ldmfd	sp!, {r4, r5, r6, r7, pc}
	.size	gf2_fast_u16_mul_m5, .-gf2_fast_u16_mul_m5
	.align	2
	.global	gf2_fast_u16_inv_m5
	.type	gf2_fast_u16_inv_m5, %function
gf2_fast_u16_inv_m5:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r1, r1, asl #1
	ldrh	r0, [r0, r1]
	bx	lr
	.size	gf2_fast_u16_inv_m5, .-gf2_fast_u16_inv_m5
	.align	2
	.global	gf2_fast_u16_div_m5
	.type	gf2_fast_u16_div_m5, %function
gf2_fast_u16_div_m5:
	@ args = 12, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, lr}
	ldrh	ip, [sp, #20]
	ldr	r4, [sp, #12]
	ldrh	r5, [sp, #16]
	mov	ip, ip, asl #1
	str	r5, [sp, #12]
	ldrh	ip, [r4, ip]
	str	ip, [sp, #16]
	ldmfd	sp!, {r4, r5, lr}
	b	gf2_fast_u16_mul_m5
	.size	gf2_fast_u16_div_m5, .-gf2_fast_u16_div_m5
	.align	2
	.global	gf2_fast_u16_init_m6
	.type	gf2_fast_u16_init_m6, %function
gf2_fast_u16_init_m6:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r0, r1, r2, r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r4, r0
	mov	r0, #131072
	mov	r5, r1
	mov	r8, r2
	bl	malloc
	str	r0, [r5, #0]
	mov	r0, #131072
	bl	malloc
	str	r0, [r8, #0]
	ldr	r7, [r5, #0]
	mov	r6, r0
	cmp	r7, #0
	beq	.L423
	cmp	r0, #0
	bne	.L424
	mov	r0, r7
	bl	free
.L423:
	ldr	r0, [r8, #0]
	cmp	r0, #0
	beq	.L429
	bl	free
	b	.L429
.L424:
	mov	r9, r0
	mov	sl, r7
	mov	r5, #1
	mov	r8, #0
	strh	r8, [r0, #0]	@ movhi
	strh	r8, [r7, #0]	@ movhi
.L426:
	uxth	r0, r5
	mov	r1, r4
	bl	gf2_long_mod_inverse_u16
	mov	r3, r5, asl #9
	add	r5, r5, #1
	cmp	r5, #256
	strh	r0, [r9, #2]!	@ movhi
	strh	r8, [sl, #2]!	@ movhi
	strh	r8, [r7, r3]	@ movhi
	bne	.L426
	mov	r5, #1
.L428:
	mov	sl, r5, asl #8
	and	r0, sl, #65280
	mov	r1, r4
	bl	gf2_long_mod_inverse_u16
	mov	r8, r5, asl #9
	uxtb	r3, r5
	strh	r0, [r6, r8]	@ movhi
	mov	r8, #1
.L427:
	mov	r0, r3
	uxtb	r1, r8
	str	r3, [sp, #4]
	bl	gf2_long_straight_multiply_u8
	orr	fp, r8, sl
	mov	r1, r4
	mov	r9, fp, asl #1
	add	r8, r8, #1
	strh	r0, [r7, r9]	@ movhi
	uxth	r0, fp
	bl	gf2_long_mod_inverse_u16
	cmp	r8, #256
	ldr	r3, [sp, #4]
	strh	r0, [r6, r9]	@ movhi
	bne	.L427
	add	r5, r5, #1
	cmp	r5, #256
	bne	.L428
	mov	r0, #0
	b	.L425
.L429:
	mvn	r0, #0
.L425:
	ldmfd	sp!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, pc}
	.size	gf2_fast_u16_init_m6, .-gf2_fast_u16_init_m6
	.align	2
	.global	gf2_fast_u16_deinit_m6
	.type	gf2_fast_u16_deinit_m6, %function
gf2_fast_u16_deinit_m6:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	mov	r0, r4
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u16_deinit_m6, .-gf2_fast_u16_deinit_m6
	.align	2
	.global	gf2_fast_u16_mul_m6
	.type	gf2_fast_u16_mul_m6, %function
gf2_fast_u16_mul_m6:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, lr}
	and	r4, r1, #65280
	mov	r5, r2, lsr #8
	orr	ip, r5, r4
	mov	r1, r1, asl #24
	mov	ip, ip, asl #1
	mov	r1, r1, lsr #16
	ldrh	ip, [r0, ip]
	uxtb	r2, r2
	orr	r5, r1, r5
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	orr	r4, r2, r4
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	mov	r4, r4, asl #1
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	mov	r5, r5, asl #1
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	ldrh	r5, [r0, r5]
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	orr	r2, r1, r2
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	mov	r2, r2, asl #1
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	uxth	r6, ip
	ldrh	ip, [r0, r4]
	ldrh	r0, [r0, r2]
	eor	ip, r5, ip
	eor	ip, ip, r6
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	ip, ip, r3
	uxth	ip, ip
	tst	ip, #32768
	mov	ip, ip, asl #1
	eorne	r3, ip, r3
	uxtheq	r3, ip
	uxthne	r3, r3
	eor	r0, r3, r0
	ldmfd	sp!, {r4, r5, r6, pc}
	.size	gf2_fast_u16_mul_m6, .-gf2_fast_u16_mul_m6
	.align	2
	.global	gf2_fast_u16_inv_m6
	.type	gf2_fast_u16_inv_m6, %function
gf2_fast_u16_inv_m6:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r1, r1, asl #1
	ldrh	r0, [r0, r1]
	bx	lr
	.size	gf2_fast_u16_inv_m6, .-gf2_fast_u16_inv_m6
	.align	2
	.global	gf2_fast_u16_div_m6
	.type	gf2_fast_u16_div_m6, %function
gf2_fast_u16_div_m6:
	@ args = 4, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r3, r3, asl #1
	ldrh	r3, [r1, r3]
	mov	r1, r2
	mov	r2, r3
	ldrh	r3, [sp, #0]
	b	gf2_fast_u16_mul_m6
	.size	gf2_fast_u16_div_m6, .-gf2_fast_u16_div_m6
	.align	2
	.global	gf2_fast_u16_init_m7
	.type	gf2_fast_u16_init_m7, %function
gf2_fast_u16_init_m7:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r0, r1, r2, r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r4, r0
	mov	r0, #131072
	mov	r5, r1
	mov	r8, r2
	mov	r9, r3
	bl	malloc
	str	r0, [r5, #0]
	mov	r0, #131072
	bl	malloc
	str	r0, [r8, #0]
	mov	r0, #512
	bl	malloc
	str	r0, [r9, #0]
	ldr	r6, [r5, #0]
	cmp	r6, #0
	beq	.L470
	ldr	r7, [r8, #0]
	cmp	r7, #0
	beq	.L471
	cmp	r0, #0
	bne	.L472
.L471:
	mov	r0, r6
	bl	free
.L470:
	ldr	r0, [r9, #0]
	cmp	r0, #0
	beq	.L473
	bl	free
.L473:
	ldr	r0, [r8, #0]
	cmp	r0, #0
	beq	.L494
	bl	free
	b	.L494
.L472:
	mov	r9, r7
	mov	sl, r0
	mov	r5, #1
	mov	r8, #0
	strh	r8, [r7, #0]	@ movhi
	strh	r8, [r6, #0]	@ movhi
	strh	r8, [r0, #0]	@ movhi
.L491:
	uxth	fp, r5
	mov	r0, fp
	mov	r1, r4
	bl	gf2_long_mod_inverse_u16
	mov	r3, r5, asl #1
	strh	r0, [r9, #2]!	@ movhi
	strh	r8, [r6, r3]	@ movhi
	mov	r3, r5, asl #9
	add	r5, r5, #1
	strh	r8, [r6, r3]	@ movhi
	mov	r3, fp, asl #8
	uxth	r3, r3
	tst	r3, #32768
	mov	r3, r3, asl #1
	eorne	r3, r3, r4
	uxth	r3, r3
	tst	r3, #32768
	mov	r3, r3, asl #1
	eorne	r3, r3, r4
	uxth	r3, r3
	tst	r3, #32768
	mov	r3, r3, asl #1
	eorne	r3, r3, r4
	uxth	r3, r3
	tst	r3, #32768
	mov	r3, r3, asl #1
	eorne	r3, r3, r4
	uxth	r3, r3
	tst	r3, #32768
	mov	r3, r3, asl #1
	eorne	r3, r3, r4
	uxth	r3, r3
	tst	r3, #32768
	mov	r3, r3, asl #1
	eorne	r3, r3, r4
	uxth	r3, r3
	tst	r3, #32768
	mov	r3, r3, asl #1
	eorne	r3, r3, r4
	uxth	r3, r3
	tst	r3, #32768
	mov	r3, r3, asl #1
	eorne	r3, r3, r4
	cmp	r5, #256
	uxth	r3, r3
	strh	r3, [sl, #2]!	@ movhi
	bne	.L491
	mov	r5, #1
.L493:
	mov	sl, r5, asl #8
	and	r0, sl, #65280
	mov	r1, r4
	bl	gf2_long_mod_inverse_u16
	mov	r8, r5, asl #9
	uxtb	r3, r5
	strh	r0, [r7, r8]	@ movhi
	mov	r8, #1
.L492:
	mov	r0, r3
	uxtb	r1, r8
	str	r3, [sp, #4]
	bl	gf2_long_straight_multiply_u8
	orr	fp, r8, sl
	mov	r1, r4
	mov	r9, fp, asl #1
	add	r8, r8, #1
	strh	r0, [r6, r9]	@ movhi
	uxth	r0, fp
	bl	gf2_long_mod_inverse_u16
	cmp	r8, #256
	ldr	r3, [sp, #4]
	strh	r0, [r7, r9]	@ movhi
	bne	.L492
	add	r5, r5, #1
	cmp	r5, #256
	bne	.L493
	mov	r0, #0
	b	.L474
.L494:
	mvn	r0, #0
.L474:
	ldmfd	sp!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, pc}
	.size	gf2_fast_u16_init_m7, .-gf2_fast_u16_init_m7
	.align	2
	.global	gf2_fast_u16_deinit_m7
	.type	gf2_fast_u16_deinit_m7, %function
gf2_fast_u16_deinit_m7:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r3, r4, r5, lr}
	mov	r4, r1
	mov	r5, r2
	bl	free
	mov	r0, r4
	bl	free
	mov	r0, r5
	ldmfd	sp!, {r3, r4, r5, lr}
	b	free
	.size	gf2_fast_u16_deinit_m7, .-gf2_fast_u16_deinit_m7
	.align	2
	.global	gf2_fast_u16_mul_m7
	.type	gf2_fast_u16_mul_m7, %function
gf2_fast_u16_mul_m7:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, lr}
	and	r4, r2, #65280
	mov	r5, r3, lsr #8
	orr	ip, r5, r4
	mov	r2, r2, asl #24
	mov	ip, ip, asl #1
	uxtb	r3, r3
	ldrh	ip, [r0, ip]
	mov	r2, r2, lsr #16
	orr	r5, r2, r5
	orr	r4, r3, r4
	mov	r6, ip, lsr #8
	mov	r4, r4, asl #1
	mov	r6, r6, asl #1
	mov	r5, r5, asl #1
	ldrh	r6, [r1, r6]
	ldrh	r5, [r0, r5]
	orr	r2, r2, r3
	eor	ip, r6, ip, asl #8
	mov	r2, r2, asl #1
	uxth	r6, ip
	ldrh	ip, [r0, r4]
	ldrh	r3, [r0, r2]
	eor	ip, r5, ip
	eor	ip, ip, r6
	mov	r4, ip, lsr #8
	mov	r4, r4, asl #1
	ldrh	r1, [r1, r4]
	eor	ip, r1, ip, asl #8
	uxth	ip, ip
	eor	r0, ip, r3
	ldmfd	sp!, {r4, r5, r6, pc}
	.size	gf2_fast_u16_mul_m7, .-gf2_fast_u16_mul_m7
	.align	2
	.global	gf2_fast_u16_inv_m7
	.type	gf2_fast_u16_inv_m7, %function
gf2_fast_u16_inv_m7:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r1, r1, asl #1
	ldrh	r0, [r0, r1]
	bx	lr
	.size	gf2_fast_u16_inv_m7, .-gf2_fast_u16_inv_m7
	.align	2
	.global	gf2_fast_u16_div_m7
	.type	gf2_fast_u16_div_m7, %function
gf2_fast_u16_div_m7:
	@ args = 4, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	ldrh	ip, [sp, #0]
	mov	ip, ip, asl #1
	ldrh	ip, [r1, ip]
	mov	r1, r2
	mov	r2, r3
	mov	r3, ip
	b	gf2_fast_u16_mul_m7
	.size	gf2_fast_u16_div_m7, .-gf2_fast_u16_div_m7
	.align	2
	.global	gf2_fast_u16_init_m8
	.type	gf2_fast_u16_init_m8, %function
gf2_fast_u16_init_m8:
	@ args = 4, pretend = 0, frame = 8
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r0, r1, r2, r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r4, r0
	mov	r0, #8192
	mov	r5, r1
	mov	r7, r2
	mov	r9, r3
	ldr	fp, [sp, #48]
	bl	malloc
	str	r0, [r5, #0]
	mov	r0, #8192
	bl	malloc
	str	r0, [r7, #0]
	mov	r0, #512
	bl	malloc
	str	r0, [r9, #0]
	mov	r0, #131072
	bl	malloc
	str	r0, [fp, #0]
	ldr	r5, [r5, #0]
	mov	r8, r0
	cmp	r5, #0
	beq	.L503
	ldr	r6, [r7, #0]
	cmp	r6, #0
	beq	.L504
	ldr	sl, [r9, #0]
	cmp	sl, #0
	beq	.L504
	cmp	r0, #0
	bne	.L505
.L504:
	mov	r0, r5
	bl	free
.L503:
	ldr	r0, [r7, #0]
	cmp	r0, #0
	beq	.L506
	bl	free
.L506:
	ldr	r0, [r9, #0]
	cmp	r0, #0
	beq	.L507
	bl	free
.L507:
	ldr	r0, [fp, #0]
	cmp	r0, #0
	beq	.L529
	bl	free
	b	.L529
.L505:
	mov	r3, #0
	mov	r7, #2
	strh	r3, [r5, #0]	@ movhi
	strh	r3, [r6, #0]	@ movhi
	strh	r3, [sl, #0]	@ movhi
	strh	r3, [r0, #0]	@ movhi
	mov	r3, #1
	strh	r3, [r0, #2]	@ movhi
.L509:
	mov	r0, r7
	mov	r1, r4
	bl	gf2_long_mod_inverse_u16
	mov	r9, r7, asl #1
	add	r7, r7, #1
	uxth	r7, r7
	cmp	r7, #0
	strh	r0, [r8, r9]	@ movhi
	bne	.L509
	mov	r0, r5
	mov	r1, r6
	mov	r3, #1
.L526:
	mov	r2, r3, asl #8
	add	r3, r3, #1
	uxth	r2, r2
	tst	r2, #32768
	mov	r2, r2, asl #1
	eorne	r2, r2, r4
	uxth	r3, r3
	uxth	r2, r2
	tst	r2, #32768
	mov	r2, r2, asl #1
	eorne	r2, r2, r4
	strh	r7, [r0, #2]!	@ movhi
	uxth	r2, r2
	tst	r2, #32768
	mov	r2, r2, asl #1
	eorne	r2, r2, r4
	strh	r7, [r1, #2]!	@ movhi
	uxth	r2, r2
	tst	r2, #32768
	mov	r2, r2, asl #1
	eorne	r2, r2, r4
	uxth	r2, r2
	tst	r2, #32768
	mov	r2, r2, asl #1
	eorne	r2, r2, r4
	uxth	r2, r2
	tst	r2, #32768
	mov	r2, r2, asl #1
	eorne	r2, r2, r4
	uxth	r2, r2
	tst	r2, #32768
	mov	r2, r2, asl #1
	eorne	r2, r2, r4
	uxth	r2, r2
	tst	r2, #32768
	mov	r2, r2, asl #1
	eorne	r2, r2, r4
	cmp	r3, #256
	uxth	r2, r2
	strh	r2, [sl, #2]!	@ movhi
	bne	.L526
	mov	r4, #1
	mov	r8, #0
.L528:
	mov	r2, r4, asl #9
	uxtb	sl, r4
	strh	r8, [r5, r2]	@ movhi
	strh	r8, [r6, r2]	@ movhi
	mov	r2, sl, asl #4
	mov	r3, r4, asl #8
	uxtb	r2, r2
	mov	r7, #1
.L527:
	uxtb	fp, r7
	mov	r0, r2
	mov	r1, fp
	orr	r9, r7, r3
	stmia	sp, {r2, r3}
	bl	gf2_long_straight_multiply_u8
	mov	r9, r9, asl #1
	mov	r1, fp
	add	r7, r7, #1
	strh	r0, [r5, r9]	@ movhi
	mov	r0, sl
	bl	gf2_long_straight_multiply_u8
	cmp	r7, #256
	ldmia	sp, {r2, r3}
	strh	r0, [r6, r9]	@ movhi
	bne	.L527
	add	r4, r4, #1
	cmp	r4, #16
	bne	.L528
	mov	r0, #0
	b	.L508
.L529:
	mvn	r0, #0
.L508:
	ldmfd	sp!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, pc}
	.size	gf2_fast_u16_init_m8, .-gf2_fast_u16_init_m8
	.align	2
	.global	gf2_fast_u16_deinit_m8
	.type	gf2_fast_u16_deinit_m8, %function
gf2_fast_u16_deinit_m8:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, lr}
	mov	r4, r1
	mov	r5, r2
	mov	r6, r3
	bl	free
	mov	r0, r4
	bl	free
	mov	r0, r5
	bl	free
	mov	r0, r6
	ldmfd	sp!, {r4, r5, r6, lr}
	b	free
	.size	gf2_fast_u16_deinit_m8, .-gf2_fast_u16_deinit_m8
	.align	2
	.global	gf2_fast_u16_mul_m8
	.type	gf2_fast_u16_mul_m8, %function
gf2_fast_u16_mul_m8:
	@ args = 4, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, sl, lr}
	mov	r6, r3, lsr #4
	ldrh	ip, [sp, #28]
	and	r7, r3, #3840
	and	r6, r6, #3840
	mov	r5, r3, asl #4
	mov	r4, ip, lsr #8
	orr	sl, r4, r7
	uxtb	ip, ip
	orr	r8, r4, r6
	orr	r7, ip, r7
	orr	r6, ip, r6
	mov	sl, sl, asl #1
	mov	r8, r8, asl #1
	mov	r7, r7, asl #1
	mov	r6, r6, asl #1
	ldrh	sl, [r1, sl]
	ldrh	r8, [r0, r8]
	ldrh	r6, [r0, r6]
	ldrh	r7, [r1, r7]
	and	r5, r5, #3840
	eor	r8, sl, r8
	eor	r7, r7, r6
	orr	r6, r5, r4
	mov	sl, r8, lsr #8
	mov	r3, r3, asl #8
	and	r3, r3, #3840
	mov	r6, r6, asl #1
	orr	r4, r3, r4
	mov	sl, sl, asl #1
	ldrh	r6, [r0, r6]
	ldrh	sl, [r2, sl]
	mov	r4, r4, asl #1
	eor	r7, r7, r6
	ldrh	r6, [r1, r4]
	eor	r8, sl, r8, asl #8
	orr	r3, r3, ip
	eor	r4, r7, r6
	uxth	r8, r8
	eor	r4, r4, r8
	orr	ip, r5, ip
	mov	r6, r4, lsr #8
	mov	r3, r3, asl #1
	mov	r6, r6, asl #1
	mov	ip, ip, asl #1
	ldrh	r2, [r2, r6]
	eor	r4, r2, r4, asl #8
	ldrh	r2, [r1, r3]
	ldrh	r3, [r0, ip]
	uxth	r4, r4
	eor	r0, r2, r3
	eor	r0, r0, r4
	ldmfd	sp!, {r4, r5, r6, r7, r8, sl, pc}
	.size	gf2_fast_u16_mul_m8, .-gf2_fast_u16_mul_m8
	.align	2
	.global	gf2_fast_u16_inv_m8
	.type	gf2_fast_u16_inv_m8, %function
gf2_fast_u16_inv_m8:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r1, r1, asl #1
	ldrh	r0, [r0, r1]
	bx	lr
	.size	gf2_fast_u16_inv_m8, .-gf2_fast_u16_inv_m8
	.align	2
	.global	gf2_fast_u16_div_m8
	.type	gf2_fast_u16_div_m8, %function
gf2_fast_u16_div_m8:
	@ args = 8, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	ldrh	r4, [sp, #12]
	ldrh	ip, [sp, #8]
	mov	r4, r4, asl #1
	ldrh	r3, [r3, r4]
	str	r3, [sp, #8]
	mov	r3, ip
	ldmfd	sp!, {r4, lr}
	b	gf2_fast_u16_mul_m8
	.size	gf2_fast_u16_div_m8, .-gf2_fast_u16_div_m8
	.align	2
	.global	gf2_fast_u32_init_m1
	.type	gf2_fast_u32_init_m1, %function
gf2_fast_u32_init_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r3, r4, r5, r6, r7, r8, sl, lr}
	mov	r4, r0
	mov	r0, #67108864
	mov	r5, r1
	mov	r6, r2
	bl	malloc
	str	r0, [r5, #0]
	mov	r0, #1024
	bl	malloc
	str	r0, [r6, #0]
	ldr	r5, [r5, #0]
	cmp	r5, #0
	beq	.L539
	cmp	r0, #0
	bne	.L540
	mov	r0, r5
	bl	free
.L539:
	ldr	r0, [r6, #0]
	cmp	r0, #0
	beq	.L561
	bl	free
	mvn	r0, #0
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, sl, pc}
.L540:
	mov	ip, r5
	mov	r3, #1
	mov	r2, #0
	str	r2, [r5, #0]
	str	r2, [r0, #0]
.L558:
	mov	r1, r3, asl #25
	tst	r3, #128
	eorne	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	add	r3, r3, #1
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r3, #256
	str	r2, [ip, #4]!
	str	r1, [r0, #4]!
	bne	.L558
	mov	r4, #1
	mov	r8, #0
.L560:
	mov	r7, r4, asl #8
	mov	r6, #1
	str	r8, [r5, r7, asl #2]
.L559:
	uxth	r1, r6
	mov	r0, r4
	bl	gf2_long_straight_multiply_u16
	orr	sl, r6, r7
	add	r6, r6, #1
	cmp	r6, #256
	str	r0, [r5, sl, asl #2]
	bne	.L559
	add	r4, r4, #1
	uxth	r4, r4
	cmp	r4, #0
	bne	.L560
	mov	r0, r4
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, sl, pc}
.L561:
	mvn	r0, #0
	ldmfd	sp!, {r3, r4, r5, r6, r7, r8, sl, pc}
	.size	gf2_fast_u32_init_m1, .-gf2_fast_u32_init_m1
	.align	2
	.global	gf2_fast_u32_deinit_m1
	.type	gf2_fast_u32_deinit_m1, %function
gf2_fast_u32_deinit_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	mov	r0, r4
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u32_deinit_m1, .-gf2_fast_u32_deinit_m1
	.align	2
	.global	gf2_fast_u32_mul_m1
	.type	gf2_fast_u32_mul_m1, %function
gf2_fast_u32_mul_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	mov	ip, r2, lsr #8
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, lr}
	bic	ip, ip, #255
	mov	sl, r3, lsr #24
	mov	r7, r3, lsr #16
	orr	r4, sl, ip
	uxtb	r7, r7
	ldr	r8, [r0, r4, asl #2]
	orr	r4, r7, ip
	mov	r5, r3, lsr #8
	ldr	r4, [r0, r4, asl #2]
	mov	r2, r2, asl #8
	eor	r8, r4, r8, asl #8
	bic	r2, r2, #-16777216
	mov	r4, r8, lsr #24
	bic	r2, r2, #255
	uxtb	r5, r5
	ldr	r9, [r1, r4, asl #2]
	orr	sl, sl, r2
	orr	r4, r5, ip
	uxtb	r3, r3
	ldr	r6, [r0, r4, asl #2]
	ldr	r4, [r0, sl, asl #2]
	orr	r7, r7, r2
	eor	r6, r6, r4
	eor	r6, r6, r8, asl #8
	eor	r6, r6, r9
	orr	ip, r3, ip
	mov	r4, r6, lsr #24
	ldr	ip, [r0, ip, asl #2]
	ldr	r8, [r1, r4, asl #2]
	ldr	r4, [r0, r7, asl #2]
	orr	r5, r5, r2
	eor	r4, r4, ip
	eor	r4, r4, r6, asl #8
	eor	r4, r4, r8
	orr	r3, r3, r2
	mov	ip, r4, lsr #24
	ldr	r6, [r1, ip, asl #2]
	ldr	ip, [r0, r5, asl #2]
	ldr	r0, [r0, r3, asl #2]
	eor	ip, ip, r4, asl #8
	eor	ip, ip, r6
	eor	r0, r0, ip, asl #8
	mov	ip, ip, lsr #24
	ldr	r3, [r1, ip, asl #2]
	eor	r0, r0, r3
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
	.size	gf2_fast_u32_mul_m1, .-gf2_fast_u32_mul_m1
	.align	2
	.global	gf2_fast_u32_inv_m1
	.type	gf2_fast_u32_inv_m1, %function
gf2_fast_u32_inv_m1:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	b	gf2_long_mod_inverse_u32
	.size	gf2_fast_u32_inv_m1, .-gf2_fast_u32_inv_m1
	.align	2
	.global	gf2_fast_u32_div_m1
	.type	gf2_fast_u32_div_m1, %function
gf2_fast_u32_div_m1:
	@ args = 4, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, lr}
	mov	r5, r0
	mov	r4, r1
	mov	r0, r3
	ldr	r1, [sp, #16]
	mov	r6, r2
	bl	gf2_long_mod_inverse_u32
	mov	r1, r4
	mov	r2, r6
	mov	r3, r0
	mov	r0, r5
	ldmfd	sp!, {r4, r5, r6, lr}
	b	gf2_fast_u32_mul_m1
	.size	gf2_fast_u32_div_m1, .-gf2_fast_u32_div_m1
	.align	2
	.global	gf2_fast_u32_init_m2
	.type	gf2_fast_u32_init_m2, %function
gf2_fast_u32_init_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, lr}
	mov	r4, r0
	mov	r0, #131072
	mov	r5, r1
	mov	r6, r2
	bl	malloc
	str	r0, [r5, #0]
	mov	r0, #1024
	bl	malloc
	str	r0, [r6, #0]
	ldr	r5, [r5, #0]
	cmp	r5, #0
	beq	.L570
	cmp	r0, #0
	bne	.L571
	mov	r0, r5
	bl	free
.L570:
	ldr	r0, [r6, #0]
	cmp	r0, #0
	beq	.L592
	bl	free
	mvn	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L571:
	mov	ip, r5
	mov	r3, #1
	mov	r2, #0
	strh	r2, [r5, #0]	@ movhi
	str	r2, [r0, #0]
.L589:
	mov	r1, r3, asl #25
	tst	r3, #128
	eorne	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r1, #0
	add	r3, r3, #1
	mov	r1, r1, asl #1
	eorlt	r1, r1, r4
	cmp	r3, #256
	strh	r2, [ip, #2]!	@ movhi
	str	r1, [r0, #4]!
	bne	.L589
	mov	r4, #1
	mov	r7, #0
.L591:
	mov	r3, r4, asl #9
	mov	sl, r4, asl #8
	mov	r6, #1
	uxtb	r8, r4
	strh	r7, [r5, r3]	@ movhi
.L590:
	uxtb	r1, r6
	mov	r0, r8
	bl	gf2_long_straight_multiply_u8
	orr	r9, r6, sl
	add	r6, r6, #1
	mov	r9, r9, asl #1
	cmp	r6, #256
	strh	r0, [r5, r9]	@ movhi
	bne	.L590
	add	r4, r4, #1
	cmp	r4, #256
	bne	.L591
	mov	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
.L592:
	mvn	r0, #0
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, pc}
	.size	gf2_fast_u32_init_m2, .-gf2_fast_u32_init_m2
	.align	2
	.global	gf2_fast_u32_deinit_m2
	.type	gf2_fast_u32_deinit_m2, %function
gf2_fast_u32_deinit_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, lr}
	mov	r4, r1
	bl	free
	mov	r0, r4
	ldmfd	sp!, {r4, lr}
	b	free
	.size	gf2_fast_u32_deinit_m2, .-gf2_fast_u32_deinit_m2
	.align	2
	.global	gf2_fast_u32_mul_m2
	.type	gf2_fast_u32_mul_m2, %function
gf2_fast_u32_mul_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r7, r2, lsr #16
	mov	r8, r3, lsr #24
	and	r7, r7, #65280
	orr	sl, r8, r7
	mov	r6, r3, lsr #16
	mov	sl, sl, asl #1
	uxtb	r6, r6
	ldrh	fp, [r0, sl]
	orr	sl, r6, r7
	mov	r5, r2, lsr #8
	mov	sl, sl, asl #1
	and	r5, r5, #65280
	ldrh	sl, [r0, sl]
	mov	r4, r3, lsr #8
	uxth	r2, r2
	eor	fp, sl, fp, asl #8
	orr	sl, r8, r5
	uxtb	r4, r4
	mov	sl, sl, asl #1
	and	ip, r2, #65280
	ldrh	sl, [r0, sl]
	uxtb	r3, r3
	mov	r2, r2, asl #8
	eor	fp, fp, sl
	orr	sl, r4, r7
	orr	r7, r3, r7
	mov	sl, sl, asl #1
	uxth	r2, r2
	ldrh	r9, [r0, sl]
	orr	sl, r6, r5
	mov	r7, r7, asl #1
	mov	sl, sl, asl #1
	ldrh	sl, [r0, sl]
	eor	r9, r9, sl
	orr	sl, r8, ip
	orr	r8, r8, r2
	mov	sl, sl, asl #1
	mov	r8, r8, asl #1
	ldrh	sl, [r0, sl]
	ldrh	r8, [r0, r8]
	eor	sl, r9, sl
	eor	sl, sl, fp, asl #8
	ldrh	fp, [r0, r7]
	orr	r7, r4, r5
	mov	r9, sl, lsr #24
	mov	r7, r7, asl #1
	eor	fp, r8, fp
	ldrh	r7, [r0, r7]
	orr	r8, r4, ip
	orr	r5, r3, r5
	eor	fp, fp, r7
	orr	r7, r6, ip
	orr	r6, r6, r2
	mov	r7, r7, asl #1
	mov	r8, r8, asl #1
	ldrh	r7, [r0, r7]
	mov	r6, r6, asl #1
	ldrh	r8, [r0, r8]
	ldrh	r6, [r0, r6]
	ldr	r9, [r1, r9, asl #2]
	eor	fp, fp, r7
	eor	fp, fp, sl, asl #8
	mov	r5, r5, asl #1
	eor	fp, fp, r9
	eor	r8, r8, r6
	ldrh	r6, [r0, r5]
	mov	r7, fp, lsr #24
	orr	r4, r4, r2
	orr	ip, r3, ip
	eor	r5, r8, r6
	ldr	r7, [r1, r7, asl #2]
	eor	r5, r5, fp, asl #8
	mov	r4, r4, asl #1
	mov	ip, ip, asl #1
	eor	r5, r5, r7
	ldrh	r4, [r0, r4]
	ldrh	ip, [r0, ip]
	orr	r3, r3, r2
	mov	r6, r5, lsr #24
	mov	r3, r3, asl #1
	ldr	r6, [r1, r6, asl #2]
	eor	ip, r4, ip
	ldrh	r0, [r0, r3]
	eor	ip, ip, r5, asl #8
	eor	ip, ip, r6
	eor	r0, r0, ip, asl #8
	mov	ip, ip, lsr #24
	ldr	r3, [r1, ip, asl #2]
	eor	r0, r0, r3
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, pc}
	.size	gf2_fast_u32_mul_m2, .-gf2_fast_u32_mul_m2
	.align	2
	.global	gf2_fast_u32_inv_m2
	.type	gf2_fast_u32_inv_m2, %function
gf2_fast_u32_inv_m2:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	b	gf2_long_mod_inverse_u32
	.size	gf2_fast_u32_inv_m2, .-gf2_fast_u32_inv_m2
	.align	2
	.global	gf2_fast_u32_div_m2
	.type	gf2_fast_u32_div_m2, %function
gf2_fast_u32_div_m2:
	@ args = 4, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, lr}
	mov	r5, r0
	mov	r4, r1
	mov	r0, r3
	ldr	r1, [sp, #16]
	mov	r6, r2
	bl	gf2_long_mod_inverse_u32
	mov	r1, r4
	mov	r2, r6
	mov	r3, r0
	mov	r0, r5
	ldmfd	sp!, {r4, r5, r6, lr}
	b	gf2_fast_u32_mul_m2
	.size	gf2_fast_u32_div_m2, .-gf2_fast_u32_div_m2
	.align	2
	.global	gf2_fast_u32_init_m3
	.type	gf2_fast_u32_init_m3, %function
gf2_fast_u32_init_m3:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r0, r1, r2, r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r4, r0
	mov	r0, #8192
	mov	r5, r1
	mov	r7, r2
	mov	r8, r3
	bl	malloc
	str	r0, [r5, #0]
	mov	r0, #8192
	bl	malloc
	str	r0, [r7, #0]
	mov	r0, #1024
	bl	malloc
	str	r0, [r8, #0]
	ldr	r5, [r5, #0]
	cmp	r5, #0
	beq	.L601
	ldr	r6, [r7, #0]
	cmp	r6, #0
	beq	.L602
	cmp	r0, #0
	bne	.L603
.L602:
	mov	r0, r5
	bl	free
.L601:
	ldr	r0, [r7, #0]
	cmp	r0, #0
	beq	.L604
	bl	free
.L604:
	ldr	r0, [r8, #0]
	cmp	r0, #0
	beq	.L625
	bl	free
	b	.L625
.L603:
	mov	r3, #0
	mov	ip, r5
	mov	r1, r6
	mov	lr, r3
	strh	r3, [r5, #0]	@ movhi
	strh	r3, [r6, #0]	@ movhi
	str	r3, [r0, #0]
.L622:
	add	r3, r3, #1
	tst	r3, #128
	mov	r2, r3, asl #25
	eorne	r2, r2, r4
	cmp	r2, #0
	mov	r2, r2, asl #1
	eorlt	r2, r2, r4
	cmp	r2, #0
	mov	r2, r2, asl #1
	eorlt	r2, r2, r4
	cmp	r2, #0
	mov	r2, r2, asl #1
	eorlt	r2, r2, r4
	cmp	r2, #0
	mov	r2, r2, asl #1
	eorlt	r2, r2, r4
	cmp	r2, #0
	mov	r2, r2, asl #1
	eorlt	r2, r2, r4
	cmp	r2, #0
	mov	r2, r2, asl #1
	eorlt	r2, r2, r4
	cmp	r2, #0
	mov	r2, r2, asl #1
	eorlt	r2, r2, r4
	cmp	r3, #255
	strh	lr, [ip, #2]!	@ movhi
	strh	lr, [r1, #2]!	@ movhi
	str	r2, [r0, #4]!
	bne	.L622
	mov	r4, #1
	mov	r8, #0
.L624:
	mov	r2, r4, asl #9
	uxtb	sl, r4
	strh	r8, [r5, r2]	@ movhi
	strh	r8, [r6, r2]	@ movhi
	mov	r2, sl, asl #4
	mov	r3, r4, asl #8
	uxtb	r2, r2
	mov	r7, #1
.L623:
	uxtb	fp, r7
	mov	r0, r2
	mov	r1, fp
	orr	r9, r7, r3
	stmia	sp, {r2, r3}
	bl	gf2_long_straight_multiply_u8
	mov	r9, r9, asl #1
	mov	r1, fp
	add	r7, r7, #1
	strh	r0, [r5, r9]	@ movhi
	mov	r0, sl
	bl	gf2_long_straight_multiply_u8
	cmp	r7, #256
	ldmia	sp, {r2, r3}
	strh	r0, [r6, r9]	@ movhi
	bne	.L623
	add	r4, r4, #1
	cmp	r4, #16
	bne	.L624
	mov	r0, #0
	b	.L605
.L625:
	mvn	r0, #0
.L605:
	ldmfd	sp!, {r1, r2, r3, r4, r5, r6, r7, r8, r9, sl, fp, pc}
	.size	gf2_fast_u32_init_m3, .-gf2_fast_u32_init_m3
	.align	2
	.global	gf2_fast_u32_deinit_m3
	.type	gf2_fast_u32_deinit_m3, %function
gf2_fast_u32_deinit_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r3, r4, r5, lr}
	mov	r4, r1
	mov	r5, r2
	bl	free
	mov	r0, r4
	bl	free
	mov	r0, r5
	ldmfd	sp!, {r3, r4, r5, lr}
	b	free
	.size	gf2_fast_u32_deinit_m3, .-gf2_fast_u32_deinit_m3
	.align	2
	.global	gf2_fast_u32_mul_m3
	.type	gf2_fast_u32_mul_m3, %function
gf2_fast_u32_mul_m3:
	@ args = 4, pretend = 0, frame = 32
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	ip, r3, lsr #12
	sub	sp, sp, #36
	and	ip, ip, #3840
	ldr	sl, [sp, #72]
	str	ip, [sp, #4]
	mov	r7, r3, lsr #20
	mov	r8, r3, lsr #16
	mov	r6, r3, lsr #8
	mov	ip, r3, lsr #4
	uxth	r3, r3
	and	ip, ip, #3840
	str	ip, [sp, #8]
	and	r4, r3, #3840
	mov	ip, r3, asl #4
	mov	r3, r3, asl #8
	mov	r5, sl, lsr #24
	and	r7, r7, #3840
	and	r8, r8, #3840
	and	ip, ip, #3840
	and	r3, r3, #3840
	str	r4, [sp, #12]
	str	ip, [sp, #16]
	str	r3, [sp, #20]
	orr	r9, r5, r8
	uxtb	r3, sl
	mov	r4, sl, lsr #16
	mov	ip, sl, lsr #8
	orr	sl, r5, r7
	mov	r9, r9, asl #1
	mov	sl, sl, asl #1
	ldrh	fp, [r1, r9]
	ldrh	sl, [r0, sl]
	uxtb	r4, r4
	orr	r9, r4, r8
	eor	fp, fp, sl
	orr	sl, r4, r7
	mov	r9, r9, asl #1
	mov	sl, sl, asl #1
	ldrh	r9, [r1, r9]
	ldrh	sl, [r0, sl]
	and	r6, r6, #3840
	uxtb	ip, ip
	eor	sl, r9, sl
	eor	sl, sl, fp, asl #8
	ldr	fp, [sp, #4]
	str	sl, [sp, #24]
	orr	r9, r5, r6
	orr	sl, r5, fp
	mov	r9, r9, asl #1
	mov	sl, sl, asl #1
	ldrh	fp, [r1, r9]
	ldrh	sl, [r0, sl]
	ldr	r9, [sp, #24]
	eor	fp, fp, sl
	eor	fp, r9, fp
	orr	sl, ip, r7
	orr	r9, ip, r8
	mov	sl, sl, asl #1
	mov	r9, r9, asl #1
	str	fp, [sp, #24]
	ldrh	sl, [r0, sl]
	ldrh	fp, [r1, r9]
	orr	r9, r4, r6
	orr	r8, r3, r8
	eor	sl, fp, sl
	ldr	fp, [sp, #4]
	str	sl, [sp, #28]
	orr	sl, r4, fp
	mov	r9, r9, asl #1
	mov	sl, sl, asl #1
	ldrh	r9, [r1, r9]
	ldrh	sl, [r0, sl]
	ldr	fp, [sp, #8]
	orr	r7, r3, r7
	eor	sl, r9, sl
	ldr	r9, [sp, #28]
	mov	r7, r7, asl #1
	eor	sl, r9, sl
	str	sl, [sp, #28]
	ldr	sl, [sp, #12]
	mov	r8, r8, asl #1
	orr	r9, r5, sl
	orr	sl, r5, fp
	mov	r9, r9, asl #1
	mov	sl, sl, asl #1
	ldrh	fp, [r1, r9]
	ldrh	sl, [r0, sl]
	ldr	r9, [sp, #28]
	ldrh	r8, [r1, r8]
	eor	fp, fp, sl
	ldr	sl, [sp, #24]
	eor	fp, r9, fp
	ldr	r9, [sp, #20]
	eor	fp, fp, sl, asl #8
	mov	sl, fp, lsr #24
	ldr	sl, [r2, sl, asl #2]
	str	sl, [sp, #24]
	orr	sl, r5, r9
	ldr	r9, [sp, #16]
	mov	sl, sl, asl #1
	orr	r5, r5, r9
	ldrh	sl, [r1, sl]
	mov	r5, r5, asl #1
	ldr	r9, [sp, #12]
	ldrh	r5, [r0, r5]
	eor	r5, sl, r5
	ldrh	sl, [r0, r7]
	orr	r7, ip, r6
	orr	r6, r3, r6
	eor	sl, r8, sl
	ldr	r8, [sp, #4]
	eor	sl, r5, sl
	orr	r5, ip, r8
	mov	r7, r7, asl #1
	mov	r5, r5, asl #1
	ldrh	r7, [r1, r7]
	ldrh	r5, [r0, r5]
	orr	r8, r4, r9
	mov	r6, r6, asl #1
	eor	r5, r7, r5
	eor	r5, sl, r5
	ldr	sl, [sp, #8]
	mov	r8, r8, asl #1
	orr	r7, r4, sl
	ldrh	r8, [r1, r8]
	mov	r7, r7, asl #1
	ldrh	r6, [r1, r6]
	ldrh	r7, [r0, r7]
	eor	r7, r8, r7
	eor	r7, r5, r7
	orr	r8, ip, r9
	eor	fp, r7, fp, asl #8
	orr	r7, ip, sl
	mov	r8, r8, asl #1
	mov	r7, r7, asl #1
	ldrh	r8, [r1, r8]
	ldrh	r7, [r0, r7]
	ldr	r9, [sp, #20]
	ldr	sl, [sp, #16]
	eor	r7, r8, r7
	orr	r8, r4, r9
	orr	r4, r4, sl
	mov	r8, r8, asl #1
	mov	r4, r4, asl #1
	ldrh	r8, [r1, r8]
	ldrh	r4, [r0, r4]
	ldr	r5, [sp, #24]
	eor	r8, r8, r4
	eor	r8, r7, r8
	ldr	r7, [sp, #4]
	eor	fp, fp, r5
	orr	r4, r3, r7
	mov	r5, fp, lsr #24
	mov	r4, r4, asl #1
	ldr	r5, [r2, r5, asl #2]
	ldrh	r7, [r0, r4]
	eor	r7, r6, r7
	eor	r7, r8, r7
	eor	fp, r7, fp, asl #8
	eor	fp, fp, r5
	orr	r5, ip, r9
	orr	ip, ip, sl
	mov	r5, r5, asl #1
	mov	ip, ip, asl #1
	ldrh	r5, [r1, r5]
	ldrh	ip, [r0, ip]
	ldr	r8, [sp, #12]
	ldr	r9, [sp, #8]
	orr	r6, r3, r8
	eor	r5, r5, ip
	orr	ip, r3, r9
	mov	r6, r6, asl #1
	mov	ip, ip, asl #1
	ldrh	r6, [r1, r6]
	ldrh	ip, [r0, ip]
	mov	r4, fp, lsr #24
	ldr	sl, [sp, #20]
	eor	ip, r6, ip
	eor	r5, r5, ip
	eor	r5, r5, fp, asl #8
	ldr	fp, [sp, #16]
	orr	ip, r3, sl
	orr	r3, r3, fp
	mov	ip, ip, asl #1
	mov	r3, r3, asl #1
	ldr	r4, [r2, r4, asl #2]
	ldrh	r3, [r0, r3]
	ldrh	r1, [r1, ip]
	eor	r5, r5, r4
	eor	r0, r1, r3
	eor	r0, r0, r5, asl #8
	mov	r5, r5, lsr #24
	ldr	r3, [r2, r5, asl #2]
	eor	r0, r0, r3
	add	sp, sp, #36
	ldmfd	sp!, {r4, r5, r6, r7, r8, r9, sl, fp, pc}
	.size	gf2_fast_u32_mul_m3, .-gf2_fast_u32_mul_m3
	.align	2
	.global	gf2_fast_u32_inv_m3
	.type	gf2_fast_u32_inv_m3, %function
gf2_fast_u32_inv_m3:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	b	gf2_long_mod_inverse_u32
	.size	gf2_fast_u32_inv_m3, .-gf2_fast_u32_inv_m3
	.align	2
	.global	gf2_fast_u32_div_m3
	.type	gf2_fast_u32_div_m3, %function
gf2_fast_u32_div_m3:
	@ args = 8, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	stmfd	sp!, {r4, r5, r6, r7, r8, lr}
	mov	r5, r0
	mov	r4, r1
	ldr	r0, [sp, #24]
	ldr	r1, [sp, #28]
	mov	r7, r2
	mov	r6, r3
	bl	gf2_long_mod_inverse_u32
	mov	r1, r4
	mov	r2, r7
	mov	r3, r6
	str	r0, [sp, #24]
	mov	r0, r5
	ldmfd	sp!, {r4, r5, r6, r7, r8, lr}
	b	gf2_fast_u32_mul_m3
	.size	gf2_fast_u32_div_m3, .-gf2_fast_u32_div_m3
	.section	.rodata
.LANCHOR0 = . + 0
	.type	size_of_byte, %object
	.size	size_of_byte, 256
size_of_byte:
	.byte	0
	.byte	1
	.byte	2
	.byte	2
	.byte	3
	.byte	3
	.byte	3
	.byte	3
	.byte	4
	.byte	4
	.byte	4
	.byte	4
	.byte	4
	.byte	4
	.byte	4
	.byte	4
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	5
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	6
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	7
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.byte	8
	.section	.rodata.str1.1,"aMS",%progbits,1
.LC0:
	.ascii	"Bad poly/generator: got product==1 (g was %u, i is "
	.ascii	"%u)\000"
.LC1:
	.ascii	"Warning: Bad poly/generator. Using fallback multipl"
	.ascii	"y.\000"
.LC2:
	.ascii	"No valid generator; using long multiply\000"
	.ident	"GCC: (Debian 4.6.3-12+rpi1) 4.6.3"
	.section	.note.GNU-stack,"",%progbits

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
	.eabi_attribute 30, 6
	.eabi_attribute 18, 4
	.file	"fast_gf2.c"
	.text
	.align	2
	.global	gf2_swab_u16
	.type	gf2_swab_u16, %function
gf2_swab_u16:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	mov	r3, r0
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-6]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	uxth	r2, r3
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #8
	uxth	r3, r3
	orr	r3, r2, r3
	uxth	r3, r3
	uxth	r3, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_swab_u16, .-gf2_swab_u16
	.align	2
	.global	gf2_swab_u32
	.type	gf2_swab_u32, %function
gf2_swab_u32:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	ldr	r3, [fp, #-8]
	mov	r2, r3, lsr #24
	ldr	r3, [fp, #-8]
	mov	r3, r3, lsr #8
	and	r3, r3, #65280
	orr	r2, r2, r3
	ldr	r3, [fp, #-8]
	mov	r3, r3, asl #8
	and	r3, r3, #16711680
	orr	r2, r2, r3
	ldr	r3, [fp, #-8]
	mov	r3, r3, asl #24
	orr	r3, r2, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_swab_u32, .-gf2_swab_u32
	.align	2
	.global	gf2_long_mod_multiply_u8
	.type	gf2_long_mod_multiply_u8, %function
gf2_long_mod_multiply_u8:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	mov	r3, r2
	mov	r2, r0
	strb	r2, [fp, #-13]
	mov	r2, r1
	strb	r2, [fp, #-14]
	strb	r3, [fp, #-15]
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	and	r3, r3, #1
	uxtb	r3, r3
	cmp	r3, #0
	beq	.L4
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	b	.L5
.L4:
	mov	r3, #0
.L5:
	strb	r3, [fp, #-5]
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	sxtb	r3, r3
	cmp	r3, #0
	bge	.L6
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	uxtb	r2, r3
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-13]
	b	.L7
.L6:
	ldrb	r3, [fp, #-13]
	mov	r3, r3, asl #1
	strb	r3, [fp, #-13]
.L7:
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	and	r3, r3, #2
	cmp	r3, #0
	beq	.L8
	ldrb	r2, [fp, #-5]
	ldrb	r3, [fp, #-13]
	eor	r3, r2, r3
	strb	r3, [fp, #-5]
.L8:
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	sxtb	r3, r3
	cmp	r3, #0
	bge	.L9
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	uxtb	r2, r3
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-13]
	b	.L10
.L9:
	ldrb	r3, [fp, #-13]
	mov	r3, r3, asl #1
	strb	r3, [fp, #-13]
.L10:
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	and	r3, r3, #4
	cmp	r3, #0
	beq	.L11
	ldrb	r2, [fp, #-5]
	ldrb	r3, [fp, #-13]
	eor	r3, r2, r3
	strb	r3, [fp, #-5]
.L11:
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	sxtb	r3, r3
	cmp	r3, #0
	bge	.L12
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	uxtb	r2, r3
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-13]
	b	.L13
.L12:
	ldrb	r3, [fp, #-13]
	mov	r3, r3, asl #1
	strb	r3, [fp, #-13]
.L13:
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	and	r3, r3, #8
	cmp	r3, #0
	beq	.L14
	ldrb	r2, [fp, #-5]
	ldrb	r3, [fp, #-13]
	eor	r3, r2, r3
	strb	r3, [fp, #-5]
.L14:
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	sxtb	r3, r3
	cmp	r3, #0
	bge	.L15
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	uxtb	r2, r3
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-13]
	b	.L16
.L15:
	ldrb	r3, [fp, #-13]
	mov	r3, r3, asl #1
	strb	r3, [fp, #-13]
.L16:
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	and	r3, r3, #16
	cmp	r3, #0
	beq	.L17
	ldrb	r2, [fp, #-5]
	ldrb	r3, [fp, #-13]
	eor	r3, r2, r3
	strb	r3, [fp, #-5]
.L17:
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	sxtb	r3, r3
	cmp	r3, #0
	bge	.L18
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	uxtb	r2, r3
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-13]
	b	.L19
.L18:
	ldrb	r3, [fp, #-13]
	mov	r3, r3, asl #1
	strb	r3, [fp, #-13]
.L19:
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	and	r3, r3, #32
	cmp	r3, #0
	beq	.L20
	ldrb	r2, [fp, #-5]
	ldrb	r3, [fp, #-13]
	eor	r3, r2, r3
	strb	r3, [fp, #-5]
.L20:
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	sxtb	r3, r3
	cmp	r3, #0
	bge	.L21
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	uxtb	r2, r3
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-13]
	b	.L22
.L21:
	ldrb	r3, [fp, #-13]
	mov	r3, r3, asl #1
	strb	r3, [fp, #-13]
.L22:
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	and	r3, r3, #64
	cmp	r3, #0
	beq	.L23
	ldrb	r2, [fp, #-5]
	ldrb	r3, [fp, #-13]
	eor	r3, r2, r3
	strb	r3, [fp, #-5]
.L23:
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	sxtb	r3, r3
	cmp	r3, #0
	bge	.L24
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	sxtb	r3, r3
	cmp	r3, #0
	bge	.L25
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	uxtb	r2, r3
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	b	.L26
.L25:
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	uxtb	r3, r3
.L26:
	ldrb	r1, [fp, #-5]	@ zero_extendqisi2
	mov	r2, r3
	mov	r3, r1
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-5]
.L24:
	ldrb	r3, [fp, #-5]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_long_mod_multiply_u8, .-gf2_long_mod_multiply_u8
	.align	2
	.global	gf2_long_mod_multiply_u16
	.type	gf2_long_mod_multiply_u16, %function
gf2_long_mod_multiply_u16:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	mov	r3, r2
	strh	r0, [fp, #-14]	@ movhi
	strh	r1, [fp, #-16]	@ movhi
	strh	r3, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #-16]
	and	r3, r3, #1
	uxtb	r3, r3
	cmp	r3, #0
	beq	.L28
	ldrh	r3, [fp, #-14]
	b	.L29
.L28:
	mov	r3, #0
.L29:
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L30
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L31
.L30:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L31:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #2
	cmp	r3, #0
	beq	.L32
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L32:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L33
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L34
.L33:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L34:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #4
	cmp	r3, #0
	beq	.L35
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L35:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L36
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L37
.L36:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L37:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #8
	cmp	r3, #0
	beq	.L38
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L38:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L39
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L40
.L39:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L40:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #16
	cmp	r3, #0
	beq	.L41
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L41:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L42
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L43
.L42:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L43:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #32
	cmp	r3, #0
	beq	.L44
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L44:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L45
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L46
.L45:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L46:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #64
	cmp	r3, #0
	beq	.L47
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L47:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L48
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L49
.L48:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L49:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #128
	cmp	r3, #0
	beq	.L50
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L50:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L51
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L52
.L51:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L52:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #256
	cmp	r3, #0
	beq	.L53
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L53:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L54
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L55
.L54:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L55:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #512
	cmp	r3, #0
	beq	.L56
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L56:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L57
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L58
.L57:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L58:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #1024
	cmp	r3, #0
	beq	.L59
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L59:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L60
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L61
.L60:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L61:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #2048
	cmp	r3, #0
	beq	.L62
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L62:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L63
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L64
.L63:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L64:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #4096
	cmp	r3, #0
	beq	.L65
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L65:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L66
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L67
.L66:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L67:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #8192
	cmp	r3, #0
	beq	.L68
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L68:
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L69
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	b	.L70
.L69:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
.L70:
	ldrh	r3, [fp, #-16]
	and	r3, r3, #16384
	cmp	r3, #0
	beq	.L71
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
.L71:
	ldrh	r3, [fp, #-16]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L72
	ldrh	r3, [fp, #-14]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L73
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	b	.L74
.L73:
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	uxth	r3, r3
.L74:
	ldrh	r1, [fp, #-6]
	mov	r2, r3	@ movhi
	mov	r3, r1	@ movhi
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
.L72:
	ldrh	r3, [fp, #-6]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_long_mod_multiply_u16, .-gf2_long_mod_multiply_u16
	.align	2
	.global	gf2_long_mod_multiply_u32
	.type	gf2_long_mod_multiply_u32, %function
gf2_long_mod_multiply_u32:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	str	r2, [fp, #-24]
	ldr	r3, [fp, #-20]
	and	r3, r3, #1
	uxtb	r3, r3
	cmp	r3, #0
	beq	.L76
	ldr	r3, [fp, #-16]
	b	.L77
.L76:
	mov	r3, #0
.L77:
	str	r3, [fp, #-8]
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L78
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L79
.L78:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L79:
	ldr	r3, [fp, #-20]
	and	r3, r3, #2
	cmp	r3, #0
	beq	.L80
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L80:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L81
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L82
.L81:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L82:
	ldr	r3, [fp, #-20]
	and	r3, r3, #4
	cmp	r3, #0
	beq	.L83
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L83:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L84
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L85
.L84:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L85:
	ldr	r3, [fp, #-20]
	and	r3, r3, #8
	cmp	r3, #0
	beq	.L86
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L86:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L87
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L88
.L87:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L88:
	ldr	r3, [fp, #-20]
	and	r3, r3, #16
	cmp	r3, #0
	beq	.L89
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L89:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L90
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L91
.L90:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L91:
	ldr	r3, [fp, #-20]
	and	r3, r3, #32
	cmp	r3, #0
	beq	.L92
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L92:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L93
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L94
.L93:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L94:
	ldr	r3, [fp, #-20]
	and	r3, r3, #64
	cmp	r3, #0
	beq	.L95
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L95:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L96
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L97
.L96:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L97:
	ldr	r3, [fp, #-20]
	and	r3, r3, #128
	cmp	r3, #0
	beq	.L98
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L98:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L99
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L100
.L99:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L100:
	ldr	r3, [fp, #-20]
	and	r3, r3, #256
	cmp	r3, #0
	beq	.L101
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L101:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L102
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L103
.L102:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L103:
	ldr	r3, [fp, #-20]
	and	r3, r3, #512
	cmp	r3, #0
	beq	.L104
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L104:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L105
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L106
.L105:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L106:
	ldr	r3, [fp, #-20]
	and	r3, r3, #1024
	cmp	r3, #0
	beq	.L107
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L107:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L108
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L109
.L108:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L109:
	ldr	r3, [fp, #-20]
	and	r3, r3, #2048
	cmp	r3, #0
	beq	.L110
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L110:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L111
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L112
.L111:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L112:
	ldr	r3, [fp, #-20]
	and	r3, r3, #4096
	cmp	r3, #0
	beq	.L113
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L113:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L114
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L115
.L114:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L115:
	ldr	r3, [fp, #-20]
	and	r3, r3, #8192
	cmp	r3, #0
	beq	.L116
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L116:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L117
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L118
.L117:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L118:
	ldr	r3, [fp, #-20]
	and	r3, r3, #16384
	cmp	r3, #0
	beq	.L119
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L119:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L120
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L121
.L120:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L121:
	ldr	r3, [fp, #-20]
	and	r3, r3, #32768
	cmp	r3, #0
	beq	.L122
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L122:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L123
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L124
.L123:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L124:
	ldr	r3, [fp, #-20]
	and	r3, r3, #65536
	cmp	r3, #0
	beq	.L125
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L125:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L126
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L127
.L126:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L127:
	ldr	r3, [fp, #-20]
	and	r3, r3, #131072
	cmp	r3, #0
	beq	.L128
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L128:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L129
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L130
.L129:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L130:
	ldr	r3, [fp, #-20]
	and	r3, r3, #262144
	cmp	r3, #0
	beq	.L131
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L131:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L132
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L133
.L132:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L133:
	ldr	r3, [fp, #-20]
	and	r3, r3, #524288
	cmp	r3, #0
	beq	.L134
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L134:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L135
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L136
.L135:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L136:
	ldr	r3, [fp, #-20]
	and	r3, r3, #1048576
	cmp	r3, #0
	beq	.L137
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L137:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L138
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L139
.L138:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L139:
	ldr	r3, [fp, #-20]
	and	r3, r3, #2097152
	cmp	r3, #0
	beq	.L140
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L140:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L141
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L142
.L141:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L142:
	ldr	r3, [fp, #-20]
	and	r3, r3, #4194304
	cmp	r3, #0
	beq	.L143
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L143:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L144
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L145
.L144:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L145:
	ldr	r3, [fp, #-20]
	and	r3, r3, #8388608
	cmp	r3, #0
	beq	.L146
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L146:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L147
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L148
.L147:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L148:
	ldr	r3, [fp, #-20]
	and	r3, r3, #16777216
	cmp	r3, #0
	beq	.L149
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L149:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L150
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L151
.L150:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L151:
	ldr	r3, [fp, #-20]
	and	r3, r3, #33554432
	cmp	r3, #0
	beq	.L152
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L152:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L153
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L154
.L153:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L154:
	ldr	r3, [fp, #-20]
	and	r3, r3, #67108864
	cmp	r3, #0
	beq	.L155
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L155:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L156
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L157
.L156:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L157:
	ldr	r3, [fp, #-20]
	and	r3, r3, #134217728
	cmp	r3, #0
	beq	.L158
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L158:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L159
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L160
.L159:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L160:
	ldr	r3, [fp, #-20]
	and	r3, r3, #268435456
	cmp	r3, #0
	beq	.L161
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L161:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L162
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L163
.L162:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L163:
	ldr	r3, [fp, #-20]
	and	r3, r3, #536870912
	cmp	r3, #0
	beq	.L164
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L164:
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L165
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	b	.L166
.L165:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	str	r3, [fp, #-16]
.L166:
	ldr	r3, [fp, #-20]
	and	r3, r3, #1073741824
	cmp	r3, #0
	beq	.L167
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L167:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L168
	ldr	r3, [fp, #-16]
	cmp	r3, #0
	bge	.L169
	ldr	r3, [fp, #-16]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	b	.L170
.L169:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
.L170:
	ldr	r2, [fp, #-8]
	eor	r3, r2, r3
	str	r3, [fp, #-8]
.L168:
	ldr	r3, [fp, #-8]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_long_mod_multiply_u32, .-gf2_long_mod_multiply_u32
	.align	2
	.global	gf2_long_straight_multiply_u8
	.type	gf2_long_straight_multiply_u8, %function
gf2_long_straight_multiply_u8:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	mov	r2, r0
	mov	r3, r1
	strb	r2, [fp, #-13]
	strb	r3, [fp, #-14]
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	strh	r3, [fp, #-6]	@ movhi
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	and	r3, r3, #1
	uxtb	r3, r3
	cmp	r3, #0
	beq	.L172
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	uxth	r3, r3
	b	.L173
.L172:
	mov	r3, #0
.L173:
	strh	r3, [fp, #-8]	@ movhi
	mov	r3, #2
	strb	r3, [fp, #-9]
.L175:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
	ldrb	r2, [fp, #-14]
	ldrb	r3, [fp, #-9]
	and	r3, r2, r3
	uxtb	r3, r3
	cmp	r3, #0
	beq	.L174
	ldrh	r2, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-6]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-8]	@ movhi
.L174:
	ldrb	r3, [fp, #-9]
	mov	r3, r3, asl #1
	strb	r3, [fp, #-9]
	ldrb	r3, [fp, #-9]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L175
	ldrh	r3, [fp, #-8]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_long_straight_multiply_u8, .-gf2_long_straight_multiply_u8
	.align	2
	.global	gf2_long_straight_multiply_u16
	.type	gf2_long_straight_multiply_u16, %function
gf2_long_straight_multiply_u16:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	mov	r2, r0
	mov	r3, r1
	strh	r2, [fp, #-22]	@ movhi
	strh	r3, [fp, #-24]	@ movhi
	ldrh	r3, [fp, #-22]
	str	r3, [fp, #-8]
	ldrh	r3, [fp, #-24]
	and	r3, r3, #1
	uxtb	r3, r3
	cmp	r3, #0
	beq	.L177
	ldrh	r3, [fp, #-22]
	b	.L178
.L177:
	mov	r3, #0
.L178:
	str	r3, [fp, #-12]
	mov	r3, #2
	strh	r3, [fp, #-14]	@ movhi
.L180:
	ldr	r3, [fp, #-8]
	mov	r3, r3, asl #1
	str	r3, [fp, #-8]
	ldrh	r2, [fp, #-24]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	and	r3, r2, r3
	uxth	r3, r3
	cmp	r3, #0
	beq	.L179
	ldr	r2, [fp, #-12]
	ldr	r3, [fp, #-8]
	eor	r3, r2, r3
	str	r3, [fp, #-12]
.L179:
	ldrh	r3, [fp, #-14]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #-14]
	cmp	r3, #0
	bne	.L180
	ldr	r3, [fp, #-12]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_long_straight_multiply_u16, .-gf2_long_straight_multiply_u16
	.data
	.align	2
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
	.text
	.align	2
	.global	size_in_bits_u8
	.type	size_in_bits_u8, %function
size_in_bits_u8:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	mov	r3, r0
	strb	r3, [fp, #-5]
	ldrb	r3, [fp, #-5]	@ zero_extendqisi2
	ldr	r2, .L182
	ldrb	r3, [r2, r3]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
.L183:
	.align	2
.L182:
	.word	size_of_byte
	.size	size_in_bits_u8, .-size_in_bits_u8
	.align	2
	.global	size_in_bits_u16
	.type	size_in_bits_u16, %function
size_in_bits_u16:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	mov	r3, r0
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-6]
	and	r3, r3, #65280
	cmp	r3, #0
	beq	.L185
	ldrh	r3, [fp, #-6]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	ldr	r2, .L187
	ldrb	r3, [r2, r3]	@ zero_extendqisi2
	add	r3, r3, #8
	b	.L186
.L185:
	ldrh	r3, [fp, #-6]
	ldr	r2, .L187
	ldrb	r3, [r2, r3]	@ zero_extendqisi2
.L186:
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
.L188:
	.align	2
.L187:
	.word	size_of_byte
	.size	size_in_bits_u16, .-size_in_bits_u16
	.align	2
	.global	size_in_bits_u32
	.type	size_in_bits_u32, %function
size_in_bits_u32:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	ldr	r3, [fp, #-8]
	and	r3, r3, #-16777216
	cmp	r3, #0
	beq	.L190
	ldr	r3, [fp, #-8]
	mov	r3, r3, lsr #24
	ldr	r2, .L194
	ldrb	r3, [r2, r3]	@ zero_extendqisi2
	add	r3, r3, #24
	b	.L191
.L190:
	ldr	r3, [fp, #-8]
	and	r3, r3, #16711680
	cmp	r3, #0
	beq	.L192
	ldr	r3, [fp, #-8]
	mov	r3, r3, lsr #16
	ldr	r2, .L194
	ldrb	r3, [r2, r3]	@ zero_extendqisi2
	add	r3, r3, #16
	b	.L191
.L192:
	ldr	r3, [fp, #-8]
	and	r3, r3, #65280
	cmp	r3, #0
	beq	.L193
	ldr	r3, [fp, #-8]
	mov	r3, r3, lsr #8
	ldr	r2, .L194
	ldrb	r3, [r2, r3]	@ zero_extendqisi2
	add	r3, r3, #8
	b	.L191
.L193:
	ldr	r2, .L194
	ldr	r3, [fp, #-8]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
.L191:
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
.L195:
	.align	2
.L194:
	.word	size_of_byte
	.size	size_in_bits_u32, .-size_in_bits_u32
	.align	2
	.global	gf2_long_mod_inverse_u8
	.type	gf2_long_mod_inverse_u8, %function
gf2_long_mod_inverse_u8:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #28
	mov	r2, r0
	mov	r3, r1
	strb	r2, [fp, #-29]
	strb	r3, [fp, #-30]
	ldrb	r3, [fp, #-29]	@ zero_extendqisi2
	cmp	r3, #1
	bhi	.L197
	ldrb	r3, [fp, #-29]	@ zero_extendqisi2
	b	.L198
.L197:
	ldrb	r3, [fp, #-30]
	strb	r3, [fp, #-13]
	ldrb	r3, [fp, #-29]
	strb	r3, [fp, #-14]
	mov	r3, #0
	strb	r3, [fp, #-15]
	mov	r3, #1
	strb	r3, [fp, #-16]
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	mov	r0, r3
	bl	size_in_bits_u8
	mov	r3, r0
	rsb	r3, r3, #9
	str	r3, [fp, #-20]
	ldrb	r2, [fp, #-14]	@ zero_extendqisi2
	ldr	r3, [fp, #-20]
	mov	r3, r2, asl r3
	uxtb	r2, r3
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-13]
	ldrb	r2, [fp, #-16]	@ zero_extendqisi2
	ldr	r3, [fp, #-20]
	mov	r3, r2, asl r3
	uxtb	r2, r3
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-15]
	b	.L199
.L201:
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r0, r3
	bl	size_in_bits_u8
	mov	r4, r0
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	mov	r0, r3
	bl	size_in_bits_u8
	mov	r3, r0
	rsb	r3, r3, r4
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L200
	ldrb	r3, [fp, #-13]
	strb	r3, [fp, #-21]
	ldrb	r3, [fp, #-14]
	strb	r3, [fp, #-13]
	ldrb	r3, [fp, #-21]
	strb	r3, [fp, #-14]
	ldrb	r3, [fp, #-15]
	strb	r3, [fp, #-21]
	ldrb	r3, [fp, #-16]
	strb	r3, [fp, #-15]
	ldrb	r3, [fp, #-21]
	strb	r3, [fp, #-16]
	ldr	r3, [fp, #-20]
	rsb	r3, r3, #0
	str	r3, [fp, #-20]
.L200:
	ldrb	r2, [fp, #-14]	@ zero_extendqisi2
	ldr	r3, [fp, #-20]
	mov	r3, r2, asl r3
	uxtb	r2, r3
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-13]
	ldrb	r2, [fp, #-16]	@ zero_extendqisi2
	ldr	r3, [fp, #-20]
	mov	r3, r2, asl r3
	uxtb	r2, r3
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
	eor	r3, r2, r3
	uxtb	r3, r3
	strb	r3, [fp, #-15]
.L199:
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	cmp	r3, #1
	bne	.L201
	ldrb	r3, [fp, #-15]	@ zero_extendqisi2
.L198:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_long_mod_inverse_u8, .-gf2_long_mod_inverse_u8
	.align	2
	.global	gf2_long_mod_inverse_u16
	.type	gf2_long_mod_inverse_u16, %function
gf2_long_mod_inverse_u16:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #28
	mov	r2, r0
	mov	r3, r1
	strh	r2, [fp, #-30]	@ movhi
	strh	r3, [fp, #-32]	@ movhi
	ldrh	r3, [fp, #-30]
	cmp	r3, #1
	bhi	.L203
	ldrh	r3, [fp, #-30]
	b	.L204
.L203:
	ldrh	r3, [fp, #-32]	@ movhi
	strh	r3, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #-30]	@ movhi
	strh	r3, [fp, #-16]	@ movhi
	mov	r3, #0
	strh	r3, [fp, #-18]	@ movhi
	mov	r3, #1
	strh	r3, [fp, #-20]	@ movhi
	ldrh	r3, [fp, #-16]
	mov	r0, r3
	bl	size_in_bits_u16
	mov	r3, r0
	rsb	r3, r3, #17
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-16]
	ldr	r3, [fp, #-24]
	mov	r3, r2, asl r3
	uxth	r2, r3
	ldrh	r3, [fp, #-14]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	ldrh	r2, [fp, #-20]
	ldr	r3, [fp, #-24]
	mov	r3, r2, asl r3
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	b	.L205
.L207:
	ldrh	r3, [fp, #-14]
	mov	r0, r3
	bl	size_in_bits_u16
	mov	r4, r0
	ldrh	r3, [fp, #-16]
	mov	r0, r3
	bl	size_in_bits_u16
	mov	r3, r0
	rsb	r3, r3, r4
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-24]
	cmp	r3, #0
	bge	.L206
	ldrh	r3, [fp, #-14]	@ movhi
	strh	r3, [fp, #-26]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	strh	r3, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	strh	r3, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-18]	@ movhi
	strh	r3, [fp, #-26]	@ movhi
	ldrh	r3, [fp, #-20]	@ movhi
	strh	r3, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	strh	r3, [fp, #-20]	@ movhi
	ldr	r3, [fp, #-24]
	rsb	r3, r3, #0
	str	r3, [fp, #-24]
.L206:
	ldrh	r2, [fp, #-16]
	ldr	r3, [fp, #-24]
	mov	r3, r2, asl r3
	uxth	r2, r3
	ldrh	r3, [fp, #-14]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-14]	@ movhi
	ldrh	r2, [fp, #-20]
	ldr	r3, [fp, #-24]
	mov	r3, r2, asl r3
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
.L205:
	ldrh	r3, [fp, #-14]
	cmp	r3, #1
	bne	.L207
	ldrh	r3, [fp, #-18]
.L204:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_long_mod_inverse_u16, .-gf2_long_mod_inverse_u16
	.align	2
	.global	gf2_long_mod_inverse_u32
	.type	gf2_long_mod_inverse_u32, %function
gf2_long_mod_inverse_u32:
	@ args = 0, pretend = 0, frame = 32
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #36
	str	r0, [fp, #-40]
	str	r1, [fp, #-44]
	ldr	r3, [fp, #-40]
	cmp	r3, #1
	bhi	.L209
	ldr	r3, [fp, #-40]
	b	.L210
.L209:
	ldr	r3, [fp, #-44]
	str	r3, [fp, #-16]
	ldr	r3, [fp, #-40]
	str	r3, [fp, #-20]
	mov	r3, #0
	str	r3, [fp, #-24]
	mov	r3, #1
	str	r3, [fp, #-28]
	ldr	r0, [fp, #-20]
	bl	size_in_bits_u32
	mov	r3, r0
	rsb	r3, r3, #33
	str	r3, [fp, #-32]
	ldr	r2, [fp, #-20]
	ldr	r3, [fp, #-32]
	mov	r3, r2, asl r3
	ldr	r2, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	ldr	r2, [fp, #-28]
	ldr	r3, [fp, #-32]
	mov	r3, r2, asl r3
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	b	.L211
.L213:
	ldr	r0, [fp, #-16]
	bl	size_in_bits_u32
	mov	r4, r0
	ldr	r0, [fp, #-20]
	bl	size_in_bits_u32
	mov	r3, r0
	rsb	r3, r3, r4
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	cmp	r3, #0
	bge	.L212
	ldr	r3, [fp, #-16]
	str	r3, [fp, #-36]
	ldr	r3, [fp, #-20]
	str	r3, [fp, #-16]
	ldr	r3, [fp, #-36]
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-24]
	str	r3, [fp, #-36]
	ldr	r3, [fp, #-28]
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-36]
	str	r3, [fp, #-28]
	ldr	r3, [fp, #-32]
	rsb	r3, r3, #0
	str	r3, [fp, #-32]
.L212:
	ldr	r2, [fp, #-20]
	ldr	r3, [fp, #-32]
	mov	r3, r2, asl r3
	ldr	r2, [fp, #-16]
	eor	r3, r2, r3
	str	r3, [fp, #-16]
	ldr	r2, [fp, #-28]
	ldr	r3, [fp, #-32]
	mov	r3, r2, asl r3
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
.L211:
	ldr	r3, [fp, #-16]
	cmp	r3, #1
	bne	.L213
	ldr	r3, [fp, #-24]
.L210:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_long_mod_inverse_u32, .-gf2_long_mod_inverse_u32
	.align	2
	.global	gf2_long_mod_power_u8
	.type	gf2_long_mod_power_u8, %function
gf2_long_mod_power_u8:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #20
	mov	r3, r2
	mov	r2, r0
	strb	r2, [fp, #-21]
	mov	r2, r1
	strb	r2, [fp, #-22]
	strb	r3, [fp, #-23]
	ldrb	r3, [fp, #-21]
	strb	r3, [fp, #-13]
	mvn	r3, #127
	strb	r3, [fp, #-14]
	ldrb	r3, [fp, #-22]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L215
	ldrb	r3, [fp, #-22]	@ zero_extendqisi2
	cmp	r3, #255
	bne	.L216
.L215:
	mov	r3, #1
	b	.L217
.L216:
	ldrb	r4, [fp, #-14]	@ zero_extendqisi2
	ldrb	r3, [fp, #-22]	@ zero_extendqisi2
	mov	r0, r3
	bl	size_in_bits_u8
	mov	r3, r0
	rsb	r3, r3, #8
	mov	r3, r4, asr r3
	strb	r3, [fp, #-14]
	b	.L218
.L219:
	ldrb	r1, [fp, #-13]	@ zero_extendqisi2
	ldrb	r2, [fp, #-13]	@ zero_extendqisi2
	ldrb	r3, [fp, #-23]	@ zero_extendqisi2
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u8
	mov	r3, r0
	strb	r3, [fp, #-13]
	ldrb	r2, [fp, #-22]
	ldrb	r3, [fp, #-14]
	and	r3, r2, r3
	uxtb	r3, r3
	cmp	r3, #0
	beq	.L218
	ldrb	r1, [fp, #-21]	@ zero_extendqisi2
	ldrb	r2, [fp, #-13]	@ zero_extendqisi2
	ldrb	r3, [fp, #-23]	@ zero_extendqisi2
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u8
	mov	r3, r0
	strb	r3, [fp, #-13]
.L218:
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	mov	r3, r3, lsr #1
	strb	r3, [fp, #-14]
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L219
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
.L217:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_long_mod_power_u8, .-gf2_long_mod_power_u8
	.align	2
	.global	gf2_long_mod_power_u16
	.type	gf2_long_mod_power_u16, %function
gf2_long_mod_power_u16:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #20
	mov	r3, r2
	strh	r0, [fp, #-22]	@ movhi
	strh	r1, [fp, #-24]	@ movhi
	strh	r3, [fp, #-26]	@ movhi
	ldrh	r3, [fp, #-22]	@ movhi
	strh	r3, [fp, #-14]	@ movhi
	mov	r3, #32768
	strh	r3, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-24]
	cmp	r3, #0
	beq	.L221
	ldrh	r2, [fp, #-24]
	ldr	r3, .L226
	cmp	r2, r3
	bne	.L222
.L221:
	mov	r3, #1
	b	.L223
.L222:
	ldrh	r4, [fp, #-16]
	ldrh	r3, [fp, #-24]
	mov	r0, r3
	bl	size_in_bits_u16
	mov	r3, r0
	rsb	r3, r3, #16
	mov	r3, r4, asr r3
	strh	r3, [fp, #-16]	@ movhi
	b	.L224
.L225:
	ldrh	r1, [fp, #-14]
	ldrh	r2, [fp, #-14]
	ldrh	r3, [fp, #-26]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [fp, #-14]	@ movhi
	ldrh	r2, [fp, #-24]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	and	r3, r2, r3
	uxth	r3, r3
	cmp	r3, #0
	beq	.L224
	ldrh	r1, [fp, #-22]
	ldrh	r2, [fp, #-14]
	ldrh	r3, [fp, #-26]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [fp, #-14]	@ movhi
.L224:
	ldrh	r3, [fp, #-16]
	mov	r3, r3, lsr #1
	strh	r3, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-16]
	cmp	r3, #0
	bne	.L225
	ldrh	r3, [fp, #-14]
.L223:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
.L227:
	.align	2
.L226:
	.word	65535
	.size	gf2_long_mod_power_u16, .-gf2_long_mod_power_u16
	.align	2
	.global	gf2_long_mod_power_u32
	.type	gf2_long_mod_power_u32, %function
gf2_long_mod_power_u32:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	str	r2, [fp, #-24]
	ldr	r3, [fp, #-16]
	str	r3, [fp, #-8]
	mov	r3, #-2147483648
	str	r3, [fp, #-12]
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	beq	.L229
	ldr	r3, [fp, #-20]
	cmn	r3, #1
	bne	.L230
.L229:
	mov	r3, #1
	b	.L231
.L230:
	ldr	r0, [fp, #-20]
	bl	size_in_bits_u32
	mov	r3, r0
	rsb	r3, r3, #32
	ldr	r2, [fp, #-12]
	mov	r3, r2, lsr r3
	str	r3, [fp, #-12]
	b	.L232
.L233:
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-8]
	ldr	r2, [fp, #-24]
	bl	gf2_long_mod_multiply_u32
	str	r0, [fp, #-8]
	ldr	r2, [fp, #-20]
	ldr	r3, [fp, #-12]
	and	r3, r2, r3
	cmp	r3, #0
	beq	.L232
	ldr	r0, [fp, #-16]
	ldr	r1, [fp, #-8]
	ldr	r2, [fp, #-24]
	bl	gf2_long_mod_multiply_u32
	str	r0, [fp, #-8]
.L232:
	ldr	r3, [fp, #-12]
	mov	r3, r3, lsr #1
	str	r3, [fp, #-12]
	ldr	r3, [fp, #-12]
	cmp	r3, #0
	bne	.L233
	ldr	r3, [fp, #-8]
.L231:
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_long_mod_power_u32, .-gf2_long_mod_power_u32
	.align	2
	.global	gf2_fast_u8_init_m1
	.type	gf2_fast_u8_init_m1, %function
gf2_fast_u8_init_m1:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	mov	r3, r0
	str	r1, [fp, #-20]
	str	r2, [fp, #-24]
	strb	r3, [fp, #-13]
	mov	r0, #65536
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-20]
	str	r2, [r3, #0]
	mov	r0, #256
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-24]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L235
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L236
.L235:
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L237
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L237:
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L238
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L238:
	mvn	r3, #0
	b	.L239
.L236:
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strb	r2, [r3, #0]
	mov	r3, #1
	strh	r3, [fp, #-6]	@ movhi
	b	.L240
.L241:
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-6]
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #8
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3, #0]
	ldrh	r3, [fp, #-6]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-6]	@ movhi
.L240:
	ldrh	r3, [fp, #-6]
	cmp	r3, #255
	bls	.L241
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	add	r3, r3, #256
	add	r3, r3, #1
	mov	r2, #1
	strb	r2, [r3, #0]
	mov	r3, #2
	strh	r3, [fp, #-6]	@ movhi
	b	.L242
.L243:
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-6]
	add	r3, r3, #256
	add	r3, r2, r3
	ldrh	r2, [fp, #-6]	@ movhi
	uxtb	r2, r2
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #8
	add	r3, r3, #1
	add	r3, r2, r3
	ldrh	r2, [fp, #-6]	@ movhi
	uxtb	r2, r2
	strb	r2, [r3, #0]
	ldrh	r3, [fp, #-6]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-6]	@ movhi
.L242:
	ldrh	r3, [fp, #-6]
	cmp	r3, #255
	bls	.L243
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r3, r3, #1
	mov	r2, #1
	strb	r2, [r3, #0]
	mov	r3, #2
	strh	r3, [fp, #-6]	@ movhi
	b	.L244
.L248:
	mov	r3, #2
	strh	r3, [fp, #-8]	@ movhi
	b	.L245
.L247:
	ldrh	r3, [fp, #-6]	@ movhi
	uxtb	r1, r3
	ldrh	r3, [fp, #-8]	@ movhi
	uxtb	r2, r3
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u8
	mov	r3, r0
	strb	r3, [fp, #-9]
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-6]
	mov	r1, r3, asl #8
	ldrh	r3, [fp, #-8]
	add	r3, r1, r3
	add	r3, r2, r3
	ldrb	r2, [fp, #-9]
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r1, [fp, #-6]
	ldrh	r3, [fp, #-8]
	mov	r3, r3, asl #8
	add	r3, r1, r3
	add	r3, r2, r3
	ldrb	r2, [fp, #-9]
	strb	r2, [r3, #0]
	ldrb	r3, [fp, #-9]	@ zero_extendqisi2
	cmp	r3, #1
	bne	.L246
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-6]
	add	r3, r2, r3
	ldrh	r2, [fp, #-8]	@ movhi
	uxtb	r2, r2
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-8]
	add	r3, r2, r3
	ldrh	r2, [fp, #-6]	@ movhi
	uxtb	r2, r2
	strb	r2, [r3, #0]
.L246:
	ldrh	r3, [fp, #-8]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-8]	@ movhi
.L245:
	ldrh	r2, [fp, #-8]
	ldrh	r3, [fp, #-6]
	cmp	r2, r3
	bls	.L247
	ldrh	r3, [fp, #-6]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-6]	@ movhi
.L244:
	ldrh	r3, [fp, #-6]
	cmp	r3, #255
	bls	.L248
	mov	r3, #0
.L239:
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u8_init_m1, .-gf2_fast_u8_init_m1
	.align	2
	.global	gf2_fast_u8_deinit_m1
	.type	gf2_fast_u8_deinit_m1, %function
gf2_fast_u8_deinit_m1:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u8_deinit_m1, .-gf2_fast_u8_deinit_m1
	.align	2
	.global	gf2_fast_u8_mul_m1
	.type	gf2_fast_u8_mul_m1, %function
gf2_fast_u8_mul_m1:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	mov	r3, r2
	mov	r2, r1
	strb	r2, [fp, #-9]
	strb	r3, [fp, #-10]
	ldrb	r3, [fp, #-9]	@ zero_extendqisi2
	mov	r2, r3, asl #8
	ldrb	r3, [fp, #-10]	@ zero_extendqisi2
	add	r3, r2, r3
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_mul_m1, .-gf2_fast_u8_mul_m1
	.align	2
	.global	gf2_fast_u8_inv_m1
	.type	gf2_fast_u8_inv_m1, %function
gf2_fast_u8_inv_m1:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	mov	r3, r1
	strb	r3, [fp, #-9]
	ldrb	r3, [fp, #-9]	@ zero_extendqisi2
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_inv_m1, .-gf2_fast_u8_inv_m1
	.align	2
	.global	gf2_fast_u8_div_m1
	.type	gf2_fast_u8_div_m1, %function
gf2_fast_u8_div_m1:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	strb	r2, [fp, #-13]
	strb	r3, [fp, #-14]
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r2, r3, asl #8
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	ldr	r1, [fp, #-12]
	add	r3, r1, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	add	r3, r2, r3
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_div_m1, .-gf2_fast_u8_div_m1
	.align	2
	.global	gf2_fast_u8_dpc_m1
	.type	gf2_fast_u8_dpc_m1, %function
gf2_fast_u8_dpc_m1:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	str	r2, [fp, #-24]
	str	r3, [fp, #-28]
	ldr	r3, [fp, #-20]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r2, r3
	ldr	r3, [fp, #-24]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	add	r3, r3, #8
	mov	r3, r2, asl r3
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]
	strb	r3, [fp, #-5]
	ldr	r3, [fp, #-28]
	cmp	r3, #0
	bne	.L256
	mov	r3, #0
	b	.L255
.L257:
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-20]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r2, r3
	ldr	r3, [fp, #-24]
	add	r3, r3, #1
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-24]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	add	r3, r3, #8
	mov	r3, r2, asl r3
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrb	r2, [r3, #0]	@ zero_extendqisi2
	ldrb	r3, [fp, #-5]
	eor	r3, r2, r3
	strb	r3, [fp, #-5]
.L256:
	ldr	r3, [fp, #-28]
	sub	r3, r3, #1
	str	r3, [fp, #-28]
	ldr	r3, [fp, #-28]
	cmp	r3, #0
	bne	.L257
	ldrb	r3, [fp, #-5]	@ zero_extendqisi2
.L255:
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_dpc_m1, .-gf2_fast_u8_dpc_m1
	.align	2
	.global	gf2_fast_u8_dpd_m1
	.type	gf2_fast_u8_dpd_m1, %function
gf2_fast_u8_dpd_m1:
	@ args = 8, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	str	r2, [fp, #-24]
	str	r3, [fp, #-28]
	ldr	r3, [fp, #-20]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r2, r3
	ldr	r3, [fp, #-28]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	add	r3, r3, #8
	mov	r3, r2, asl r3
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]
	strb	r3, [fp, #-5]
	ldr	r3, [fp, #8]
	cmp	r3, #0
	bne	.L261
	mov	r3, #0
	b	.L260
.L262:
	ldr	r3, [fp, #-24]
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-20]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r2, r3
	ldr	r3, [fp, #4]
	ldr	r1, [fp, #-28]
	add	r3, r1, r3
	str	r3, [fp, #-28]
	ldr	r3, [fp, #-28]
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	add	r3, r3, #8
	mov	r3, r2, asl r3
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrb	r2, [r3, #0]	@ zero_extendqisi2
	ldrb	r3, [fp, #-5]
	eor	r3, r2, r3
	strb	r3, [fp, #-5]
.L261:
	ldr	r3, [fp, #8]
	sub	r3, r3, #1
	str	r3, [fp, #8]
	ldr	r3, [fp, #8]
	cmp	r3, #0
	bne	.L262
	ldrb	r3, [fp, #-5]	@ zero_extendqisi2
.L260:
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_dpd_m1, .-gf2_fast_u8_dpd_m1
	.section	.rodata
	.align	2
.LC0:
	.ascii	"Bad poly/generator: got product==1 (g was %u, i is "
	.ascii	"%u)\000"
	.text
	.align	2
	.global	gf2_fast_u8_init_m2
	.type	gf2_fast_u8_init_m2, %function
gf2_fast_u8_init_m2:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r2, [fp, #-20]
	str	r3, [fp, #-24]
	mov	r3, r0
	strb	r3, [fp, #-13]
	mov	r3, r1
	strb	r3, [fp, #-14]
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L264
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L265
.L264:
	mvn	r3, #0
	b	.L266
.L265:
	mov	r0, #256
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-20]
	str	r2, [r3, #0]
	mov	r0, #256
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-24]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L267
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L268
.L267:
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L269
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L269:
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L270
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L270:
	mvn	r3, #0
	b	.L266
.L268:
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r2, #1
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r3, r3, #1
	ldrb	r2, [fp, #-14]
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	add	r3, r2, r3
	mov	r2, #1
	strb	r2, [r3, #0]
	ldrb	r3, [fp, #-14]
	strb	r3, [fp, #-6]
	mov	r3, #2
	strb	r3, [fp, #-5]
.L272:
	ldrb	r3, [fp, #-6]	@ zero_extendqisi2
	cmp	r3, #1
	bne	.L271
	ldr	r3, .L273
	ldr	r3, [r3, #0]
	mov	r0, r3
	ldr	r1, .L273+4
	ldrb	r2, [fp, #-6]	@ zero_extendqisi2
	ldrb	r3, [fp, #-5]	@ zero_extendqisi2
	bl	fprintf
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
	ldrb	r3, [fp, #-5]	@ zero_extendqisi2
	rsb	r3, r3, #0
	b	.L266
.L271:
	ldrb	r1, [fp, #-6]	@ zero_extendqisi2
	ldrb	r2, [fp, #-14]	@ zero_extendqisi2
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u8
	mov	r3, r0
	strb	r3, [fp, #-6]
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldrb	r3, [fp, #-5]	@ zero_extendqisi2
	add	r3, r2, r3
	ldrb	r2, [fp, #-6]
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrb	r3, [fp, #-6]	@ zero_extendqisi2
	add	r3, r2, r3
	ldrb	r2, [fp, #-5]
	strb	r2, [r3, #0]
	ldrb	r3, [fp, #-5]
	add	r3, r3, #1
	strb	r3, [fp, #-5]
	ldrb	r3, [fp, #-5]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L272
	mov	r3, #0
.L266:
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L274:
	.align	2
.L273:
	.word	stderr
	.word	.LC0
	.size	gf2_fast_u8_init_m2, .-gf2_fast_u8_init_m2
	.align	2
	.global	gf2_fast_u8_deinit_m2
	.type	gf2_fast_u8_deinit_m2, %function
gf2_fast_u8_deinit_m2:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u8_deinit_m2, .-gf2_fast_u8_deinit_m2
	.align	2
	.global	gf2_fast_u8_mul_m2
	.type	gf2_fast_u8_mul_m2, %function
gf2_fast_u8_mul_m2:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	strb	r2, [fp, #-21]
	strb	r3, [fp, #-22]
	ldrb	r3, [fp, #-21]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L277
	ldrb	r3, [fp, #-22]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L278
.L277:
	mov	r3, #0
	b	.L279
.L278:
	ldrb	r3, [fp, #-21]	@ zero_extendqisi2
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r2, r3
	ldrb	r3, [fp, #-22]	@ zero_extendqisi2
	ldr	r1, [fp, #-16]
	add	r3, r1, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	add	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-6]	@ movhi
	uxtb	r3, r3
	uxth	r2, r3
	ldrh	r3, [fp, #-6]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	add	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-6]
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
.L279:
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_mul_m2, .-gf2_fast_u8_mul_m2
	.align	2
	.global	gf2_fast_u8_inv_m2
	.type	gf2_fast_u8_inv_m2, %function
gf2_fast_u8_inv_m2:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	mov	r3, r2
	strb	r3, [fp, #-13]
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	rsb	r3, r3, #255
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_inv_m2, .-gf2_fast_u8_inv_m2
	.align	2
	.global	gf2_fast_u8_div_m2
	.type	gf2_fast_u8_div_m2, %function
gf2_fast_u8_div_m2:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	strb	r2, [fp, #-21]
	strb	r3, [fp, #-22]
	ldrb	r3, [fp, #-21]	@ zero_extendqisi2
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]
	strb	r3, [fp, #-5]
	ldrb	r3, [fp, #-22]	@ zero_extendqisi2
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]
	strb	r3, [fp, #-6]
	ldrb	r2, [fp, #-5]	@ zero_extendqisi2
	ldrb	r3, [fp, #-6]	@ zero_extendqisi2
	cmp	r2, r3
	bcc	.L282
	ldrb	r2, [fp, #-5]	@ zero_extendqisi2
	ldrb	r3, [fp, #-6]	@ zero_extendqisi2
	rsb	r3, r3, r2
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	b	.L283
.L282:
	ldrb	r3, [fp, #-5]	@ zero_extendqisi2
	add	r2, r3, #255
	ldrb	r3, [fp, #-6]	@ zero_extendqisi2
	rsb	r3, r3, r2
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
.L283:
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_div_m2, .-gf2_fast_u8_div_m2
	.align	2
	.global	gf2_fast_u8_init_m3
	.type	gf2_fast_u8_init_m3, %function
gf2_fast_u8_init_m3:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r2, [fp, #-20]
	str	r3, [fp, #-24]
	mov	r3, r0
	strb	r3, [fp, #-13]
	mov	r3, r1
	strb	r3, [fp, #-14]
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L285
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L286
.L285:
	mvn	r3, #0
	b	.L287
.L286:
	mov	r0, #512
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-20]
	str	r2, [r3, #0]
	mov	r0, #1024
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-24]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L288
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L289
.L288:
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L290
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L290:
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L291
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L291:
	mvn	r3, #0
	b	.L287
.L289:
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r2, r3, #512
	ldr	r3, [fp, #-24]
	str	r2, [r3, #0]
	mov	r3, #65024
	strh	r3, [fp, #-6]	@ movhi
	b	.L292
.L293:
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldrsh	r3, [fp, #-6]
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3, #0]
	ldrh	r3, [fp, #-6]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-6]	@ movhi
.L292:
	ldrsh	r3, [fp, #-6]
	cmp	r3, #0
	bne	.L293
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r2, #65280
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r2, #1
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #1
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r3, r3, #1
	ldrb	r2, [fp, #-14]
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r3, r3, #255
	mov	r2, #1
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r3, r3, #256
	ldrb	r2, [fp, #-14]
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r3, r3, #508
	add	r3, r3, #3
	mov	r2, #0
	strb	r2, [r3, #0]
	ldrb	r3, [fp, #-14]
	strb	r3, [fp, #-7]
	mov	r3, #2
	strh	r3, [fp, #-6]	@ movhi
.L295:
	ldrb	r3, [fp, #-7]	@ zero_extendqisi2
	cmp	r3, #1
	bne	.L294
	ldr	r3, .L296
	ldr	r3, [r3, #0]
	mov	r0, r3
	ldr	r1, .L296+4
	ldrb	r2, [fp, #-7]	@ zero_extendqisi2
	ldrsh	r3, [fp, #-6]
	bl	fprintf
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	sub	r3, r3, #512
	mov	r0, r3
	bl	free
	ldrsh	r3, [fp, #-6]
	rsb	r3, r3, #0
	b	.L287
.L294:
	ldrb	r1, [fp, #-7]	@ zero_extendqisi2
	ldrb	r2, [fp, #-14]	@ zero_extendqisi2
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u8
	mov	r3, r0
	strb	r3, [fp, #-7]
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldrsh	r3, [fp, #-6]
	add	r3, r2, r3
	ldrb	r2, [fp, #-7]
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldrsh	r3, [fp, #-6]
	add	r3, r3, #255
	add	r3, r2, r3
	ldrb	r2, [fp, #-7]
	strb	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrb	r3, [fp, #-7]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldrh	r2, [fp, #-6]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-6]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-6]	@ movhi
	ldrsh	r3, [fp, #-6]
	cmp	r3, #255
	ble	.L295
	mov	r3, #0
.L287:
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L297:
	.align	2
.L296:
	.word	stderr
	.word	.LC0
	.size	gf2_fast_u8_init_m3, .-gf2_fast_u8_init_m3
	.align	2
	.global	gf2_fast_u8_deinit_m3
	.type	gf2_fast_u8_deinit_m3, %function
gf2_fast_u8_deinit_m3:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r3, [fp, #-12]
	sub	r3, r3, #512
	mov	r0, r3
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u8_deinit_m3, .-gf2_fast_u8_deinit_m3
	.align	2
	.global	gf2_fast_u8_mul_m3
	.type	gf2_fast_u8_mul_m3, %function

# Accelerated log/exp table u8 multiply
gf2_fast_u8_mul_m3:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.

# return gf2_u8
#   gf2_s16 *log_table,
#   gf2_u8  *exp_table,
#   gf2_u8 a
#   gf2_u8 b

	# set up frame pointer, stack pointer
	str	fp, [sp, #-4]!  
	add	fp, sp, #0
	sub	sp, sp, #20

	# save old registers
	str	r0, [fp, #-8]	
	str	r1, [fp, #-12]	
	strb	r2, [fp, #-13]	
	strb	r3, [fp, #-14]	

	# ??? loading old value for some reason?
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2

	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	sxth	r2, r3
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-8]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	sxth	r3, r3
	add	r3, r2, r3
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}

	# return from routine
	bx	lr

	.size	gf2_fast_u8_mul_m3, .-gf2_fast_u8_mul_m3
	.align	2
	.global	gf2_fast_u8_inv_m3
	.type	gf2_fast_u8_inv_m3, %function
gf2_fast_u8_inv_m3:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	mov	r3, r2
	strb	r3, [fp, #-13]
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	sxth	r3, r3
	rsb	r3, r3, #255
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_inv_m3, .-gf2_fast_u8_inv_m3
	.align	2
	.global	gf2_fast_u8_div_m3
	.type	gf2_fast_u8_div_m3, %function
gf2_fast_u8_div_m3:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	strb	r2, [fp, #-13]
	strb	r3, [fp, #-14]
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	sxth	r3, r3
	add	r2, r3, #255
	ldrb	r3, [fp, #-14]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-8]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	sxth	r3, r3
	rsb	r3, r3, r2
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u8_div_m3, .-gf2_fast_u8_div_m3
	.align	2
	.global	gf2_fast_u8_pow_m3
	.type	gf2_fast_u8_pow_m3, %function
gf2_fast_u8_pow_m3:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	strb	r2, [fp, #-13]
	strb	r3, [fp, #-14]
	ldrb	r3, [fp, #-13]	@ zero_extendqisi2
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	sxth	r3, r3
	ldrb	r2, [fp, #-14]	@ zero_extendqisi2
	mul	r1, r2, r3
	ldr	r3, .L303
	smull	r2, r3, r3, r1
	add	r3, r3, r1
	mov	r2, r3, asr #7
	mov	r3, r1, asr #31
	rsb	r2, r3, r2
	mov	r3, r2
	mov	r3, r3, asl #8
	rsb	r3, r2, r3
	rsb	r2, r3, r1
	mov	r3, r2
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrb	r3, [r3, #0]	@ zero_extendqisi2
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
.L304:
	.align	2
.L303:
	.word	-2139062143
	.size	gf2_fast_u8_pow_m3, .-gf2_fast_u8_pow_m3
	.align	2
	.global	gf2_fast_u16_init_m1
	.type	gf2_fast_u16_init_m1, %function
gf2_fast_u16_init_m1:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r2, [fp, #-20]
	str	r3, [fp, #-24]
	strh	r0, [fp, #-14]	@ movhi
	strh	r1, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-16]
	cmp	r3, #0
	beq	.L306
	ldrh	r3, [fp, #-14]
	cmp	r3, #0
	bne	.L307
.L306:
	mvn	r3, #0
	b	.L308
.L307:
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-20]
	str	r2, [r3, #0]
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-24]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L309
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L310
.L309:
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L311
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L311:
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L312
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L312:
	mvn	r3, #0
	b	.L308
.L310:
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r2, #1
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r3, r3, #2
	ldrh	r2, [fp, #-16]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #1
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	strh	r3, [fp, #-8]	@ movhi
	mov	r3, #2
	strh	r3, [fp, #-6]	@ movhi
.L314:
	ldrh	r3, [fp, #-8]
	cmp	r3, #1
	bne	.L313
	ldr	r3, .L315
	ldr	r3, [r3, #0]
	mov	r0, r3
	ldr	r1, .L315+4
	ldrh	r2, [fp, #-8]
	ldrh	r3, [fp, #-6]
	bl	fprintf
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
	ldrh	r3, [fp, #-6]
	rsb	r3, r3, #0
	b	.L308
.L313:
	ldrh	r1, [fp, #-8]
	ldrh	r2, [fp, #-16]
	ldrh	r3, [fp, #-14]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [fp, #-8]	@ movhi
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldrh	r2, [fp, #-8]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-8]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldrh	r2, [fp, #-6]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-6]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-6]
	cmp	r3, #0
	bne	.L314
	mov	r3, #0
.L308:
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L316:
	.align	2
.L315:
	.word	stderr
	.word	.LC0
	.size	gf2_fast_u16_init_m1, .-gf2_fast_u16_init_m1
	.align	2
	.global	gf2_fast_u16_deinit_m1
	.type	gf2_fast_u16_deinit_m1, %function
gf2_fast_u16_deinit_m1:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_deinit_m1, .-gf2_fast_u16_deinit_m1
	.align	2
	.global	gf2_fast_u16_mul_m1
	.type	gf2_fast_u16_mul_m1, %function
gf2_fast_u16_mul_m1:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	strh	r2, [fp, #-22]	@ movhi
	strh	r3, [fp, #-24]	@ movhi
	ldrh	r3, [fp, #-22]
	cmp	r3, #0
	beq	.L319
	ldrh	r3, [fp, #-24]
	cmp	r3, #0
	bne	.L320
.L319:
	mov	r3, #0
	b	.L321
.L320:
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r2, r3
	ldrh	r3, [fp, #-24]
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-16]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	add	r3, r2, r3
	str	r3, [fp, #-8]
	ldr	r3, [fp, #-8]
	mov	r3, r3, asl #16
	mov	r3, r3, lsr #16
	ldr	r2, [fp, #-8]
	mov	r2, r2, lsr #16
	add	r3, r3, r2
	str	r3, [fp, #-8]
	ldr	r3, [fp, #-8]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
.L321:
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_mul_m1, .-gf2_fast_u16_mul_m1
	.align	2
	.global	gf2_fast_u16_inv_m1
	.type	gf2_fast_u16_inv_m1, %function
gf2_fast_u16_inv_m1:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	mov	r3, r2
	strh	r3, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	rsb	r3, r3, #65280
	add	r3, r3, #255
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_inv_m1, .-gf2_fast_u16_inv_m1
	.align	2
	.global	gf2_fast_u16_div_m1
	.type	gf2_fast_u16_div_m1, %function
gf2_fast_u16_div_m1:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	strh	r2, [fp, #-22]	@ movhi
	strh	r3, [fp, #-24]	@ movhi
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]	@ movhi
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-24]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]	@ movhi
	strh	r3, [fp, #-8]	@ movhi
	ldrh	r2, [fp, #-6]
	ldrh	r3, [fp, #-8]
	cmp	r2, r3
	bcc	.L324
	ldrh	r2, [fp, #-6]
	ldrh	r3, [fp, #-8]
	rsb	r3, r3, r2
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	b	.L325
.L324:
	ldrh	r3, [fp, #-6]
	add	r3, r3, #65280
	add	r3, r3, #255
	ldrh	r2, [fp, #-8]
	rsb	r3, r2, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
.L325:
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_div_m1, .-gf2_fast_u16_div_m1
	.section	.rodata
	.align	2
.LC1:
	.ascii	"Warning: Bad poly/generator. Using fallback multipl"
	.ascii	"y.\000"
	.align	2
.LC2:
	.ascii	"No valid generator; using long multiply\000"
	.text
	.align	2
	.global	gf2_fast_u16_init_m2
	.type	gf2_fast_u16_init_m2, %function
gf2_fast_u16_init_m2:
	@ args = 4, pretend = 0, frame = 40
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #44
	str	r2, [fp, #-44]
	str	r3, [fp, #-48]
	strh	r0, [fp, #-38]	@ movhi
	strh	r1, [fp, #-40]	@ movhi
	mov	r0, #33554432
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-44]
	str	r2, [r3, #0]
	mov	r0, #33554432
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-48]
	str	r2, [r3, #0]
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #4]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-44]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L327
	ldr	r3, [fp, #-48]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L327
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L328
.L327:
	ldr	r3, [fp, #-44]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L329
	ldr	r3, [fp, #-44]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L329:
	ldr	r3, [fp, #-48]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L330
	ldr	r3, [fp, #-48]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L330:
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L331
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L331:
	mvn	r3, #0
	b	.L332
.L328:
	ldrh	r3, [fp, #-40]
	cmp	r3, #0
	beq	.L333
	ldr	r3, [fp, #-48]
	ldr	r3, [r3, #0]
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-48]
	ldr	r3, [r3, #0]
	add	r3, r3, #131072
	str	r3, [fp, #-36]
	ldr	r3, [fp, #-32]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-36]
	mov	r2, #1
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-40]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	mov	r2, #1
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-36]
	add	r3, r3, #2
	ldrh	r2, [fp, #-40]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-40]	@ movhi
	strh	r3, [fp, #-22]	@ movhi
	mov	r3, #2
	str	r3, [fp, #-16]
.L336:
	ldrh	r3, [fp, #-22]
	cmp	r3, #1
	bne	.L334
	ldr	r2, .L357
	ldr	r3, .L357+4
	ldr	r3, [r3, #0]
	mov	r0, r2
	mov	r1, #1
	mov	r2, #53
	bl	fwrite
	mov	r3, #0
	strh	r3, [fp, #-40]	@ movhi
	b	.L335
.L334:
	ldrh	r1, [fp, #-22]
	ldrh	r2, [fp, #-40]
	ldrh	r3, [fp, #-38]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [fp, #-22]	@ movhi
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-36]
	add	r3, r2, r3
	ldrh	r2, [fp, #-22]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldr	r2, [fp, #-16]
	uxth	r2, r2
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
	ldr	r2, [fp, #-16]
	ldr	r3, .L357+8
	cmp	r2, r3
	bls	.L336
.L335:
	ldrh	r3, [fp, #-40]
	cmp	r3, #0
	beq	.L333
	mov	r3, #2
	str	r3, [fp, #-16]
	b	.L337
.L342:
	ldr	r3, [fp, #-44]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #17
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-48]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #17
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	mov	r3, #2
	str	r3, [fp, #-20]
	b	.L338
.L341:
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #9
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r2, r3
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-32]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	add	r3, r2, r3
	str	r3, [fp, #-28]
	ldr	r2, [fp, #-28]
	ldr	r3, .L357+8
	cmp	r2, r3
	bls	.L339
	ldr	r3, [fp, #-28]
	sub	r3, r3, #65280
	sub	r3, r3, #255
	str	r3, [fp, #-28]
.L339:
	ldr	r3, [fp, #-44]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #16
	ldr	r3, [fp, #-20]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldr	r2, [fp, #-28]
	mov	r2, r2, asl #1
	ldr	r1, [fp, #-36]
	add	r2, r1, r2
	ldrh	r2, [r2, #0]
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r2, r3
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-32]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	add	r3, r2, r3
	str	r3, [fp, #-28]
	ldr	r2, [fp, #-28]
	ldr	r3, .L357+8
	cmp	r2, r3
	bls	.L340
	ldr	r3, [fp, #-28]
	sub	r3, r3, #65280
	sub	r3, r3, #255
	str	r3, [fp, #-28]
.L340:
	ldr	r3, [fp, #-48]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #16
	ldr	r3, [fp, #-20]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldr	r2, [fp, #-28]
	mov	r2, r2, asl #1
	ldr	r1, [fp, #-36]
	add	r2, r1, r2
	ldrh	r2, [r2, #0]
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L338:
	ldr	r2, [fp, #-20]
	ldr	r3, .L357+8
	cmp	r2, r3
	bls	.L341
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L337:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	bls	.L342
	mov	r3, #0
	str	r3, [fp, #-20]
	b	.L343
.L345:
	ldr	r3, [fp, #-32]
	add	r3, r3, #512
	ldrh	r3, [r3, #0]
	mov	r2, r3
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-32]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	add	r3, r2, r3
	str	r3, [fp, #-28]
	ldr	r2, [fp, #-28]
	ldr	r3, .L357+8
	cmp	r2, r3
	bls	.L344
	ldr	r3, [fp, #-28]
	sub	r3, r3, #65280
	sub	r3, r3, #255
	str	r3, [fp, #-28]
.L344:
	ldr	r3, [fp, #-44]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	orr	r3, r3, #65536
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldr	r2, [fp, #-28]
	mov	r2, r2, asl #1
	ldr	r1, [fp, #-36]
	add	r2, r1, r2
	ldrh	r2, [r2, #0]
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L343:
	ldr	r2, [fp, #-20]
	ldr	r3, .L357+8
	cmp	r2, r3
	bls	.L345
	ldr	r3, [fp, #-44]
	ldr	r3, [r3, #0]
	mov	r2, r3
	mov	r3, #131072
	mov	r0, r2
	mov	r1, #0
	mov	r2, r3
	bl	memset
	ldr	r3, [fp, #-48]
	ldr	r3, [r3, #0]
	mov	r2, r3
	mov	r3, #131072
	mov	r0, r2
	mov	r1, #0
	mov	r2, r3
	bl	memset
	mov	r3, #0
	str	r3, [fp, #-20]
	b	.L346
.L347:
	ldr	r3, [fp, #-48]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	orr	r3, r3, #65536
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldr	r2, [fp, #-20]
	uxth	r2, r2
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L346:
	ldr	r2, [fp, #-20]
	ldr	r3, .L357+8
	cmp	r2, r3
	bls	.L347
.L333:
	ldrh	r3, [fp, #-40]
	cmp	r3, #0
	bne	.L348
	ldr	r0, .L357+12
	bl	puts
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	mov	r3, #0
	str	r3, [fp, #-16]
	b	.L349
.L350:
	ldr	r3, [fp, #-44]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #17
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-48]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #17
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L349:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	bls	.L350
	mov	r3, #1
	str	r3, [fp, #-20]
	b	.L351
.L352:
	ldr	r3, [fp, #4]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-20]
	uxth	r2, r3
	ldrh	r3, [fp, #-38]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-44]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-48]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L351:
	ldr	r2, [fp, #-20]
	ldr	r3, .L357+8
	cmp	r2, r3
	bls	.L352
	mov	r3, #1
	str	r3, [fp, #-16]
	b	.L353
.L356:
	mov	r3, #1
	str	r3, [fp, #-20]
	b	.L354
.L355:
	ldr	r3, [fp, #-44]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #16
	ldr	r3, [fp, #-20]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r1, r3
	ldr	r3, [fp, #-20]
	uxth	r2, r3
	ldrh	r3, [fp, #-38]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-48]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #16
	ldr	r3, [fp, #-20]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r1, r3
	ldr	r3, [fp, #-20]
	uxth	r2, r3
	ldrh	r3, [fp, #-38]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L354:
	ldr	r2, [fp, #-20]
	ldr	r3, .L357+8
	cmp	r2, r3
	bls	.L355
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L353:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	bls	.L356
.L348:
	mov	r3, #0
.L332:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
.L358:
	.align	2
.L357:
	.word	.LC1
	.word	stderr
	.word	65535
	.word	.LC2
	.size	gf2_fast_u16_init_m2, .-gf2_fast_u16_init_m2
	.align	2
	.global	gf2_fast_u16_deinit_m2
	.type	gf2_fast_u16_deinit_m2, %function
gf2_fast_u16_deinit_m2:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #16
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	ldr	r0, [fp, #-16]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_deinit_m2, .-gf2_fast_u16_deinit_m2
	.align	2
	.global	gf2_fast_u16_mul_m2
	.type	gf2_fast_u16_mul_m2, %function
gf2_fast_u16_mul_m2:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	strh	r2, [fp, #-14]	@ movhi
	strh	r3, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-14]
	and	r3, r3, #65280
	mov	r2, r3, asl #8
	ldrh	r3, [fp, #-16]
	orr	r3, r2, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	uxtb	r3, r3
	mov	r1, r3, asl #16
	ldrh	r3, [fp, #-16]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-12]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_mul_m2, .-gf2_fast_u16_mul_m2
	.align	2
	.global	gf2_fast_u16_inv_m2
	.type	gf2_fast_u16_inv_m2, %function
gf2_fast_u16_inv_m2:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	mov	r3, r1
	strh	r3, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-10]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_inv_m2, .-gf2_fast_u16_inv_m2
	.align	2
	.global	gf2_fast_u16_div_m2
	.type	gf2_fast_u16_div_m2, %function
gf2_fast_u16_div_m2:
	@ args = 4, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	str	r2, [fp, #-24]
	strh	r3, [fp, #-26]	@ movhi
	ldrh	r3, [fp, #4]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]	@ movhi
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-26]
	and	r3, r3, #65280
	mov	r2, r3, asl #8
	ldrh	r3, [fp, #-6]
	orr	r3, r2, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #-26]
	uxtb	r3, r3
	mov	r1, r3, asl #16
	ldrh	r3, [fp, #-6]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-20]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_div_m2, .-gf2_fast_u16_div_m2
	.align	2
	.global	gf2_fast_u16_init_m3
	.type	gf2_fast_u16_init_m3, %function
gf2_fast_u16_init_m3:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r2, [fp, #-20]
	str	r3, [fp, #-24]
	strh	r0, [fp, #-14]	@ movhi
	strh	r1, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-16]
	cmp	r3, #0
	beq	.L364
	ldrh	r3, [fp, #-14]
	cmp	r3, #0
	bne	.L365
.L364:
	mvn	r3, #0
	b	.L366
.L365:
	mov	r0, #262144
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-20]
	str	r2, [r3, #0]
	mov	r0, #524288
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-24]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L367
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L368
.L367:
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L369
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L369:
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L370
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L370:
	mvn	r3, #0
	b	.L366
.L368:
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r2, r3, #262144
	ldr	r3, [fp, #-24]
	str	r2, [r3, #0]
	ldr	r3, .L375
	str	r3, [fp, #-8]
	b	.L371
.L372:
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-8]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-8]
	add	r3, r3, #1
	str	r3, [fp, #-8]
.L371:
	ldr	r3, [fp, #-8]
	cmp	r3, #0
	bne	.L372
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	ldr	r2, .L375+4
	str	r2, [r3, #0]
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	mov	r2, #1
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #2
	add	r3, r2, r3
	mov	r2, #1
	str	r2, [r3, #0]
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r3, r3, #2
	ldrh	r2, [fp, #-16]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldr	r3, .L375+8
	add	r3, r2, r3
	mov	r2, #1
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	add	r3, r3, #131072
	ldrh	r2, [fp, #-16]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	sub	r3, r3, #-67108862
	sub	r3, r3, #66846720
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	strh	r3, [fp, #-10]	@ movhi
	mov	r3, #2
	str	r3, [fp, #-8]
.L374:
	ldrh	r3, [fp, #-10]
	cmp	r3, #1
	bne	.L373
	ldr	r3, .L375+12
	ldr	r3, [r3, #0]
	mov	r0, r3
	ldr	r1, .L375+16
	ldrh	r2, [fp, #-10]
	ldr	r3, [fp, #-8]
	bl	fprintf
	ldr	r3, [fp, #-20]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
	ldr	r3, [fp, #-24]
	ldr	r3, [r3, #0]
	sub	r3, r3, #262144
	mov	r0, r3
	bl	free
	ldr	r3, [fp, #-8]
	rsb	r3, r3, #0
	b	.L366
.L373:
	ldrh	r1, [fp, #-10]
	ldrh	r2, [fp, #-16]
	ldrh	r3, [fp, #-14]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [fp, #-10]	@ movhi
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-8]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldrh	r2, [fp, #-10]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-24]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-8]
	add	r3, r3, #65280
	add	r3, r3, #255
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldrh	r2, [fp, #-10]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-20]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-10]
	mov	r3, r3, asl #2
	add	r3, r2, r3
	ldr	r2, [fp, #-8]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-8]
	add	r3, r3, #1
	str	r3, [fp, #-8]
	ldr	r2, [fp, #-8]
	ldr	r3, .L375+20
	cmp	r2, r3
	ble	.L374
	mov	r3, #0
.L366:
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
.L376:
	.align	2
.L375:
	.word	-131072
	.word	-65536
	.word	131070
	.word	stderr
	.word	.LC0
	.word	65535
	.size	gf2_fast_u16_init_m3, .-gf2_fast_u16_init_m3
	.align	2
	.global	gf2_fast_u16_deinit_m3
	.type	gf2_fast_u16_deinit_m3, %function
gf2_fast_u16_deinit_m3:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r3, [fp, #-12]
	sub	r3, r3, #262144
	mov	r0, r3
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_deinit_m3, .-gf2_fast_u16_deinit_m3
	.align	2
	.global	gf2_fast_u16_mul_m3
	.type	gf2_fast_u16_mul_m3, %function
gf2_fast_u16_mul_m3:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	strh	r2, [fp, #-14]	@ movhi
	strh	r3, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-8]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	add	r3, r2, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_mul_m3, .-gf2_fast_u16_mul_m3
	.align	2
	.global	gf2_fast_u16_inv_m3
	.type	gf2_fast_u16_inv_m3, %function
gf2_fast_u16_inv_m3:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	mov	r3, r2
	strh	r3, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	rsb	r3, r3, #65280
	add	r3, r3, #255
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_inv_m3, .-gf2_fast_u16_inv_m3
	.align	2
	.global	gf2_fast_u16_div_m3
	.type	gf2_fast_u16_div_m3, %function
gf2_fast_u16_div_m3:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	strh	r2, [fp, #-14]	@ movhi
	strh	r3, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	add	r3, r3, #65280
	add	r3, r3, #255
	ldrh	r2, [fp, #-16]
	mov	r2, r2, asl #2
	ldr	r1, [fp, #-8]
	add	r2, r1, r2
	ldr	r2, [r2, #0]
	rsb	r3, r2, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_div_m3, .-gf2_fast_u16_div_m3
	.align	2
	.global	gf2_fast_u16_pow_m3
	.type	gf2_fast_u16_pow_m3, %function
gf2_fast_u16_pow_m3:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #20
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	strh	r2, [fp, #-14]	@ movhi
	strh	r3, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	ldrh	r2, [fp, #-16]
	mul	r1, r2, r3
	ldr	r3, .L382
	smull	r2, r3, r3, r1
	add	r3, r3, r1
	mov	r2, r3, asr #15
	mov	r3, r1, asr #31
	rsb	r2, r3, r2
	mov	r3, r2
	mov	r3, r3, asl #16
	rsb	r3, r2, r3
	rsb	r2, r3, r1
	mov	r3, r2
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
.L383:
	.align	2
.L382:
	.word	-2147450879
	.size	gf2_fast_u16_pow_m3, .-gf2_fast_u16_pow_m3
	.align	2
	.global	gf2_fast_u16_init_m4
	.type	gf2_fast_u16_init_m4, %function
gf2_fast_u16_init_m4:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #28
	mov	r3, r0
	str	r1, [fp, #-28]
	str	r2, [fp, #-32]
	strh	r3, [fp, #-22]	@ movhi
	mov	r0, #524288
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-28]
	str	r2, [r3, #0]
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-32]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L385
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L386
.L385:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L387
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L387:
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L388
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L388:
	mvn	r3, #0
	b	.L389
.L386:
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r3, #1
	str	r3, [fp, #-16]
	b	.L390
.L391:
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #2
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #10
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	mov	r2, #0
	strb	r2, [r3, #0]
	add	r3, r3, #1
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L390:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	ble	.L391
	mov	r3, #1
	str	r3, [fp, #-16]
	b	.L392
.L395:
	mov	r3, #1
	str	r3, [fp, #-20]
	b	.L393
.L394:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #10
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #2
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxtb	r2, r3
	ldr	r3, [fp, #-20]
	uxtb	r3, r3
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u8
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #10
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #2
	orr	r3, r1, r3
	orr	r3, r3, #1
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r1, r3
	ldr	r3, [fp, #-20]
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #10
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #2
	orr	r3, r1, r3
	orr	r3, r3, #2
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r1, r3
	ldr	r3, [fp, #-20]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #10
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #2
	orr	r3, r1, r3
	orr	r3, r3, #3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r1, r3
	ldr	r3, [fp, #-20]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L393:
	ldr	r3, [fp, #-20]
	cmp	r3, #255
	ble	.L394
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L392:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	ble	.L395
	mov	r3, #0
.L389:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_fast_u16_init_m4, .-gf2_fast_u16_init_m4
	.align	2
	.global	gf2_fast_u16_deinit_m4
	.type	gf2_fast_u16_deinit_m4, %function
gf2_fast_u16_deinit_m4:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_deinit_m4, .-gf2_fast_u16_deinit_m4
	.align	2
	.global	gf2_fast_u16_mul_m4
	.type	gf2_fast_u16_mul_m4, %function
gf2_fast_u16_mul_m4:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	stmfd	sp!, {r4, r5, r6, r7, fp}
	add	fp, sp, #16
	sub	sp, sp, #12
	str	r0, [fp, #-24]
	mov	r3, r2
	strh	r1, [fp, #-26]	@ movhi
	strh	r3, [fp, #-28]	@ movhi
	ldrh	r3, [fp, #-26]
	uxtb	r3, r3
	mov	r6, r3, asl #10
	ldrh	r3, [fp, #-26]
	and	r3, r3, #65280
	mov	r5, r3, asl #2
	ldrh	r3, [fp, #-28]
	uxtb	r3, r3
	mov	r3, r3, asl #2
	mov	r7, r3
	ldrh	r3, [fp, #-28]
	and	r3, r3, #65280
	mov	r3, r3, asr #6
	mov	r4, r3
	orr	r3, r6, r7
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	orr	r3, r5, r7
	orr	r3, r3, #1
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-24]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r2, r3
	orr	r3, r6, r4
	orr	r3, r3, #2
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-24]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r2, r3
	orr	r3, r5, r4
	orr	r3, r3, #3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-24]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	mov	r0, r3
	sub	sp, fp, #16
	ldmfd	sp!, {r4, r5, r6, r7, fp}
	bx	lr
	.size	gf2_fast_u16_mul_m4, .-gf2_fast_u16_mul_m4
	.align	2
	.global	gf2_fast_u16_inv_m4
	.type	gf2_fast_u16_inv_m4, %function
gf2_fast_u16_inv_m4:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	mov	r3, r1
	strh	r3, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-10]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_inv_m4, .-gf2_fast_u16_inv_m4
	.align	2
	.global	gf2_fast_u16_div_m4
	.type	gf2_fast_u16_div_m4, %function
gf2_fast_u16_div_m4:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	strh	r2, [fp, #-22]	@ movhi
	strh	r3, [fp, #-24]	@ movhi
	ldrh	r3, [fp, #-24]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]	@ movhi
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r2, [fp, #-22]
	ldrh	r3, [fp, #-6]
	ldr	r0, [fp, #-16]
	mov	r1, r2
	mov	r2, r3
	bl	gf2_fast_u16_mul_m4
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_div_m4, .-gf2_fast_u16_div_m4
	.align	2
	.global	gf2_fast_u16_init_m5
	.type	gf2_fast_u16_init_m5, %function
gf2_fast_u16_init_m5:
	@ args = 8, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #28
	str	r1, [fp, #-28]
	str	r2, [fp, #-32]
	str	r3, [fp, #-36]
	strh	r0, [fp, #-22]	@ movhi
	mov	r0, #524288
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-28]
	str	r2, [r3, #0]
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #8]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L401
	ldr	r3, [fp, #8]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L402
.L401:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L403
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L403:
	ldr	r3, [fp, #8]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L404
	ldr	r3, [fp, #8]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L404:
	mvn	r3, #0
	b	.L405
.L402:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	add	r2, r3, #131072
	ldr	r3, [fp, #-32]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	add	r2, r3, #131072
	ldr	r3, [fp, #-36]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	add	r2, r3, #131072
	ldr	r3, [fp, #4]
	str	r2, [r3, #0]
	ldr	r3, [fp, #8]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	mov	r3, #1
	str	r3, [fp, #-16]
	b	.L406
.L407:
	ldr	r3, [fp, #8]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-36]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-36]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #4]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #4]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L406:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	ble	.L407
	mov	r3, #1
	str	r3, [fp, #-16]
	b	.L408
.L411:
	mov	r3, #1
	str	r3, [fp, #-20]
	b	.L409
.L410:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #8
	ldr	r3, [fp, #-20]
	add	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxtb	r2, r3
	ldr	r3, [fp, #-20]
	uxtb	r3, r3
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u8
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #8
	ldr	r3, [fp, #-20]
	add	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r1, r3
	ldr	r3, [fp, #-20]
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-36]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #8
	ldr	r3, [fp, #-20]
	add	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r1, r3
	ldr	r3, [fp, #-20]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #4]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #8
	ldr	r3, [fp, #-20]
	add	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r1, r3
	ldr	r3, [fp, #-20]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r1
	mov	r1, r2
	mov	r2, r3
	bl	gf2_long_mod_multiply_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L409:
	ldr	r3, [fp, #-20]
	cmp	r3, #255
	ble	.L410
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L408:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	ble	.L411
	mov	r3, #0
.L405:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_fast_u16_init_m5, .-gf2_fast_u16_init_m5
	.align	2
	.global	gf2_fast_u16_deinit_m5
	.type	gf2_fast_u16_deinit_m5, %function
gf2_fast_u16_deinit_m5:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_deinit_m5, .-gf2_fast_u16_deinit_m5
	.align	2
	.global	gf2_fast_u16_mul_m5
	.type	gf2_fast_u16_mul_m5, %function
gf2_fast_u16_mul_m5:
	@ args = 8, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	stmfd	sp!, {r4, r5, r6, r7, fp}
	add	fp, sp, #16
	sub	sp, sp, #20
	str	r0, [fp, #-24]
	str	r1, [fp, #-28]
	str	r2, [fp, #-32]
	str	r3, [fp, #-36]
	ldrh	r3, [fp, #4]	@ movhi
	mov	r3, r3, asl #8
	uxth	r6, r3
	ldrh	r3, [fp, #4]	@ movhi
	bic	r3, r3, #255
	uxth	r5, r3
	ldrh	r3, [fp, #8]	@ movhi
	uxtb	r3, r3
	uxth	r7, r3
	ldrh	r3, [fp, #8]
	mov	r3, r3, lsr #8
	uxth	r4, r3
	orr	r3, r6, r7
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	orr	r3, r5, r7
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-28]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r2, r3
	orr	r3, r6, r4
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-32]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r2, r3
	orr	r3, r5, r4
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-36]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	mov	r0, r3
	sub	sp, fp, #16
	ldmfd	sp!, {r4, r5, r6, r7, fp}
	bx	lr
	.size	gf2_fast_u16_mul_m5, .-gf2_fast_u16_mul_m5
	.align	2
	.global	gf2_fast_u16_inv_m5
	.type	gf2_fast_u16_inv_m5, %function
gf2_fast_u16_inv_m5:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	mov	r3, r1
	strh	r3, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-10]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_inv_m5, .-gf2_fast_u16_inv_m5
	.align	2
	.global	gf2_fast_u16_div_m5
	.type	gf2_fast_u16_div_m5, %function
gf2_fast_u16_div_m5:
	@ args = 12, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	str	r3, [fp, #-20]
	ldrh	r3, [fp, #12]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #4]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldrh	r2, [fp, #8]
	str	r2, [sp, #0]
	str	r3, [sp, #4]
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-12]
	ldr	r2, [fp, #-16]
	ldr	r3, [fp, #-20]
	bl	gf2_fast_u16_mul_m5
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_div_m5, .-gf2_fast_u16_div_m5
	.align	2
	.global	gf2_fast_u16_init_m6
	.type	gf2_fast_u16_init_m6, %function
gf2_fast_u16_init_m6:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #28
	mov	r3, r0
	str	r1, [fp, #-28]
	str	r2, [fp, #-32]
	strh	r3, [fp, #-22]	@ movhi
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-28]
	str	r2, [r3, #0]
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-32]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L417
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L418
.L417:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L419
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L419:
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L420
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L420:
	mvn	r3, #0
	b	.L421
.L418:
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	mov	r3, #1
	str	r3, [fp, #-16]
	b	.L422
.L423:
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L422:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	ble	.L423
	mov	r3, #1
	str	r3, [fp, #-16]
	b	.L424
.L427:
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	mov	r3, #1
	str	r3, [fp, #-20]
	b	.L425
.L426:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #8
	ldr	r3, [fp, #-20]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxtb	r2, r3
	ldr	r3, [fp, #-20]
	uxtb	r3, r3
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u8
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #8
	ldr	r3, [fp, #-20]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldr	r3, [fp, #-20]
	uxth	r3, r3
	orr	r3, r2, r3
	uxth	r3, r3
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L425:
	ldr	r3, [fp, #-20]
	cmp	r3, #255
	ble	.L426
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L424:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	ble	.L427
	mov	r3, #0
.L421:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_fast_u16_init_m6, .-gf2_fast_u16_init_m6
	.align	2
	.global	gf2_fast_u16_deinit_m6
	.type	gf2_fast_u16_deinit_m6, %function
gf2_fast_u16_deinit_m6:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_deinit_m6, .-gf2_fast_u16_deinit_m6
	.align	2
	.global	gf2_fast_u16_mul_m6
	.type	gf2_fast_u16_mul_m6, %function
gf2_fast_u16_mul_m6:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	strh	r1, [fp, #-18]	@ movhi
	strh	r2, [fp, #-20]	@ movhi
	strh	r3, [fp, #-22]	@ movhi
	ldrh	r3, [fp, #-18]
	and	r2, r3, #65280
	ldrh	r3, [fp, #-20]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	orr	r3, r2, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]	@ movhi
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L430
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L431
.L430:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L431:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L432
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L433
.L432:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L433:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L434
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L435
.L434:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L435:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L436
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L437
.L436:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L437:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L438
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L439
.L438:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L439:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L440
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L441
.L440:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L441:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L442
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L443
.L442:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L443:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L444
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L445
.L444:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L445:
	ldrh	r3, [fp, #-18]
	and	r2, r3, #65280
	ldrh	r3, [fp, #-20]
	uxtb	r3, r3
	orr	r3, r2, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #-6]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #16
	mov	r3, r3, lsr #16
	ldrh	r2, [fp, #-20]
	mov	r2, r2, lsr #8
	uxth	r2, r2
	orr	r3, r3, r2
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #-6]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L446
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L447
.L446:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L447:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L448
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L449
.L448:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L449:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L450
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L451
.L450:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L451:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L452
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L453
.L452:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L453:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L454
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L455
.L454:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L455:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L456
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L457
.L456:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L457:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L458
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L459
.L458:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L459:
	ldrh	r3, [fp, #-6]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L460
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	b	.L461
.L460:
	ldrh	r3, [fp, #-6]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-6]	@ movhi
.L461:
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #16
	mov	r3, r3, lsr #16
	ldrh	r2, [fp, #-20]
	uxtb	r2, r2
	orr	r3, r3, r2
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #-6]	@ movhi
	eor	r3, r2, r3
	uxth	r3, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_mul_m6, .-gf2_fast_u16_mul_m6
	.align	2
	.global	gf2_fast_u16_inv_m6
	.type	gf2_fast_u16_inv_m6, %function
gf2_fast_u16_inv_m6:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	mov	r3, r1
	strh	r3, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-10]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_inv_m6, .-gf2_fast_u16_inv_m6
	.align	2
	.global	gf2_fast_u16_div_m6
	.type	gf2_fast_u16_div_m6, %function
gf2_fast_u16_div_m6:
	@ args = 4, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	strh	r2, [fp, #-22]	@ movhi
	strh	r3, [fp, #-24]	@ movhi
	ldrh	r3, [fp, #-24]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]	@ movhi
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r1, [fp, #-22]
	ldrh	r2, [fp, #-6]
	ldrh	r3, [fp, #4]
	ldr	r0, [fp, #-16]
	bl	gf2_fast_u16_mul_m6
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_div_m6, .-gf2_fast_u16_div_m6
	.align	2
	.global	gf2_fast_u16_init_m7
	.type	gf2_fast_u16_init_m7, %function
gf2_fast_u16_init_m7:
	@ args = 0, pretend = 0, frame = 32
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #36
	str	r1, [fp, #-36]
	str	r2, [fp, #-40]
	str	r3, [fp, #-44]
	strh	r0, [fp, #-30]	@ movhi
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-36]
	str	r2, [r3, #0]
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-40]
	str	r2, [r3, #0]
	mov	r0, #512
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-44]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L465
	ldr	r3, [fp, #-40]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L465
	ldr	r3, [fp, #-44]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L466
.L465:
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L467
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L467:
	ldr	r3, [fp, #-44]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L468
	ldr	r3, [fp, #-44]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L468:
	ldr	r3, [fp, #-40]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L469
	ldr	r3, [fp, #-40]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L469:
	mvn	r3, #0
	b	.L470
.L466:
	ldr	r3, [fp, #-40]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-44]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	mov	r3, #1
	str	r3, [fp, #-16]
	b	.L471
.L488:
	ldr	r3, [fp, #-40]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-36]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-36]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-16]
	uxth	r3, r3
	mov	r3, r3, asl #8
	strh	r3, [fp, #-22]	@ movhi
	ldrh	r3, [fp, #-22]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L472
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-22]	@ movhi
	b	.L473
.L472:
	ldrh	r3, [fp, #-22]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-22]	@ movhi
.L473:
	ldrh	r3, [fp, #-22]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L474
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-22]	@ movhi
	b	.L475
.L474:
	ldrh	r3, [fp, #-22]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-22]	@ movhi
.L475:
	ldrh	r3, [fp, #-22]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L476
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-22]	@ movhi
	b	.L477
.L476:
	ldrh	r3, [fp, #-22]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-22]	@ movhi
.L477:
	ldrh	r3, [fp, #-22]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L478
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-22]	@ movhi
	b	.L479
.L478:
	ldrh	r3, [fp, #-22]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-22]	@ movhi
.L479:
	ldrh	r3, [fp, #-22]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L480
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-22]	@ movhi
	b	.L481
.L480:
	ldrh	r3, [fp, #-22]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-22]	@ movhi
.L481:
	ldrh	r3, [fp, #-22]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L482
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-22]	@ movhi
	b	.L483
.L482:
	ldrh	r3, [fp, #-22]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-22]	@ movhi
.L483:
	ldrh	r3, [fp, #-22]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L484
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-22]	@ movhi
	b	.L485
.L484:
	ldrh	r3, [fp, #-22]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-22]	@ movhi
.L485:
	ldrh	r3, [fp, #-22]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L486
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-22]	@ movhi
	b	.L487
.L486:
	ldrh	r3, [fp, #-22]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-22]	@ movhi
.L487:
	ldr	r3, [fp, #-44]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldrh	r2, [fp, #-22]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L471:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	ble	.L488
	mov	r3, #1
	str	r3, [fp, #-16]
	b	.L489
.L492:
	ldr	r3, [fp, #-40]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	mov	r3, #1
	str	r3, [fp, #-20]
	b	.L490
.L491:
	ldr	r3, [fp, #-36]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #8
	ldr	r3, [fp, #-20]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	uxtb	r2, r3
	ldr	r3, [fp, #-20]
	uxtb	r3, r3
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u8
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-40]
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-16]
	mov	r1, r3, asl #8
	ldr	r3, [fp, #-20]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldr	r3, [fp, #-16]
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldr	r3, [fp, #-20]
	uxth	r3, r3
	orr	r3, r2, r3
	uxth	r3, r3
	uxth	r2, r3
	ldrh	r3, [fp, #-30]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]
.L490:
	ldr	r3, [fp, #-20]
	cmp	r3, #255
	ble	.L491
	ldr	r3, [fp, #-16]
	add	r3, r3, #1
	str	r3, [fp, #-16]
.L489:
	ldr	r3, [fp, #-16]
	cmp	r3, #255
	ble	.L492
	mov	r3, #0
.L470:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_fast_u16_init_m7, .-gf2_fast_u16_init_m7
	.align	2
	.global	gf2_fast_u16_deinit_m7
	.type	gf2_fast_u16_deinit_m7, %function
gf2_fast_u16_deinit_m7:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #16
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	ldr	r0, [fp, #-16]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_deinit_m7, .-gf2_fast_u16_deinit_m7
	.align	2
	.global	gf2_fast_u16_mul_m7
	.type	gf2_fast_u16_mul_m7, %function
gf2_fast_u16_mul_m7:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-16]
	str	r1, [fp, #-20]
	strh	r2, [fp, #-22]	@ movhi
	strh	r3, [fp, #-24]	@ movhi
	ldrh	r3, [fp, #-22]
	and	r2, r3, #65280
	ldrh	r3, [fp, #-24]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	orr	r3, r2, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]	@ movhi
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-6]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-20]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	uxth	r3, r3
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-22]
	and	r2, r3, #65280
	ldrh	r3, [fp, #-24]
	uxtb	r3, r3
	orr	r3, r2, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #-6]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #16
	mov	r3, r3, lsr #16
	ldrh	r2, [fp, #-24]
	mov	r2, r2, lsr #8
	uxth	r2, r2
	orr	r3, r3, r2
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #-6]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-6]
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-6]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-20]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	uxth	r3, r3
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-22]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #16
	mov	r3, r3, lsr #16
	ldrh	r2, [fp, #-24]
	uxtb	r2, r2
	orr	r3, r3, r2
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-16]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #-6]	@ movhi
	eor	r3, r2, r3
	uxth	r3, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_mul_m7, .-gf2_fast_u16_mul_m7
	.align	2
	.global	gf2_fast_u16_inv_m7
	.type	gf2_fast_u16_inv_m7, %function
gf2_fast_u16_inv_m7:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	mov	r3, r1
	strh	r3, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-10]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_inv_m7, .-gf2_fast_u16_inv_m7
	.align	2
	.global	gf2_fast_u16_div_m7
	.type	gf2_fast_u16_div_m7, %function
gf2_fast_u16_div_m7:
	@ args = 4, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #16
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	strh	r3, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #4]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-12]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldrh	r2, [fp, #-18]
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-16]
	bl	gf2_fast_u16_mul_m7
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_div_m7, .-gf2_fast_u16_div_m7
	.align	2
	.global	gf2_fast_u16_init_m8
	.type	gf2_fast_u16_init_m8, %function
gf2_fast_u16_init_m8:
	@ args = 4, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #28
	str	r1, [fp, #-28]
	str	r2, [fp, #-32]
	str	r3, [fp, #-36]
	strh	r0, [fp, #-22]	@ movhi
	mov	r0, #8192
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-28]
	str	r2, [r3, #0]
	mov	r0, #8192
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-32]
	str	r2, [r3, #0]
	mov	r0, #512
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-36]
	str	r2, [r3, #0]
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #4]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L498
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L498
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L498
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L499
.L498:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L500
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L500:
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L501
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L501:
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L502
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L502:
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L503
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L503:
	mvn	r3, #0
	b	.L504
.L499:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #4]
	ldr	r3, [r3, #0]
	add	r3, r3, #2
	mov	r2, #1
	strh	r2, [r3, #0]	@ movhi
	mov	r3, #2
	strh	r3, [fp, #-16]	@ movhi
	b	.L505
.L506:
	ldr	r3, [fp, #4]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldrh	r2, [fp, #-16]
	ldrh	r3, [fp, #-22]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_mod_inverse_u16
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-16]	@ movhi
.L505:
	ldrh	r3, [fp, #-16]
	cmp	r3, #0
	bne	.L506
	mov	r3, #1
	strh	r3, [fp, #-16]	@ movhi
	b	.L507
.L524:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	mov	r3, r3, asl #8
	strh	r3, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #-18]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L508
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	b	.L509
.L508:
	ldrh	r3, [fp, #-18]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-18]	@ movhi
.L509:
	ldrh	r3, [fp, #-18]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L510
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	b	.L511
.L510:
	ldrh	r3, [fp, #-18]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-18]	@ movhi
.L511:
	ldrh	r3, [fp, #-18]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L512
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	b	.L513
.L512:
	ldrh	r3, [fp, #-18]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-18]	@ movhi
.L513:
	ldrh	r3, [fp, #-18]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L514
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	b	.L515
.L514:
	ldrh	r3, [fp, #-18]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-18]	@ movhi
.L515:
	ldrh	r3, [fp, #-18]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L516
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	b	.L517
.L516:
	ldrh	r3, [fp, #-18]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-18]	@ movhi
.L517:
	ldrh	r3, [fp, #-18]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L518
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	b	.L519
.L518:
	ldrh	r3, [fp, #-18]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-18]	@ movhi
.L519:
	ldrh	r3, [fp, #-18]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L520
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	b	.L521
.L520:
	ldrh	r3, [fp, #-18]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-18]	@ movhi
.L521:
	ldrh	r3, [fp, #-18]
	sxth	r3, r3
	cmp	r3, #0
	bge	.L522
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #1
	uxth	r2, r3
	ldrh	r3, [fp, #-22]
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	b	.L523
.L522:
	ldrh	r3, [fp, #-18]	@ movhi
	mov	r3, r3, asl #1
	strh	r3, [fp, #-18]	@ movhi
.L523:
	ldr	r3, [fp, #-36]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	ldrh	r2, [fp, #-18]	@ movhi
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-16]	@ movhi
.L507:
	ldrh	r3, [fp, #-16]
	cmp	r3, #255
	bls	.L524
	mov	r3, #1
	strh	r3, [fp, #-14]	@ movhi
	b	.L525
.L528:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	mov	r3, #1
	strh	r3, [fp, #-16]	@ movhi
	b	.L526
.L527:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r1, r3, asl #8
	ldrh	r3, [fp, #-16]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldrh	r3, [fp, #-14]	@ movhi
	uxtb	r3, r3
	mov	r3, r3, asl #4
	uxtb	r2, r3
	ldrh	r3, [fp, #-16]	@ movhi
	uxtb	r3, r3
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u8
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r1, r3, asl #8
	ldrh	r3, [fp, #-16]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldrh	r3, [fp, #-14]	@ movhi
	uxtb	r2, r3
	ldrh	r3, [fp, #-16]	@ movhi
	uxtb	r3, r3
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u8
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-16]	@ movhi
.L526:
	ldrh	r3, [fp, #-16]
	cmp	r3, #255
	bls	.L527
	ldrh	r3, [fp, #-14]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-14]	@ movhi
.L525:
	ldrh	r3, [fp, #-14]
	cmp	r3, #15
	bls	.L528
	mov	r3, #0
.L504:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_fast_u16_init_m8, .-gf2_fast_u16_init_m8
	.align	2
	.global	gf2_fast_u16_deinit_m8
	.type	gf2_fast_u16_deinit_m8, %function
gf2_fast_u16_deinit_m8:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #16
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	str	r3, [fp, #-20]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	ldr	r0, [fp, #-16]
	bl	free
	ldr	r0, [fp, #-20]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_deinit_m8, .-gf2_fast_u16_deinit_m8
	.align	2
	.global	gf2_fast_u16_mul_m8
	.type	gf2_fast_u16_mul_m8, %function
gf2_fast_u16_mul_m8:
	@ args = 4, pretend = 0, frame = 32
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #36
	str	r0, [fp, #-24]
	str	r1, [fp, #-28]
	str	r2, [fp, #-32]
	strh	r3, [fp, #-34]	@ movhi
	ldrh	r3, [fp, #-34]
	mov	r3, r3, lsr #4
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-34]	@ movhi
	and	r3, r3, #3840
	strh	r3, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-34]
	mov	r3, r3, asl #4
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-34]
	mov	r3, r3, asl #8
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #4]
	mov	r3, r3, lsr #8
	strh	r3, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #4]	@ movhi
	uxtb	r3, r3
	strh	r3, [fp, #-16]	@ movhi
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-28]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	strh	r3, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-32]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	uxth	r3, r3
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-28]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r2, r3
	ldrh	r3, [fp, #-18]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-18]	@ movhi
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-28]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r2, r3
	ldrh	r3, [fp, #-18]	@ movhi
	eor	r3, r2, r3
	strh	r3, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #-18]
	mov	r3, r3, asl #8
	uxth	r2, r3
	ldrh	r3, [fp, #-18]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-32]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	uxth	r3, r3
	eor	r3, r2, r3
	uxth	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #-18]	@ movhi
	eor	r3, r2, r3
	uxth	r2, r3
	ldrh	r1, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-28]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_mul_m8, .-gf2_fast_u16_mul_m8
	.align	2
	.global	gf2_fast_u16_inv_m8
	.type	gf2_fast_u16_inv_m8, %function
gf2_fast_u16_inv_m8:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #12
	str	r0, [fp, #-8]
	mov	r3, r1
	strh	r3, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-10]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-8]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u16_inv_m8, .-gf2_fast_u16_inv_m8
	.align	2
	.global	gf2_fast_u16_div_m8
	.type	gf2_fast_u16_div_m8, %function
gf2_fast_u16_div_m8:
	@ args = 8, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	str	r3, [fp, #-20]
	ldrh	r3, [fp, #8]
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-20]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r3, [fp, #4]
	str	r2, [sp, #0]
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-12]
	ldr	r2, [fp, #-16]
	bl	gf2_fast_u16_mul_m8
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u16_div_m8, .-gf2_fast_u16_div_m8
	.align	2
	.global	gf2_fast_u32_init_m1
	.type	gf2_fast_u32_init_m1, %function
gf2_fast_u32_init_m1:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #28
	str	r0, [fp, #-24]
	str	r1, [fp, #-28]
	str	r2, [fp, #-32]
	mov	r0, #67108864
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-28]
	str	r2, [r3, #0]
	mov	r0, #1024
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-32]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L534
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L535
.L534:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L536
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L536:
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L537
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L537:
	mvn	r3, #0
	b	.L538
.L535:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r2, #0
	str	r2, [r3, #0]
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r2, #0
	str	r2, [r3, #0]
	mov	r3, #1
	strh	r3, [fp, #-14]	@ movhi
	b	.L539
.L556:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #2
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #24
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L540
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L541
.L540:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L541:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L542
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L543
.L542:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L543:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L544
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L545
.L544:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L545:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L546
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L547
.L546:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L547:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L548
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L549
.L548:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L549:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L550
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L551
.L550:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L551:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L552
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L553
.L552:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L553:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L554
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L555
.L554:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L555:
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #2
	add	r3, r2, r3
	ldr	r2, [fp, #-20]
	str	r2, [r3, #0]
	ldrh	r3, [fp, #-14]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-14]	@ movhi
.L539:
	ldrh	r3, [fp, #-14]
	cmp	r3, #255
	bls	.L556
	mov	r3, #1
	strh	r3, [fp, #-14]	@ movhi
	b	.L557
.L560:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #2
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #0]
	mov	r3, #1
	strh	r3, [fp, #-16]	@ movhi
	b	.L558
.L559:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r1, r3, asl #8
	ldrh	r3, [fp, #-16]
	orr	r3, r1, r3
	mov	r3, r3, asl #2
	add	r4, r2, r3
	ldrh	r2, [fp, #-14]
	ldrh	r3, [fp, #-16]
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u16
	mov	r3, r0
	str	r3, [r4, #0]
	ldrh	r3, [fp, #-16]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-16]	@ movhi
.L558:
	ldrh	r3, [fp, #-16]
	cmp	r3, #255
	bls	.L559
	ldrh	r3, [fp, #-14]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-14]	@ movhi
.L557:
	ldrh	r3, [fp, #-14]
	cmp	r3, #0
	bne	.L560
	mov	r3, #0
.L538:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_fast_u32_init_m1, .-gf2_fast_u32_init_m1
	.align	2
	.global	gf2_fast_u32_deinit_m1
	.type	gf2_fast_u32_deinit_m1, %function
gf2_fast_u32_deinit_m1:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u32_deinit_m1, .-gf2_fast_u32_deinit_m1
	.align	2
	.global	gf2_fast_u32_mul_m1
	.type	gf2_fast_u32_mul_m1, %function
gf2_fast_u32_mul_m1:
	@ args = 0, pretend = 0, frame = 48
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #52
	str	r0, [fp, #-40]
	str	r1, [fp, #-44]
	str	r2, [fp, #-48]
	str	r3, [fp, #-52]
	ldr	r3, [fp, #-48]
	mov	r3, r3, lsr #8
	bic	r3, r3, #-16777216
	bic	r3, r3, #255
	str	r3, [fp, #-8]
	ldr	r3, [fp, #-48]
	mov	r3, r3, asl #8
	bic	r3, r3, #-16777216
	bic	r3, r3, #255
	str	r3, [fp, #-12]
	ldr	r3, [fp, #-52]
	mov	r3, r3, lsr #24
	str	r3, [fp, #-16]
	ldr	r3, [fp, #-52]
	mov	r3, r3, lsr #16
	uxtb	r3, r3
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-52]
	mov	r3, r3, lsr #8
	uxtb	r3, r3
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-52]
	uxtb	r3, r3
	str	r3, [fp, #-28]
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-16]
	orr	r3, r2, r3
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r3, r3, asl #8
	str	r3, [fp, #-32]
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-20]
	orr	r3, r2, r3
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-32]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-24]
	orr	r3, r2, r3
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r2, [fp, #-12]
	ldr	r3, [fp, #-16]
	orr	r3, r2, r3
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-32]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r2, [fp, #-12]
	ldr	r3, [fp, #-20]
	orr	r3, r2, r3
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r2, [fp, #-8]
	ldr	r3, [fp, #-28]
	orr	r3, r2, r3
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-32]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r2, [fp, #-12]
	ldr	r3, [fp, #-24]
	orr	r3, r2, r3
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldr	r3, [r3, #0]
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-32]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r2, [fp, #-12]
	ldr	r3, [fp, #-28]
	orr	r3, r2, r3
	mov	r3, r3, asl #2
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldr	r2, [r3, #0]
	ldr	r3, [fp, #-32]
	eor	r3, r2, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u32_mul_m1, .-gf2_fast_u32_mul_m1
	.align	2
	.global	gf2_fast_u32_inv_m1
	.type	gf2_fast_u32_inv_m1, %function
gf2_fast_u32_inv_m1:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-12]
	bl	gf2_long_mod_inverse_u32
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u32_inv_m1, .-gf2_fast_u32_inv_m1
	.align	2
	.global	gf2_fast_u32_div_m1
	.type	gf2_fast_u32_div_m1, %function
gf2_fast_u32_div_m1:
	@ args = 4, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #16
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	str	r3, [fp, #-20]
	ldr	r0, [fp, #-20]
	ldr	r1, [fp, #4]
	bl	gf2_long_mod_inverse_u32
	mov	r3, r0
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-12]
	ldr	r2, [fp, #-16]
	bl	gf2_fast_u32_mul_m1
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u32_div_m1, .-gf2_fast_u32_div_m1
	.align	2
	.global	gf2_fast_u32_init_m2
	.type	gf2_fast_u32_init_m2, %function
gf2_fast_u32_init_m2:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #28
	str	r0, [fp, #-24]
	str	r1, [fp, #-28]
	str	r2, [fp, #-32]
	mov	r0, #131072
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-28]
	str	r2, [r3, #0]
	mov	r0, #1024
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-32]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L566
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L567
.L566:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L568
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L568:
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L569
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L569:
	mvn	r3, #0
	b	.L570
.L567:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r2, #0
	str	r2, [r3, #0]
	mov	r3, #1
	strh	r3, [fp, #-14]	@ movhi
	b	.L571
.L588:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #24
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L572
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L573
.L572:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L573:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L574
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L575
.L574:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L575:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L576
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L577
.L576:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L577:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L578
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L579
.L578:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L579:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L580
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L581
.L580:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L581:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L582
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L583
.L582:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L583:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L584
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L585
.L584:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L585:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L586
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L587
.L586:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L587:
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #2
	add	r3, r2, r3
	ldr	r2, [fp, #-20]
	str	r2, [r3, #0]
	ldrh	r3, [fp, #-14]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-14]	@ movhi
.L571:
	ldrh	r3, [fp, #-14]
	cmp	r3, #255
	bls	.L588
	mov	r3, #1
	strh	r3, [fp, #-14]	@ movhi
	b	.L589
.L592:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	mov	r3, #1
	strh	r3, [fp, #-16]	@ movhi
	b	.L590
.L591:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r1, r3, asl #8
	ldrh	r3, [fp, #-16]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldrh	r3, [fp, #-14]	@ movhi
	uxtb	r2, r3
	ldrh	r3, [fp, #-16]	@ movhi
	uxtb	r3, r3
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u8
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-16]	@ movhi
.L590:
	ldrh	r3, [fp, #-16]
	cmp	r3, #255
	bls	.L591
	ldrh	r3, [fp, #-14]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-14]	@ movhi
.L589:
	ldrh	r3, [fp, #-14]
	cmp	r3, #255
	bls	.L592
	mov	r3, #0
.L570:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_fast_u32_init_m2, .-gf2_fast_u32_init_m2
	.align	2
	.global	gf2_fast_u32_deinit_m2
	.type	gf2_fast_u32_deinit_m2, %function
gf2_fast_u32_deinit_m2:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u32_deinit_m2, .-gf2_fast_u32_deinit_m2
	.align	2
	.global	gf2_fast_u32_mul_m2
	.type	gf2_fast_u32_mul_m2, %function
gf2_fast_u32_mul_m2:
	@ args = 0, pretend = 0, frame = 40
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #44
	str	r0, [fp, #-32]
	str	r1, [fp, #-36]
	str	r2, [fp, #-40]
	str	r3, [fp, #-44]
	ldr	r3, [fp, #-40]
	mov	r3, r3, lsr #16
	uxth	r3, r3
	bic	r3, r3, #255
	strh	r3, [fp, #-6]	@ movhi
	ldr	r3, [fp, #-40]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	bic	r3, r3, #255
	strh	r3, [fp, #-8]	@ movhi
	ldr	r3, [fp, #-40]
	uxth	r3, r3
	bic	r3, r3, #255
	strh	r3, [fp, #-10]	@ movhi
	ldr	r3, [fp, #-40]
	uxth	r3, r3
	mov	r3, r3, asl #8
	strh	r3, [fp, #-12]	@ movhi
	ldr	r3, [fp, #-44]
	mov	r3, r3, lsr #24
	strh	r3, [fp, #-14]	@ movhi
	ldr	r3, [fp, #-44]
	mov	r3, r3, lsr #16
	uxth	r3, r3
	uxtb	r3, r3
	strh	r3, [fp, #-16]	@ movhi
	ldr	r3, [fp, #-44]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	uxtb	r3, r3
	strh	r3, [fp, #-18]	@ movhi
	ldr	r3, [fp, #-44]
	uxth	r3, r3
	uxtb	r3, r3
	strh	r3, [fp, #-20]	@ movhi
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-24]
	mov	r3, r3, asl #8
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-24]
	mov	r3, r3, asl #8
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-18]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-24]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-24]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-36]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-20]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-18]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-14]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-24]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-24]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-36]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-20]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-18]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-24]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-24]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-36]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-20]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-18]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	ldr	r2, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldr	r3, [fp, #-24]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-24]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-36]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-24]
	ldrh	r2, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-20]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-32]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r2, r3
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u32_mul_m2, .-gf2_fast_u32_mul_m2
	.align	2
	.global	gf2_fast_u32_inv_m2
	.type	gf2_fast_u32_inv_m2, %function
gf2_fast_u32_inv_m2:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-12]
	bl	gf2_long_mod_inverse_u32
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u32_inv_m2, .-gf2_fast_u32_inv_m2
	.align	2
	.global	gf2_fast_u32_div_m2
	.type	gf2_fast_u32_div_m2, %function
gf2_fast_u32_div_m2:
	@ args = 4, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #16
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	str	r3, [fp, #-20]
	ldr	r0, [fp, #-20]
	ldr	r1, [fp, #4]
	bl	gf2_long_mod_inverse_u32
	mov	r3, r0
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-12]
	ldr	r2, [fp, #-16]
	bl	gf2_fast_u32_mul_m2
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u32_div_m2, .-gf2_fast_u32_div_m2
	.align	2
	.global	gf2_fast_u32_init_m3
	.type	gf2_fast_u32_init_m3, %function
gf2_fast_u32_init_m3:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {r4, fp, lr}
	add	fp, sp, #8
	sub	sp, sp, #28
	str	r0, [fp, #-24]
	str	r1, [fp, #-28]
	str	r2, [fp, #-32]
	str	r3, [fp, #-36]
	mov	r0, #8192
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-28]
	str	r2, [r3, #0]
	mov	r0, #8192
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-32]
	str	r2, [r3, #0]
	mov	r0, #1024
	bl	malloc
	mov	r3, r0
	mov	r2, r3
	ldr	r3, [fp, #-36]
	str	r2, [r3, #0]
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L598
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L598
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	bne	.L599
.L598:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L600
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L600:
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L601
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L601:
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	cmp	r3, #0
	beq	.L602
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	mov	r0, r3
	bl	free
.L602:
	mvn	r3, #0
	b	.L603
.L599:
	ldr	r3, [fp, #-28]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r3, [r3, #0]
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-36]
	ldr	r3, [r3, #0]
	mov	r2, #0
	str	r2, [r3, #0]
	mov	r3, #1
	strh	r3, [fp, #-16]	@ movhi
	b	.L604
.L621:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #24
	str	r3, [fp, #-20]
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L605
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L606
.L605:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L606:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L607
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L608
.L607:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L608:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L609
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L610
.L609:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L610:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L611
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L612
.L611:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L612:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L613
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L614
.L613:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L614:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L615
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L616
.L615:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L616:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L617
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L618
.L617:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L618:
	ldr	r3, [fp, #-20]
	cmp	r3, #0
	bge	.L619
	ldr	r3, [fp, #-20]
	mov	r2, r3, asl #1
	ldr	r3, [fp, #-24]
	eor	r3, r2, r3
	str	r3, [fp, #-20]
	b	.L620
.L619:
	ldr	r3, [fp, #-20]
	mov	r3, r3, asl #1
	str	r3, [fp, #-20]
.L620:
	ldr	r3, [fp, #-36]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-16]
	mov	r3, r3, asl #2
	add	r3, r2, r3
	ldr	r2, [fp, #-20]
	str	r2, [r3, #0]
	ldrh	r3, [fp, #-16]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-16]	@ movhi
.L604:
	ldrh	r3, [fp, #-16]
	cmp	r3, #255
	bls	.L621
	mov	r3, #1
	strh	r3, [fp, #-14]	@ movhi
	b	.L622
.L625:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r3, r3, asl #8
	mov	r3, r3, asl #1
	add	r3, r2, r3
	mov	r2, #0
	strh	r2, [r3, #0]	@ movhi
	mov	r3, #1
	strh	r3, [fp, #-16]	@ movhi
	b	.L623
.L624:
	ldr	r3, [fp, #-28]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r1, r3, asl #8
	ldrh	r3, [fp, #-16]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldrh	r3, [fp, #-14]	@ movhi
	uxtb	r3, r3
	mov	r3, r3, asl #4
	uxtb	r2, r3
	ldrh	r3, [fp, #-16]	@ movhi
	uxtb	r3, r3
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u8
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldr	r3, [fp, #-32]
	ldr	r2, [r3, #0]
	ldrh	r3, [fp, #-14]
	mov	r1, r3, asl #8
	ldrh	r3, [fp, #-16]
	orr	r3, r1, r3
	mov	r3, r3, asl #1
	add	r4, r2, r3
	ldrh	r3, [fp, #-14]	@ movhi
	uxtb	r2, r3
	ldrh	r3, [fp, #-16]	@ movhi
	uxtb	r3, r3
	mov	r0, r2
	mov	r1, r3
	bl	gf2_long_straight_multiply_u8
	mov	r3, r0
	strh	r3, [r4, #0]	@ movhi
	ldrh	r3, [fp, #-16]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-16]	@ movhi
.L623:
	ldrh	r3, [fp, #-16]
	cmp	r3, #255
	bls	.L624
	ldrh	r3, [fp, #-14]	@ movhi
	add	r3, r3, #1
	strh	r3, [fp, #-14]	@ movhi
.L622:
	ldrh	r3, [fp, #-14]
	cmp	r3, #15
	bls	.L625
	mov	r3, #0
.L603:
	mov	r0, r3
	sub	sp, fp, #8
	ldmfd	sp!, {r4, fp, pc}
	.size	gf2_fast_u32_init_m3, .-gf2_fast_u32_init_m3
	.align	2
	.global	gf2_fast_u32_deinit_m3
	.type	gf2_fast_u32_deinit_m3, %function
gf2_fast_u32_deinit_m3:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #16
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	ldr	r0, [fp, #-8]
	bl	free
	ldr	r0, [fp, #-12]
	bl	free
	ldr	r0, [fp, #-16]
	bl	free
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u32_deinit_m3, .-gf2_fast_u32_deinit_m3
	.align	2
	.global	gf2_fast_u32_mul_m3
	.type	gf2_fast_u32_mul_m3, %function
gf2_fast_u32_mul_m3:
	@ args = 4, pretend = 0, frame = 48
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #52
	str	r0, [fp, #-40]
	str	r1, [fp, #-44]
	str	r2, [fp, #-48]
	str	r3, [fp, #-52]
	ldr	r3, [fp, #-52]
	mov	r3, r3, lsr #20
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-6]	@ movhi
	ldr	r3, [fp, #-52]
	mov	r3, r3, lsr #16
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-8]	@ movhi
	ldr	r3, [fp, #-52]
	mov	r3, r3, lsr #12
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-10]	@ movhi
	ldr	r3, [fp, #-52]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-12]	@ movhi
	ldr	r3, [fp, #-52]
	mov	r3, r3, lsr #4
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-14]	@ movhi
	ldr	r3, [fp, #-52]
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-16]	@ movhi
	ldr	r3, [fp, #-52]
	uxth	r3, r3
	mov	r3, r3, asl #4
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-18]	@ movhi
	ldr	r3, [fp, #-52]
	uxth	r3, r3
	mov	r3, r3, asl #8
	uxth	r3, r3
	and	r3, r3, #3840
	strh	r3, [fp, #-20]	@ movhi
	ldr	r3, [fp, #4]
	mov	r3, r3, lsr #24
	strh	r3, [fp, #-22]	@ movhi
	ldr	r3, [fp, #4]
	mov	r3, r3, lsr #16
	uxth	r3, r3
	uxtb	r3, r3
	strh	r3, [fp, #-24]	@ movhi
	ldr	r3, [fp, #4]
	mov	r3, r3, lsr #8
	uxth	r3, r3
	uxtb	r3, r3
	strh	r3, [fp, #-26]	@ movhi
	ldr	r3, [fp, #4]
	uxth	r3, r3
	uxtb	r3, r3
	strh	r3, [fp, #-28]	@ movhi
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-22]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-22]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r3, r3, asl #8
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-24]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-24]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-22]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-22]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r3, r3, asl #8
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-24]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-24]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #-22]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-22]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-32]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-48]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-6]	@ movhi
	ldrh	r3, [fp, #-28]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-8]	@ movhi
	ldrh	r3, [fp, #-28]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #-24]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-24]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #-22]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-20]	@ movhi
	ldrh	r3, [fp, #-22]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-32]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-48]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-10]	@ movhi
	ldrh	r3, [fp, #-28]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-12]	@ movhi
	ldrh	r3, [fp, #-28]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #-24]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-20]	@ movhi
	ldrh	r3, [fp, #-24]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-32]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-48]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-14]	@ movhi
	ldrh	r3, [fp, #-28]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-16]	@ movhi
	ldrh	r3, [fp, #-28]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r2, [r3, #0]
	ldrh	r1, [fp, #-20]	@ movhi
	ldrh	r3, [fp, #-26]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	uxth	r3, r3
	ldr	r2, [fp, #-32]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldr	r3, [fp, #-32]
	mov	r2, r3, asl #8
	ldr	r3, [fp, #-32]
	mov	r3, r3, lsr #24
	mov	r3, r3, asl #2
	ldr	r1, [fp, #-48]
	add	r3, r1, r3
	ldr	r3, [r3, #0]
	eor	r3, r2, r3
	str	r3, [fp, #-32]
	ldrh	r2, [fp, #-18]	@ movhi
	ldrh	r3, [fp, #-28]	@ movhi
	orr	r3, r2, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r2, [fp, #-40]
	add	r3, r2, r3
	ldrh	r3, [r3, #0]
	mov	r2, r3
	ldr	r3, [fp, #-32]
	eor	r2, r2, r3
	ldrh	r1, [fp, #-20]	@ movhi
	ldrh	r3, [fp, #-28]	@ movhi
	orr	r3, r1, r3
	uxth	r3, r3
	mov	r3, r3, asl #1
	ldr	r1, [fp, #-44]
	add	r3, r1, r3
	ldrh	r3, [r3, #0]
	eor	r3, r2, r3
	mov	r0, r3
	add	sp, fp, #0
	ldmfd	sp!, {fp}
	bx	lr
	.size	gf2_fast_u32_mul_m3, .-gf2_fast_u32_mul_m3
	.align	2
	.global	gf2_fast_u32_inv_m3
	.type	gf2_fast_u32_inv_m3, %function
gf2_fast_u32_inv_m3:
	@ args = 0, pretend = 0, frame = 8
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #8
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-12]
	bl	gf2_long_mod_inverse_u32
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u32_inv_m3, .-gf2_fast_u32_inv_m3
	.align	2
	.global	gf2_fast_u32_div_m3
	.type	gf2_fast_u32_div_m3, %function
gf2_fast_u32_div_m3:
	@ args = 8, pretend = 0, frame = 16
	@ frame_needed = 1, uses_anonymous_args = 0
	stmfd	sp!, {fp, lr}
	add	fp, sp, #4
	sub	sp, sp, #24
	str	r0, [fp, #-8]
	str	r1, [fp, #-12]
	str	r2, [fp, #-16]
	str	r3, [fp, #-20]
	ldr	r0, [fp, #4]
	ldr	r1, [fp, #8]
	bl	gf2_long_mod_inverse_u32
	mov	r3, r0
	str	r3, [sp, #0]
	ldr	r0, [fp, #-8]
	ldr	r1, [fp, #-12]
	ldr	r2, [fp, #-16]
	ldr	r3, [fp, #-20]
	bl	gf2_fast_u32_mul_m3
	mov	r3, r0
	mov	r0, r3
	sub	sp, fp, #4
	ldmfd	sp!, {fp, pc}
	.size	gf2_fast_u32_div_m3, .-gf2_fast_u32_div_m3
	.ident	"GCC: (Debian 4.6.3-8+rpi1) 4.6.3"
	.section	.note.GNU-stack,"",%progbits

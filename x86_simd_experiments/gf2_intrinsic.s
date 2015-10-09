	.file	"gf2_intrinsic.c"
	.text
	.globl	gf2_vp_intrinsics
	.type	gf2_vp_intrinsics, @function
gf2_vp_intrinsics:
.LFB650:
	.cfi_startproc
	vmovdqa	%xmm0, %xmm3
	vpxor	%xmm0, %xmm0, %xmm0
	movl	$7, %eax
.L2:
	movl	%eax, -12(%rsp)
	vmovd	-12(%rsp), %xmm6
	vpsllw	%xmm6, %xmm1, %xmm5
	vpxor	%xmm3, %xmm0, %xmm4
	vpblendvb	%xmm5, %xmm4, %xmm0, %xmm0
	vpaddb	%xmm3, %xmm3, %xmm4
	vpxor	%xmm2, %xmm4, %xmm5
	vpblendvb	%xmm3, %xmm5, %xmm4, %xmm3
	subl	$1, %eax
	cmpl	$-1, %eax
	jne	.L2
	rep ret
	.cfi_endproc
.LFE650:
	.size	gf2_vp_intrinsics, .-gf2_vp_intrinsics
	.globl	gf2_vp_intrinsics_unrolled
	.type	gf2_vp_intrinsics_unrolled, @function
gf2_vp_intrinsics_unrolled:
.LFB652:
	.cfi_startproc
	vpsllw	$7, %xmm1, %xmm8
	vpxor	%xmm4, %xmm4, %xmm4
	vpblendvb	%xmm8, %xmm0, %xmm4, %xmm9
	vpaddb	%xmm0, %xmm0, %xmm3
	vpxor	%xmm2, %xmm3, %xmm7
	vpblendvb	%xmm0, %xmm7, %xmm3, %xmm0
	vpsllw	$6, %xmm1, %xmm7
	vpxor	%xmm9, %xmm0, %xmm3
	vpblendvb	%xmm7, %xmm3, %xmm9, %xmm8
	vpaddb	%xmm0, %xmm0, %xmm3
	vpxor	%xmm2, %xmm3, %xmm7
	vpblendvb	%xmm0, %xmm7, %xmm3, %xmm0
	vpsllw	$5, %xmm1, %xmm6
	vpxor	%xmm8, %xmm0, %xmm3
	vpblendvb	%xmm6, %xmm3, %xmm8, %xmm7
	vpaddb	%xmm0, %xmm0, %xmm3
	vpxor	%xmm2, %xmm3, %xmm5
	vpblendvb	%xmm0, %xmm5, %xmm3, %xmm0
	vpsllw	$4, %xmm1, %xmm5
	vpxor	%xmm7, %xmm0, %xmm3
	vpblendvb	%xmm5, %xmm3, %xmm7, %xmm6
	vpaddb	%xmm0, %xmm0, %xmm3
	vpxor	%xmm2, %xmm3, %xmm7
	vpblendvb	%xmm0, %xmm7, %xmm3, %xmm7
	vpsllw	$3, %xmm1, %xmm4
	vpxor	%xmm6, %xmm7, %xmm0
	vpblendvb	%xmm4, %xmm0, %xmm6, %xmm5
	vpaddb	%xmm7, %xmm7, %xmm3
	vpxor	%xmm2, %xmm3, %xmm0
	vpblendvb	%xmm7, %xmm0, %xmm3, %xmm7
	vpsllw	$2, %xmm1, %xmm3
	vpxor	%xmm5, %xmm7, %xmm0
	vpblendvb	%xmm3, %xmm0, %xmm5, %xmm4
	vpaddb	%xmm7, %xmm7, %xmm6
	vpxor	%xmm2, %xmm6, %xmm5
	vpblendvb	%xmm7, %xmm5, %xmm6, %xmm5
	vpsllw	$1, %xmm1, %xmm3
	vpxor	%xmm4, %xmm5, %xmm0
	vpblendvb	%xmm3, %xmm0, %xmm4, %xmm3
	vpaddb	%xmm5, %xmm5, %xmm0
	vpxor	%xmm2, %xmm0, %xmm2
	vpblendvb	%xmm5, %xmm2, %xmm0, %xmm0
	vpxor	%xmm3, %xmm0, %xmm0
	vpblendvb	%xmm1, %xmm0, %xmm3, %xmm0
	ret
	.cfi_endproc
.LFE652:
	.size	gf2_vp_intrinsics_unrolled, .-gf2_vp_intrinsics_unrolled
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"ok"
.LC1:
	.string	"not ok"
.LC4:
	.string	"Basic test %s\n"
	.text
	.globl	test_gf2_vp_intrinsics
	.type	test_gf2_vp_intrinsics, @function
test_gf2_vp_intrinsics:
.LFB651:
	.cfi_startproc
	subq	$24, %rsp
	.cfi_def_cfa_offset 32
	vmovdqa	poly(%rip), %xmm2
	vmovdqa	.LC2(%rip), %xmm1
	vmovdqa	.LC3(%rip), %xmm0
	call	*%rdi
	vmovaps	%xmm0, (%rsp)
	movq	%rsp, %rax
	leaq	16(%rsp), %rsi
	movl	$1, %edx
	movl	$0, %ecx
.L7:
	cmpb	$1, (%rax)
	cmovne	%ecx, %edx
	addq	$1, %rax
	cmpq	%rsi, %rax
	jne	.L7
	testl	%edx, %edx
	movl	$.LC1, %esi
	movl	$.LC0, %eax
	cmovne	%rax, %rsi
	movl	$.LC4, %edi
	movl	$0, %eax
	call	printf
	addq	$24, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE651:
	.size	test_gf2_vp_intrinsics, .-test_gf2_vp_intrinsics
	.globl	main
	.type	main, @function
main:
.LFB653:
	.cfi_startproc
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movl	$gf2_vp_intrinsics, %edi
	call	test_gf2_vp_intrinsics
	movl	$gf2_vp_intrinsics_unrolled, %edi
	call	test_gf2_vp_intrinsics
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE653:
	.size	main, .-main
	.globl	poly
	.data
	.align 16
	.type	poly, @object
	.size	poly, 16
poly:
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.byte	27
	.comm	a,16,16
	.section	.rodata.cst16,"aM",@progbits,16
	.align 16
.LC2:
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.align 16
.LC3:
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.byte	83
	.byte	-54
	.ident	"GCC: (Debian 4.9.2-10) 4.9.2"
	.section	.note.GNU-stack,"",@progbits

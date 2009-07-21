/* -*- C -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "clib/FastGF2.h"

MODULE = Math::FastGF2		PACKAGE = Math::FastGF2		

PROTOTYPES: ENABLE

unsigned long
gf2_mul (width, a, b)
	int	width
	unsigned long	a
	unsigned long	b

unsigned long
gf2_inv (width, a)
	int	width
	unsigned long	a

unsigned long
gf2_div (width, a, b)
	int	width
	unsigned long	a
	unsigned long	b

unsigned long
gf2_pow (width, a, b)
	int	width
	unsigned long	a
	unsigned long	b

unsigned long
gf2_info (bits)
	int bits



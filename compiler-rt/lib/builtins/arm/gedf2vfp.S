//===-- gedf2vfp.S - Implement gedf2vfp -----------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "../assembly.h"

//
// extern int __gedf2vfp(double a, double b);
//
// Returns one iff a >= b and neither is NaN.
// Uses Darwin calling convention where double precision arguments are passsed
// like in GPR pairs.
//
	.syntax unified
	.p2align 2
DEFINE_COMPILERRT_FUNCTION(__gedf2vfp)
#if defined(COMPILER_RT_ARMHF_TARGET)
	vcmp.f64 d0, d1
#else
	VMOV_TO_DOUBLE(d6, r0, r1)	// load r0/r1 pair in double register
	VMOV_TO_DOUBLE(d7, r2, r3)	// load r2/r3 pair in double register
	vcmp.f64 d6, d7
#endif
	vmrs	apsr_nzcv, fpscr
	ITE(ge)
	movge	r0, #1      // set result register to 1 if greater than or equal
	movlt	r0, #0
	bx	lr
END_COMPILERRT_FUNCTION(__gedf2vfp)

NO_EXEC_STACK_DIRECTIVE


; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=armv4t-eabi %s -o -  | FileCheck %s --check-prefix=V4T
; RUN: llc -mtriple=armv6-eabi %s -o -   | FileCheck %s --check-prefix=V6
; RUN: llc -mtriple=armv6t2-eabi %s -o - | FileCheck %s --check-prefix=V6T2

; Check for several conditions that should result in USAT.
; For example, the base test is equivalent to
; x < 0 ? 0 : (x > k ? k : x) in C. All patterns that bound x
; to the interval [0, k] where k + 1 is a power of 2 can be
; transformed into USAT. At the end there are some tests
; checking that conditionals are not transformed if they don't
; match the right pattern.

;
; Base tests with different bit widths
;

; x < 0 ? 0 : (x > k ? k : x)
; 32-bit base test
define i32 @unsigned_sat_base_32bit(i32 %x) #0 {
; V4T-LABEL: unsigned_sat_base_32bit:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI0_0
; V4T-NEXT:    cmp r0, r1
; V4T-NEXT:    movlt r1, r0
; V4T-NEXT:    bic r0, r1, r1, asr #31
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI0_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: unsigned_sat_base_32bit:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    ldr r1, .LCPI0_0
; V6-NEXT:    cmp r0, r1
; V6-NEXT:    movlt r1, r0
; V6-NEXT:    bic r0, r1, r1, asr #31
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI0_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: unsigned_sat_base_32bit:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    movw r1, #65535
; V6T2-NEXT:    movt r1, #127
; V6T2-NEXT:    cmp r0, r1
; V6T2-NEXT:    movlt r1, r0
; V6T2-NEXT:    bic r0, r1, r1, asr #31
; V6T2-NEXT:    bx lr
entry:
  %0 = icmp slt i32 %x, 8388607
  %saturateUp = select i1 %0, i32 %x, i32 8388607
  %1 = icmp sgt i32 %saturateUp, 0
  %saturateLow = select i1 %1, i32 %saturateUp, i32 0
  ret i32 %saturateLow
}

; x < 0 ? 0 : (x > k ? k : x)
; 16-bit base test
define i16 @unsigned_sat_base_16bit(i16 %x) #0 {
; V4T-LABEL: unsigned_sat_base_16bit:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    mov r2, #255
; V4T-NEXT:    lsl r1, r0, #16
; V4T-NEXT:    orr r2, r2, #1792
; V4T-NEXT:    asr r1, r1, #16
; V4T-NEXT:    cmp r1, r2
; V4T-NEXT:    movlt r2, r0
; V4T-NEXT:    lsl r0, r2, #16
; V4T-NEXT:    bic r0, r2, r0, asr #31
; V4T-NEXT:    bx lr
;
; V6-LABEL: unsigned_sat_base_16bit:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    mov r2, #255
; V6-NEXT:    sxth r1, r0
; V6-NEXT:    orr r2, r2, #1792
; V6-NEXT:    cmp r1, r2
; V6-NEXT:    movlt r2, r0
; V6-NEXT:    sxth r0, r2
; V6-NEXT:    bic r0, r2, r0, asr #15
; V6-NEXT:    bx lr
;
; V6T2-LABEL: unsigned_sat_base_16bit:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    sxth r1, r0
; V6T2-NEXT:    movw r2, #2047
; V6T2-NEXT:    cmp r1, r2
; V6T2-NEXT:    movlt r2, r0
; V6T2-NEXT:    sxth r0, r2
; V6T2-NEXT:    bic r0, r2, r0, asr #15
; V6T2-NEXT:    bx lr
entry:
  %0 = icmp slt i16 %x, 2047
  %saturateUp = select i1 %0, i16 %x, i16 2047
  %1 = icmp sgt i16 %saturateUp, 0
  %saturateLow = select i1 %1, i16 %saturateUp, i16 0
  ret i16 %saturateLow
}

; x < 0 ? 0 : (x > k ? k : x)
; 8-bit base test
define i8 @unsigned_sat_base_8bit(i8 %x) #0 {
; V4T-LABEL: unsigned_sat_base_8bit:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    lsl r1, r0, #24
; V4T-NEXT:    asr r1, r1, #24
; V4T-NEXT:    cmp r1, #31
; V4T-NEXT:    movge r0, #31
; V4T-NEXT:    lsl r1, r0, #24
; V4T-NEXT:    bic r0, r0, r1, asr #31
; V4T-NEXT:    bx lr
;
; V6-LABEL: unsigned_sat_base_8bit:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    sxtb r1, r0
; V6-NEXT:    cmp r1, #31
; V6-NEXT:    movge r0, #31
; V6-NEXT:    sxtb r1, r0
; V6-NEXT:    bic r0, r0, r1, asr #7
; V6-NEXT:    bx lr
;
; V6T2-LABEL: unsigned_sat_base_8bit:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    sxtb r1, r0
; V6T2-NEXT:    cmp r1, #31
; V6T2-NEXT:    movge r0, #31
; V6T2-NEXT:    sxtb r1, r0
; V6T2-NEXT:    bic r0, r0, r1, asr #7
; V6T2-NEXT:    bx lr
entry:
  %0 = icmp slt i8 %x, 31
  %saturateUp = select i1 %0, i8 %x, i8 31
  %1 = icmp sgt i8 %saturateUp, 0
  %saturateLow = select i1 %1, i8 %saturateUp, i8 0
  ret i8 %saturateLow
}

;
; Tests where the conditionals that check for upper and lower bounds,
; or the < and > operators, are arranged in different ways. Only some
; of the possible combinations that lead to USAT are tested.
;
; x < 0 ? 0 : (x < k ? x : k)
define i32 @unsigned_sat_lower_upper_1(i32 %x) #0 {
; V4T-LABEL: unsigned_sat_lower_upper_1:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI3_0
; V4T-NEXT:    cmp r0, r1
; V4T-NEXT:    movlt r1, r0
; V4T-NEXT:    bic r0, r1, r1, asr #31
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI3_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: unsigned_sat_lower_upper_1:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    ldr r1, .LCPI3_0
; V6-NEXT:    cmp r0, r1
; V6-NEXT:    movlt r1, r0
; V6-NEXT:    bic r0, r1, r1, asr #31
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI3_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: unsigned_sat_lower_upper_1:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    movw r1, #65535
; V6T2-NEXT:    movt r1, #127
; V6T2-NEXT:    cmp r0, r1
; V6T2-NEXT:    movlt r1, r0
; V6T2-NEXT:    bic r0, r1, r1, asr #31
; V6T2-NEXT:    bx lr
entry:
  %cmpUp = icmp slt i32 %x, 8388607
  %saturateUp = select i1 %cmpUp, i32 %x, i32 8388607
  %0 = icmp sgt i32 %saturateUp, 0
  %saturateLow = select i1 %0, i32 %saturateUp, i32 0
  ret i32 %saturateLow
}

; x > 0 ? (x > k ? k : x) : 0
define i32 @unsigned_sat_lower_upper_2(i32 %x) #0 {
; V4T-LABEL: unsigned_sat_lower_upper_2:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI4_0
; V4T-NEXT:    cmp r0, r1
; V4T-NEXT:    movlt r1, r0
; V4T-NEXT:    bic r0, r1, r1, asr #31
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI4_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: unsigned_sat_lower_upper_2:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    ldr r1, .LCPI4_0
; V6-NEXT:    cmp r0, r1
; V6-NEXT:    movlt r1, r0
; V6-NEXT:    bic r0, r1, r1, asr #31
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI4_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: unsigned_sat_lower_upper_2:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    movw r1, #65535
; V6T2-NEXT:    movt r1, #127
; V6T2-NEXT:    cmp r0, r1
; V6T2-NEXT:    movlt r1, r0
; V6T2-NEXT:    bic r0, r1, r1, asr #31
; V6T2-NEXT:    bx lr
entry:
  %0 = icmp slt i32 %x, 8388607
  %saturateUp = select i1 %0, i32 %x, i32 8388607
  %1 = icmp sgt i32 %saturateUp, 0
  %saturateLow = select i1 %1, i32 %saturateUp, i32 0
  ret i32 %saturateLow
}

; x < k ? (x < 0 ? 0 : x) : k
define i32 @unsigned_sat_upper_lower_1(i32 %x) #0 {
; V4T-LABEL: unsigned_sat_upper_lower_1:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    bic r1, r0, r0, asr #31
; V4T-NEXT:    ldr r0, .LCPI5_0
; V4T-NEXT:    cmp r1, r0
; V4T-NEXT:    movlt r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI5_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: unsigned_sat_upper_lower_1:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    bic r1, r0, r0, asr #31
; V6-NEXT:    ldr r0, .LCPI5_0
; V6-NEXT:    cmp r1, r0
; V6-NEXT:    movlt r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI5_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: unsigned_sat_upper_lower_1:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    bic r1, r0, r0, asr #31
; V6T2-NEXT:    movw r0, #65535
; V6T2-NEXT:    movt r0, #127
; V6T2-NEXT:    cmp r1, r0
; V6T2-NEXT:    movlt r0, r1
; V6T2-NEXT:    bx lr
entry:
  %0 = icmp sgt i32 %x, 0
  %saturateLow = select i1 %0, i32 %x, i32 0
  %1 = icmp slt i32 %saturateLow, 8388607
  %saturateUp = select i1 %1, i32 %saturateLow, i32 8388607
  ret i32 %saturateUp
}

; x > k ? k : (x < 0 ? 0 : x)
define i32 @unsigned_sat_upper_lower_2(i32 %x) #0 {
; V4T-LABEL: unsigned_sat_upper_lower_2:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    bic r1, r0, r0, asr #31
; V4T-NEXT:    ldr r0, .LCPI6_0
; V4T-NEXT:    cmp r1, r0
; V4T-NEXT:    movlt r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI6_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: unsigned_sat_upper_lower_2:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    bic r1, r0, r0, asr #31
; V6-NEXT:    ldr r0, .LCPI6_0
; V6-NEXT:    cmp r1, r0
; V6-NEXT:    movlt r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI6_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: unsigned_sat_upper_lower_2:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    bic r1, r0, r0, asr #31
; V6T2-NEXT:    movw r0, #65535
; V6T2-NEXT:    movt r0, #127
; V6T2-NEXT:    cmp r1, r0
; V6T2-NEXT:    movlt r0, r1
; V6T2-NEXT:    bx lr
entry:
  %0 = icmp sgt i32 %x, 0
  %saturateLow = select i1 %0, i32 %x, i32 0
  %1 = icmp slt i32 %saturateLow, 8388607
  %saturateUp = select i1 %1, i32 %saturateLow, i32 8388607
  ret i32 %saturateUp
}

; k < x ? k : (x > 0 ? x : 0)
define i32 @unsigned_sat_upper_lower_3(i32 %x) #0 {
; V4T-LABEL: unsigned_sat_upper_lower_3:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    bic r1, r0, r0, asr #31
; V4T-NEXT:    ldr r0, .LCPI7_0
; V4T-NEXT:    cmp r1, r0
; V4T-NEXT:    movlt r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI7_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: unsigned_sat_upper_lower_3:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    bic r1, r0, r0, asr #31
; V6-NEXT:    ldr r0, .LCPI7_0
; V6-NEXT:    cmp r1, r0
; V6-NEXT:    movlt r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI7_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: unsigned_sat_upper_lower_3:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    bic r1, r0, r0, asr #31
; V6T2-NEXT:    movw r0, #65535
; V6T2-NEXT:    movt r0, #127
; V6T2-NEXT:    cmp r1, r0
; V6T2-NEXT:    movlt r0, r1
; V6T2-NEXT:    bx lr
entry:
  %cmpLow = icmp sgt i32 %x, 0
  %saturateLow = select i1 %cmpLow, i32 %x, i32 0
  %0 = icmp slt i32 %saturateLow, 8388607
  %saturateUp = select i1 %0, i32 %saturateLow, i32 8388607
  ret i32 %saturateUp
}

;
; The following tests check for patterns that should not transform
; into USAT but are similar enough that could confuse the selector.
;
; x > k ? k : (x > 0 ? 0 : x)
; First condition upper-saturates, second doesn't lower-saturate.
define i32 @no_unsigned_sat_missing_lower(i32 %x) #0 {
; V4T-LABEL: no_unsigned_sat_missing_lower:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI8_0
; V4T-NEXT:    cmp r0, #8388608
; V4T-NEXT:    andlt r1, r0, r0, asr #31
; V4T-NEXT:    mov r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI8_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: no_unsigned_sat_missing_lower:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    ldr r1, .LCPI8_0
; V6-NEXT:    cmp r0, #8388608
; V6-NEXT:    andlt r1, r0, r0, asr #31
; V6-NEXT:    mov r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI8_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: no_unsigned_sat_missing_lower:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    and r1, r0, r0, asr #31
; V6T2-NEXT:    cmp r0, #8388608
; V6T2-NEXT:    movwge r1, #65535
; V6T2-NEXT:    movtge r1, #127
; V6T2-NEXT:    mov r0, r1
; V6T2-NEXT:    bx lr
entry:
  %cmpUp = icmp sgt i32 %x, 8388607
  %0 = icmp slt i32 %x, 0
  %saturateLow = select i1 %0, i32 %x, i32 0
  %saturateUp = select i1 %cmpUp, i32 8388607, i32 %saturateLow
  ret i32 %saturateUp
}

; x < k ? k : (x < 0 ? 0 : x)
; Second condition lower-saturates, first doesn't upper-saturate.
define i32 @no_unsigned_sat_missing_upper(i32 %x) #0 {
; V4T-LABEL: no_unsigned_sat_missing_upper:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI9_0
; V4T-NEXT:    cmp r0, r1
; V4T-NEXT:    bicge r1, r0, r0, asr #31
; V4T-NEXT:    mov r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI9_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: no_unsigned_sat_missing_upper:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    ldr r1, .LCPI9_0
; V6-NEXT:    cmp r0, r1
; V6-NEXT:    bicge r1, r0, r0, asr #31
; V6-NEXT:    mov r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI9_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: no_unsigned_sat_missing_upper:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    movw r2, #65535
; V6T2-NEXT:    bic r1, r0, r0, asr #31
; V6T2-NEXT:    movt r2, #127
; V6T2-NEXT:    cmp r0, r2
; V6T2-NEXT:    movwlt r1, #65535
; V6T2-NEXT:    movtlt r1, #127
; V6T2-NEXT:    mov r0, r1
; V6T2-NEXT:    bx lr
entry:
  %cmpUp = icmp slt i32 %x, 8388607
  %0 = icmp sgt i32 %x, 0
  %saturateLow = select i1 %0, i32 %x, i32 0
  %saturateUp = select i1 %cmpUp, i32 8388607, i32 %saturateLow
  ret i32 %saturateUp
}

; Lower constant is different in the select and in the compare
define i32 @no_unsigned_sat_incorrect_constant(i32 %x) #0 {
; V4T-LABEL: no_unsigned_sat_incorrect_constant:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    orr r1, r0, r0, asr #31
; V4T-NEXT:    ldr r0, .LCPI10_0
; V4T-NEXT:    cmp r1, r0
; V4T-NEXT:    movlt r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI10_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: no_unsigned_sat_incorrect_constant:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    orr r1, r0, r0, asr #31
; V6-NEXT:    ldr r0, .LCPI10_0
; V6-NEXT:    cmp r1, r0
; V6-NEXT:    movlt r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI10_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: no_unsigned_sat_incorrect_constant:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    orr r1, r0, r0, asr #31
; V6T2-NEXT:    movw r0, #65535
; V6T2-NEXT:    movt r0, #127
; V6T2-NEXT:    cmp r1, r0
; V6T2-NEXT:    movlt r0, r1
; V6T2-NEXT:    bx lr
entry:
  %cmpLow.inv = icmp sgt i32 %x, -1
  %saturateLow = select i1 %cmpLow.inv, i32 %x, i32 -1
  %0 = icmp slt i32 %saturateLow, 8388607
  %saturateUp = select i1 %0, i32 %saturateLow, i32 8388607
  ret i32 %saturateUp
}

; The interval is [0, k] but k+1 is not a power of 2
define i32 @no_unsigned_sat_incorrect_constant2(i32 %x) #0 {
; V4T-LABEL: no_unsigned_sat_incorrect_constant2:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    bic r1, r0, r0, asr #31
; V4T-NEXT:    mov r0, #1
; V4T-NEXT:    orr r0, r0, #8388608
; V4T-NEXT:    cmp r1, #8388608
; V4T-NEXT:    movle r0, r1
; V4T-NEXT:    bx lr
;
; V6-LABEL: no_unsigned_sat_incorrect_constant2:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    bic r1, r0, r0, asr #31
; V6-NEXT:    mov r0, #1
; V6-NEXT:    orr r0, r0, #8388608
; V6-NEXT:    cmp r1, #8388608
; V6-NEXT:    movle r0, r1
; V6-NEXT:    bx lr
;
; V6T2-LABEL: no_unsigned_sat_incorrect_constant2:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    bic r1, r0, r0, asr #31
; V6T2-NEXT:    movw r0, #1
; V6T2-NEXT:    movt r0, #128
; V6T2-NEXT:    cmp r1, #8388608
; V6T2-NEXT:    movle r0, r1
; V6T2-NEXT:    bx lr
entry:
  %0 = icmp sgt i32 %x, 0
  %saturateLow = select i1 %0, i32 %x, i32 0
  %1 = icmp slt i32 %saturateLow, 8388609
  %saturateUp = select i1 %1, i32 %saturateLow, i32 8388609
  ret i32 %saturateUp
}

; The interval is not [0, k]
define i32 @no_unsigned_sat_incorrect_interval(i32 %x) #0 {
; V4T-LABEL: no_unsigned_sat_incorrect_interval:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI12_0
; V4T-NEXT:    cmn r0, #4
; V4T-NEXT:    mvnle r0, #3
; V4T-NEXT:    cmp r0, r1
; V4T-NEXT:    movge r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI12_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: no_unsigned_sat_incorrect_interval:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    ldr r1, .LCPI12_0
; V6-NEXT:    cmn r0, #4
; V6-NEXT:    mvnle r0, #3
; V6-NEXT:    cmp r0, r1
; V6-NEXT:    movge r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI12_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: no_unsigned_sat_incorrect_interval:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    cmn r0, #4
; V6T2-NEXT:    movw r1, #65535
; V6T2-NEXT:    mvnle r0, #3
; V6T2-NEXT:    movt r1, #127
; V6T2-NEXT:    cmp r0, r1
; V6T2-NEXT:    movge r0, r1
; V6T2-NEXT:    bx lr
entry:
  %0 = icmp sgt i32 %x, -4
  %saturateLow = select i1 %0, i32 %x, i32 -4
  %1 = icmp slt i32 %saturateLow, 8388607
  %saturateUp = select i1 %1, i32 %saturateLow, i32 8388607
  ret i32 %saturateUp
}

; The returned value (y) is not the same as the tested value (x).
define i32 @no_unsigned_sat_incorrect_return(i32 %x, i32 %y) #0 {
; V4T-LABEL: no_unsigned_sat_incorrect_return:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    cmp r0, #0
; V4T-NEXT:    ldr r2, .LCPI13_0
; V4T-NEXT:    movmi r1, #0
; V4T-NEXT:    cmp r0, #8388608
; V4T-NEXT:    movlt r2, r1
; V4T-NEXT:    mov r0, r2
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI13_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: no_unsigned_sat_incorrect_return:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    cmp r0, #0
; V6-NEXT:    ldr r2, .LCPI13_0
; V6-NEXT:    movmi r1, #0
; V6-NEXT:    cmp r0, #8388608
; V6-NEXT:    movlt r2, r1
; V6-NEXT:    mov r0, r2
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI13_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: no_unsigned_sat_incorrect_return:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    cmp r0, #0
; V6T2-NEXT:    movwmi r1, #0
; V6T2-NEXT:    cmp r0, #8388608
; V6T2-NEXT:    movwge r1, #65535
; V6T2-NEXT:    movtge r1, #127
; V6T2-NEXT:    mov r0, r1
; V6T2-NEXT:    bx lr
entry:
  %cmpUp = icmp sgt i32 %x, 8388607
  %cmpLow = icmp slt i32 %x, 0
  %saturateLow = select i1 %cmpLow, i32 0, i32 %y
  %saturateUp = select i1 %cmpUp, i32 8388607, i32 %saturateLow
  ret i32 %saturateUp
}

; One of the values in a compare (y) is not the same as the rest
; of the compare and select values (x).
define i32 @no_unsigned_sat_incorrect_compare(i32 %x, i32 %y) #0 {
; V4T-LABEL: no_unsigned_sat_incorrect_compare:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    cmp r1, #0
; V4T-NEXT:    mov r2, r0
; V4T-NEXT:    movmi r2, #0
; V4T-NEXT:    ldr r1, .LCPI14_0
; V4T-NEXT:    cmp r0, #8388608
; V4T-NEXT:    movlt r1, r2
; V4T-NEXT:    mov r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI14_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: no_unsigned_sat_incorrect_compare:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    cmp r1, #0
; V6-NEXT:    mov r2, r0
; V6-NEXT:    movmi r2, #0
; V6-NEXT:    ldr r1, .LCPI14_0
; V6-NEXT:    cmp r0, #8388608
; V6-NEXT:    movlt r1, r2
; V6-NEXT:    mov r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI14_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: no_unsigned_sat_incorrect_compare:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    cmp r1, #0
; V6T2-NEXT:    mov r1, r0
; V6T2-NEXT:    movwmi r1, #0
; V6T2-NEXT:    cmp r0, #8388608
; V6T2-NEXT:    movwge r1, #65535
; V6T2-NEXT:    movtge r1, #127
; V6T2-NEXT:    mov r0, r1
; V6T2-NEXT:    bx lr
entry:
  %cmpUp = icmp sgt i32 %x, 8388607
  %cmpLow = icmp slt i32 %y, 0
  %saturateLow = select i1 %cmpLow, i32 0, i32 %x
  %saturateUp = select i1 %cmpUp, i32 8388607, i32 %saturateLow
  ret i32 %saturateUp
}

define i32 @mm_unsigned_sat_base_32bit(i32 %x) {
; V4T-LABEL: mm_unsigned_sat_base_32bit:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI15_0
; V4T-NEXT:    cmp r0, r1
; V4T-NEXT:    movlt r1, r0
; V4T-NEXT:    bic r0, r1, r1, asr #31
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI15_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: mm_unsigned_sat_base_32bit:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    usat r0, #23, r0
; V6-NEXT:    bx lr
;
; V6T2-LABEL: mm_unsigned_sat_base_32bit:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    usat r0, #23, r0
; V6T2-NEXT:    bx lr
entry:
  %0 = call i32 @llvm.smin.i32(i32 %x, i32 8388607)
  %1 = call i32 @llvm.smax.i32(i32 %0, i32 0)
  ret i32 %1
}

define i16 @mm_unsigned_sat_base_16bit(i16 %x) {
; V4T-LABEL: mm_unsigned_sat_base_16bit:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    mov r2, #255
; V4T-NEXT:    lsl r0, r0, #16
; V4T-NEXT:    orr r2, r2, #1792
; V4T-NEXT:    asr r1, r0, #16
; V4T-NEXT:    cmp r1, r2
; V4T-NEXT:    asrlt r2, r0, #16
; V4T-NEXT:    bic r0, r2, r2, asr #31
; V4T-NEXT:    bx lr
;
; V6-LABEL: mm_unsigned_sat_base_16bit:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    sxth r0, r0
; V6-NEXT:    usat r0, #11, r0
; V6-NEXT:    bx lr
;
; V6T2-LABEL: mm_unsigned_sat_base_16bit:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    sxth r0, r0
; V6T2-NEXT:    usat r0, #11, r0
; V6T2-NEXT:    bx lr
entry:
  %0 = call i16 @llvm.smin.i16(i16 %x, i16 2047)
  %1 = call i16 @llvm.smax.i16(i16 %0, i16 0)
  ret i16 %1
}

define i8 @mm_unsigned_sat_base_8bit(i8 %x) {
; V4T-LABEL: mm_unsigned_sat_base_8bit:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    lsl r0, r0, #24
; V4T-NEXT:    mov r2, #31
; V4T-NEXT:    asr r1, r0, #24
; V4T-NEXT:    cmp r1, #31
; V4T-NEXT:    asrlt r2, r0, #24
; V4T-NEXT:    bic r0, r2, r2, asr #31
; V4T-NEXT:    bx lr
;
; V6-LABEL: mm_unsigned_sat_base_8bit:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    sxtb r0, r0
; V6-NEXT:    usat r0, #5, r0
; V6-NEXT:    bx lr
;
; V6T2-LABEL: mm_unsigned_sat_base_8bit:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    sxtb r0, r0
; V6T2-NEXT:    usat r0, #5, r0
; V6T2-NEXT:    bx lr
entry:
  %0 = call i8 @llvm.smin.i8(i8 %x, i8 31)
  %1 = call i8 @llvm.smax.i8(i8 %0, i8 0)
  ret i8 %1
}

define i32 @mm_unsigned_sat_lower_upper_1(i32 %x) {
; V4T-LABEL: mm_unsigned_sat_lower_upper_1:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI18_0
; V4T-NEXT:    cmp r0, r1
; V4T-NEXT:    movlt r1, r0
; V4T-NEXT:    bic r0, r1, r1, asr #31
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI18_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: mm_unsigned_sat_lower_upper_1:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    usat r0, #23, r0
; V6-NEXT:    bx lr
;
; V6T2-LABEL: mm_unsigned_sat_lower_upper_1:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    usat r0, #23, r0
; V6T2-NEXT:    bx lr
entry:
  %0 = call i32 @llvm.smin.i32(i32 %x, i32 8388607)
  %1 = call i32 @llvm.smax.i32(i32 %0, i32 0)
  ret i32 %1
}

define i32 @mm_unsigned_sat_lower_upper_2(i32 %x) {
; V4T-LABEL: mm_unsigned_sat_lower_upper_2:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI19_0
; V4T-NEXT:    cmp r0, r1
; V4T-NEXT:    movlt r1, r0
; V4T-NEXT:    bic r0, r1, r1, asr #31
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI19_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: mm_unsigned_sat_lower_upper_2:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    usat r0, #23, r0
; V6-NEXT:    bx lr
;
; V6T2-LABEL: mm_unsigned_sat_lower_upper_2:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    usat r0, #23, r0
; V6T2-NEXT:    bx lr
entry:
  %0 = call i32 @llvm.smin.i32(i32 %x, i32 8388607)
  %1 = call i32 @llvm.smax.i32(i32 %0, i32 0)
  ret i32 %1
}

define i32 @mm_unsigned_sat_upper_lower_1(i32 %x) {
; V4T-LABEL: mm_unsigned_sat_upper_lower_1:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    bic r1, r0, r0, asr #31
; V4T-NEXT:    ldr r0, .LCPI20_0
; V4T-NEXT:    cmp r1, r0
; V4T-NEXT:    movlt r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI20_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: mm_unsigned_sat_upper_lower_1:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    usat r0, #23, r0
; V6-NEXT:    bx lr
;
; V6T2-LABEL: mm_unsigned_sat_upper_lower_1:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    usat r0, #23, r0
; V6T2-NEXT:    bx lr
entry:
  %0 = call i32 @llvm.smax.i32(i32 %x, i32 0)
  %1 = call i32 @llvm.umin.i32(i32 %0, i32 8388607)
  ret i32 %1
}

define i32 @mm_unsigned_sat_upper_lower_2(i32 %x) {
; V4T-LABEL: mm_unsigned_sat_upper_lower_2:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    bic r1, r0, r0, asr #31
; V4T-NEXT:    ldr r0, .LCPI21_0
; V4T-NEXT:    cmp r1, r0
; V4T-NEXT:    movlt r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI21_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: mm_unsigned_sat_upper_lower_2:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    usat r0, #23, r0
; V6-NEXT:    bx lr
;
; V6T2-LABEL: mm_unsigned_sat_upper_lower_2:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    usat r0, #23, r0
; V6T2-NEXT:    bx lr
entry:
  %0 = call i32 @llvm.smax.i32(i32 %x, i32 0)
  %1 = call i32 @llvm.umin.i32(i32 %0, i32 8388607)
  ret i32 %1
}

define i32 @mm_unsigned_sat_upper_lower_3(i32 %x) {
; V4T-LABEL: mm_unsigned_sat_upper_lower_3:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    bic r1, r0, r0, asr #31
; V4T-NEXT:    ldr r0, .LCPI22_0
; V4T-NEXT:    cmp r1, r0
; V4T-NEXT:    movlt r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI22_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: mm_unsigned_sat_upper_lower_3:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    usat r0, #23, r0
; V6-NEXT:    bx lr
;
; V6T2-LABEL: mm_unsigned_sat_upper_lower_3:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    usat r0, #23, r0
; V6T2-NEXT:    bx lr
entry:
  %0 = call i32 @llvm.smax.i32(i32 %x, i32 0)
  %1 = call i32 @llvm.umin.i32(i32 %0, i32 8388607)
  ret i32 %1
}

define i32 @mm_no_unsigned_sat_incorrect_constant(i32 %x) {
; V4T-LABEL: mm_no_unsigned_sat_incorrect_constant:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    orr r1, r0, r0, asr #31
; V4T-NEXT:    ldr r0, .LCPI23_0
; V4T-NEXT:    cmp r1, r0
; V4T-NEXT:    movlt r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI23_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: mm_no_unsigned_sat_incorrect_constant:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    orr r1, r0, r0, asr #31
; V6-NEXT:    ldr r0, .LCPI23_0
; V6-NEXT:    cmp r1, r0
; V6-NEXT:    movlt r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI23_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: mm_no_unsigned_sat_incorrect_constant:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    orr r1, r0, r0, asr #31
; V6T2-NEXT:    movw r0, #65535
; V6T2-NEXT:    movt r0, #127
; V6T2-NEXT:    cmp r1, r0
; V6T2-NEXT:    movlt r0, r1
; V6T2-NEXT:    bx lr
entry:
  %0 = call i32 @llvm.smax.i32(i32 %x, i32 -1)
  %1 = call i32 @llvm.smin.i32(i32 %0, i32 8388607)
  ret i32 %1
}

define i32 @mm_no_unsigned_sat_incorrect_constant2(i32 %x) {
; V4T-LABEL: mm_no_unsigned_sat_incorrect_constant2:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    bic r1, r0, r0, asr #31
; V4T-NEXT:    mov r0, #1
; V4T-NEXT:    orr r0, r0, #8388608
; V4T-NEXT:    cmp r1, #8388608
; V4T-NEXT:    movle r0, r1
; V4T-NEXT:    bx lr
;
; V6-LABEL: mm_no_unsigned_sat_incorrect_constant2:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    bic r1, r0, r0, asr #31
; V6-NEXT:    mov r0, #1
; V6-NEXT:    orr r0, r0, #8388608
; V6-NEXT:    cmp r1, #8388608
; V6-NEXT:    movle r0, r1
; V6-NEXT:    bx lr
;
; V6T2-LABEL: mm_no_unsigned_sat_incorrect_constant2:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    bic r1, r0, r0, asr #31
; V6T2-NEXT:    movw r0, #1
; V6T2-NEXT:    movt r0, #128
; V6T2-NEXT:    cmp r1, #8388608
; V6T2-NEXT:    movle r0, r1
; V6T2-NEXT:    bx lr
entry:
  %0 = call i32 @llvm.smax.i32(i32 %x, i32 0)
  %1 = call i32 @llvm.umin.i32(i32 %0, i32 8388609)
  ret i32 %1
}

define i32 @mm_no_unsigned_sat_incorrect_interval(i32 %x) {
; V4T-LABEL: mm_no_unsigned_sat_incorrect_interval:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    ldr r1, .LCPI25_0
; V4T-NEXT:    cmn r0, #4
; V4T-NEXT:    mvnle r0, #3
; V4T-NEXT:    cmp r0, r1
; V4T-NEXT:    movge r0, r1
; V4T-NEXT:    bx lr
; V4T-NEXT:    .p2align 2
; V4T-NEXT:  @ %bb.1:
; V4T-NEXT:  .LCPI25_0:
; V4T-NEXT:    .long 8388607 @ 0x7fffff
;
; V6-LABEL: mm_no_unsigned_sat_incorrect_interval:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    ldr r1, .LCPI25_0
; V6-NEXT:    cmn r0, #4
; V6-NEXT:    mvnle r0, #3
; V6-NEXT:    cmp r0, r1
; V6-NEXT:    movge r0, r1
; V6-NEXT:    bx lr
; V6-NEXT:    .p2align 2
; V6-NEXT:  @ %bb.1:
; V6-NEXT:  .LCPI25_0:
; V6-NEXT:    .long 8388607 @ 0x7fffff
;
; V6T2-LABEL: mm_no_unsigned_sat_incorrect_interval:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    cmn r0, #4
; V6T2-NEXT:    movw r1, #65535
; V6T2-NEXT:    mvnle r0, #3
; V6T2-NEXT:    movt r1, #127
; V6T2-NEXT:    cmp r0, r1
; V6T2-NEXT:    movge r0, r1
; V6T2-NEXT:    bx lr
entry:
  %0 = call i32 @llvm.smax.i32(i32 %x, i32 -4)
  %1 = call i32 @llvm.smin.i32(i32 %0, i32 8388607)
  ret i32 %1
}

define i32 @test_umin_smax_usat(i32 %x) {
; V4T-LABEL: test_umin_smax_usat:
; V4T:       @ %bb.0: @ %entry
; V4T-NEXT:    bic r0, r0, r0, asr #31
; V4T-NEXT:    cmp r0, #255
; V4T-NEXT:    movge r0, #255
; V4T-NEXT:    bx lr
;
; V6-LABEL: test_umin_smax_usat:
; V6:       @ %bb.0: @ %entry
; V6-NEXT:    usat r0, #8, r0
; V6-NEXT:    bx lr
;
; V6T2-LABEL: test_umin_smax_usat:
; V6T2:       @ %bb.0: @ %entry
; V6T2-NEXT:    usat r0, #8, r0
; V6T2-NEXT:    bx lr
entry:
  %v1 = tail call i32 @llvm.smax.i32(i32 %x, i32 0)
  %v2 = tail call i32 @llvm.umin.i32(i32 %v1, i32 255)
  ret i32 %v2
}

declare i32 @llvm.smin.i32(i32, i32)
declare i32 @llvm.smax.i32(i32, i32)
declare i16 @llvm.smin.i16(i16, i16)
declare i16 @llvm.smax.i16(i16, i16)
declare i8 @llvm.smin.i8(i8, i8)
declare i8 @llvm.smax.i8(i8, i8)
declare i32 @llvm.umin.i32(i32, i32)

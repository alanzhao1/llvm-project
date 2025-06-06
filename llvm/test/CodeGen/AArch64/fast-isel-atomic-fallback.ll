; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=arm64_32-apple-darwin -O0 -fast-isel -verify-machineinstrs \
; RUN:   -aarch64-enable-atomic-cfg-tidy=0 -aarch64-enable-collect-loh=0 \
; RUN:   < %s | FileCheck %s

; FastISel doesn't support cstexprs as operands here, but make
; sure it knows to fallback, at least.

define void @atomic_store_cstexpr_addr(i32 %val) #0 {
; CHECK-LABEL: atomic_store_cstexpr_addr:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    adrp x8, _g@PAGE
; CHECK-NEXT:    add x8, x8, _g@PAGEOFF
; CHECK-NEXT:    ; kill: def $w1 killed $w8 killed $x8
; CHECK-NEXT:    adrp x8, _g@PAGE
; CHECK-NEXT:    add x8, x8, _g@PAGEOFF
; CHECK-NEXT:    stlr w0, [x8]
; CHECK-NEXT:    ret
  store atomic i32 %val, ptr inttoptr (i32 ptrtoint (ptr @g to i32) to ptr) release, align 4
  ret void
}

define i32 @cmpxchg_cstexpr_addr(i32 %cmp, i32 %new, ptr %ps) #0 {
; CHECK-LABEL: cmpxchg_cstexpr_addr:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov w8, w0
; CHECK-NEXT:    adrp x10, _g@PAGE
; CHECK-NEXT:    add x10, x10, _g@PAGEOFF
; CHECK-NEXT:  LBB1_1: ; =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    ldaxr w0, [x10]
; CHECK-NEXT:    cmp w0, w8
; CHECK-NEXT:    b.ne LBB1_3
; CHECK-NEXT:  ; %bb.2: ; in Loop: Header=BB1_1 Depth=1
; CHECK-NEXT:    stlxr w9, w1, [x10]
; CHECK-NEXT:    cbnz w9, LBB1_1
; CHECK-NEXT:  LBB1_3:
; CHECK-NEXT:    subs w8, w0, w8
; CHECK-NEXT:    cset w8, eq
; CHECK-NEXT:    ; kill: def $w1 killed $w8
; CHECK-NEXT:    str w8, [x2]
; CHECK-NEXT:    ret
  %tmp0 = cmpxchg ptr inttoptr (i32 ptrtoint (ptr @g to i32) to ptr), i32 %cmp, i32 %new seq_cst seq_cst
  %tmp1 = extractvalue { i32, i1 } %tmp0, 0
  %tmp2 = extractvalue { i32, i1 } %tmp0, 1
  %tmp3 = zext i1 %tmp2 to i32
  store i32 %tmp3, ptr %ps
  ret i32 %tmp1
}

@g = global i32 0

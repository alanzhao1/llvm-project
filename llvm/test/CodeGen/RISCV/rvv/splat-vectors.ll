; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv32 -mattr=+v,+d,+zvfh -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=riscv64 -mattr=+v,+d,+zvfh -verify-machineinstrs < %s | FileCheck %s

define <vscale x 4 x i32> @splat_c3_nxv4i32(<vscale x 4 x i32> %v) {
; CHECK-LABEL: splat_c3_nxv4i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, zero, e32, m2, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 3
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 4 x i32> %v, i32 3
  %ins = insertelement <vscale x 4 x i32> poison, i32 %x, i32 0
  %splat = shufflevector <vscale x 4 x i32> %ins, <vscale x 4 x i32> poison, <vscale x 4 x i32> zeroinitializer
  ret <vscale x 4 x i32> %splat
}

define <vscale x 4 x i32> @splat_idx_nxv4i32(<vscale x 4 x i32> %v, i64 %idx) {
; CHECK-LABEL: splat_idx_nxv4i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a1, zero, e32, m2, ta, ma
; CHECK-NEXT:    vrgather.vx v10, v8, a0
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 4 x i32> %v, i64 %idx
  %ins = insertelement <vscale x 4 x i32> poison, i32 %x, i32 0
  %splat = shufflevector <vscale x 4 x i32> %ins, <vscale x 4 x i32> poison, <vscale x 4 x i32> zeroinitializer
  ret <vscale x 4 x i32> %splat
}

define <vscale x 8 x i16> @splat_c4_nxv8i16(<vscale x 8 x i16> %v) {
; CHECK-LABEL: splat_c4_nxv8i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, zero, e16, m2, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 4
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 8 x i16> %v, i32 4
  %ins = insertelement <vscale x 8 x i16> poison, i16 %x, i32 0
  %splat = shufflevector <vscale x 8 x i16> %ins, <vscale x 8 x i16> poison, <vscale x 8 x i32> zeroinitializer
  ret <vscale x 8 x i16> %splat
}

define <vscale x 8 x i16> @splat_idx_nxv8i16(<vscale x 8 x i16> %v, i64 %idx) {
; CHECK-LABEL: splat_idx_nxv8i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a1, zero, e16, m2, ta, ma
; CHECK-NEXT:    vrgather.vx v10, v8, a0
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 8 x i16> %v, i64 %idx
  %ins = insertelement <vscale x 8 x i16> poison, i16 %x, i32 0
  %splat = shufflevector <vscale x 8 x i16> %ins, <vscale x 8 x i16> poison, <vscale x 8 x i32> zeroinitializer
  ret <vscale x 8 x i16> %splat
}

define <vscale x 2 x half> @splat_c1_nxv2f16(<vscale x 2 x half> %v) {
; CHECK-LABEL: splat_c1_nxv2f16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, zero, e16, mf2, ta, ma
; CHECK-NEXT:    vrgather.vi v9, v8, 1
; CHECK-NEXT:    vmv1r.v v8, v9
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 2 x half> %v, i32 1
  %ins = insertelement <vscale x 2 x half> poison, half %x, i32 0
  %splat = shufflevector <vscale x 2 x half> %ins, <vscale x 2 x half> poison, <vscale x 2 x i32> zeroinitializer
  ret <vscale x 2 x half> %splat
}

define <vscale x 2 x half> @splat_idx_nxv2f16(<vscale x 2 x half> %v, i64 %idx) {
; CHECK-LABEL: splat_idx_nxv2f16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a1, zero, e16, mf2, ta, ma
; CHECK-NEXT:    vrgather.vx v9, v8, a0
; CHECK-NEXT:    vmv1r.v v8, v9
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 2 x half> %v, i64 %idx
  %ins = insertelement <vscale x 2 x half> poison, half %x, i32 0
  %splat = shufflevector <vscale x 2 x half> %ins, <vscale x 2 x half> poison, <vscale x 2 x i32> zeroinitializer
  ret <vscale x 2 x half> %splat
}

define <vscale x 4 x float> @splat_c3_nxv4f32(<vscale x 4 x float> %v) {
; CHECK-LABEL: splat_c3_nxv4f32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, zero, e32, m2, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 3
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 4 x float> %v, i64 3
  %ins = insertelement <vscale x 4 x float> poison, float %x, i32 0
  %splat = shufflevector <vscale x 4 x float> %ins, <vscale x 4 x float> poison, <vscale x 4 x i32> zeroinitializer
  ret <vscale x 4 x float> %splat
}

define <vscale x 4 x float> @splat_idx_nxv4f32(<vscale x 4 x float> %v, i64 %idx) {
; CHECK-LABEL: splat_idx_nxv4f32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a1, zero, e32, m2, ta, ma
; CHECK-NEXT:    vrgather.vx v10, v8, a0
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 4 x float> %v, i64 %idx
  %ins = insertelement <vscale x 4 x float> poison, float %x, i32 0
  %splat = shufflevector <vscale x 4 x float> %ins, <vscale x 4 x float> poison, <vscale x 4 x i32> zeroinitializer
  ret <vscale x 4 x float> %splat
}

define <vscale x 8 x float> @splat_idx_nxv4f32_nxv8f32(<vscale x 4 x float> %v, i64 %idx) {
; CHECK-LABEL: splat_idx_nxv4f32_nxv8f32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a1, zero, e32, m4, ta, ma
; CHECK-NEXT:    vrgather.vx v12, v8, a0
; CHECK-NEXT:    vmv.v.v v8, v12
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 4 x float> %v, i64 %idx
  %ins = insertelement <vscale x 8 x float> poison, float %x, i32 0
  %splat = shufflevector <vscale x 8 x float> %ins, <vscale x 8 x float> poison, <vscale x 8 x i32> zeroinitializer
  ret <vscale x 8 x float> %splat
}

define <vscale x 4 x float> @splat_idx_v4f32_nxv4f32(<4 x float> %v, i64 %idx) {
; CHECK-LABEL: splat_idx_v4f32_nxv4f32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a1, zero, e32, m2, ta, ma
; CHECK-NEXT:    vrgather.vx v10, v8, a0
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <4 x float> %v, i64 %idx
  %ins = insertelement <vscale x 4 x float> poison, float %x, i32 0
  %splat = shufflevector <vscale x 4 x float> %ins, <vscale x 4 x float> poison, <vscale x 4 x i32> zeroinitializer
  ret <vscale x 4 x float> %splat
}

; Negative test, scale could have a value > 2
define <8 x float> @splat_idx_nxv4f32_v8f32(<vscale x 4 x float> %v, i64 %idx) {
; CHECK-LABEL: splat_idx_nxv4f32_v8f32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 1, e32, m2, ta, ma
; CHECK-NEXT:    vslidedown.vx v8, v8, a0
; CHECK-NEXT:    vfmv.f.s fa5, v8
; CHECK-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; CHECK-NEXT:    vfmv.v.f v8, fa5
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 4 x float> %v, i64 %idx
  %ins = insertelement <8 x float> poison, float %x, i32 0
  %splat = shufflevector <8 x float> %ins, <8 x float> poison, <8 x i32> zeroinitializer
  ret <8 x float> %splat
}

define <vscale x 4 x float> @splat_idx_nxv8f32_nxv4f32_constant_0(<vscale x 8 x float> %v) {
; CHECK-LABEL: splat_idx_nxv8f32_nxv4f32_constant_0:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, zero, e32, m2, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 0
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 8 x float> %v, i64 0
  %ins = insertelement <vscale x 4 x float> poison, float %x, i32 0
  %splat = shufflevector <vscale x 4 x float> %ins, <vscale x 4 x float> poison, <vscale x 4 x i32> zeroinitializer
  ret <vscale x 4 x float> %splat
}

define <vscale x 4 x i8> @splat_idx_nxv8i8_nxv4i8_constant_0(<vscale x 8 x i8> %v) {
; CHECK-LABEL: splat_idx_nxv8i8_nxv4i8_constant_0:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, zero, e8, mf2, ta, ma
; CHECK-NEXT:    vrgather.vi v9, v8, 0
; CHECK-NEXT:    vmv1r.v v8, v9
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 8 x i8> %v, i64 0
  %ins = insertelement <vscale x 4 x i8> poison, i8 %x, i32 0
  %splat = shufflevector <vscale x 4 x i8> %ins, <vscale x 4 x i8> poison, <vscale x 4 x i32> zeroinitializer
  ret <vscale x 4 x i8> %splat
}

define <vscale x 4 x i8> @splat_idx_nxv8i8_nxv4i8_constant_3(<vscale x 8 x i8> %v) {
; CHECK-LABEL: splat_idx_nxv8i8_nxv4i8_constant_3:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli a0, zero, e8, mf2, ta, ma
; CHECK-NEXT:    vrgather.vi v9, v8, 3
; CHECK-NEXT:    vmv1r.v v8, v9
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 8 x i8> %v, i64 3
  %ins = insertelement <vscale x 4 x i8> poison, i8 %x, i32 0
  %splat = shufflevector <vscale x 4 x i8> %ins, <vscale x 4 x i8> poison, <vscale x 4 x i32> zeroinitializer
  ret <vscale x 4 x i8> %splat
}


; Negative test, vscale coule be 2
define <vscale x 4 x i8> @splat_idx_nxv8i8_nxv4i8_constant_15(<vscale x 8 x i8> %v) {
; CHECK-LABEL: splat_idx_nxv8i8_nxv4i8_constant_15:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 1, e8, m1, ta, ma
; CHECK-NEXT:    vslidedown.vi v8, v8, 15
; CHECK-NEXT:    vmv.x.s a0, v8
; CHECK-NEXT:    vsetvli a1, zero, e8, mf2, ta, ma
; CHECK-NEXT:    vmv.v.x v8, a0
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 8 x i8> %v, i64 15
  %ins = insertelement <vscale x 4 x i8> poison, i8 %x, i32 0
  %splat = shufflevector <vscale x 4 x i8> %ins, <vscale x 4 x i8> poison, <vscale x 4 x i32> zeroinitializer
  ret <vscale x 4 x i8> %splat
}

define <8 x float> @splat_idx_nxv4f32_v8f32_constant_0(<vscale x 4 x float> %v) {
; CHECK-LABEL: splat_idx_nxv4f32_v8f32_constant_0:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 0
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 4 x float> %v, i64 0
  %ins = insertelement <8 x float> poison, float %x, i32 0
  %splat = shufflevector <8 x float> %ins, <8 x float> poison, <8 x i32> zeroinitializer
  ret <8 x float> %splat
}

define <8 x float> @splat_idx_nxv4f32_v8f32_constant_7(<vscale x 4 x float> %v) {
; CHECK-LABEL: splat_idx_nxv4f32_v8f32_constant_7:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; CHECK-NEXT:    vrgather.vi v10, v8, 7
; CHECK-NEXT:    vmv.v.v v8, v10
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 4 x float> %v, i64 7
  %ins = insertelement <8 x float> poison, float %x, i32 0
  %splat = shufflevector <8 x float> %ins, <8 x float> poison, <8 x i32> zeroinitializer
  ret <8 x float> %splat
}

; This test shouldn't crash.
define <vscale x 2 x float> @splat_idx_illegal_type(<3 x float> %v) {
; CHECK-LABEL: splat_idx_illegal_type:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    vsetvli a0, zero, e32, m1, ta, ma
; CHECK-NEXT:    vrgather.vi v9, v8, 0
; CHECK-NEXT:    vmv.v.v v8, v9
; CHECK-NEXT:    ret
entry:
  %x = extractelement <3 x float> %v, i64 0
  %ins = insertelement <vscale x 2 x float> poison, float %x, i64 0
  %splat = shufflevector <vscale x 2 x float> %ins, <vscale x 2 x float> poison, <vscale x 2 x i32> zeroinitializer
  ret <vscale x 2 x float> %splat
}

; Negative test, vscale might be 4
define <8 x float> @splat_idx_nxv4f32_v8f32_constant_8(<vscale x 4 x float> %v) {
; CHECK-LABEL: splat_idx_nxv4f32_v8f32_constant_8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 1, e32, m2, ta, ma
; CHECK-NEXT:    vslidedown.vi v8, v8, 8
; CHECK-NEXT:    vfmv.f.s fa5, v8
; CHECK-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; CHECK-NEXT:    vfmv.v.f v8, fa5
; CHECK-NEXT:    ret
  %x = extractelement <vscale x 4 x float> %v, i64 8
  %ins = insertelement <8 x float> poison, float %x, i32 0
  %splat = shufflevector <8 x float> %ins, <8 x float> poison, <8 x i32> zeroinitializer
  ret <8 x float> %splat
}

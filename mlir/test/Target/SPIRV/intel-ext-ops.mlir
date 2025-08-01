// RUN: mlir-translate -no-implicit-module -test-spirv-roundtrip -split-input-file %s | FileCheck %s

spirv.module Logical GLSL450 requires #spirv.vce<v1.0, [Bfloat16ConversionINTEL], [SPV_INTEL_bfloat16_conversion]> {
  // CHECK-LABEL: @f32_to_bf16
  spirv.func @f32_to_bf16(%arg0 : f32) "None" {
    // CHECK: {{%.*}} = spirv.INTEL.ConvertFToBF16 {{%.*}} : f32 to i16
    %0 = spirv.INTEL.ConvertFToBF16 %arg0 : f32 to i16
    spirv.Return
  }

  // CHECK-LABEL: @f32_to_bf16_vec
  spirv.func @f32_to_bf16_vec(%arg0 : vector<2xf32>) "None" {
    // CHECK: {{%.*}} = spirv.INTEL.ConvertFToBF16 {{%.*}} : vector<2xf32> to vector<2xi16>
    %0 = spirv.INTEL.ConvertFToBF16 %arg0 : vector<2xf32> to vector<2xi16>
    spirv.Return
  }

  // CHECK-LABEL: @bf16_to_f32
  spirv.func @bf16_to_f32(%arg0 : i16) "None" {
    // CHECK: {{%.*}} = spirv.INTEL.ConvertBF16ToF {{%.*}} : i16 to f32
    %0 = spirv.INTEL.ConvertBF16ToF %arg0 : i16 to f32
    spirv.Return
  }

  // CHECK-LABEL: @bf16_to_f32_vec
  spirv.func @bf16_to_f32_vec(%arg0 : vector<2xi16>) "None" {
    // CHECK: {{%.*}} = spirv.INTEL.ConvertBF16ToF {{%.*}} : vector<2xi16> to vector<2xf32>
    %0 = spirv.INTEL.ConvertBF16ToF %arg0 : vector<2xi16> to vector<2xf32>
    spirv.Return
  }
}

// -----

//===----------------------------------------------------------------------===//
// spirv.INTEL.RoundFToTF32
//===----------------------------------------------------------------------===//

spirv.module Logical GLSL450 requires #spirv.vce<v1.0, [TensorFloat32RoundingINTEL], [SPV_INTEL_tensor_float32_conversion]> {
  // CHECK-LABEL: @f32_to_tf32
  spirv.func @f32_to_tf32(%arg0 : f32) "None" {
    // CHECK: {{%.*}} = spirv.INTEL.RoundFToTF32 {{%.*}} : f32 to f32
    %1 = spirv.INTEL.RoundFToTF32 %arg0 : f32 to f32
    spirv.Return
  }

  // CHECK-LABEL: @f32_to_tf32_vec
  spirv.func @f32_to_tf32_vec(%arg0 : vector<2xf32>) "None" {
    // CHECK: {{%.*}} = spirv.INTEL.RoundFToTF32 {{%.*}} : vector<2xf32> to vector<2xf32>
    %1 = spirv.INTEL.RoundFToTF32 %arg0 : vector<2xf32> to vector<2xf32>
    spirv.Return
  }
}

// -----

//===----------------------------------------------------------------------===//
// spirv.INTEL.SplitBarrier
//===----------------------------------------------------------------------===//

// CHECK: spirv.module Logical GLSL450 requires #spirv.vce<v1.0, [SplitBarrierINTEL], [SPV_INTEL_split_barrier]>
spirv.module Logical GLSL450 requires #spirv.vce<v1.0, [SplitBarrierINTEL], [SPV_INTEL_split_barrier]> {
  // CHECK-LABEL: @split_barrier
  spirv.func @split_barrier() "None" {
    // CHECK: spirv.INTEL.ControlBarrierArrive <Workgroup> <Device> <Acquire|UniformMemory>
    spirv.INTEL.ControlBarrierArrive <Workgroup> <Device> <Acquire|UniformMemory>
    // CHECK: spirv.INTEL.ControlBarrierWait <Workgroup> <Device> <Acquire|UniformMemory>
    spirv.INTEL.ControlBarrierWait <Workgroup> <Device> <Acquire|UniformMemory>
    spirv.Return
  }
}

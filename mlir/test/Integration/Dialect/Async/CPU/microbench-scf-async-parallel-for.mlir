// RUN:   mlir-opt %s                                                          \
// RUN:               -async-parallel-for                                      \
// RUN:               -async-to-async-runtime                                  \
// RUN:               -async-runtime-ref-counting                              \
// RUN:               -async-runtime-ref-counting-opt                          \
// RUN:               -convert-async-to-llvm                                   \
// RUN:               -convert-linalg-to-loops                                 \
// RUN:               -convert-scf-to-cf                                       \
// RUN:               -arith-expand                                            \
// RUN:               -memref-expand                                           \
// RUN:               -convert-vector-to-llvm                                  \
// RUN:               -finalize-memref-to-llvm                                 \
// RUN:               -convert-func-to-llvm                                    \
// RUN:               -convert-arith-to-llvm                                   \
// RUN:               -convert-cf-to-llvm                                      \
// RUN:               -reconcile-unrealized-casts                              \
// RUN: | mlir-runner                                                      \
// RUN: -e entry -entry-point-result=void -O3                                  \
// RUN: -shared-libs=%mlir_runner_utils  \
// RUN: -shared-libs=%mlir_c_runner_utils\
// RUN: -shared-libs=%mlir_async_runtime \
// RUN: | FileCheck %s --dump-input=always

// RUN:   mlir-opt %s                                                          \
// RUN:               -async-parallel-for=async-dispatch=false                 \
// RUN:               -async-to-async-runtime                                  \
// RUN:               -async-runtime-ref-counting                              \
// RUN:               -async-runtime-ref-counting-opt                          \
// RUN:               -convert-async-to-llvm                                   \
// RUN:               -convert-linalg-to-loops                                 \
// RUN:               -convert-scf-to-cf                                       \
// RUN:               -arith-expand                                            \
// RUN:               -memref-expand                                           \
// RUN:               -convert-vector-to-llvm                                  \
// RUN:               -finalize-memref-to-llvm                                 \
// RUN:               -convert-func-to-llvm                                    \
// RUN:               -convert-arith-to-llvm                                   \
// RUN:               -convert-cf-to-llvm                                      \
// RUN:               -reconcile-unrealized-casts                              \
// RUN: | mlir-runner                                                      \
// RUN: -e entry -entry-point-result=void -O3                                  \
// RUN: -shared-libs=%mlir_runner_utils  \
// RUN: -shared-libs=%mlir_c_runner_utils\
// RUN: -shared-libs=%mlir_async_runtime \
// RUN: | FileCheck %s --dump-input=always

// RUN:   mlir-opt %s                                                          \
// RUN:               -convert-linalg-to-loops                                 \
// RUN:               -convert-scf-to-cf                                       \
// RUN:               -convert-vector-to-llvm                                  \
// RUN:               -finalize-memref-to-llvm                                 \
// RUN:               -convert-func-to-llvm                                    \
// RUN:               -convert-arith-to-llvm                                   \
// RUN:               -convert-cf-to-llvm                                      \
// RUN:               -reconcile-unrealized-casts                              \
// RUN: | mlir-runner                                                      \
// RUN: -e entry -entry-point-result=void -O3                                  \
// RUN: -shared-libs=%mlir_runner_utils  \
// RUN: -shared-libs=%mlir_c_runner_utils\
// RUN: -shared-libs=%mlir_async_runtime \
// RUN: | FileCheck %s --dump-input=always

#map0 = affine_map<(d0, d1) -> (d0, d1)>

func.func @scf_parallel(%lhs: memref<?x?xf32>,
                   %rhs: memref<?x?xf32>,
                   %sum: memref<?x?xf32>) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index

  %d0 = memref.dim %lhs, %c0 : memref<?x?xf32>
  %d1 = memref.dim %lhs, %c1 : memref<?x?xf32>

  scf.parallel (%i, %j) = (%c0, %c0) to (%d0, %d1) step (%c1, %c1) {
    %lv = memref.load %lhs[%i, %j] : memref<?x?xf32>
    %rv = memref.load %lhs[%i, %j] : memref<?x?xf32>
    %r = arith.addf %lv, %rv : f32
    memref.store %r, %sum[%i, %j] : memref<?x?xf32>
  }

  return
}

func.func @entry() {
  %f1 = arith.constant 1.0 : f32
  %f4 = arith.constant 4.0 : f32
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %cN = arith.constant 50 : index

  //
  // Sanity check for the function under test.
  //

  %LHS10 = memref.alloc() {alignment = 64} : memref<1x10xf32>
  %RHS10 = memref.alloc() {alignment = 64} : memref<1x10xf32>
  %DST10 = memref.alloc() {alignment = 64} : memref<1x10xf32>

  linalg.fill ins(%f1 : f32) outs(%LHS10 : memref<1x10xf32>)
  linalg.fill ins(%f1 : f32) outs(%RHS10 : memref<1x10xf32>)

  %LHS = memref.cast %LHS10 : memref<1x10xf32> to memref<?x?xf32>
  %RHS = memref.cast %RHS10 : memref<1x10xf32> to memref<?x?xf32>
  %DST = memref.cast %DST10 : memref<1x10xf32> to memref<?x?xf32>

  call @scf_parallel(%LHS, %RHS, %DST)
    : (memref<?x?xf32>, memref<?x?xf32>, memref<?x?xf32>) -> ()

  // CHECK: [2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
  %U = memref.cast %DST10 :  memref<1x10xf32> to memref<*xf32>
  call @printMemrefF32(%U): (memref<*xf32>) -> ()

  memref.dealloc %LHS10: memref<1x10xf32>
  memref.dealloc %RHS10: memref<1x10xf32>
  memref.dealloc %DST10: memref<1x10xf32>

  //
  // Allocate data for microbenchmarks.
  //

  %LHS1024 = memref.alloc() {alignment = 64} : memref<1024x1024xf32>
  %RHS1024 = memref.alloc() {alignment = 64} : memref<1024x1024xf32>
  %DST1024 = memref.alloc() {alignment = 64} : memref<1024x1024xf32>

  %LHS0 = memref.cast %LHS1024 : memref<1024x1024xf32> to memref<?x?xf32>
  %RHS0 = memref.cast %RHS1024 : memref<1024x1024xf32> to memref<?x?xf32>
  %DST0 = memref.cast %DST1024 : memref<1024x1024xf32> to memref<?x?xf32>

  //
  // Warm up.
  //

  call @scf_parallel(%LHS0, %RHS0, %DST0)
    : (memref<?x?xf32>, memref<?x?xf32>, memref<?x?xf32>) -> ()

  //
  // Measure execution time.
  //

  %t0 = call @rtclock() : () -> f64
  scf.for %i = %c0 to %cN step %c1 {
    func.call @scf_parallel(%LHS0, %RHS0, %DST0)
      : (memref<?x?xf32>, memref<?x?xf32>, memref<?x?xf32>) -> ()
  }
  %t1 = call @rtclock() : () -> f64
  %t1024 = arith.subf %t1, %t0 : f64

  // Print timings.
  vector.print %t1024 : f64

  // Free.
  memref.dealloc %LHS1024: memref<1024x1024xf32>
  memref.dealloc %RHS1024: memref<1024x1024xf32>
  memref.dealloc %DST1024: memref<1024x1024xf32>

  return
}

func.func private @rtclock() -> f64

func.func private @printMemrefF32(memref<*xf32>)
  attributes { llvm.emit_c_interface }

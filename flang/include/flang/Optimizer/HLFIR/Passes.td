//===-- Passes.td - HLFIR pass definition file -------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef FORTRAN_DIALECT_HLFIR_PASSES
#define FORTRAN_DIALECT_HLFIR_PASSES

include "mlir/Pass/PassBase.td"
def ConvertHLFIRtoFIR : Pass<"convert-hlfir-to-fir", "::mlir::ModuleOp"> {
  let summary = "Lower High-Level FIR to FIR";
  let dependentDialects = [
    "mlir::func::FuncDialect",
  ];
}

def BufferizeHLFIR : Pass<"bufferize-hlfir", "::mlir::ModuleOp"> {
  let summary = "Convert HLFIR operations operating on hlfir.expr into operations on memory";
  let options = [Option<"optimizeEmptyElementals", "opt-empty-elementals",
                        "bool", /*default=*/"false",
                        "When converting hlfir.elemental into a loop nest, "
                        "check if the resulting expression is an empty array, "
                        "and make sure none of the loops is executed.">];
}

def OptimizedBufferization : Pass<"opt-bufferization"> {
  let summary = "Special cases for hlfir.expr bufferization where we can avoid a temporary which would be created by the generic bufferization pass";
}

def LowerHLFIRIntrinsics : Pass<"lower-hlfir-intrinsics", "::mlir::ModuleOp"> {
  let summary = "Lower HLFIR transformational intrinsic operations";
}

def LowerHLFIROrderedAssignments : Pass<"lower-hlfir-ordered-assignments", "::mlir::ModuleOp"> {
  let summary = "Lower HLFIR ordered assignments like forall and where operations";
  let options = [
    Option<"tryFusingAssignments", "fuse-assignments",
           "bool", /*default=*/"false",
           "Fuse Forall and Where assignments in the same loop nest when legal."
           "It is not clear yet if this is always beneficial. It may be best to"
           "leave this to later loop optimizations."
           "Hence this is off by default.">
  ];
}

def SimplifyHLFIRIntrinsics : Pass<"simplify-hlfir-intrinsics"> {
  let summary = "Simplify HLFIR intrinsic operations that don't need to result in runtime calls";
  let options = [Option<"allowNewSideEffects", "allow-new-side-effects", "bool",
                        /*default=*/"false",
                        "If enabled, then the HLFIR operations simplification "
                        "may introduce operations with side effects. "
                        "For example, hlfir.matmul may be inlined as "
                        "and hlfir.eval_in_mem with hlfir.assign inside it."
                        "The hlfir.assign has a write effect on the memory "
                        "argument of hlfir.eval_in_mem, which may block "
                        "some existing MLIR transformations (e.g. CSE) "
                        "that otherwise would have been possible across "
                        "the hlfir.matmul.">];
}

def InlineElementals : Pass<"inline-elementals"> {
  let summary = "Inline chained hlfir.elemental operations";
}

def InlineHLFIRAssign : Pass<"inline-hlfir-assign"> {
  let summary = "Inline hlfir.assign operations";
}

def InlineHLFIRCopyIn : Pass<"inline-hlfir-copy-in"> {
  let summary = "Inline hlfir.copy_in operations";
}

def PropagateFortranVariableAttributes : Pass<"propagate-fortran-attrs"> {
  let summary = "Propagate FortranVariableFlagsAttr attributes through HLFIR";
}

#endif //FORTRAN_DIALECT_HLFIR_PASSES

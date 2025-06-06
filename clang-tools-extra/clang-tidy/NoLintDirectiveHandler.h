//===-- clang-tools-extra/clang-tidy/NoLintDirectiveHandler.h ----*- C++ *-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_TOOLS_EXTRA_CLANG_TIDY_NOLINTDIRECTIVEHANDLER_H
#define LLVM_CLANG_TOOLS_EXTRA_CLANG_TIDY_NOLINTDIRECTIVEHANDLER_H

#include "clang/Basic/Diagnostic.h"
#include "llvm/ADT/StringRef.h"
#include <memory>

namespace clang::tooling {
struct Diagnostic;
} // namespace clang::tooling

namespace llvm {
template <typename T> class SmallVectorImpl;
} // namespace llvm

namespace clang::tidy {

/// This class is used to locate NOLINT comments in the file being analyzed, to
/// decide whether a diagnostic should be suppressed.
/// This class keeps a cache of every NOLINT comment found so that files do not
/// have to be repeatedly parsed each time a new diagnostic is raised.
class NoLintDirectiveHandler {
public:
  NoLintDirectiveHandler();
  ~NoLintDirectiveHandler();
  NoLintDirectiveHandler(const NoLintDirectiveHandler &) = delete;
  NoLintDirectiveHandler &operator=(const NoLintDirectiveHandler &) = delete;

  bool shouldSuppress(DiagnosticsEngine::Level DiagLevel,
                      const Diagnostic &Diag, llvm::StringRef DiagName,
                      llvm::SmallVectorImpl<tooling::Diagnostic> &NoLintErrors,
                      bool AllowIO, bool EnableNoLintBlocks);

private:
  class Impl;
  std::unique_ptr<Impl> PImpl;
};

} // namespace clang::tidy

#endif // LLVM_CLANG_TOOLS_EXTRA_CLANG_TIDY_NOLINTDIRECTIVEHANDLER_H

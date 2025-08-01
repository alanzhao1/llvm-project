//===-- Implementation of atoll -------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "src/stdlib/atoll.h"
#include "src/__support/common.h"
#include "src/__support/libc_errno.h"
#include "src/__support/macros/config.h"
#include "src/__support/str_to_integer.h"

namespace LIBC_NAMESPACE_DECL {

LLVM_LIBC_FUNCTION(long long, atoll, (const char *str)) {
  auto result = internal::strtointeger<long long>(str, 10);
  if (result.has_error())
    libc_errno = result.error;

  return result;
}

} // namespace LIBC_NAMESPACE_DECL

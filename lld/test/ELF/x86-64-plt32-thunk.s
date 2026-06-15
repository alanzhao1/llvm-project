# REQUIRES: x86
# RUN: llvm-mc -filetype=obj -triple=x86_64 %s -o %t.o
# RUN: ld.lld %t.o -o %t
# RUN: llvm-objdump -d %t | FileCheck %s
# RUN: llvm-readobj -S %t | FileCheck --check-prefix=SEC %s

# SEC: Name: .got

# CHECK-LABEL: <high>:
# CHECK-NEXT: [[#%x, HIGH:]]: c3                            retq
# CHECK-LABEL: <_start>:
# CHECK-NEXT: {{.*}}: e8 {{.*}} callq {{.*}} <__X86_64Thunk_high>
# CHECK-LABEL: <__X86_64Thunk_high>:
# CHECK-NEXT: {{.*}}: ff 25 {{.*}} jmpq *{{.*}}(%rip)

.section .ltext, "axl"
.globl high
.type high, @function
high:
  ret

.section .ltext.pad, "axl", @nobits
.space 0x80000000

.section .text, "ax"
.globl _start
_start:
  call high
# REQUIRES: x86
# RUN: llvm-mc -filetype=obj -triple=x86_64 %s -o %t.o
# RUN: echo "SECTIONS { \
# RUN:   .text 0x10000 : { *(.text) } \
# RUN:   .text.high 0x80020000 : { *(.text.high) } \
# RUN: }" > %t.script
# RUN: ld.lld -T %t.script %t.o -o %t
# RUN: llvm-objdump -d %t | FileCheck %s

# CHECK-LABEL: <__X86_64Thunk_high>:
# CHECK-NEXT: {{.*}}: ff 25 {{.*}} jmpq *{{.*}}(%rip)
# CHECK-LABEL: <_start>:
# CHECK-NEXT: {{.*}}: e8 {{.*}} callq {{.*}} <__X86_64Thunk_high>
# CHECK-LABEL: <high>:
# CHECK-NEXT: [[#%x, HIGH:]]: c3                            retq

.section .text.high, "ax"
.globl high
.type high, @function
high:
  ret

.section .text, "ax"
.globl _start
_start:
  call high@PLT
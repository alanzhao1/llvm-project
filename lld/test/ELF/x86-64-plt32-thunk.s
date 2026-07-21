# REQUIRES: x86
# RUN: llvm-mc -filetype=obj -triple=x86_64 %s -o %t.o
# RUN: ld.lld %t.o -o %t
# RUN: llvm-objdump -d %t | FileCheck %s
# RUN: llvm-readobj -S %t | FileCheck --check-prefix=SEC %s

# RUN: ld.lld -pie %t.o -o %t.pie
# RUN: llvm-objdump -d %t.pie | FileCheck %s
# RUN: llvm-readelf -r %t.pie | FileCheck --check-prefix=PIE %s

# RUN: ld.lld -pie --pack-dyn-relocs=relr %t.o -o %t.pie.relr
# RUN: llvm-objdump -d %t.pie.relr | FileCheck %s
# RUN: llvm-readelf -r %t.pie.relr | FileCheck --check-prefix=PIE-RELR %s

# SEC: Name: .got

# PIE: R_X86_64_RELATIVE

# PIE-RELR: Relocation section '.relr.dyn'
# PIE-RELR: 0000000080002338 0000000080002338 _DYNAMIC + 0xf0

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

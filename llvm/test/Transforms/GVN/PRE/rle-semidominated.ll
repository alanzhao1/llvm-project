; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 5
; RUN: opt < %s -passes=gvn -S | FileCheck %s --check-prefixes=CHECK,MDEP
; RUN: opt < %s -passes='gvn<memoryssa>' -S | FileCheck %s --check-prefixes=CHECK,MSSA

define i32 @main(ptr %p, i32 %x, i32 %y) {
; MDEP-LABEL: define i32 @main(
; MDEP-SAME: ptr [[P:%.*]], i32 [[X:%.*]], i32 [[Y:%.*]]) {
; MDEP-NEXT:  [[BLOCK1:.*:]]
; MDEP-NEXT:    [[CMP:%.*]] = icmp eq i32 [[X]], [[Y]]
; MDEP-NEXT:    br i1 [[CMP]], label %[[BLOCK2:.*]], label %[[BLOCK3:.*]]
; MDEP:       [[BLOCK2]]:
; MDEP-NEXT:    [[DEAD_PRE:%.*]] = load i32, ptr [[P]], align 4
; MDEP-NEXT:    br label %[[BLOCK4:.*]]
; MDEP:       [[BLOCK3]]:
; MDEP-NEXT:    store i32 0, ptr [[P]], align 4
; MDEP-NEXT:    br label %[[BLOCK4]]
; MDEP:       [[BLOCK4]]:
; MDEP-NEXT:    [[DEAD:%.*]] = phi i32 [ 0, %[[BLOCK3]] ], [ [[DEAD_PRE]], %[[BLOCK2]] ]
; MDEP-NEXT:    ret i32 [[DEAD]]
;
; MSSA-LABEL: define i32 @main(
; MSSA-SAME: ptr [[P:%.*]], i32 [[X:%.*]], i32 [[Y:%.*]]) {
; MSSA-NEXT:  [[BLOCK1:.*:]]
; MSSA-NEXT:    [[Z:%.*]] = load i32, ptr [[P]], align 4
; MSSA-NEXT:    [[CMP:%.*]] = icmp eq i32 [[X]], [[Y]]
; MSSA-NEXT:    br i1 [[CMP]], label %[[BLOCK2:.*]], label %[[BLOCK3:.*]]
; MSSA:       [[BLOCK2]]:
; MSSA-NEXT:    br label %[[BLOCK4:.*]]
; MSSA:       [[BLOCK3]]:
; MSSA-NEXT:    store i32 0, ptr [[P]], align 4
; MSSA-NEXT:    br label %[[BLOCK4]]
; MSSA:       [[BLOCK4]]:
; MSSA-NEXT:    [[DEAD:%.*]] = load i32, ptr [[P]], align 4
; MSSA-NEXT:    ret i32 [[DEAD]]
;
block1:
  %z = load i32, ptr %p
  %cmp = icmp eq i32 %x, %y
  br i1 %cmp, label %block2, label %block3

block2:
  br label %block4

block3:
  %b = bitcast i32 0 to i32
  store i32 %b, ptr %p
  br label %block4

block4:
  %DEAD = load i32, ptr %p
  ret i32 %DEAD
}

;; NOTE: These prefixes are unused and the list is autogenerated. Do not add tests below this line:
; CHECK: {{.*}}

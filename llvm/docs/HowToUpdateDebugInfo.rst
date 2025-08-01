=======================================================
How to Update Debug Info: A Guide for LLVM Pass Authors
=======================================================

.. contents::
   :local:

Introduction
============

Certain kinds of code transformations can inadvertently result in a loss of
debug info, or worse, make debug info misrepresent the state of a program. Debug
info availability is also essential for SamplePGO.

This document specifies how to correctly update debug info in various kinds of
code transformations, and offers suggestions for how to create targeted debug
info tests for arbitrary transformations.

For more on the philosophy behind LLVM debugging information, see
:doc:`SourceLevelDebugging`.

Rules for updating debug locations
==================================

.. _WhenToPreserveLocation:

When to preserve an instruction location
----------------------------------------

A transformation should preserve the debug location of an instruction if the
instruction either remains in its basic block, or if its basic block is folded
into a predecessor that branches unconditionally. The APIs to use are
``IRBuilder``, or ``Instruction::setDebugLoc``.

The purpose of this rule is to ensure that common block-local optimizations
preserve the ability to set breakpoints on source locations corresponding to
the instructions they touch. Debugging, crash logs, and SamplePGO accuracy
would be severely impacted if that ability were lost.

Examples of transformations that should follow this rule include:

* Instruction scheduling. Block-local instruction reordering should not drop
  source locations, even though this may lead to jumpy single-stepping
  behavior.

* Simple jump threading. For example, if block ``B1`` unconditionally jumps to
  ``B2``, *and* is its unique predecessor, instructions from ``B2`` can be
  hoisted into ``B1``. Source locations from ``B2`` should be preserved.

* Peephole optimizations that replace or expand an instruction, like ``(add X
  X) => (shl X 1)``. The location of the ``shl`` instruction should be the same
  as the location of the ``add`` instruction.

* Tail duplication. For example, if blocks ``B1`` and ``B2`` both
  unconditionally branch to ``B3`` and ``B3`` can be folded into its
  predecessors, source locations from ``B3`` should be preserved.

Examples of transformations for which this rule *does not* apply include:

* LICM. E.g., if an instruction is moved from the loop body to the preheader,
  the rule for :ref:`dropping locations<WhenToDropLocation>` applies.

In addition to the rule above, a transformation should also preserve the debug
location of an instruction that is moved between basic blocks, if the
destination block already contains an instruction with an identical debug
location.

Examples of transformations that should follow this rule include:

* Moving instructions between basic blocks. For example, if instruction ``I1``
  in ``BB1`` is moved before ``I2`` in ``BB2``, the source location of ``I1``
  can be preserved if it has the same source location as ``I2``.

.. _WhenToMergeLocation:

When to merge instruction locations
-----------------------------------

A transformation should merge instruction locations if it replaces multiple
instructions with one or more new instructions, *and* the new instruction(s)
produce the output of more than one of the original instructions. The API to use
is ``Instruction::applyMergedLocation``. For each new instruction I, its new
location should be a merge of the locations of all instructions whose output is
produced by I. Typically, this includes any instruction being RAUWed by a new
instruction, and excludes any instruction that only produces an intermediate
value used by the RAUWed instruction.

The purpose of this rule is to ensure that a) the single merged instruction
has a location with an accurate scope attached, and b) to prevent misleading
single-stepping (or breakpoint) behavior. Often, merged instructions are memory
accesses which can trap: having an accurate scope attached greatly assists in
crash triage by identifying the (possibly inlined) function where the bad
memory access occurred.

To maintain distinct source locations for SamplePGO, it is often beneficial to
retain an arbitrary but deterministic location instead of discarding line and
column information as part of merging. In particular, loss of location
information for calls inhibit optimizations such as indirect call promotion.
This behavior can be optionally enabled until support for accurately
representing merged instructions in the line table is implemented.

Examples of transformations that should follow this rule include:

* Hoisting identical instructions from all successors of a conditional branch
  or sinking those from all paths to a postdominating block. For example,
  merging identical loads/stores which occur on both sides of a CFG diamond
  (see the ``MergedLoadStoreMotion`` pass). For each group of identical
  instructions being hoisted/sunk, the merge of all their locations should be
  applied to the merged instruction.

* Merging identical loop-invariant stores (see the LICM utility
  ``llvm::promoteLoopAccessesToScalars``).

* Scalar instructions being combined into a vector instruction, like
  ``(add A1, B1), (add A2, B2) => (add (A1, A2), (B1, B2))``. As the new vector
  ``add`` computes the result of both original ``add`` instructions
  simultaneously, it should use a merge of the two locations. Similarly, if
  prior optimizations have already produced vectors ``(A1, A2)`` and
  ``(B2, B1)``, then we might create a ``(shufflevector (1, 0), (B2, B1))``
  instruction to produce ``(B1, B2)`` for the vector ``add``; in this case we've
  created two instructions to replace the original ``adds``, so both new
  instructions should use the merged location.

Examples of transformations for which this rule *does not* apply include:

* Block-local peepholes which delete redundant instructions, like
  ``(sext (zext i8 %x to i16) to i32) => (zext i8 %x to i32)``. The inner
  ``zext`` is modified but remains in its block, so the rule for
  :ref:`preserving locations<WhenToPreserveLocation>` should apply.

* Peephole optimizations which combine multiple instructions together, like
  ``(add (mul A B) C) => llvm.fma.f32(A, B, C)``. Note that the result of the
  ``mul`` no longer appears in the program, while the result of the ``add`` is
  now produced by the ``fma``, so the ``add``'s location should be used.

* Converting an if-then-else CFG diamond into a ``select``. Preserving the
  debug locations of speculated instructions can make it seem like a condition
  is true when it's not (or vice versa), which leads to a confusing
  single-stepping experience. The rule for
  :ref:`dropping locations<WhenToDropLocation>` should apply here.

* Hoisting/sinking that would make a location reachable when it previously
  wasn't. Consider hoisting two identical instructions with the same location
  from first two cases of a switch that has three cases. Merging their
  locations would make the location from the first two cases reachable when the
  third case is taken. The rule for
  :ref:`dropping locations<WhenToDropLocation>` applies.

.. _WhenToDropLocation:

When to drop an instruction location
------------------------------------

A transformation should drop debug locations if the rules for
:ref:`preserving<WhenToPreserveLocation>` and
:ref:`merging<WhenToMergeLocation>` debug locations do not apply. The API to
use is ``Instruction::dropLocation()``.

The purpose of this rule is to prevent erratic or misleading single-stepping
behavior in situations in which an instruction has no clear, unambiguous
relationship to a source location.

To handle an instruction without a location, the DWARF generator
defaults to allowing the last-set location after a label to cascade forward, or
to setting a line 0 location with viable scope information if no previous
location is available.

See the discussion in the section about
:ref:`merging locations<WhenToMergeLocation>` for examples of when the rule for
dropping locations applies.

When to remap a debug location
------------------------------

When code paths are duplicated, during passes such as loop unrolling or jump
threading, `DILocation` attachments need to be remapped using `mapAtomInstance`
and `RemapSourceAtom`. This is to support the Key Instructions debug info feature.
See :doc:`KeyInstructionsDebugInfo` for information.

.. _NewInstLocations:

Setting locations for new instructions
--------------------------------------

Whenever a new instruction is created and there is no suitable location for that
instruction, that instruction should be annotated accordingly. There are a set
of special ``DebugLoc`` values that can be set on an instruction to annotate the
reason that it does not have a valid location. These are as follows:

* ``DebugLoc::getCompilerGenerated()``: This indicates that the instruction is a
  compiler-generated instruction, i.e. it is not associated with any user source
  code.

* ``DebugLoc::getDropped()``: This indicates that the instruction has
  intentionally had its source location removed, according to the rules for
  :ref:`dropping locations<WhenToDropLocation>`; this is set automatically by
  ``Instruction::dropLocation()``.

* ``DebugLoc::getUnknown()``: This indicates that the instruction does not have
  a known or currently knowable source location, e.g. that it is infeasible to
  determine the correct source location, or that the source location is
  ambiguous in a way that LLVM cannot currently represent.

* ``DebugLoc::getTemporary()``: This is used for instructions that we don't
  expect to be emitted (e.g. ``UnreachableInst``), and so should not need a
  valid location; if we ever try to emit a temporary location into an object/asm
  file, this indicates that something has gone wrong.

Where applicable, these should be used instead of leaving an instruction without
an assigned location or explicitly setting the location as ``DebugLoc()``.
Ordinarily these special locations are identical to an absent location, but LLVM
built with coverage-tracking
(``-DLLVM_ENABLE_DEBUGLOC_COVERAGE_TRACKING="COVERAGE"``) will keep track of
these special locations in order to detect unintentionally-missing locations;
for this reason, the most important rule is to *not* apply any of these if it
isn't clear which, if any, is appropriate - an absent location can be detected
and fixed, while an incorrectly annotated instruction is much harder to detect.
On the other hand, if any of these clearly apply, then they should be used to
prevent false positives from being flagged up.

Rules for updating debug values
===============================

Deleting an IR-level Instruction
--------------------------------

When an ``Instruction`` is deleted, its debug uses change to ``undef``. This is
a loss of debug info: the value of one or more source variables becomes
unavailable, starting with the ``#dbg_value(undef, ...)``. When there is no
way to reconstitute the value of the lost instruction, this is the best
possible outcome. However, it's often possible to do better:

* If the dying instruction can be RAUW'd, do so. The
  ``Value::replaceAllUsesWith`` API transparently updates debug uses of the
  dying instruction to point to the replacement value.

* If the dying instruction cannot be RAUW'd, call ``llvm::salvageDebugInfo`` on
  it. This makes a best-effort attempt to rewrite debug uses of the dying
  instruction by describing its effect as a ``DIExpression``.

* If one of the **operands** of a dying instruction would become trivially
  dead, use ``llvm::replaceAllDbgUsesWith`` to rewrite the debug uses of that
  operand. Consider the following example function:

.. code-block:: llvm

  define i16 @foo(i16 %a) {
    %b = sext i16 %a to i32
    %c = and i32 %b, 15
      #dbg_value(i32 %c, ...)
    %d = trunc i32 %c to i16
    ret i16 %d
  }

Now, here's what happens after the unnecessary truncation instruction ``%d`` is
replaced with a simplified instruction:

.. code-block:: llvm

  define i16 @foo(i16 %a) {
      #dbg_value(i32 undef, ...)
    %simplified = and i16 %a, 15
    ret i16 %simplified
  }

Note that after deleting ``%d``, all uses of its operand ``%c`` become
trivially dead. The debug use which used to point to ``%c`` is now ``undef``,
and debug info is needlessly lost.

To solve this problem, do:

.. code-block:: cpp

  llvm::replaceAllDbgUsesWith(%c, theSimplifiedAndInstruction, ...)

This results in better debug info because the debug use of ``%c`` is preserved:

.. code-block:: llvm

  define i16 @foo(i16 %a) {
    %simplified = and i16 %a, 15
      #dbg_value(i16 %simplified, ...)
    ret i16 %simplified
  }

You may have noticed that ``%simplified`` is narrower than ``%c``: this is not
a problem, because ``llvm::replaceAllDbgUsesWith`` takes care of inserting the
necessary conversion operations into the DIExpressions of updated debug uses.

Deleting a MIR-level MachineInstr
---------------------------------

TODO

Rules for updating ``DIAssignID`` Attachments
=============================================

``DIAssignID`` metadata attachments are used by Assignment Tracking, which is
currently an experimental debug mode.

See :doc:`AssignmentTracking` for how to update them and for more info on
Assignment Tracking.

How to automatically convert tests into debug info tests
========================================================

.. _IRDebugify:

Mutation testing for IR-level transformations
---------------------------------------------

An IR test case for a transformation can, in many cases, be automatically
mutated to test debug info handling within that transformation. This is a
simple way to test for proper debug info handling.

The ``debugify`` utility pass
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``debugify`` testing utility is just a pair of passes: ``debugify`` and
``check-debugify``.

The first applies synthetic debug information to every instruction of the
module, and the second checks that this DI is still available after an
optimization has occurred, reporting any errors/warnings while doing so.

The instructions are assigned sequentially increasing line locations, and are
immediately used by debug value records everywhere possible.

For example, here is a module before:

.. code-block:: llvm

   define void @f(i32* %x) {
   entry:
     %x.addr = alloca i32*, align 8
     store i32* %x, i32** %x.addr, align 8
     %0 = load i32*, i32** %x.addr, align 8
     store i32 10, i32* %0, align 4
     ret void
   }

and after running ``opt -debugify``:

.. code-block:: llvm

   define void @f(i32* %x) !dbg !6 {
   entry:
     %x.addr = alloca i32*, align 8, !dbg !12
       #dbg_value(i32** %x.addr, !9, !DIExpression(), !12)
     store i32* %x, i32** %x.addr, align 8, !dbg !13
     %0 = load i32*, i32** %x.addr, align 8, !dbg !14
       #dbg_value(i32* %0, !11, !DIExpression(), !14)
     store i32 10, i32* %0, align 4, !dbg !15
     ret void, !dbg !16
   }

   !llvm.dbg.cu = !{!0}
   !llvm.debugify = !{!3, !4}
   !llvm.module.flags = !{!5}

   !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "debugify", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, enums: !2)
   !1 = !DIFile(filename: "debugify-sample.ll", directory: "/")
   !2 = !{}
   !3 = !{i32 5}
   !4 = !{i32 2}
   !5 = !{i32 2, !"Debug Info Version", i32 3}
   !6 = distinct !DISubprogram(name: "f", linkageName: "f", scope: null, file: !1, line: 1, type: !7, isLocal: false, isDefinition: true, scopeLine: 1, isOptimized: true, unit: !0, retainedNodes: !8)
   !7 = !DISubroutineType(types: !2)
   !8 = !{!9, !11}
   !9 = !DILocalVariable(name: "1", scope: !6, file: !1, line: 1, type: !10)
   !10 = !DIBasicType(name: "ty64", size: 64, encoding: DW_ATE_unsigned)
   !11 = !DILocalVariable(name: "2", scope: !6, file: !1, line: 3, type: !10)
   !12 = !DILocation(line: 1, column: 1, scope: !6)
   !13 = !DILocation(line: 2, column: 1, scope: !6)
   !14 = !DILocation(line: 3, column: 1, scope: !6)
   !15 = !DILocation(line: 4, column: 1, scope: !6)
   !16 = !DILocation(line: 5, column: 1, scope: !6)

Using ``debugify``
^^^^^^^^^^^^^^^^^^

A simple way to use ``debugify`` is as follows:

.. code-block:: bash

  $ opt -debugify -pass-to-test -check-debugify sample.ll

This will inject synthetic DI to ``sample.ll`` run the ``pass-to-test`` and
then check for missing DI. The ``-check-debugify`` step can of course be
omitted in favor of more customizable FileCheck directives.

Some other ways to run debugify are available:

.. code-block:: bash

   # Same as the above example.
   $ opt -enable-debugify -pass-to-test sample.ll

   # Suppresses verbose debugify output.
   $ opt -enable-debugify -debugify-quiet -pass-to-test sample.ll

   # Prepend -debugify before and append -check-debugify -strip after
   # each pass on the pipeline (similar to -verify-each).
   $ opt -debugify-each -O2 sample.ll

In order for ``check-debugify`` to work, the DI must be coming from
``debugify``. Thus, modules with existing DI will be skipped.

``debugify`` can be used to test a backend, e.g:

.. code-block:: bash

   $ opt -debugify < sample.ll | llc -o -

There is also a MIR-level debugify pass that can be run before each backend
pass, see:
:ref:`Mutation testing for MIR-level transformations<MIRDebugify>`.

``debugify`` in regression tests
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The output of the ``debugify`` pass must be stable enough to use in regression
tests. Changes to this pass are not allowed to break existing tests.

.. note::

   Regression tests must be robust. Avoid hardcoding line/variable numbers in
   check lines. In cases where this can't be avoided (say, if a test wouldn't
   be precise enough), moving the test to its own file is preferred.

Using Coverage Tracking to remove false positives
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

As described :ref:`above<WhenToDropLocation>`, there are valid reasons for
instructions to not have source locations. Therefore, when detecting dropped or
not-generated source locations, it may be preferable to avoid detecting cases
where the missing source location is intentional. For this, you can use the
"coverage tracking" feature in LLVM to prevent these from appearing in the
``debugify`` output. This is enabled in a build of LLVM by setting the CMake
flag ``-DLLVM_ENABLE_DEBUGLOC_COVERAGE_TRACKING=COVERAGE``. When this has been
set, LLVM will enable runtime tracking of
:ref:`DebugLoc annotations<NewInstLocations>`, allowing ``debugify`` to ignore
instructions that have an explicitly recorded reason given for not having a
source location.

For triaging source location bugs detected with ``debugify``, you may find it
helpful to instead set the CMake flag to enable "origin tracking",
``-DLLVM_ENABLE_DEBUGLOC_COVERAGE_TRACKING=COVERAGE_AND_ORIGIN``. This flag adds
more detail to ``debugify``'s output, by including one or more stacktraces with
every missing source location, capturing the point at which the empty source
location was created, and every point at which it was copied to an instruction,
making it trivial in most cases to find the origin of the underlying bug. If
using origin tracking, it is recommended to also build LLVM with debug info
enabled, so that the stacktrace can be accurately symbolized.

.. note::

   The coverage tracking feature has been designed primarily for use with the
   :ref:`original debug info preservation<OriginalDI>` mode of ``debugify``, and
   so may not be reliable in other settings. When using this mode, the
   stacktraces produced by the ``COVERAGE_AND_ORIGIN`` setting will be printed
   in an easy-to-read format as part of the reports generated by the
   ``llvm-original-di-preservation.py`` script.

.. _OriginalDI:

Test original debug info preservation in optimizations
------------------------------------------------------

In addition to automatically generating debug info, the checks provided by
the ``debugify`` utility pass can also be used to test the preservation of
pre-existing debug info metadata. It could be run as follows:

.. code-block:: bash

  # Run the pass by checking original Debug Info preservation.
  $ opt -verify-debuginfo-preserve -pass-to-test sample.ll

  # Check the preservation of original Debug Info after each pass.
  $ opt -verify-each-debuginfo-preserve -O2 sample.ll

Limit number of observed functions to speed up the analysis:

.. code-block:: bash

  # Test up to 100 functions (per compile unit) per pass.
  $ opt -verify-each-debuginfo-preserve -O2 -debugify-func-limit=100 sample.ll

Please do note that running ``-verify-each-debuginfo-preserve`` on big projects
could be heavily time consuming. Therefore, we suggest using
``-debugify-func-limit`` with a suitable limit number to prevent extremely long
builds.

Furthermore, there is a way to export the issues that have been found into
a JSON file as follows:

.. code-block:: bash

  $ opt -verify-debuginfo-preserve -verify-di-preserve-export=sample.json -pass-to-test sample.ll

and then use the ``llvm/utils/llvm-original-di-preservation.py`` script
to generate an HTML page with the issues reported in a more human-readable form
as follows:

.. code-block:: bash

  $ llvm-original-di-preservation.py sample.json --report-file sample.html

Testing of original debug info preservation can be invoked from front-end level
as follows:

.. code-block:: bash

  # Test each pass.
  $ clang -Xclang -fverify-debuginfo-preserve -g -O2 sample.c

  # Test each pass and export the issues report into the JSON file.
  $ clang -Xclang -fverify-debuginfo-preserve -Xclang -fverify-debuginfo-preserve-export=sample.json -g -O2 sample.c

Please do note that there are some known false positives, for source locations
and debug record checking, so that will be addressed as a future work.

.. _MIRDebugify:

Mutation testing for MIR-level transformations
----------------------------------------------

A variant of the ``debugify`` utility described in
:ref:`Mutation testing for IR-level transformations<IRDebugify>` can be used
for MIR-level transformations as well: much like the IR-level pass,
``mir-debugify`` inserts sequentially increasing line locations to each
``MachineInstr`` in a ``Module``. And the MIR-level ``mir-check-debugify`` is
similar to IR-level ``check-debugify`` pass.

For example, here is a snippet before:

.. code-block:: llvm

  name:            test
  body:             |
    bb.1 (%ir-block.0):
      %0:_(s32) = IMPLICIT_DEF
      %1:_(s32) = IMPLICIT_DEF
      %2:_(s32) = G_CONSTANT i32 2
      %3:_(s32) = G_ADD %0, %2
      %4:_(s32) = G_SUB %3, %1

and after running ``llc -run-pass=mir-debugify``:

.. code-block:: llvm

  name:            test
  body:             |
    bb.0 (%ir-block.0):
      %0:_(s32) = IMPLICIT_DEF debug-location !12
      DBG_VALUE %0(s32), $noreg, !9, !DIExpression(), debug-location !12
      %1:_(s32) = IMPLICIT_DEF debug-location !13
      DBG_VALUE %1(s32), $noreg, !11, !DIExpression(), debug-location !13
      %2:_(s32) = G_CONSTANT i32 2, debug-location !14
      DBG_VALUE %2(s32), $noreg, !9, !DIExpression(), debug-location !14
      %3:_(s32) = G_ADD %0, %2, debug-location !DILocation(line: 4, column: 1, scope: !6)
      DBG_VALUE %3(s32), $noreg, !9, !DIExpression(), debug-location !DILocation(line: 4, column: 1, scope: !6)
      %4:_(s32) = G_SUB %3, %1, debug-location !DILocation(line: 5, column: 1, scope: !6)
      DBG_VALUE %4(s32), $noreg, !9, !DIExpression(), debug-location !DILocation(line: 5, column: 1, scope: !6)

By default, ``mir-debugify`` inserts ``DBG_VALUE`` instructions **everywhere**
it is legal to do so.  In particular, every (non-PHI) machine instruction that
defines a register must be followed by a ``DBG_VALUE`` use of that def.  If
an instruction does not define a register, but can be followed by a debug inst,
MIRDebugify inserts a ``DBG_VALUE`` that references a constant.  Insertion of
``DBG_VALUE``'s can be disabled by setting ``-debugify-level=locations``.

To run MIRDebugify once, simply insert ``mir-debugify`` into your ``llc``
invocation, like:

.. code-block:: bash

  # Before some other pass.
  $ llc -run-pass=mir-debugify,other-pass ...

  # After some other pass.
  $ llc -run-pass=other-pass,mir-debugify ...

To run MIRDebugify before each pass in a pipeline, use
``-debugify-and-strip-all-safe``. This can be combined with ``-start-before``
and ``-start-after``. For example:

.. code-block:: bash

  $ llc -debugify-and-strip-all-safe -run-pass=... <other llc args>
  $ llc -debugify-and-strip-all-safe -O1 <other llc args>

If you want to check it after each pass in a pipeline, use
``-debugify-check-and-strip-all-safe``. This can also be combined with
``-start-before`` and ``-start-after``. For example:

.. code-block:: bash

  $ llc -debugify-check-and-strip-all-safe -run-pass=... <other llc args>
  $ llc -debugify-check-and-strip-all-safe -O1 <other llc args>

To check all debug info from a test, use ``mir-check-debugify``, like:

.. code-block:: bash

  $ llc -run-pass=mir-debugify,other-pass,mir-check-debugify

To strip out all debug info from a test, use ``mir-strip-debug``, like:

.. code-block:: bash

  $ llc -run-pass=mir-debugify,other-pass,mir-strip-debug

It can be useful to combine ``mir-debugify``, ``mir-check-debugify`` and/or
``mir-strip-debug`` to identify backend transformations which break in
the presence of debug info. For example, to run the AArch64 backend tests
with all normal passes "sandwiched" in between MIRDebugify and
MIRStripDebugify mutation passes, run:

.. code-block:: bash

  $ llvm-lit test/CodeGen/AArch64 -Dllc="llc -debugify-and-strip-all-safe"

Using LostDebugLocObserver
--------------------------

TODO

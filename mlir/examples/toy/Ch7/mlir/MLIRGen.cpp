//===- MLIRGen.cpp - MLIR Generation from a Toy AST -----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements a simple IR generation targeting MLIR from a Module AST
// for the Toy language.
//
//===----------------------------------------------------------------------===//

#include "toy/MLIRGen.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/Value.h"
#include "toy/AST.h"
#include "toy/Dialect.h"

#include "mlir/IR/Attributes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Verifier.h"
#include "toy/Lexer.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/ScopedHashTable.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <numeric>
#include <optional>
#include <tuple>
#include <utility>
#include <vector>

using namespace mlir::toy;
using namespace toy;

using llvm::ArrayRef;
using llvm::cast;
using llvm::dyn_cast;
using llvm::isa;
using llvm::ScopedHashTableScope;
using llvm::SmallVector;
using llvm::StringRef;
using llvm::Twine;

namespace {

/// Implementation of a simple MLIR emission from the Toy AST.
///
/// This will emit operations that are specific to the Toy language, preserving
/// the semantics of the language and (hopefully) allow to perform accurate
/// analysis and transformation based on these high level semantics.
class MLIRGenImpl {
public:
  MLIRGenImpl(mlir::MLIRContext &context) : builder(&context) {}

  /// Public API: convert the AST for a Toy module (source file) to an MLIR
  /// Module operation.
  mlir::ModuleOp mlirGen(ModuleAST &moduleAST) {
    // We create an empty MLIR module and codegen functions one at a time and
    // add them to the module.
    theModule = mlir::ModuleOp::create(builder.getUnknownLoc());

    for (auto &record : moduleAST) {
      if (FunctionAST *funcAST = llvm::dyn_cast<FunctionAST>(record.get())) {
        mlir::toy::FuncOp func = mlirGen(*funcAST);
        if (!func)
          return nullptr;
        functionMap.insert({func.getName(), func});
      } else if (StructAST *str = llvm::dyn_cast<StructAST>(record.get())) {
        if (failed(mlirGen(*str)))
          return nullptr;
      } else {
        llvm_unreachable("unknown record type");
      }
    }

    // Verify the module after we have finished constructing it, this will check
    // the structural properties of the IR and invoke any specific verifiers we
    // have on the Toy operations.
    if (failed(mlir::verify(theModule))) {
      theModule.emitError("module verification error");
      return nullptr;
    }

    return theModule;
  }

private:
  /// A "module" matches a Toy source file: containing a list of functions.
  mlir::ModuleOp theModule;

  /// The builder is a helper class to create IR inside a function. The builder
  /// is stateful, in particular it keeps an "insertion point": this is where
  /// the next operations will be introduced.
  mlir::OpBuilder builder;

  /// The symbol table maps a variable name to a value in the current scope.
  /// Entering a function creates a new scope, and the function arguments are
  /// added to the mapping. When the processing of a function is terminated, the
  /// scope is destroyed and the mappings created in this scope are dropped.
  llvm::ScopedHashTable<StringRef, std::pair<mlir::Value, VarDeclExprAST *>>
      symbolTable;
  using SymbolTableScopeT =
      llvm::ScopedHashTableScope<StringRef,
                                 std::pair<mlir::Value, VarDeclExprAST *>>;

  /// A mapping for the functions that have been code generated to MLIR.
  llvm::StringMap<mlir::toy::FuncOp> functionMap;

  /// A mapping for named struct types to the underlying MLIR type and the
  /// original AST node.
  llvm::StringMap<std::pair<mlir::Type, StructAST *>> structMap;

  /// Helper conversion for a Toy AST location to an MLIR location.
  mlir::Location loc(const Location &loc) {
    return mlir::FileLineColLoc::get(builder.getStringAttr(*loc.file), loc.line,
                                     loc.col);
  }

  /// Declare a variable in the current scope, return success if the variable
  /// wasn't declared yet.
  llvm::LogicalResult declare(VarDeclExprAST &var, mlir::Value value) {
    if (symbolTable.count(var.getName()))
      return mlir::failure();
    symbolTable.insert(var.getName(), {value, &var});
    return mlir::success();
  }

  /// Create an MLIR type for the given struct.
  llvm::LogicalResult mlirGen(StructAST &str) {
    if (structMap.count(str.getName()))
      return emitError(loc(str.loc())) << "error: struct type with name `"
                                       << str.getName() << "' already exists";

    auto variables = str.getVariables();
    std::vector<mlir::Type> elementTypes;
    elementTypes.reserve(variables.size());
    for (auto &variable : variables) {
      if (variable->getInitVal())
        return emitError(loc(variable->loc()))
               << "error: variables within a struct definition must not have "
                  "initializers";
      if (!variable->getType().shape.empty())
        return emitError(loc(variable->loc()))
               << "error: variables within a struct definition must not have "
                  "initializers";

      mlir::Type type = getType(variable->getType(), variable->loc());
      if (!type)
        return mlir::failure();
      elementTypes.push_back(type);
    }

    structMap.try_emplace(str.getName(), StructType::get(elementTypes), &str);
    return mlir::success();
  }

  /// Create the prototype for an MLIR function with as many arguments as the
  /// provided Toy AST prototype.
  mlir::toy::FuncOp mlirGen(PrototypeAST &proto) {
    auto location = loc(proto.loc());

    // This is a generic function, the return type will be inferred later.
    llvm::SmallVector<mlir::Type, 4> argTypes;
    argTypes.reserve(proto.getArgs().size());
    for (auto &arg : proto.getArgs()) {
      mlir::Type type = getType(arg->getType(), arg->loc());
      if (!type)
        return nullptr;
      argTypes.push_back(type);
    }
    auto funcType = builder.getFunctionType(argTypes, /*results=*/{});
    return mlir::toy::FuncOp::create(builder, location, proto.getName(),
                                     funcType);
  }

  /// Emit a new function and add it to the MLIR module.
  mlir::toy::FuncOp mlirGen(FunctionAST &funcAST) {
    // Create a scope in the symbol table to hold variable declarations.
    SymbolTableScopeT varScope(symbolTable);

    // Create an MLIR function for the given prototype.
    builder.setInsertionPointToEnd(theModule.getBody());
    mlir::toy::FuncOp function = mlirGen(*funcAST.getProto());
    if (!function)
      return nullptr;

    // Let's start the body of the function now!
    mlir::Block &entryBlock = function.front();
    auto protoArgs = funcAST.getProto()->getArgs();

    // Declare all the function arguments in the symbol table.
    for (const auto nameValue :
         llvm::zip(protoArgs, entryBlock.getArguments())) {
      if (failed(declare(*std::get<0>(nameValue), std::get<1>(nameValue))))
        return nullptr;
    }

    // Set the insertion point in the builder to the beginning of the function
    // body, it will be used throughout the codegen to create operations in this
    // function.
    builder.setInsertionPointToStart(&entryBlock);

    // Emit the body of the function.
    if (mlir::failed(mlirGen(*funcAST.getBody()))) {
      function.erase();
      return nullptr;
    }

    // Implicitly return void if no return statement was emitted.
    // FIXME: we may fix the parser instead to always return the last expression
    // (this would possibly help the REPL case later)
    ReturnOp returnOp;
    if (!entryBlock.empty())
      returnOp = dyn_cast<ReturnOp>(entryBlock.back());
    if (!returnOp) {
      ReturnOp::create(builder, loc(funcAST.getProto()->loc()));
    } else if (returnOp.hasOperand()) {
      // Otherwise, if this return operation has an operand then add a result to
      // the function.
      function.setType(
          builder.getFunctionType(function.getFunctionType().getInputs(),
                                  *returnOp.operand_type_begin()));
    }

    // If this function isn't main, then set the visibility to private.
    if (funcAST.getProto()->getName() != "main")
      function.setPrivate();

    return function;
  }

  /// Return the struct type that is the result of the given expression, or null
  /// if it cannot be inferred.
  StructAST *getStructFor(ExprAST *expr) {
    llvm::StringRef structName;
    if (auto *decl = llvm::dyn_cast<VariableExprAST>(expr)) {
      auto varIt = symbolTable.lookup(decl->getName());
      if (!varIt.first)
        return nullptr;
      structName = varIt.second->getType().name;
    } else if (auto *access = llvm::dyn_cast<BinaryExprAST>(expr)) {
      if (access->getOp() != '.')
        return nullptr;
      // The name being accessed should be in the RHS.
      auto *name = llvm::dyn_cast<VariableExprAST>(access->getRHS());
      if (!name)
        return nullptr;
      StructAST *parentStruct = getStructFor(access->getLHS());
      if (!parentStruct)
        return nullptr;

      // Get the element within the struct corresponding to the name.
      VarDeclExprAST *decl = nullptr;
      for (auto &var : parentStruct->getVariables()) {
        if (var->getName() == name->getName()) {
          decl = var.get();
          break;
        }
      }
      if (!decl)
        return nullptr;
      structName = decl->getType().name;
    }
    if (structName.empty())
      return nullptr;

    // If the struct name was valid, check for an entry in the struct map.
    auto structIt = structMap.find(structName);
    if (structIt == structMap.end())
      return nullptr;
    return structIt->second.second;
  }

  /// Return the numeric member index of the given struct access expression.
  std::optional<size_t> getMemberIndex(BinaryExprAST &accessOp) {
    assert(accessOp.getOp() == '.' && "expected access operation");

    // Lookup the struct node for the LHS.
    StructAST *structAST = getStructFor(accessOp.getLHS());
    if (!structAST)
      return std::nullopt;

    // Get the name from the RHS.
    VariableExprAST *name = llvm::dyn_cast<VariableExprAST>(accessOp.getRHS());
    if (!name)
      return std::nullopt;

    auto structVars = structAST->getVariables();
    const auto *it = llvm::find_if(structVars, [&](auto &var) {
      return var->getName() == name->getName();
    });
    if (it == structVars.end())
      return std::nullopt;
    return it - structVars.begin();
  }

  /// Emit a binary operation
  mlir::Value mlirGen(BinaryExprAST &binop) {
    // First emit the operations for each side of the operation before emitting
    // the operation itself. For example if the expression is `a + foo(a)`
    // 1) First it will visiting the LHS, which will return a reference to the
    //    value holding `a`. This value should have been emitted at declaration
    //    time and registered in the symbol table, so nothing would be
    //    codegen'd. If the value is not in the symbol table, an error has been
    //    emitted and nullptr is returned.
    // 2) Then the RHS is visited (recursively) and a call to `foo` is emitted
    //    and the result value is returned. If an error occurs we get a nullptr
    //    and propagate.
    //
    mlir::Value lhs = mlirGen(*binop.getLHS());
    if (!lhs)
      return nullptr;
    auto location = loc(binop.loc());

    // If this is an access operation, handle it immediately.
    if (binop.getOp() == '.') {
      std::optional<size_t> accessIndex = getMemberIndex(binop);
      if (!accessIndex) {
        emitError(location, "invalid access into struct expression");
        return nullptr;
      }
      return StructAccessOp::create(builder, location, lhs, *accessIndex);
    }

    // Otherwise, this is a normal binary op.
    mlir::Value rhs = mlirGen(*binop.getRHS());
    if (!rhs)
      return nullptr;

    // Derive the operation name from the binary operator. At the moment we only
    // support '+' and '*'.
    switch (binop.getOp()) {
    case '+':
      return AddOp::create(builder, location, lhs, rhs);
    case '*':
      return MulOp::create(builder, location, lhs, rhs);
    }

    emitError(location, "invalid binary operator '") << binop.getOp() << "'";
    return nullptr;
  }

  /// This is a reference to a variable in an expression. The variable is
  /// expected to have been declared and so should have a value in the symbol
  /// table, otherwise emit an error and return nullptr.
  mlir::Value mlirGen(VariableExprAST &expr) {
    if (auto variable = symbolTable.lookup(expr.getName()).first)
      return variable;

    emitError(loc(expr.loc()), "error: unknown variable '")
        << expr.getName() << "'";
    return nullptr;
  }

  /// Emit a return operation. This will return failure if any generation fails.
  llvm::LogicalResult mlirGen(ReturnExprAST &ret) {
    auto location = loc(ret.loc());

    // 'return' takes an optional expression, handle that case here.
    mlir::Value expr = nullptr;
    if (ret.getExpr().has_value()) {
      if (!(expr = mlirGen(**ret.getExpr())))
        return mlir::failure();
    }

    // Otherwise, this return operation has zero operands.
    ReturnOp::create(builder, location,
                     expr ? ArrayRef(expr) : ArrayRef<mlir::Value>());
    return mlir::success();
  }

  /// Emit a constant for a literal/constant array. It will be emitted as a
  /// flattened array of data in an Attribute attached to a `toy.constant`
  /// operation. See documentation on [Attributes](LangRef.md#attributes) for
  /// more details. Here is an excerpt:
  ///
  ///   Attributes are the mechanism for specifying constant data in MLIR in
  ///   places where a variable is never allowed [...]. They consist of a name
  ///   and a concrete attribute value. The set of expected attributes, their
  ///   structure, and their interpretation are all contextually dependent on
  ///   what they are attached to.
  ///
  /// Example, the source level statement:
  ///   var a<2, 3> = [[1, 2, 3], [4, 5, 6]];
  /// will be converted to:
  ///   %0 = "toy.constant"() {value: dense<tensor<2x3xf64>,
  ///     [[1.000000e+00, 2.000000e+00, 3.000000e+00],
  ///      [4.000000e+00, 5.000000e+00, 6.000000e+00]]>} : () -> tensor<2x3xf64>
  ///
  mlir::DenseElementsAttr getConstantAttr(LiteralExprAST &lit) {
    // The attribute is a vector with a floating point value per element
    // (number) in the array, see `collectData()` below for more details.
    std::vector<double> data;
    data.reserve(std::accumulate(lit.getDims().begin(), lit.getDims().end(), 1,
                                 std::multiplies<int>()));
    collectData(lit, data);

    // The type of this attribute is tensor of 64-bit floating-point with the
    // shape of the literal.
    mlir::Type elementType = builder.getF64Type();
    auto dataType = mlir::RankedTensorType::get(lit.getDims(), elementType);

    // This is the actual attribute that holds the list of values for this
    // tensor literal.
    return mlir::DenseElementsAttr::get(dataType, llvm::ArrayRef(data));
  }
  mlir::DenseElementsAttr getConstantAttr(NumberExprAST &lit) {
    // The type of this attribute is tensor of 64-bit floating-point with no
    // shape.
    mlir::Type elementType = builder.getF64Type();
    auto dataType = mlir::RankedTensorType::get({}, elementType);

    // This is the actual attribute that holds the list of values for this
    // tensor literal.
    return mlir::DenseElementsAttr::get(dataType,
                                        llvm::ArrayRef(lit.getValue()));
  }
  /// Emit a constant for a struct literal. It will be emitted as an array of
  /// other literals in an Attribute attached to a `toy.struct_constant`
  /// operation. This function returns the generated constant, along with the
  /// corresponding struct type.
  std::pair<mlir::ArrayAttr, mlir::Type>
  getConstantAttr(StructLiteralExprAST &lit) {
    std::vector<mlir::Attribute> attrElements;
    std::vector<mlir::Type> typeElements;

    for (auto &var : lit.getValues()) {
      if (auto *number = llvm::dyn_cast<NumberExprAST>(var.get())) {
        attrElements.push_back(getConstantAttr(*number));
        typeElements.push_back(getType(/*shape=*/{}));
      } else if (auto *lit = llvm::dyn_cast<LiteralExprAST>(var.get())) {
        attrElements.push_back(getConstantAttr(*lit));
        typeElements.push_back(getType(/*shape=*/{}));
      } else {
        auto *structLit = llvm::cast<StructLiteralExprAST>(var.get());
        auto attrTypePair = getConstantAttr(*structLit);
        attrElements.push_back(attrTypePair.first);
        typeElements.push_back(attrTypePair.second);
      }
    }
    mlir::ArrayAttr dataAttr = builder.getArrayAttr(attrElements);
    mlir::Type dataType = StructType::get(typeElements);
    return std::make_pair(dataAttr, dataType);
  }

  /// Emit an array literal.
  mlir::Value mlirGen(LiteralExprAST &lit) {
    mlir::Type type = getType(lit.getDims());
    mlir::DenseElementsAttr dataAttribute = getConstantAttr(lit);

    // Build the MLIR op `toy.constant`. This invokes the `ConstantOp::build`
    // method.
    return ConstantOp::create(builder, loc(lit.loc()), type, dataAttribute);
  }

  /// Emit a struct literal. It will be emitted as an array of
  /// other literals in an Attribute attached to a `toy.struct_constant`
  /// operation.
  mlir::Value mlirGen(StructLiteralExprAST &lit) {
    mlir::ArrayAttr dataAttr;
    mlir::Type dataType;
    std::tie(dataAttr, dataType) = getConstantAttr(lit);

    // Build the MLIR op `toy.struct_constant`. This invokes the
    // `StructConstantOp::build` method.
    return StructConstantOp::create(builder, loc(lit.loc()), dataType,
                                    dataAttr);
  }

  /// Recursive helper function to accumulate the data that compose an array
  /// literal. It flattens the nested structure in the supplied vector. For
  /// example with this array:
  ///  [[1, 2], [3, 4]]
  /// we will generate:
  ///  [ 1, 2, 3, 4 ]
  /// Individual numbers are represented as doubles.
  /// Attributes are the way MLIR attaches constant to operations.
  void collectData(ExprAST &expr, std::vector<double> &data) {
    if (auto *lit = dyn_cast<LiteralExprAST>(&expr)) {
      for (auto &value : lit->getValues())
        collectData(*value, data);
      return;
    }

    assert(isa<NumberExprAST>(expr) && "expected literal or number expr");
    data.push_back(cast<NumberExprAST>(expr).getValue());
  }

  /// Emit a call expression. It emits specific operations for the `transpose`
  /// builtin. Other identifiers are assumed to be user-defined functions.
  mlir::Value mlirGen(CallExprAST &call) {
    llvm::StringRef callee = call.getCallee();
    auto location = loc(call.loc());

    // Codegen the operands first.
    SmallVector<mlir::Value, 4> operands;
    for (auto &expr : call.getArgs()) {
      auto arg = mlirGen(*expr);
      if (!arg)
        return nullptr;
      operands.push_back(arg);
    }

    // Builtin calls have their custom operation, meaning this is a
    // straightforward emission.
    if (callee == "transpose") {
      if (call.getArgs().size() != 1) {
        emitError(location, "MLIR codegen encountered an error: toy.transpose "
                            "does not accept multiple arguments");
        return nullptr;
      }
      return TransposeOp::create(builder, location, operands[0]);
    }

    // Otherwise this is a call to a user-defined function. Calls to
    // user-defined functions are mapped to a custom call that takes the callee
    // name as an attribute.
    auto calledFuncIt = functionMap.find(callee);
    if (calledFuncIt == functionMap.end()) {
      emitError(location) << "no defined function found for '" << callee << "'";
      return nullptr;
    }
    mlir::toy::FuncOp calledFunc = calledFuncIt->second;
    return GenericCallOp::create(builder, location,
                                 calledFunc.getFunctionType().getResult(0),
                                 callee, operands);
  }

  /// Emit a print expression. It emits specific operations for two builtins:
  /// transpose(x) and print(x).
  llvm::LogicalResult mlirGen(PrintExprAST &call) {
    auto arg = mlirGen(*call.getArg());
    if (!arg)
      return mlir::failure();

    PrintOp::create(builder, loc(call.loc()), arg);
    return mlir::success();
  }

  /// Emit a constant for a single number (FIXME: semantic? broadcast?)
  mlir::Value mlirGen(NumberExprAST &num) {
    return ConstantOp::create(builder, loc(num.loc()), num.getValue());
  }

  /// Dispatch codegen for the right expression subclass using RTTI.
  mlir::Value mlirGen(ExprAST &expr) {
    switch (expr.getKind()) {
    case toy::ExprAST::Expr_BinOp:
      return mlirGen(cast<BinaryExprAST>(expr));
    case toy::ExprAST::Expr_Var:
      return mlirGen(cast<VariableExprAST>(expr));
    case toy::ExprAST::Expr_Literal:
      return mlirGen(cast<LiteralExprAST>(expr));
    case toy::ExprAST::Expr_StructLiteral:
      return mlirGen(cast<StructLiteralExprAST>(expr));
    case toy::ExprAST::Expr_Call:
      return mlirGen(cast<CallExprAST>(expr));
    case toy::ExprAST::Expr_Num:
      return mlirGen(cast<NumberExprAST>(expr));
    default:
      emitError(loc(expr.loc()))
          << "MLIR codegen encountered an unhandled expr kind '"
          << Twine(expr.getKind()) << "'";
      return nullptr;
    }
  }

  /// Handle a variable declaration, we'll codegen the expression that forms the
  /// initializer and record the value in the symbol table before returning it.
  /// Future expressions will be able to reference this variable through symbol
  /// table lookup.
  mlir::Value mlirGen(VarDeclExprAST &vardecl) {
    auto *init = vardecl.getInitVal();
    if (!init) {
      emitError(loc(vardecl.loc()),
                "missing initializer in variable declaration");
      return nullptr;
    }

    mlir::Value value = mlirGen(*init);
    if (!value)
      return nullptr;

    // Handle the case where we are initializing a struct value.
    VarType varType = vardecl.getType();
    if (!varType.name.empty()) {
      // Check that the initializer type is the same as the variable
      // declaration.
      mlir::Type type = getType(varType, vardecl.loc());
      if (!type)
        return nullptr;
      if (type != value.getType()) {
        emitError(loc(vardecl.loc()))
            << "struct type of initializer is different than the variable "
               "declaration. Got "
            << value.getType() << ", but expected " << type;
        return nullptr;
      }

      // Otherwise, we have the initializer value, but in case the variable was
      // declared with specific shape, we emit a "reshape" operation. It will
      // get optimized out later as needed.
    } else if (!varType.shape.empty()) {
      value = ReshapeOp::create(builder, loc(vardecl.loc()),
                                getType(varType.shape), value);
    }

    // Register the value in the symbol table.
    if (failed(declare(vardecl, value)))
      return nullptr;
    return value;
  }

  /// Codegen a list of expression, return failure if one of them hit an error.
  llvm::LogicalResult mlirGen(ExprASTList &blockAST) {
    SymbolTableScopeT varScope(symbolTable);
    for (auto &expr : blockAST) {
      // Specific handling for variable declarations, return statement, and
      // print. These can only appear in block list and not in nested
      // expressions.
      if (auto *vardecl = dyn_cast<VarDeclExprAST>(expr.get())) {
        if (!mlirGen(*vardecl))
          return mlir::failure();
        continue;
      }
      if (auto *ret = dyn_cast<ReturnExprAST>(expr.get()))
        return mlirGen(*ret);
      if (auto *print = dyn_cast<PrintExprAST>(expr.get())) {
        if (mlir::failed(mlirGen(*print)))
          return mlir::success();
        continue;
      }

      // Generic expression dispatch codegen.
      if (!mlirGen(*expr))
        return mlir::failure();
    }
    return mlir::success();
  }

  /// Build a tensor type from a list of shape dimensions.
  mlir::Type getType(ArrayRef<int64_t> shape) {
    // If the shape is empty, then this type is unranked.
    if (shape.empty())
      return mlir::UnrankedTensorType::get(builder.getF64Type());

    // Otherwise, we use the given shape.
    return mlir::RankedTensorType::get(shape, builder.getF64Type());
  }

  /// Build an MLIR type from a Toy AST variable type (forward to the generic
  /// getType above for non-struct types).
  mlir::Type getType(const VarType &type, const Location &location) {
    if (!type.name.empty()) {
      auto it = structMap.find(type.name);
      if (it == structMap.end()) {
        emitError(loc(location))
            << "error: unknown struct type '" << type.name << "'";
        return nullptr;
      }
      return it->second.first;
    }

    return getType(type.shape);
  }
};

} // namespace

namespace toy {

// The public API for codegen.
mlir::OwningOpRef<mlir::ModuleOp> mlirGen(mlir::MLIRContext &context,
                                          ModuleAST &moduleAST) {
  return MLIRGenImpl(context).mlirGen(moduleAST);
}

} // namespace toy

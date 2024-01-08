// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import BUILDParser
import struct Foundation.URL

extension Expression {
  package func evaluate(in scope: inout Scope) throws -> any Value {
    switch self {
    case let array as ArrayExpression:
      return try ListValue(array.elements.map { try $0.evaluate(in: &scope) })

    case let block as BlockExpression:
      for statement in block.statements {
        _ = try statement.evaluate(in: &scope)
      }
      return NilValue()

    case let binop as BinaryOperandExpression:
      switch binop.operation.kind {
      case .equal:
        let destination: String =
            if let dre = binop.lhs as? DeclarationReferenceExpression {
              dre.name
            } else {
              fatalError("evaluation required")
            }
        scope[destination] = try binop.rhs.evaluate(in: &scope)

        return NilValue()

      case .plus_equal, .minus_equal:
print("(assign \(binop.lhs), \(binop.rhs))")
return NilValue()
      case .ampersand_ampersand:
print("(and \(binop.lhs), \(binop.rhs))")
return NilValue()
      case .pipe_pipe:
print("(or \(binop.lhs), \(binop.rhs))")
return NilValue()
      default: break
      }

      let lhs: any Value = try binop.lhs.evaluate(in: &scope)
      let rhs: any Value = try binop.rhs.evaluate(in: &scope)

      switch binop.operation.kind {
      case .equal, .plus_equal, .minus_equal: fatalError()
      case .ampersand_ampersand, .pipe_pipe: fatalError()
      case .equal_equal:
        return BooleanValue(lhs == rhs)
      case .bang_equal:
        return BooleanValue(lhs == rhs ? false : true)
      case .greater_equal, .less_equal, .greater, .less:
        guard let lhs = lhs as? IntegerValue, let rhs = rhs as? IntegerValue else {
          throw ExecutionError("comparision requires two integer values",
                               at: binop.range)
        }

        let value: Bool = switch binop.operation.kind {
        case .greater_equal: lhs.data >= rhs.data
        case .less_equal: lhs.data <= rhs.data
        case .greater: lhs.data > rhs.data
        case .less: lhs.data < rhs.data
        default: fatalError("invalid case")
        }
        return BooleanValue(value)
      default:
        fatalError("unknown binary operation '\(binop.operation.kind)'")
      }

    case let conditional as ConditionalExpression:
      let condition = try conditional.condition.evaluate(in: &scope)
      guard let condition = condition as? BooleanValue else {
        throw ExecutionError("conditional statement requires a boolean value",
                             at: conditional.range)
      }
      return try condition.data
          ? conditional.positive.evaluate(in: &scope)
          : (conditional.negative?.evaluate(in: &scope) ?? NilValue())

    case let reference as DeclarationReferenceExpression:
      if let value = scope[reference.name] { return value }
      throw ExecutionError("\(reference.name) is undefined",
                           at: reference.range)

    case let function as FunctionCallExpression:
      let callee = function.callee.name
      if let template = scope.template(named: callee) {
        let arguments = try function.arguments.map {
          try $0.evaluate(in: &scope)
        }
        return try template.invoke(function, arguments: arguments,
                                   scope: function.scope, in: &scope)
      } else if let builtin = Builtin[callee] {
        // TODO(compnerd) handle `foreach` which uses delayed parameter
        // evaluation.
        assert(!builtin.delayed)

        let location = function.range.file.url.deletingLastPathComponent()
        var child: Scope = Scope(parent: &scope, directory: location)

        let arguments = try function.arguments.map {
          try $0.evaluate(in: &scope)
        }
        if let block = function.scope {
          _ = try block.evaluate(in: &child)
        }
        return try builtin.invoke(function, arguments, &scope)
      }

      throw ExecutionError("unknown function '\(callee)'",
                            at: function.callee.range)

    case let literal as BooleanLiteralExpression:
      return BooleanValue(literal.value)

    case let literal as StringLiteralExpression:
      // TODO(compnerd) string expansion
      return StringValue(literal.value)

    default:
      fatalError("uhandled statement type")
    }
  }
}

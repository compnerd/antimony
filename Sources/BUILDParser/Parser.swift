// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

// The top level block and condition parser is recursive descent. The expression
// parser is a Pratt parser.

private enum Precedence: Int {
  case assignment = 1 // lowest precedence
  case or
  case and
  case equality
  case relation
  case sum
  case prefix
  case call
  case dot
}

extension Token {
  fileprivate var `break`: Bool {
    [.identifier, .lbrace, .rbrace, .if, .else].contains(kind)
  }

  fileprivate var precedence: Int {
    return switch kind {
    case .equal: Precedence.assignment.rawValue
    case .plus, .minus: Precedence.sum.rawValue
    case .plus_equal, .minus_equal: Precedence.assignment.rawValue
    case .equal_equal, .bang_equal: Precedence.equality.rawValue
    case .less_equal, .greater_equal, .less, .greater: Precedence.relation.rawValue
    case .ampersand_ampersand: Precedence.and.rawValue
    case .pipe_pipe: Precedence.or.rawValue
    case .dot: Precedence.dot.rawValue
    case .lbracket: Precedence.call.rawValue
    case .identifier: Precedence.call.rawValue
    default: -1
    }
  }
}

extension Expression {
  fileprivate var isAssignment: Bool {
    if let expr = self as? BinaryOperandExpression {
      return [.equal, .plus_equal, .minus_equal].contains(expr.operation.kind)
    }
    return false
  }
}

public struct Parser {
  private static func list(from: Token, to terminator: Token.Kind,
                           _ state: inout ParserState,
                           permitTrailingComma: Bool = false) -> [Expression]? {
    var list: [Expression] = []
    while state.peek()?.kind != terminator {
      if !list.isEmpty {
        if state.take(.comma) == nil {
          state.diagnostics.insert(.error(expected: .comma, at: state.location))
          return nil
        }
        if permitTrailingComma, state.peek()?.kind == terminator { break }
      }

      // We are parsing entities with a precendence higher than a `,` which
      // demarcates items of the list. The lowest boolean expression
      // precedence is `or`.
      if let expression = self.expression(precedence: .or, &state) {
        list.append(expression)
      }

      guard state.diagnostics.empty else { return nil }
      if state.peek() == nil {
        let range = from.range.extended(upto: state.cursor)
        state.diagnostics.insert(.error("unexpected end of file in list",
                                        range: range))
        return nil
      }
    }
    return list
  }

  private static func apply(_ continuation: Expression? = nil,
                            _ state: inout ParserState) -> Expression? {
    guard let identifier = state.take() else { return nil }

    let name =
        state.source.text[identifier.range.start ..< identifier.range.end]
    let dre = DeclarationReferenceExpression(name: String(name),
                                             range: identifier.range)

    if let lparen = state.take(.lparen) {
      guard let arguments = list(from: lparen, to: .rparen, &state) else {
        return nil
      }

      guard let rparen = state.take(.rparen) else {
        state.diagnostics.insert(.error(expected: .rparen, at: state.location))
        return nil
      }

      let range = lparen.range.extended(upto: rparen.range.end)

      if state.peek()?.kind == .lbrace {
        guard let scope = block(&state) else { return nil }
        return FunctionCallExpression(dre, arguments: arguments, range: range,
                                      scope: scope)
      }

      return FunctionCallExpression(dre, arguments: arguments, range: range)
    }

    if continuation == nil { return dre }
    return FunctionCallExpression(dre, range: state.location ..< state.location)
  }

  private static func binop(_ lhs: Expression,
                            _ state: inout ParserState) -> Expression? {
    guard let operation = state.take() else {
      return nil
    }
    let precedence = operation.precedence == -1
                        ? nil
                        : Precedence(rawValue: operation.precedence + 1)
    guard let rhs = expression(precedence: precedence, &state) else {
      state.diagnostics.insert(.error("expected right hand side expression for '\(operation)'",
                                      range: state.location ..< state.location))
      return nil
    }
    return BinaryOperandExpression(operation: operation, lhs: lhs, rhs: rhs)
  }

  private static func assignment(_ lhs: Expression,
                                 _ state: inout ParserState) -> Expression? {
    guard lhs is DeclarationReferenceExpression else {
      state.diagnostics.insert(.error("the left-hand side of an assignment must be an identifier, scope access, or array access",
                                      range: state.location ..< state.location))
      return nil
    }

    guard let operand = state.take(.equal) else { return nil }

    guard let value = expression(precedence: .assignment, &state) else {
      if !state.diagnostics.empty {
        let range = state.location ..< state.location
        state.diagnostics.insert(.error("expected right-hand side for assignment",
                                        range: range))
      }
      return nil
    }

    return BinaryOperandExpression(operation: operand, lhs: lhs, rhs: value)
  }

  private static func block(_ state: inout ParserState) -> Expression? {
    guard state.diagnostics.empty else { return nil }

    var statements: [Expression] = []

    guard let lbrace = state.take(.lbrace) else { return nil }
    while state.peek()?.kind != .rbrace {
      guard let statement = statement(&state) else { return nil }
      statements.append(statement)
    }
    guard let rbrace = state.take(.rbrace) else { return nil }

    let range = lbrace.range.extended(upto: rbrace.range.end)
    return BlockExpression(statements: statements, range: range)
  }

  private static func expression(precedence: Precedence?,
                                 _ state: inout ParserState) -> Expression? {
    var lhs: Expression?

    if let token = state.peek() {
      switch token.kind {
      case let .literal(type):
        switch type {
        case .integer:
          fatalError()
        case .string:
          _ = state.take()!
          let literal = state.source.text[token.range.start ..< token.range.end]
          lhs = StringLiteralExpression(value: String(literal),
                                        range: token.range)
        }
      case .true, .false:
        _ = state.take()!
        lhs = BooleanLiteralExpression(value: token.kind == .true,
                                       range: token.range)
      case .bang: break // not
      case .lparen: break // group
      case .lbracket:
        let lbracket = state.take()!
        guard let elements = list(from: lbracket, to: .rbracket, &state,
                                  permitTrailingComma: true) else {
          return nil
        }
        guard let rbracket = state.take(.rbracket) else {
          state.diagnostics.insert(.error(expected: .rbracket,
                                          at: state.location))
          return nil
        }
        let range = lbracket.range.extended(upto: rbracket.range.end)
        lhs = ArrayExpression(elements: elements, range: range)

      case .identifier:
        lhs = apply(nil, &state)

      default:
        state.diagnostics.insert(.error(unexpected: token, at: state.location))
        return nil
      }
    }

    while let token = state.peek(), !token.break,
        (precedence?.rawValue ?? 0) <= token.precedence {
      switch token.kind {
      case .equal:
        guard let lvalue = lhs else {
          // TODO(compnerd) diagnose
          return nil
        }
        lhs = assignment(lvalue, &state)

      case .plus, .minus: fallthrough
      case .plus_equal, .minus_equal: fallthrough
      case .equal_equal, .bang_equal: fallthrough
      case .less, .less_equal, .greater, .greater_equal: fallthrough
      case .ampersand_ampersand: fallthrough
      case .pipe_pipe:
        guard let unwrapped = lhs else {
          // TODO(compnerd) diagnose
          return nil
        }
        lhs = binop(unwrapped, &state)

      case .dot: break // dot operator
      case .lbracket: break // subscript
      case .lparen: break // call
      default:
        state.diagnostics.insert(.error(unexpected: token, at: state.location))
        return nil
      }
    }

    return lhs
  }

  private static func statement(_ state: inout ParserState) -> Expression? {
    if state.peek() == nil { return nil }
    if state.peek()?.kind == .if { return condition(&state) }
    // TODO(compnerd) handle block comment
    if let expression = expression(precedence: .none, &state) {
      if expression is FunctionCallExpression || expression.isAssignment {
        return expression
      }
    }
    if state.diagnostics.empty {
      state.diagnostics.insert(.error("expected assignment or function call",
                                      range: state.location ..< state.location))
    }
    return nil
  }

  private static func condition(_ state: inout ParserState) -> Expression? {
    guard let `if` = state.take(.if) else { return nil }

    if state.take(.lparen) == nil {
      state.diagnostics.insert(.error(expected: .lparen, at: state.location))
      return nil
    }
    guard let condition = expression(precedence: .none, &state) else {
      return nil
    }
    if condition.isAssignment {
      state.diagnostics.insert(.error("assignment is not permitted in 'if'",
                                      range: condition.range))
      return nil
    }
    if state.take(.rparen) == nil {
      state.diagnostics.insert(.error(expected: .rparen, at: state.location))
      return nil
    }

    guard state.peek()?.kind == .lbrace else {
      state.diagnostics.insert(.error(expected: .lbrace, at: state.location))
      return nil
    }
    guard let positive = block(&state) else { return nil }

    if let `else` = state.take(.else) {
      switch state.peek()?.kind {
      case .some(.lbrace):
        guard let negative = block(&state) else { return nil }
        return ConditionalExpression(condition: condition, true: positive,
                                     false: negative)
      case .some(.if):
        guard let negative = statement(&state) else { return nil }
        return ConditionalExpression(condition: condition, true: positive,
                                     false: negative)
      default:
        state.diagnostics.insert(.error("expected '{' or 'if' after 'else'",
                                        range: state.location ..< state.location))
        return nil
      }
    }

    return ConditionalExpression(condition: condition, true: positive)
  }

  public static func parse(_ input: SourceFile,
                           into expressions: inout [Expression],
                           diagnostics: inout DiagnosticSet) throws {
    var state: ParserState =
        ParserState(lexing: input, into: expressions, diagnostics: diagnostics)

    defer { diagnostics = state.diagnostics }
    diagnostics = DiagnosticSet()

    while let statement = statement(&state) {
      state.product(statement)
    }

    if !state.diagnostics.empty {
      throw state.diagnostics
    }

    // Check that the entire input was consumed.
    assert(state.peek() == nil, "expected EOF")

    expressions = state.expressions
  }
}

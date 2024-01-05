// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

// MARK:- Statements

public protocol Statement {
  var range: SourceRange { get }
}

public struct BlockStatement: Statement {
  public let range: SourceRange
  public let statements: [Statement]

  public init(statements: [Statement], range: SourceRange) {
    self.statements = statements
    self.range = range
  }
}

// MARK:- Expressions

public protocol Expression: Statement {}

public struct ArrayExpression: Expression {
  public let elements: [Expression]
  public let range: SourceRange
}

public struct BinaryOperandExpression: Expression {
  public let operation: Token
  public let lhs: Expression
  public let rhs: Expression

  public var range: SourceRange {
    lhs.range.extended(upto: rhs.range.end)
  }
}

public struct DeclarationReferenceExpression: Expression {
  public let name: String
  public let range: SourceRange

  public init(name: String, range: SourceRange) {
    self.name = name
    self.range = range
  }
}

public struct FunctionCallExpression: Expression {
  public let callee: DeclarationReferenceExpression
  public let range: SourceRange
  public let arguments: [Expression]
  public let scope: Statement?

  public init(_ dre: DeclarationReferenceExpression, range: SourceRange) {
    self.callee = dre
    self.range = range
    self.arguments = []
    self.scope = nil
  }

  public init(_ dre: DeclarationReferenceExpression, arguments: [Expression],
              range: SourceRange) {
    self.callee = dre
    self.range = range
    self.arguments = arguments
    self.scope = nil
  }

  public init(_ dre: DeclarationReferenceExpression, arguments: [Expression],
              range: SourceRange, scope: Statement) {
    self.callee = dre
    self.range = range
    self.arguments = arguments
    self.scope = scope
  }
}

public struct BooleanLiteralExpression: Expression {
  public let value: Bool
  public let range: SourceRange

  public init(value: Bool, range: SourceRange) {
    self.value = value
    self.range = range
  }
}

public struct IntegerLiteralExpression: Expression {
  public let value: String
  public let range: SourceRange

  public init(value: String, range: SourceRange) {
    self.value = value
    self.range = range
  }
}

public struct StringLiteralExpression: Expression {
  public let value: String
  public let range: SourceRange

  public init(value: String, range: SourceRange) {
    self.value = value
    self.range = range
  }
}

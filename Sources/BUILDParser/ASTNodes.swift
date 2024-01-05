// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

public protocol Expression {
  var range: SourceRange { get }
}

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

public struct BlockExpression: Expression {
  public let range: SourceRange
  public let statements: [Expression]

  public init(statements: [Expression], range: SourceRange) {
    self.statements = statements
    self.range = range
  }
}

public struct ConditionalExpression: Expression {
  public let condition: Expression
  public let positive: Expression
  public let negative: Expression?

  public var range: SourceRange {
    condition.range
  }

  public init(condition: Expression, `true` positive: Expression,
              `false` negative: Expression? = nil) {
    self.condition = condition
    self.positive = positive
    self.negative = negative
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
  public let scope: Expression?

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
              range: SourceRange, scope: Expression) {
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

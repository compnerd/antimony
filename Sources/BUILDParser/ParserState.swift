// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import DequeModule

internal struct ParserState {
  public private(set) var lexer: Lexer
  public private(set) var cursor: SourceFile.Index

  public let source: SourceFile
  public var diagnostics: DiagnosticSet
  public private(set) var expressions: [Expression]

  private var lookahead: Deque<Token> = Deque<Token>()

  public init(lexing source: SourceFile, into expressions: [Expression],
              diagnostics: DiagnosticSet? = nil) {
    self.expressions = expressions
    self.source = source
    self.cursor = source.text.startIndex
    self.lexer = Lexer(tokenizing: source)
    self.diagnostics = diagnostics ?? DiagnosticSet()
  }

  public var location: SourceLocation {
    source.location(cursor)
  }

  public mutating func peek() -> Token? {
    if let token = lookahead.first { return token }
    guard let token = lexer.next() else { return nil }
    lookahead.append(token)
    return token
  }

  public mutating func peek(_ n: Int) -> Deque<Token>.SubSequence {
    while lookahead.count < n {
      guard let token = lexer.next() else { break }
      lookahead.append(token)
    }
    return lookahead.prefix(upTo: min(n, lookahead.count))
  }

  public mutating func take() -> Token? {
    guard let token = lookahead.popFirst() ?? lexer.next() else {
      return nil
    }
    cursor = token.range.end
    return token
  }

  public mutating func take(_ kind: Token.Kind) -> Token? {
    guard peek()?.kind == kind else { return nil }
    return take()
  }

  public mutating func take(_ kinds: Token.Kind...) -> [Token]? {
    let tokens = peek(kinds.count)
    guard tokens.elementsEqual(kinds, by: { $0.kind == $1 }) else {
      return nil
    }
    lookahead.removeFirst(kinds.count)
    cursor = tokens.last!.range.end
    return Array(tokens)
  }

  public mutating func expect<ResultType>(_ token: Token.Kind,
                                          _ parse: (inout ParserState) throws -> ResultType?)
      throws -> ResultType {
    if let element = try parse(&self) { return element }
    diagnostics.insert(.error(expected: token, at: location))
    throw diagnostics
  }

  public mutating func product<E: Expression>(_ expression: E) {
    expressions.append(expression)
  }
}

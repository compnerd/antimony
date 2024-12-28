// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import BUILDParser
import XCTest

extension SourceFile {
  internal func text(for token: Token) -> Substring? {
    if token.kind == .invalid { return nil }
    return text[token.range.start ..< token.range.end]
  }
}

final class LexerTests: XCTestCase {
  func testEmpty() {
    let source: SourceFile = SourceFile(buffer: "")
    let lexer = Lexer(tokenizing: source)
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 0)
    XCTAssertEqual(tokens, [])
  }

  func testWhitespace() {
    let source: SourceFile = SourceFile(buffer: "  \r \n \r\n")
    let lexer = Lexer(tokenizing: source)
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 0)
    XCTAssertEqual(tokens, [])
  }

  func testIdentifier() throws {
    let source: SourceFile = SourceFile(buffer: "  identifier ")
    let lexer = Lexer(tokenizing: source)
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 1)
    XCTAssertEqual(tokens.map(\.kind), [.identifier])
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[0])), "identifier")
  }

  func testInteger() throws {
    let source: SourceFile = SourceFile(buffer: "  123 -456 ")
    let lexer = Lexer(tokenizing: SourceFile(buffer: "  123 -456 "))
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 2)
    XCTAssertEqual(tokens.map(\.kind), [.literal(.integer), .literal(.integer)])
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[0])), "123")
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[1])), "-456")
  }

  func testIntegerNoSpace() throws {
    let source: SourceFile = SourceFile(buffer: "  123-456 ")
    let lexer = Lexer(tokenizing: source)
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 2)
    XCTAssertEqual(tokens.map(\.kind), [.literal(.integer), .literal(.integer)])
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[0])), "123")
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[1])), "-456")
  }

  func testStrings() throws {
    let source: SourceFile =
        SourceFile(buffer: "  \"alpha\" \"beta\\\"gamma\" \"delta\\\\\" ")
    let lexer = Lexer(tokenizing: source)
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 3)
    XCTAssertEqual(tokens.map(\.kind), [
        .literal(.string), .literal(.string), .literal(.string)
    ])
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[0])), "alpha")
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[1])), "beta\\\"gamma")
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[2])), "delta\\\\")
  }

  func testOperators() {
    let source: SourceFile =
        SourceFile(buffer: "- + = += -= != ==  < > <= >= ! || && . ,")
    let lexer = Lexer(tokenizing: source)
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 16)
    XCTAssertEqual(tokens.map(\.kind), [
        .minus, .plus, .equal, .plus_equal, .minus_equal, .bang_equal,
        .equal_equal, .less, .greater, .less_equal, .greater_equal, .bang,
        .pipe_pipe, .ampersand_ampersand, .dot, .comma
    ])
  }

  func testScoping() {
    let source: SourceFile = SourceFile(buffer: "{[ ]} ()")
    let lexer = Lexer(tokenizing: source)
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 6)
    XCTAssertEqual(tokens.map(\.kind), [
        .lbrace, .lbracket, .rbracket, .rbrace, .lparen, .rparen
    ])
  }

  func testFunctionCall() {
    let source: SourceFile = SourceFile(buffer: """
    fun(\"variable\") {
      variable = 32
    }
    """)
    let lexer = Lexer(tokenizing: source)
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 9)
    XCTAssertEqual(tokens.map(\.kind), [
        .identifier, .lparen, .literal(.string), .rparen, .lbrace, .identifier,
        .equal, .literal(.integer), .rbrace
    ])
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[0])), "fun")
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[2])), "variable")
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[5])), "variable")
    try XCTAssertEqual(XCTUnwrap(source.text(for: tokens[7])), "32")
  }

  func testLocations() {
    let source: SourceFile = SourceFile(buffer: """
    1 2 \"three\"
      4
    """)
    let lexer = Lexer(tokenizing: source)
    let tokens = lexer.reduce(into: []) { $0.append($1) }
    XCTAssertEqual(tokens.count, 4)
    XCTAssertEqual(tokens.map(\.kind), [
        .literal(.integer), .literal(.integer), .literal(.string),
        .literal(.integer)
    ])
    XCTAssertEqual(source.location(tokens[0].range.start),
                   SourceLocation(line: 1, column: 1, in: source))
    XCTAssertEqual(source.location(tokens[1].range.start),
                   SourceLocation(line: 1, column: 3, in: source))
    XCTAssertEqual(source.location(tokens[2].range.start),
                   SourceLocation(line: 1, column: 6, in: source))
    XCTAssertEqual(source.location(tokens[3].range.start),
                   SourceLocation(line: 2, column: 3, in: source))
  }
}

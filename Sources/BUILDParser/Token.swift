// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

public struct Token {
  public enum LiteralType: Equatable {
    case integer
    case string
  }

  public enum CommentType: Equatable {
    case unclassified
    case line
    case suffix
    case block
  }

  public enum Kind: Equatable {
    case invalid

    case comment(CommentType)
    case identifier
    case literal(LiteralType)

    // keywords
    case `else`
    case `false`
    case `if`
    case `true`

    // assignment operators
    case equal
    case plus_equal
    case minus_equal

    // unary operators
    case bang

    // binary operators
    case plus
    case minus
    case less
    case less_equal
    case greater
    case greater_equal
    case equal_equal
    case bang_equal
    case ampersand_ampersand
    case pipe_pipe

    // punctuation
    case lparen
    case rparen
    case lbrace
    case rbrace
    case lbracket
    case rbracket
    case comma
    case dot
  }

  public internal(set) var kind: Kind
  public internal(set) var range: SourceRange
}

extension Token: Equatable {}

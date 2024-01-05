// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

public struct Lexer: Sequence {
  private let source: SourceFile
  private var cursor: SourceFile.Index

  public init(tokenizing source: SourceFile) {
    self.source = source
    self.cursor = source.text.startIndex
  }
}

extension Lexer {
  private func peek() -> Character? {
    if cursor == source.text.endIndex { return nil }
    return source.text[cursor]
  }

  private mutating func take(_ character: Character) -> SourceFile.Index? {
    guard peek() == character else { return nil }
    defer { cursor = source.text.index(after: cursor) }
    return cursor
  }

  private mutating func take(prefix: String) -> SourceFile.Index? {
    if cursor == source.text.endIndex { return nil }
    guard source.text[cursor...].prefix(prefix.count) == prefix else {
      return nil
    }
    defer { cursor = source.text.index(cursor, offsetBy: prefix.count) }
    return cursor
  }

  private mutating func take<S: Sequence>(prefix: S)
      -> SourceFile.Index? where S.Element == Character {
    var end = cursor
    for char in prefix {
      if end == source.text.endIndex { return nil }
      guard source.text[end] == char else { return nil }
      end = source.text.index(after: end)
    }
    defer { cursor = end }
    return cursor
  }

  private mutating func take(_ character: Character) -> Bool {
    return take(character) == nil ? false : true
  }

  private mutating func take<S: Sequence>(prefix: S)
      -> Bool where S.Element == Character {
    return take(prefix: prefix) == nil ? false : true
  }

  private mutating func take(while predicate: (Character) -> Bool)
      -> Substring {
    let start = cursor
    while let char = peek(), predicate(char) {
      cursor = source.text.index(after: cursor)
    }
    return source.text[start ..< cursor]
  }
}

extension Character {
  fileprivate var isASCIIDigit: Bool {
    guard let ascii = asciiValue else { return false }
    return (0x30 ... 0x39) ~= ascii
  }

  fileprivate var isUnderscore: Bool {
    guard let ascii = asciiValue else { return false }
    return ascii == 0x5f
  }
}

extension Lexer: IteratorProtocol {
  public typealias Element = Token

  private var location: SourceLocation {
    source.location(cursor)
  }

  private mutating func scan(literal: Token.LiteralType) -> Token {
    switch literal {
    case .integer:
      let end = source.text[source.text.index(after: cursor)...].firstIndex(where: {
        return !$0.isASCIIDigit
      }) ?? source.text.endIndex

      defer {
        cursor = end == source.text.endIndex
                    ? source.text.endIndex
                    : source.text.index(after: end)
      }
      return Token(kind: .literal(.integer),
                   range: location ..< source.location(end))

    case .string:
      precondition(peek() == "\"")
      cursor = source.text.index(after: cursor)

      let start = source.location(cursor)
    
      var escape = false
      while cursor < source.text.endIndex {
        if !escape, take("\"") {
          break
        } else if take("\\") {
          escape.toggle()
        } else {
          cursor = source.text.index(after: cursor)
          escape = false
        }
      }

      let end = source.location(source.text.index(before: cursor))

      return Token(kind: .literal(.string), range: start ..< end)
    }
  }

  public mutating func next() -> Token? {
    if cursor == source.text.endIndex { return nil }

    // Skip whitespace
    // FIXME(compnerd) ht (0x09), vt (0x0b), and formfeed (0x0c) are invalid
    if source.text[cursor].isWhitespace {
      cursor = source.text[cursor...].firstIndex(where: {
        return !$0.isWhitespace
      }) ?? source.text.endIndex
    }
    if cursor == source.text.endIndex { return nil }

    // Process line comments.
    if source.text[cursor] == "#" {
      let end = source.text[cursor...].firstIndex(where: {
        return $0.isNewline
      }) ?? source.text.endIndex

      defer {
        cursor = end == source.text.endIndex
                    ? source.text.endIndex
                    : source.text.index(after: end)
      }
      return Token(kind: .comment(.unclassified),
                   range: location ..< source.location(end))
    }

    // TODO(compnerd) handle block comments

    // Scan a new token.
    let head = source.text[cursor]
    var token: Token = Token(kind: .invalid, range: location ..< location)

    // Scan names and keywords.
    if head.isLetter {
      let identifier =
          take(while: { $0.isLetter || $0.isASCIIDigit || $0.isUnderscore })
      token.range.extend(upto: cursor)

      token.kind = switch identifier {
      case "else": .else
      case "false": .false
      case "if": .if  
      case "true": .true
      default: .identifier
      }
      return token
    }

    // Scan integer literals.
    if head.isASCIIDigit ||
        (head == "-" &&
         source.text[source.text.index(after: cursor)].isASCIIDigit) {
      return scan(literal: .integer)
    }

    // Scan string literals.
    if head == "\"" {
      return scan(literal: .string)
    }

    // Scan punctuation.
    switch head {
    case "+":
      if take(prefix: "+=") {
        token.kind = .plus_equal
      } else {
        token.kind = .plus
        cursor = source.text.index(after: cursor)
      }
    case "-":
      if take(prefix: "-=") {
        token.kind = .minus_equal
      } else {
        token.kind = .minus
        cursor = source.text.index(after: cursor)
      }
    case "!":
      token.kind = .bang
    case "=":
      if take(prefix: "==") {
        token.kind = .equal_equal
      } else {
        token.kind = .equal
        cursor = source.text.index(after: cursor)
      }
    case "<":
      if take(prefix: "<=") {
        token.kind = .less_equal
      } else {
        token.kind = .less
        cursor = source.text.index(after: cursor)
      }
    case ">":
      if take(prefix: ">=") {
        token.kind = .greater_equal
      } else {
        token.kind = .greater
        cursor = source.text.index(after: cursor)
      }
    case ".":
      token.kind = .dot
      cursor = source.text.index(after: cursor)
    case ",":
      token.kind = .comma
      cursor = source.text.index(after: cursor)
    case "(":
      token.kind = .lparen
      cursor = source.text.index(after: cursor)
    case ")":
      token.kind = .rparen
      cursor = source.text.index(after: cursor)
    case "[":
      token.kind = .lbracket
      cursor = source.text.index(after: cursor)
    case "]":
      token.kind = .rbracket
      cursor = source.text.index(after: cursor)
    case "&":
      if take(prefix: "&&") {
        token.kind = .ampersand_ampersand
      }
    case "|":
      if take(prefix: "||") {
        token.kind = .pipe_pipe
      }
    case "{":
      token.kind = .lbrace
      cursor = source.text.index(after: cursor)
    case "}":
      token.kind = .rbrace
      cursor = source.text.index(after: cursor)
    default:
      break // invalid token
    }

    token.range.extend(upto: cursor)
    return token
  }
}

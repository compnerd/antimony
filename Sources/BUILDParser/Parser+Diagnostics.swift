// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

extension Diagnostic {
  static func error(expected kind: Token.Kind, at location: SourceLocation)
      -> Diagnostic {
    error("expected '\(kind)'", range: location ..< location)
  }

  static func error(unexpected token: Token, at location: SourceLocation)
      -> Diagnostic {
    error("unxpected '\(token.range.file.text[token.range.start ..< token.range.end])'",
          range: location ..< location)
  }
}

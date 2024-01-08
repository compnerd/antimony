// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import BUILDParser

/// A user-defined build rule template.
internal final class Template {
  private let scope: Scope
  private let closure:FunctionCallExpression

  internal init(_ closure: FunctionCallExpression, in scope: Scope) {
    self.closure = closure
    self.scope = scope
  }

  internal func invoke(_ function: FunctionCallExpression, arguments: [Value],
                       scope block: Statement?, in scope: inout Scope)
      throws -> Value {
    .void
  }
}

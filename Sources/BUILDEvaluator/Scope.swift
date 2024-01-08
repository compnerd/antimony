// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

/// Defines a variable scope.
///
/// A scope contains the variable, configuration, and build definitions for a
/// given lexical scope within the evaluation of the antimony script.
package final class Scope {
  public private(set) var parent: Scope?

  /// Indicates if an `import` is being processed.
  public var importing: Bool = false
  /// Indicates if the build configuration is being processed.
  public var configuring: Bool = false

  /// Values which are defined in the current scope.
  public var values: [String:(value: Value, used: Bool)] = [:]

  /// Create a root scope.
  public init() {
    self.parent = nil
    for variable in Variables.allCases {
      if let value = variable.default {
        self.values[variable.rawValue] = (value: value, used: true)
      }
    }
  }

  /// Create a child scope.
  public init(parent scope: inout Scope) {
    self.parent = scope
  }

  /// Lookup a template by its name.
  internal func template(named name: String) -> Template? {
    nil
  }
}

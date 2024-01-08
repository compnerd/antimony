// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import struct Foundation.URL

/// Defines a variable scope.
///
/// A scope contains the variable, configuration, and build definitions for a
/// given lexical scope within the evaluation of the antimony script.
public final class Scope {
  public private(set) var parent: Scope?
  public private(set) var directory: URL

  /// Indicates if an `import` is being processed.
  public var importing: Bool = false
  /// Indicates if the build configuration is being processed.
  public var configuring: Bool = false

  /// Values which are defined in the current scope.
  private var values: [String:any Value] = [:]

  public var collector: TargetCollector

  /// Create a root scope.
  public init(_ root: URL) {
    self.parent = nil
    self.directory = root
    self.values = Dictionary<String, any Value>(uniqueKeysWithValues: Variable.allCases.compactMap {
      guard let value = $0.default else { return nil }
      return ($0.rawValue, value)
    })
    self.collector = []
  }

  /// Create a child scope.
  public init(parent scope: inout Scope, directory: URL) {
    self.parent = scope
    self.directory = directory
    self.collector = scope.collector
  }

  /// Lookup a template by its name.
  internal func template(named name: String) -> Template? {
    fatalError("\(#function) unimplemented")
  }

  internal subscript (_ identifier: Variable) -> (any Value)? {
    get { self[identifier.rawValue] }
    set { self[identifier.rawValue] = newValue }
  }

  package subscript (_ identifier: String) -> (any Value)? {
    get { self.values[identifier] ?? self.parent?[identifier] }
    set { self.values[identifier] = newValue }
  }
}

extension Scope: Equatable {
  public static func == (_ lhs: Scope, _ rhs: Scope) -> Bool {
    fatalError("\(#function) unimplemented")
  }
}

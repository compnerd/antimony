// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import BUILDParser

/// A value within the BUILD evalutor.
///
/// Holds a value (or the conceptual `nil` value - the unit type of `void`).
package struct Value {
  enum Storage {
    /// No valid (unit type)
    case void
    /// A boolean value
    case boolean(Bool)
    /// An integer value
    case integer(Int64)
    /// A string value
    case string(String)
    /// A list.
    case list([Value])
    /// A scope.
    case scope(Scope)
  }

  var storage: Storage

  // TODO(compnerd) define a builtin origin

  /// The location where the variable is defined.
  ///
  /// The `origin` may be `nil` for builtin variables.
  var origin: SourceLocation?

  internal static var void: Value {
    Value(storage: .void, origin: nil)
  }

  internal static func boolean(_ value: Bool,
                               origin: SourceLocation?) -> Value {
    Value(storage: .boolean(value), origin: origin)
  }

  internal static func integer(_ value: Int64,
                               origin: SourceLocation?) -> Value {
    Value(storage: .integer(value), origin: origin)
  }

  internal static func string(_ value: String,
                              origin: SourceLocation?) -> Value {
    Value(storage: .string(value), origin: origin)
  }

  internal static func list(_ value: [Value],
                            origin: SourceLocation?) -> Value {
    Value(storage: .list(value), origin: origin)
  }
}

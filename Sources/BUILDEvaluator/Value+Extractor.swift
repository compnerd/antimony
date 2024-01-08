// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

extension Value {
  internal var boolean: Bool? {
    guard let value = self as? BooleanValue else { return nil }
    return value.data
  }

  internal var integer: Int64? {
    guard let value = self as? IntegerValue else { return nil }
    return value.data
  }

  internal var list: [any Value]? {
    guard let value = self as? ListValue else { return nil }
    return value.data
  }

  internal var string: String? {
    guard let value = self as? StringValue else { return nil }
    return value.data
  }
}

extension Array where Element == String {
  internal init?(_ value: any Value) {
    guard let list = value.list else { return nil }
    self = list.compactMap { $0.string }
  }
}

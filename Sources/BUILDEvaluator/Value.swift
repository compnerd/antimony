// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import BUILDParser

public protocol Value {
  associatedtype ValueType
  var data: ValueType { get }
}

public struct NilValue: Value {
  public typealias ValueType = Void
  public let data: ValueType = ()
}

public struct BooleanValue: Value {
  public typealias ValueType = Bool
  public internal(set) var data: ValueType
  public init(_ data: ValueType) {
    self.data = data
  }
}

public struct IntegerValue: Value {
  public typealias ValueType = Int64
  public internal(set) var data: ValueType
  public init(_ data: ValueType) {
    self.data = data
  }
}

public struct StringValue: Value {
  public typealias ValueType = String
  public internal(set) var data: ValueType
  public init(_ data: ValueType) {
    self.data = data
  }
}

public struct ListValue: Value {
  public typealias ValueType = Array<any Value>
  public internal(set) var data: ValueType
  public init(_ data: ValueType) {
    self.data = data
  }
}

public struct ScopeValue: Value {
  public typealias ValueType = Scope
  public internal(set) var data: Scope
  public init(_ data: ValueType) {
    self.data = data
  }
}

public func == (_ lhs: any Value, _ rhs: any Value) -> Bool {
  return switch (lhs, rhs) {
  case let (lhs as BooleanValue, rhs as BooleanValue):
    lhs.data == rhs.data
  case let (lhs as IntegerValue, rhs as IntegerValue):
    lhs.data == rhs.data
  case let (lhs as StringValue, rhs as StringValue):
    lhs.data == rhs.data
  case let (lhs as ListValue, rhs as ListValue):
    !zip(lhs.data, rhs.data).lazy.map { $0.0 == $0.1 }.contains(false)
  case let (lhs as ScopeValue, rhs as ScopeValue):
    lhs.data == rhs.data
  default: false
  }
}

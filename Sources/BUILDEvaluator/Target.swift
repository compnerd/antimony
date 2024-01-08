// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import struct Foundation.URL

public protocol Target {
  var label: Label { get }
  var dependencies: (private: [String], public: [String]) { get }
}

// MARK:- Group

public struct GroupTarget: Target {
  public var label: Label
  public var dependencies: (private: [String], public: [String])
}

extension GroupTarget {
  internal static func reify(in scope: Scope) throws -> Self {
    guard let name = scope[.target_name]?.string else {
      throw ExecutionError("'target_name' is not of type 'string'", at: nil)
    }
    guard let deps = Array<String>(scope[.deps] ?? ListValue([])) else {
      fatalError("'deps' is not of type '[string]'")
    }
    return GroupTarget(label: Label(directory: scope.directory, name: name),
                       dependencies: (private: deps, public: []))
  }
}

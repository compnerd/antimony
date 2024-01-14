// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import SwiftDriver
internal import TSCBasic

extension Array where Element == TypedVirtualPath {
  internal func paths(objdir: RelativePath, excluding: Set<String> = []) -> [String] {
    self.map {
        if excluding.contains($0.file.description) { return $0.file.description }
        return objdir.appending(component: $0.file.description).pathString
    }
  }

  internal func paths() -> [String] {
    self.map(\.file.description)
  }
}

extension Job {
  internal var name: String {
    switch kind {
    case .compile:
      guard let input = displayInputs.first?.file.basename else {
        return "COMPILE_\(moduleName)"
      }
      return "COMPILE_\(moduleName)_\(input)"

    case .link:
      return "LINK_\(moduleName)"

    case .emitModule:
      return "EMIT_MODULE_\(moduleName)"

    case .mergeModule:
      return "MERGE_MODULE_\(moduleName)"

    default: fatalError("do not know how to handle job type '\(kind)'")
    }
  }
}

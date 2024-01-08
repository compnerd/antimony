// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import struct Foundation.URL

public struct Label {
  public let directory: URL
  public let name: String
}

extension Label: Comparable {
  public static func < (_ lhs: Self, _ rhs: Self) -> Bool {
    if lhs.directory == rhs.directory {
      return lhs.name < rhs.name
    }
    return lhs.directory.path < rhs.directory.path
  }
}

extension Label: Equatable {
  public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
    lhs.directory == rhs.directory && lhs.name == rhs.name
  }
}

extension Label: Hashable {}

extension Label {
  public static func resolve(_ label: String, root: URL) -> Label {
    let components: (Substring, Substring) =
        if let index = label.lastIndex(of: ":") {
          (label[..<index], label[label.index(after: index)...])
        } else if let index = label.lastIndex(of: "/") {
          (label[...], label[label.index(after: index)...])
        } else {
          (label[...], label[...])
        }
    let directory: URL =
        components.0.starts(with: "//")
            ? URL(fileURLWithPath: String(components.0.dropFirst(2)),
                  isDirectory: true, relativeTo: root)
            : URL(fileURLWithPath: String(components.0), isDirectory: true)
    return Label(directory: directory, name: String(components.1))
  }
}

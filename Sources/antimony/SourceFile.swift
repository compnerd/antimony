// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import struct Foundation.URL

extension SourceFile {
  public enum SourceType {
    case unknown
    case assembly
    case c
    case cplusplus
    case modulemap
    case swift
    case swiftmodule
  }
}

extension SourceFile.SourceType: CaseIterable {}

public class SourceFile {
  let url: URL

  public init(_ url: URL) {
    precondition(url.isFileURL)
    self.url = url
  }

  public var path: String {
    self.url.withUnsafeFileSystemRepresentation { String(cString: $0!) }
  }

  public var type: SourceType {
    return switch url.pathExtension {
    case "s", "S": .assembly
    case "c": .c
    case "cc", "cxx", "cpp": .cplusplus
    case "modulemap": .modulemap
    case "swift": .swift
    case "swiftmodule": .swiftmodule
    default: .unknown
    }
  }
}

extension SourceFile: Equatable {
  public static func == (_ lhs: SourceFile, _ rhs: SourceFile) -> Bool {
    lhs.url == rhs.url
  }
}

extension SourceFile: Hashable {
  public func hash(into hasher: inout Hasher) {
    url.hash(into: &hasher)
  }
}

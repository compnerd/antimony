// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import WinSDK
import struct Foundation.URL

/// A label is a unique identifier for a BUILD entity.
///
/// Everything participating in the build graph is identified by a label.  It is
/// rooted at the workspace root (identified explicitly via `--root` or the
/// precense of the `.sb` file). A label contains multiple parts, some of which
/// may be elided.
///
/// A workspace may contain multiple repositories. The canonical name of the
/// repository is identified by the `@@` sigil while the apparent name uses the
/// `@` sigil. A canonical repository name is a unique name within the context
/// of the workspace. The main repository uses the empty string as the canonical
/// repository name. The apparent repository name is used to identify the
/// repository in the context of a specific repository within the workspace. The
/// repository name must be limited to the alphanumeric and the `+`, `-`, or `_`
/// symbols.
///
/// The label references the root of the repository using the `//` sigil
/// (inspired by the POSIX alternate root specification). When the label is
/// referencing the same repository, the repository name may be elided. The
/// component following the `//` sigil is the relative path within the
/// repository. An absolute path may be used in place of the root relative path.
///
/// A `:` separates the repository path from the label identifier. The label may
/// be elided, in which case it inherits the name of the directory. The label is
/// required to unique within the directory. The label name is limited to the
/// alphanumeric characters, `+`, `-`, and `_` symbols.
///
/// A subsequent label is encoded in `(` and `)` and is used to identify a
/// toolchain which is used to build the target.
///
/// Examples:
///   - `:antimony`
///   - `//antimony`
///   - `//antimony:antimony`
///   - `//antimony:antimony(//build/toolchain/windows:swift)`
///   - `S:\SourceCache\compnerd\antimony\antimony:antimony(S:\SourceCache\compnerd\build\toolchain\windows:swift)`
///   - `@antimony//antimony:antimony(@antimony//build/toolchain/windows:swift)`
///   - `@@antimony//antimony:antimony(@@antimony//build/toolchain/windows:swift)`
///
public struct Label {
  public let directory: URL
  public let name: String

  public init() {
    self.directory = URL(fileURLWithPath: "")
    self.name = ""
  }

  public init(_ directory: URL, _ name: String) {
    self.directory = directory
    self.name = name
  }

  public init(resolving label: String, in directory: URL) throws {
    guard let components = label.firstIndex(of: ":").map({
        (label[..<$0], label[label.index($0, offsetBy: 1)...])
    }) else {
      throw AntimonyError()
    }
    self.directory = URL(fileURLWithPath: String(components.0))
    self.name = String(components.1)
  }

  public var isNull: Bool {
    directory.path.isEmpty
  }
}

extension Label: Comparable {
  public static func < (_ lhs: Self, _ rhs: Self) -> Bool {
    if lhs.directory == rhs.directory {
      return lhs.name < rhs.name
    }
    return lhs.directory.path < rhs.directory.path
  }
}

extension Label: CustomStringConvertible {
  public var description: String {
    if isNull { return "" }
    if directory.relativePath == "." { return ":\(name)" }
    return "//\(directory.relativePath):\(name)"
  }
}

extension Label: Equatable {
  public static func == (_ lhs: Self, _ rhs: Self) -> Bool {
    lhs.directory == rhs.directory && lhs.name == rhs.name
  }
}

extension Label: Hashable {
  public func hash(into hasher: Hasher) {
    // TODO(compnerd) implement hashing
  }
}

// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

public struct SourceLocation {
  public let file: SourceFile
  public let index: SourceFile.Index

  public init(_ index: SourceFile.Index, in file: SourceFile) {
    self.file = file
    self.index = index
  }

  public init(line: Int, column: Int, in file: SourceFile) {
    self.file = file
    self.index = file.index(line: line, column: column)
  }
}

extension SourceLocation {
  public static func ..< (_ lhs: Self, _ rhs: Self) -> SourceRange {
    precondition(lhs.file == rhs.file, "incompatible locations")
    return lhs.file.range(lhs.index ..< rhs.index)
  }
}

extension SourceLocation: CustomStringConvertible {
  internal var position: (line: Int, column: Int) {
    return file.position(index)
  }

  public var description: String {
    let (line, column) = position
    return "\(file.url.fileSystemPath):\(line):\(column)"
  }
}

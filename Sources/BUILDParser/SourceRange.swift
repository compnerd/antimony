// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

public struct SourceRange {
  private let indicies: Range<SourceFile.Index>

  public let file: SourceFile
  public var start: SourceFile.Index { indicies.lowerBound }
  public var end: SourceFile.Index { indicies.upperBound }

  public init(_ indicies: Range<SourceFile.Index>, in file: SourceFile) {
    self.file = file
    self.indicies = indicies
  }

  public func extended(upto position: SourceFile.Index) -> SourceRange {
    precondition(position >= end)
    return file.range(start ..< position)
  }

  public mutating func extend(upto position: SourceFile.Index) {
    self = self.extended(upto: position)
  }
}
extension SourceRange: CustomStringConvertible {
  public var description: String {
    let start = file.location(self.start).position
    let head = "\(file.url.fileSystemPath):\(start.line):\(start.column)"
    if self.start == self.end { return head }

    let end = file.location(self.end).position
    if end.line == start.line { return "\(head)-\(end.column)" }
    return "\(head)-\(end.line):\(end.column)"
  }
}

extension SourceRange: Equatable {}

extension SourceRange: Hashable {}

// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import struct Foundation.URL
import struct Foundation.UUID

public final class SourceFile {
  public typealias Index = Substring.Index

  public let url: URL
  public let text: Substring
  private let lines: [Index]

  public init(contentsOf filePath: URL) throws {
    self.url = filePath
    self.text = try String(contentsOf: filePath)[...]
    self.lines = self.text.lines()
  }

  public init(buffer text: String, name: String = UUID().uuidString) {
    self.url = URL(string: "scratch://\(name)")!
    self.text = text[...]
    self.lines = self.text.lines()
  }

  internal func position(_ index: Index) -> (line: Int, column: Int) {
    let line = lines.partitioning(by: { $0 > index })
    let column = text.distance(from: lines[line - 1], to: index) + 1
    return (line, column)
  }

  public func index(line: Int, column: Int) -> Index {
    return text.index(lines[line - 1], offsetBy: column - 1)
  }

  public func location(_ index: Index) -> SourceLocation {
    SourceLocation(index, in: self)
  }

  public func range(_ range: Range<Index>) -> SourceRange {
    SourceRange(range, in: self)
  }
}

extension SourceFile: CustomStringConvertible {
  public var description: String {
    "SourceFile(\(url))"
  }
}

extension SourceFile: Equatable {
  public static func == (_ lhs: SourceFile, _ rhs: SourceFile) -> Bool {
    return lhs === rhs
  }
}

extension SourceFile: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

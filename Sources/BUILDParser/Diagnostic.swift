// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

public struct Diagnostic {
  public enum Level {
    case note
    case warning
    case error
  }

  public let level: Level
  public let message: String
  public let range: SourceRange
  public let notes: [Diagnostic]

  public var file: SourceFile { range.file }

  public init(level: Level, message: String, range: SourceRange,
              notes: [Diagnostic] = []) {
    precondition(notes.allSatisfy { $0.level == .note }, file: #filePath)
    self.level = level
    self.message = message
    self.range = range
    self.notes = notes
  }
}

extension Diagnostic {
  public static func note(_ message: String, range: SourceRange) -> Diagnostic {
    Diagnostic(level: .note, message: message, range: range)
  }

  public static func warning(_ message: String, range: SourceRange,
                             notes: [Diagnostic] = []) -> Diagnostic {
    Diagnostic(level: .warning, message: message, range: range, notes: notes)
  }

  public static func error(_ message: String, range: SourceRange,
                           notes: [Diagnostic] = []) -> Diagnostic {
    Diagnostic(level: .error, message: message, range: range, notes: notes)
  }
}

extension Diagnostic.Level: Hashable {}

extension Diagnostic: CustomStringConvertible {
  public var description: String {
    let start = file.location(range.start).position
    return "\(file.url.fileSystemPath):\(start.line):\(start.column): \(level): \(message)"
  }
}

extension Diagnostic: Comparable {
  public static func < (_ lhs: Diagnostic, _ rhs: Diagnostic) -> Bool {
    if lhs.file == rhs.file {
      return lhs.range.start < rhs.range.start
    }
    let lhs = lhs.file.url.fileSystemPath, rhs = rhs.file.url.fileSystemPath
    return lhs.lexicographicallyPrecedes(rhs)
  }
}

extension Diagnostic: Hashable {}

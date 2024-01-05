// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

public struct DiagnosticSet {
  public private(set) var elements: Set<Diagnostic> = []
  public private(set) var errors: Bool = false

  public var empty: Bool { elements.isEmpty }

  @discardableResult
  public mutating func insert(_ diagnostic: Diagnostic) -> Bool {
    errors = errors || diagnostic.level == .error
    return elements.insert(diagnostic).inserted
  }
}

extension DiagnosticSet: CustomStringConvertible {
  public var description: String {
    elements.sorted()
            .map { String(describing: $0) }
            .joined(separator: "\n")
  }
}

extension DiagnosticSet: Error {}

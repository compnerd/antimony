// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import BUILDParser

public struct ExecutionError {
  private let message: String
  private let location: SourceRange?

  internal init(_ message: String, at location: SourceRange?) {
    self.message = message
    self.location = location
  }
}

extension ExecutionError: Error {
}

extension ExecutionError: CustomStringConvertible {
  public var description: String {
    "\(location?.description ?? "<unknown>"): \(message)"
  }
}

// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import BUILDParser

extension SourceRange {
  internal var location: SourceLocation {
    SourceLocation(start, in: file)
  }
}

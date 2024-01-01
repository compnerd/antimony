// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser
import struct Foundation.URL

internal struct FileURL: ExpressibleByArgument {
  public let url: URL

  public init?(argument: String) {
    self.url = URL(fileURLWithPath: argument)
  }
}

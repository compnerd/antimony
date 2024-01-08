// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import struct Foundation.URL

extension URL {
  internal var fileSystemPath: String {
    self.standardizedFileURL.withUnsafeFileSystemRepresentation {
      String(cString: $0!)
    }
  }
}

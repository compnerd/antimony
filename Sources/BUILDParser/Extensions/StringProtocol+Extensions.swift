// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

extension StringProtocol {
  internal func lines() -> [Index] {
    var anchors = [startIndex]
    var tail = self[...]
    while !tail.isEmpty, let position = tail.firstIndex(where: \.isNewline) {
      let anchor = index(after: position)
      anchors.append(anchor)
      tail = tail[anchor...]
    }
    return anchors
  }
}

// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

extension Collection {
  internal func partitioning(by predicate: (Element) throws -> Bool) rethrows
       -> Index {
    var elements = distance(from: startIndex, to: endIndex)
    var position = startIndex
    while elements > 0 {
      let half = elements / 2
      let midpoint = index(position, offsetBy: half)
      if try predicate(self[midpoint]) {
        elements = half
      } else {
        position = index(after: midpoint)
        elements -= half + 1
      }
    }
    return position
  }
}

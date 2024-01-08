// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

public final class TargetCollector {
  public private(set) var targets: Array<any Target> = []

  public func append<T: Target>(_ target: T) {
    targets.append(target)
  }
}

extension TargetCollector: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = Target

  public convenience init(arrayLiteral elements: any ArrayLiteralElement...) {
    self.init()
    self.targets = elements
  }
}

extension TargetCollector: Sequence {
  public typealias Iterator = Array<Target>.Iterator

  public __consuming func makeIterator() -> Iterator {
    targets.makeIterator()
  }
}

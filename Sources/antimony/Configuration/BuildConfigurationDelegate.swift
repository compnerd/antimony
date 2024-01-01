// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

public protocol BuildConfigurationDelegate: AnyObject {
  func resolved(label: Label, to target: Target)
  func lookup(_ label: Label) -> Target?
}

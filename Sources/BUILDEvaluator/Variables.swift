// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

/// A convenience enumeration of well-defined variables.
internal enum Variables: String {
  /// The version of antimony
  case antimony_version
  /// The CPU we are building on
  case build_cpu
  /// The OS we are building on
  case build_os
  /// The CPU we are building for
  case host_cpu
  /// The OS we are building for
  case host_os
  /// THe CPU that binaries from the host binaries will run on
  case target_cpu
  /// The OS that binaries from the host binaries will run on
  case target_os
}

extension Variables: CaseIterable {}

extension Variables {
  internal var `default`: Value? {
    return switch self {
    case .antimony_version:
      .string("00000000", origin: nil)
    case .build_cpu, .host_cpu, .target_cpu:
#if arch(arm64)
      .string("arm64", origin: nil)
#elseif arch(x86_64)
      .string("x86_64", origin: nil)
#endif
    case .build_os, .host_os, .target_os:
#if os(Linux)
      .string("linux", origin: nil)
#elseif os(macOS)
      .string("macos", origin: nil)
#elseif os(Windows)
      .string("windows", origin: nil)
#endif
    }
  }
}

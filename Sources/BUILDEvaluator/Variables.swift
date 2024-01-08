// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

/// A convenience enumeration of well-defined variables.
internal enum Variable: String {
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

  /// Merge any static libraries that this target links against.
  case complete_static_lib
  /// Privately linked dependencies.
  case deps
  /// The name for the compiled module. Defaults to the target name.
  case module_name
  /// The extension to use for the output.
  case output_extension
  /// Defines a name for the output file other than the default.
  case output_name
  /// Indicates to trim the output prefix if any.
  case output_prefix_override
  /// The soures that the target consumes.
  case sources
  /// Flags passed to the swift compiler.
  case swiftflags
  /// The name of the target.
  case target_name

  /// The location of the BUILD.gn file for an external repository.
  case build
  /// The location of the external repository.
  case path
}

extension Variable: CaseIterable {}

extension Variable {
  internal var `default`: (any Value)? {
    return switch self {
    case .antimony_version:
      StringValue("00000000")
    case .build_cpu, .host_cpu, .target_cpu:
#if arch(arm64)
      StringValue("arm64")
#elseif arch(x86_64)
      StringValue("x86_64")
#endif
    case .build_os, .host_os, .target_os:
#if os(Linux)
      StringValue("linux")
#elseif os(macOS)
      StringValue("macos")
#elseif os(Windows)
      StringValue("windows")
#endif
    case .complete_static_lib, .deps, .module_name,
         .output_extension, .output_name, .output_prefix_override,
         .sources, .swiftflags, .target_name:
      nil
    case .build, .path:
      nil
    }
  }
}

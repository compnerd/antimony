// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import struct Foundation.URL

public protocol Module: Target {
  var sources: [String] { get }
  var output_name: String { get }
  var output_extension: String { get }
}

public struct StaticLibraryTarget: Module {
  public var label: Label

  public let module_name: String
  public let swiftflags: [String]

  public let sources: [String]
  public let dependencies: (private: [String], public: [String])

  public let complete_static_lib: Bool = false
  public let output_prefix_override: Bool = false

  public let output_name: String
  public let output_extension: String
}

public struct DynamicLibraryTarget: Module {
  public var label: Label

  public let module_name: String
  public let swiftflags: [String]

  public let sources: [String]
  public let dependencies: (private: [String], public: [String])

  public let output_prefix_override: Bool = false

  public let output_name: String
  public let output_extension: String
}

public struct ExecutableTarget: Module {
  public let label: Label

  public let module_name: String
  public let swiftflags: [String]

  public let sources: [String]
  public let dependencies: (private: [String], public: [String])

  public let output_name: String
  public let output_extension: String
}

// MARK:- Static Library

extension StaticLibraryTarget {
  internal static func reify(in scope: Scope) throws -> Self {
    guard let name = scope[.target_name]?.string else {
      fatalError("'target_name' is not of type 'string'")
    }
    guard let os = scope[.host_os]?.string else {
      fatalError("'host_os' is not of type 'string'")
    }

    guard let deps = Array<String>(scope[.deps] ?? ListValue([])) else {
      throw ExecutionError("'deps' is not of type '[string]'", at: nil)
    }
    guard let sources = Array<String>(scope[.sources] ?? ListValue([])) else {
      fatalError("'sources' is not of type '[string]'")
    }

    if let module_name = scope[.module_name] {
      guard module_name.string != nil else {
        throw ExecutionError("'module_name' is not of type 'string'", at: nil)
      }
    }

    let `extension`: String =
        scope[.output_extension]?.string ?? os == "windows" ? "lib" : "a"

    return StaticLibraryTarget(label: Label(directory: scope.directory, name: name),
                               module_name: scope[.module_name]?.string ?? name,
                               swiftflags: Array<String>(scope[.swiftflags] ?? ListValue([])) ?? [],
                               sources: sources.map { scope.directory.appendingPathComponent($0, isDirectory: false).fileSystemPath },
                               dependencies: (private: deps, public: []),
                               output_name: scope[.output_name]?.string ?? name,
                               output_extension: `extension`)
  }
}

// MARK:- Dynamic Library

extension DynamicLibraryTarget {
  internal static func reify(in scope: Scope) throws -> Self {
    guard let name = scope[.target_name]?.string else {
      fatalError("'target_name' is not of type 'string'")
    }
    guard let os = scope[.host_os]?.string else {
      fatalError("'host_os' is not of type 'string'")
    }

    guard let deps = Array<String>(scope[.deps] ?? ListValue([])) else {
      throw ExecutionError("'deps' is not of type '[string]'", at: nil)
    }
    guard let sources = Array<String>(scope[.sources] ?? ListValue([])) else {
      fatalError("'sources' is not of type '[string]'")
    }

    if let module_name = scope[.module_name] {
      guard module_name.string != nil else {
        throw ExecutionError("'module_name' is not of type 'string'", at: nil)
      }
    }

    // TODO(compnerd) handle Darwin
    let `extension`: String =
        scope[.output_extension]?.string ?? os == "windows" ? "dll" : "so"

    return DynamicLibraryTarget(label: Label(directory: scope.directory, name: name),
                                module_name: scope[.module_name]?.string ?? name,
                                swiftflags: Array<String>(scope[.swiftflags] ?? ListValue([])) ?? [],
                                sources: sources.map { scope.directory.appendingPathComponent($0, isDirectory: false).fileSystemPath },
                                dependencies: (private: deps, public: []),
                                output_name: scope[.output_name]?.string ?? name,
                                output_extension: `extension`)
  }
}

// MARK:- Executable

extension ExecutableTarget {
  internal static func reify(in scope: Scope) throws -> Self {
    guard let name = scope[.target_name]?.string else {
      fatalError("'target_name' is not of type 'string'")
    }
    guard let os = scope[.host_os]?.string else {
      fatalError("'host_os' is not of type 'string'")
    }

    guard let deps = Array<String>(scope[.deps] ?? ListValue([])) else {
      throw ExecutionError("'deps' is not of type '[string]'", at: nil)
    }
    guard let sources = Array<String>(scope[.sources] ?? ListValue([])) else {
      fatalError("'sources' is not of type '[string]'")
    }

    if let module_name = scope[.module_name] {
      guard module_name.string != nil else {
        throw ExecutionError("'module_name' is not of type 'string'", at: nil)
      }
    }

    let `extension`: String =
        scope[.output_extension]?.string ?? os == "windows" ? "exe" : ""

    return ExecutableTarget(label: Label(directory: scope.directory, name: name),
                            module_name: scope[.module_name]?.string ?? name,
                            swiftflags: Array<String>(scope[.swiftflags] ?? ListValue([])) ?? [],
                            sources: sources,
                            dependencies: (private: deps, public: []),
                            output_name: scope[.output_name]?.string ?? name,
                            output_extension: `extension`)
  }
}

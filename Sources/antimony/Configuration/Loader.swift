// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import class Foundation.JSONDecoder
import struct Foundation.Data
import struct Foundation.URL

public enum Operation {
  case format
  case generate
}

public protocol Loader: AnyObject {
  init(_ delegate: BuildConfigurationDelegate)
  func load(_ file: URL, root url: URL) throws
}

/// Load a placeholder representation of the build configuration.
///
/// The placeholder representation is a JSON representation of the build
/// to ease the parsing.  It is of the following form:
/// ```
/// {
///   "executables" : {
///     "sb": {
///       "directory": "Sources/Tools/sb",
///       "sources": ["sb.swift"],
///       "private_dependencies": [
///         "Sources/antimony:antimony",
///         ".build/checkouts/swift-argument-parser/Sources/ArgumentParser:ArgumentParser",
///       ],
///       "swiftflags": ["-parse-as-library"]
///    }
///   },
///   "static_libraries": { ... },
///   "dynamic_libraries" : { ... }
/// }
/// ```
public class LegacyLoader_DO_NOT_USE_OR_YOU_WILL_BE_FIRED: Loader {
  struct BUILD: Codable {
    struct Target: Codable {
      enum CodingKeys: String, CodingKey {
        case directory, sources, defines, libs
        case includes = "include_dirs"
        case privateDependencies = "private_dependencies"
        case publicDependencies = "public_dependencies"
        case swiftFlags = "swiftflags"
      }

      let directory: String
      let sources: [String]
      let defines: [String]?
      let libs: [String]?
      let includes: [String]?
      let privateDependencies: [String]?
      let publicDependencies: [String]?
      let swiftFlags: [String]?
    }

    enum CodingKeys: String, CodingKey {
      case executable = "executables"
      case `static` = "static_libraries"
      case dynamic = "dynamic_libraries"
    }

    let executable: [String:Target]?
    let `static`: [String:Target]?
    let dynamic: [String:Target]?
  }

  public weak var delegate: BuildConfigurationDelegate?

  public required init(_ delegate: BuildConfigurationDelegate) {
    self.delegate = delegate
  }

  public func load(_ file: URL, root: URL) throws {
    let data = try Data(contentsOf: file, options: [.uncached])

    // Deserialise a JSON representation; we currently cannot parse the
    // starlark-esque build definition, so use a JSON serialisation as
    // a placeholder.
    //
    // We expect the following JSON structure:
    // ```
    //  { "executables" : { }, "static_libraries": { }, "dynamic_libraries" : { } }
    // ```
    let build = try JSONDecoder().decode(BUILD.self, from: data)

    let elements: [(KeyPath<BUILD, [String:BUILD.Target]?>, Target.OutputType)] = [
      (\.executable, .executable),
      (\.static, .static),
      (\.dynamic, .dynamic),
    ]

    for element in elements {
      guard let targets = build[keyPath: element.0] else { continue }
      for target in targets {
        let srcdir = URL(fileURLWithPath: target.value.directory,
                         relativeTo: file.deletingLastPathComponent())
        let label = Label(srcdir, target.key)
        let sources = Set<SourceFile>(target.value.sources.compactMap { SourceFile(URL(fileURLWithPath: $0, relativeTo: srcdir)) })

        var dependencies: Target.Dependencies = ([], [], [], [])
        dependencies.private = target.value.privateDependencies?.compactMap { try? Label(resolving: $0, in: root) } ?? []
        dependencies.public = target.value.publicDependencies?.compactMap { try? Label(resolving: $0, in: root) } ?? []

        let target = {
          $0.defines = target.value.defines ?? []
          $0.dependencies = dependencies
          $0.includes = target.value.includes ?? []
          $0.libs = target.value.libs ?? []
          $0.flags.swift = target.value.swiftFlags ?? []
          return $0
        }(Target(label, sources, type: element.1))

        self.delegate?.resolved(label: label, to: target)
      }
    }
  }
}

// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

extension Target {
  public enum OutputType {
    case unknown
    case group      // group
    case executable // executable
    case dynamic    // shared_library
    case module     // loadable_module
    case `static`   // static_library
    case sources    // source_set
    case resource   // copy
    case action     // action
    case iteration  // action_foreach
    case generator  // generated_file
  }
}

extension Target.OutputType: CustomStringConvertible {
  public var description: String {
    switch self {
      case .unknown: "unknown"
      case .group: "group"
      case .executable: "executable"
      case .dynamic: "shared_library"
      case .module: "loadable_module"
      case .static: "static_library"
      case .sources: "source_set"
      case .resource: "copy"
      case .action: "action"
      case .iteration: "action_foreach"
      case .generator: "generated_file"
    }
  }
}

public class Target {
  public typealias Dependencies =
      (data: [Label], generated: [Label], private: [Label], public: [Label])

  public private(set) var label: Label
  public private(set) var sources: Set<SourceFile>

  public var type: OutputType
  public var defines: [String] = []
  public var includes: [String] = []
  public var libs: [String] = []
  public var flags: (c: [String], swift: [String]) = ([], [])

  public var dependencies: Dependencies = ([], [], [], [])

  public init(_ label: Label, _ sources: Set<SourceFile> = [],
              type: OutputType = .unknown) {
    self.label = label
    self.sources = sources
    self.type = type
  }
}

extension Target {
  public var isSwiftTarget: Bool {
    self.sources.lazy.first(where: { $0.type == .swift }) == nil ? false : true
  }

  public var isCTarget: Bool {
    self.sources.lazy.first(where: { $0.type == .c }) == nil ? false : true
  }
}

extension Target: CustomStringConvertible {
  public var description: String {
    let deps = dependencies.public.isEmpty ? "" : """
      deps = [
        \(dependencies.public.map { #""\#($0)""# }.joined(separator: ",\n    ")),
      ]
    """
    let defines = defines.isEmpty ? "" : """
      defines = [
        \(defines.map { #""\#($0)"# }.joined(separator: ",\n    ")),
      ]
    """
    let includes = includes.isEmpty ? "" : """
      include_dirs = [
        \(includes.map { #""\#($0)""# }.joined(separator: ",\n     ")),
      ]
    """
    let sources = sources.isEmpty ? "" : """
      sources = [
        \(sources.map(\.path).map { #""\#($0)""# }.joined(separator: ",\n    ")),
      ]
    """

    return """
    \(type)("\(label.name)") {
    \([sources, defines, includes, deps].filter { !$0.isEmpty }.joined(separator: "\n"))
    }
    """
  }
}

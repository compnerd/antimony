// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import struct Foundation.URL
import SwiftDriver
import TSCBasic

extension Array where Element == String {
  fileprivate func quoted() -> Self {
    map {
      if $0.firstIndex(of: " ") == nil { return $0 }
      return #""\#($0)""#
    }
  }
}

public struct JobEmitter {
  public var writer: NinjaWriter
  public let configuration: BuildConfiguration

  public init(for configuration: BuildConfiguration, into ninja: NinjaWriter) {
    self.writer = ninja
    self.configuration = configuration
  }

  public func emitJobs(for target: Target, flags: [String] = [], at out: URL) throws {
    let objdir = try RelativePath(validating: "\(target.label.name).dir")
    let bindir = try RelativePath(validating: "bin")
    let libdir = try RelativePath(validating: "lib")

    var driver: Driver

    // NOTE: the absolute diretory is required to support emission of file lists
    let resolver: ArgsResolver =
        try ArgsResolver(fileSystem: localFileSystem,
                         temporaryDirectory: .absolute(AbsolutePath(validating: objdir.pathString,
                                                                    relativeTo: AbsolutePath(validating: out.path))))
    let executor: DriverExecutor = NULLExecutor(resolver: resolver)

#if os(Windows)
#if arch(arm64)
    let triple: String = "aarch64-unknown-windows-msvc"
#elseif arch(x86_64)
    let triple: String = "x86_64-unknown-windows-msvc"
#endif
#elseif os(Linux)
#if arch(arm64)
    let triple: String = "aarch64-unknown-linux-gnu"
#elseif arch(x86_64)
    let triple: String = "x86_64-unknown-linux-gnu"
#endif
#elseif os(macOS)
#if arch(arm64)
    let triple: String = "arm64-apple-macosx13.0"
#elseif arch(x86_64)
    let triple: String = "x86_64-apple-macosx13.0"
#endif
#endif

    let module: RelativePath =
        objdir.appending(components: "swift",
                                     "\(target.label.name).swiftmodule",
                                     "\(triple).swiftmodule")
    let output: RelativePath

    let dependencies: [Target] = target.dependencies.public.compactMap(configuration.lookup) + target.dependencies.private.compactMap(configuration.lookup)
    let headerIncludes = target.dependencies.private.compactMap(configuration.lookup).filter(\.isCTarget).map {
      let source = $0.label.directory
      return $0.includes.compactMap { try? AbsolutePath(validating: source.appendingPathComponent($0).path) }
    }.flatMap { $0 }
    let swiftIncludes = dependencies.filter(\.isSwiftTarget).compactMap { try? RelativePath(validating: "\($0.label.name).dir/swift") }
    let libs = dependencies.filter(\.isSwiftTarget).compactMap { libdir.appending(component: "\($0.label.name).lib").pathString }

    let arguments = [
      target.defines.map { "-D\($0)" },
      swiftIncludes.map(\.pathString).map { "-I\($0)" },
      headerIncludes.map(\.pathString).map { "-I\($0)" },
      target.sources.map(\.path),
      target.libs.map { "-l\($0)" },
      libs,
      flags,
      target.isSwiftTarget ? target.flags.swift : []
    ].flatMap { $0 }

    switch target.type {
    case .executable:
      output = bindir.appending(component: "\(target.label.name).exe")
      driver = try Driver(args: [
          "swiftc.exe",
          "-emit-dependencies",
          "-emit-executable",
          "-module-name",
          target.label.name,
          "-o", output.pathString,
      ] + arguments, executor: executor)

    case .static:
      output = libdir.appending(component: "\(target.label.name).lib")
      driver = try Driver(args: [
          "swiftc.exe",
          "-parse-as-library",
          "-static",
          "-emit-dependencies",
          "-emit-library",
          "-emit-module",
          "-emit-module-path",
          module.pathString,
          "-module-name",
          target.label.name,
          "-o", output.pathString,
      ] + arguments, executor: executor)

    case .dynamic:
      output = bindir.appending(component: "\(target.label.name).dll")
      driver = try Driver(args: [
          "swiftc.exe",
          "-parse-as-library",
          "-emit-dependencies",
          "-emit-library",
          "-emit-module",
          "-emit-module-path",
          module.pathString,
          "-module-name",
          target.label.name,
          "-o", output.pathString,
      ] + arguments, executor: executor)

    default:
      fatalError("do not know how to build target type '\(target.type)'")
    }

    let jobs = try driver.planBuild()
    let deps: [String] =
        dependencies.filter(\.isSwiftTarget)
                    .compactMap { "\($0.label.name).dir/swift/\($0.label.name).swiftmodule/\(triple).swiftmodule" }

    for job in jobs {
      let command: String =
          try resolver.resolveArgumentList(for: job)
                      .quoted()
                      .joined(separator: " ")

      switch job.kind {
      case .compile:
        writer.rule(job.name, command: command,
                    description: job.description, restat: true)
        writer.build(job.outputs.paths(objdir: objdir), rule: job.name,
                      inputs: job.inputs.paths(objdir: objdir),
                      implicitInputs: deps)

      case .emitModule:
        writer.rule(job.name, command: command,
                    description: job.description, restat: true)
        writer.build(job.outputs.paths(), rule: job.name,
                      inputs: job.inputs.paths(objdir: objdir),
                      implicitInputs: deps)

      case .link:
        writer.rule(job.name, command: command, description: job.description)
        writer.build(job.outputs.paths(), rule: job.name,
                      inputs: job.inputs.paths(objdir: objdir,
                                              excluding: Set<String>(libs)))

      case .mergeModule:
        writer.rule(job.name, command: command, description: job.description)
        writer.build(job.outputs.paths(), rule: job.name,
                      inputs: job.inputs.paths(objdir: objdir))

      default: fatalError("do not know how to handle job type '\(job.kind)'")
      }
    }

    writer.phony(target.label.name,
                 outputs: jobs.filter { [.link, .emitModule].contains($0.kind) }
                              .map(\.outputs)
                              .flatMap { $0 }
                              .filter {
                                return switch $0.type {
                                case .emitModuleDependencies: false
                                default: true
                                }
                              }
                              .paths())
  }
}

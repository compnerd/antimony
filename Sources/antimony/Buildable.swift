// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import struct Foundation.URL
internal import BUILDEvaluator
internal import SwiftDriver

internal import struct TSCBasic.AbsolutePath
internal import struct TSCBasic.RelativePath
internal import var TSCBasic.localFileSystem
internal import protocol TSCBasic.FileSystem

internal protocol Buildable: Target {
  var invocation: [String] { get throws }
  func emitRules(into writer: NinjaWriter) throws
}

extension Buildable {
  internal func emitRules(into writer: NinjaWriter) throws {
    var driver: Driver = try Driver(args: invocation, executor: executor)
    let jobs: [Job] = try driver.planBuild()

    for job in jobs {
      let command: String = try resolver.resolveArgumentList(for: job)
                                        .quoted()
                                        .joined(separator: " ")
      switch job.kind {
      case .compile:
        // FIXME(compnerd) - should we restat?
        writer.rule(job.name, command: command, description: job.description)
        // FIXME(compnerd) - implict_inputs = dependencies
        try writer.build(job.outputs.paths(objdir: objdir), rule: job.name,
                         inputs: job.inputs.paths(objdir: objdir),
                         implicitInputs: [])

      case .emitModule:
        // FIXME(compnerd) - should we restat?
        writer.rule(job.name, command: command, description: job.description)
        // FIXME(compnerd) - implict_inputs = dependencies
        try writer.build(job.outputs.paths(), rule: job.name,
                         inputs: job.inputs.paths(objdir: objdir),
                         implicitInputs: [])

      case .link:
        // FIXME(compnerd) - should we restat?
        writer.rule(job.name, command: command, description: job.description)
        // FIXME(compnerd) - excluding = libs
        try writer.build(job.outputs.paths(), rule: job.name,
                         inputs: job.inputs.paths(objdir: objdir, excluding: []))

      case .mergeModule:
        // FIXME(compnerd) - should we restat?
        writer.rule(job.name, command: command, description: job.description)
        try writer.build(job.outputs.paths(), rule: job.name,
                         inputs: job.inputs.paths(objdir: objdir))

      default: fatalError("unable to handle '\(job.kind)' job")
      }
    }
  }
}

extension TSCBasic.FileSystem {
  // TODO(compnerd) figure out how to get this value from the build context
  internal var out: AbsolutePath {
    get throws {
      try AbsolutePath(validating: #"S:\b"#)
    }
  }
}

// TODO(compnerd): honour `output_dir` property on the target
extension Buildable {
  internal var objdir: RelativePath {
    get throws {
      try RelativePath(validating: "\(label.name).dir")
    }
  }

  internal var bindir: RelativePath {
    get throws {
      try RelativePath(validating: "bin")
    }
  }

  internal var libdir: RelativePath {
    get throws {
      try RelativePath(validating: "lib")
    }
  }
}

extension Buildable {
  internal var resolver: ArgsResolver {
    get throws {
      // NOTE: the temporary directory must be specified as an absolute
      // directory to enable the driver to emit file lists.
      try ArgsResolver(fileSystem: localFileSystem,
                       temporaryDirectory: .absolute(.init(validating: objdir.pathString,
                                                           relativeTo: localFileSystem.out)))
    }
  }

  internal var executor: DriverExecutor {
    get throws {
      try NULLExecutor(resolver: resolver)
    }
  }
}

extension DynamicLibraryTarget: Buildable {
  internal var invocation: [String] {
    get throws {
      var output: String = ""
      output.append(self.output_name)
      output.append(".")
      output.append(self.output_extension)

      return try [
        "swiftc.exe",
        "-module-name",
        self.module_name,
        "-emit-dependencies",
        "-emit-library",
        "-o",
        bindir.appending(component: output).pathString
      ] + self.swiftflags
    }
  }
}

extension ExecutableTarget: Buildable {
  internal var invocation: [String] {
    get throws {
      var output: String = ""
      output.append(self.output_name)
      if !self.output_extension.isEmpty { output.append(".") }
      output.append(self.output_extension)

      return try [
        "swiftc.exe",
        "-module-name",
        self.module_name,
        "-emit-dependencies",
        "-emit-executable",
        "-o",
        bindir.appending(component: output).pathString
      ] + self.swiftflags
    }
  }
}

extension GroupTarget: Buildable {
  internal var invocation: [String] { [] }
  internal func emitRules(into writer: NinjaWriter) throws {
    writer.phony(self.label.name, outputs: self.dependencies.public)
  }
}

extension StaticLibraryTarget: Buildable {
  internal var invocation: [String] {
    get throws {
      return try [
        "swiftc.exe",
        "-parse-as-library",
        "-static",
        "-emit-dependencies",
        "-emit-library",
        "-emit-module",
        "-emit-module-path",
        // self.module.pathString,
        "-module-name",
        self.module_name,
        "-o",
        libdir.appending(component: "\(self.output_name).\(self.output_extension)").pathString
      ] + self.swiftflags
    }
  }
}

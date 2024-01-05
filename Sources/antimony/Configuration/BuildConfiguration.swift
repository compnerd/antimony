// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import class Foundation.FileManager
import struct Foundation.URL

public class BuildConfiguration {
  var loader: Loader?

  private var registered: [Label:Target] = [:]
  private let fs = Foundation.FileManager.default

  private func repo() throws -> URL? {
    var root = URL(fileURLWithPath: fs.currentDirectoryPath)
    repeat {
      if fs.fileExists(atPath: root.appendingPathComponent("WORKSPACE").path) {
        return root
      }
      root.deleteLastPathComponent()
    } while !(root.path == "/..")

    return nil
  }

  public init() {}

  public func load(_ options: BuildConfigurationOptions,
                   for operation: Operation) async throws {
    self.loader = AntimonyLoader(self)
    guard let loader else { return }

    guard let root = try options.root?.url ?? repo() else {
      // throw DirectoryNotFound(.source)
      return
    }
    let out = URL(fileURLWithPath: options.location, isDirectory: true,
                  relativeTo: URL(fileURLWithPath: fs.currentDirectoryPath))

    try loader.load(URL(fileURLWithPath: "BUILD.gn", relativeTo: root), root: root)

    switch operation {
    case .format:
      for target in registered.values {
        print(target)
      }

    case .generate:
      try fs.createDirectory(at: out, withIntermediateDirectories: true)

      let writer = NinjaWriter()
      let emitter = JobEmitter(for: self, into: writer)
      for target in registered.values {
        try emitter.emitJobs(for: target, flags: ["-use-ld=lld"], at: out)
      }
      try writer.write(to: URL(fileURLWithPath: "build.ninja", relativeTo: out))
    }
  }
}

extension BuildConfiguration: BuildConfigurationDelegate {
  public func resolved(label: Label, to target: Target) {
    registered[label] = target
  }

  public func lookup(_ label: Label) -> Target? {
    registered[label]
  }
}

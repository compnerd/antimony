// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import antimony
import ArgumentParser

import class Foundation.FileManager
import struct Foundation.URL

import struct BUILDEvaluator.Label

private struct Format: AsyncParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(commandName: "format", abstract: "Format BUILD files")
  }

  @OptionGroup
  var options: CLIOptions

  mutating func run() async throws {
    fatalError()
  }
}

private let fs = Foundation.FileManager.default

private func repo() -> URL? {
  var root = URL(fileURLWithPath: fs.currentDirectoryPath)
  repeat {
    if fs.fileExists(atPath: root.appendingPathComponent(".gn").path) {
      return root
    }
    root.deleteLastPathComponent()
  } while !(root.path == "/..")

  return nil
}

private struct Generate: AsyncParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(commandName: "gen", abstract: "Generate Ninja files")
  }

  @OptionGroup
  var options: CLIOptions

  mutating func run() async throws {
    let fs = Foundation.FileManager.default
    let out = URL(fileURLWithPath: options.out, isDirectory: true,
                  relativeTo: URL(fileURLWithPath: fs.currentDirectoryPath))
    guard let directory = options.root?.url ?? repo() else {
      throw AntimonyError()
    }
    try await Antimony.shared.build(Label.resolve("//:default", root: directory),
                                    at: out)
  }
}

@main
private struct SB: AsyncParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(subcommands: [Format.self, Generate.self])
  }

  @Flag
  var version: Bool = false

  private func DoVersion() {
  }

  mutating func run() throws {
    if version { return DoVersion() }
  }
}

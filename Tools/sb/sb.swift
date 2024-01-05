// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import antimony

import ArgumentParser
import struct Foundation.URL

private struct Format: AsyncParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(commandName: "format", abstract: "Format BUILD files")
  }

  @OptionGroup
  var options: BuildConfigurationOptions

  mutating func run() async throws {
    let configuration = BuildConfiguration()
    try await configuration.load(options, for: .format)
  }
}

private struct Generate: AsyncParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(commandName: "gen", abstract: "Generate Ninja files")
  }

  @OptionGroup
  var options: BuildConfigurationOptions

  mutating func run() async throws {
    let configuration = BuildConfiguration()
    try await configuration.load(options, for: .generate)
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

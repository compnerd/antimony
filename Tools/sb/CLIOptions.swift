// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

import ArgumentParser

public struct CLIOptions: ParsableArguments {
  @Option
  var root: FileURL?

  @Argument(help: .init(valueName: "out_dir"))
  var out: String

  public init() {}
}

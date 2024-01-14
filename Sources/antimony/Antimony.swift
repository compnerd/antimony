// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import BUILDParser
internal import BUILDEvaluator

public import struct BUILDEvaluator.Label

internal import class Foundation.FileManager
public import struct Foundation.URL

extension Target {
  fileprivate var dependency_labels: [String] {
    [dependencies.public, dependencies.private].reduce([], +)
  }
}

public actor Antimony {
  private var icache: [Label:any Buildable] = [:]
  private var dcache: [URL:[any Buildable]] = [:]
  private var fs: FileManager = FileManager.default

  public static var shared: Antimony = Antimony()

  private func load(_ directory: URL) throws -> [any Buildable] {
    if let targets = dcache[directory] { return targets }

    var rules = directory.appendingPathComponent("BUILD.gn")
    if !fs.fileExists(atPath: rules.path) {
      rules = URL(fileURLWithPath: directory.relativePath, isDirectory: true,
                  relativeTo: URL(fileURLWithPath: #"S:\SourceCache\compnerd\antimony\build"#))
          .appendingPathComponent("BUILD.gn")
    }

    guard let source: SourceFile = try? SourceFile(contentsOf: rules) else {
      fatalError("Could not load \(rules.path).")
    }

    var scope: Scope = Scope(directory)
    var expressions: [any Expression] = []
    var diagnostics: DiagnosticSet = DiagnosticSet()

    try Parser.parse(source, into: &expressions, diagnostics: &diagnostics)
    guard diagnostics.empty else { throw diagnostics }

    let range: SourceRange =
        if let first = expressions.first, let last = expressions.last {
      SourceRange(first.range.start ..< last.range.end, in: source)
    } else {
      source.location(source.text.startIndex) ..< source.location(source.text.startIndex)
    }

    let block: BlockExpression =
        BlockExpression(statements: expressions, range: range)
    _ = try block.evaluate(in: &scope)

    let buildables: [any Buildable] =
        scope.collector.targets.compactMap { $0 as? Buildable }
    dcache[directory] = buildables
    return buildables
  }

  private func load(_ directory: URL) async throws -> [any Buildable] {
    if let targets = dcache[directory] { return targets }
    return try await Task {
      try load(directory)
    }.value
  }

  private func resolve(_ label: Label) async throws -> (any Buildable)? {
    if let target = icache[label] { return target }

    let targets = try await load(label.directory)
    if let target = targets.first(where: { $0.label == label }) {
      icache[label] = target
      return target
    }
    return nil
  }

  public func build(_ label: Label, at out: URL) async throws {
    guard let target = try await resolve(label) else { return }
    let root = label.directory

    var frontier: [String] = target.dependency_labels
    while !frontier.isEmpty {
      frontier = try await withThrowingTaskGroup(of: (any Buildable)?.self) { group in
        let labels = frontier.map { Label.resolve($0, root: root) }
        for label in labels {
          group.addTask {
            try await self.resolve(label)
          }
        }

        return try await group.reduce(into: [], {
          $0.append(contentsOf: $1?.dependency_labels ?? [])
        })
      }
    }

// print(icache)
    try fs.createDirectory(at: out, withIntermediateDirectories: true)
    let writer = NinjaWriter()
    try icache.values.forEach { try $0.emitRules(into: writer) }
    // try target.emitRules(into: writer)
    try writer.write(to: out.appendingPathComponent("build.ninja"))
  }
}

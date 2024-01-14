// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import struct Foundation.Data
internal import struct Foundation.URL

extension String {
  fileprivate func escapedPath() -> String {
    self.replacing("$ ", with: "$$ ").replacing(" ", with: "$ ").replacing(":", with: "$:")
  }

  fileprivate func escapedRuleName() -> String {
    self.replacing("+", with: "_").replacing(" ", with: "_")
  }
}

extension String.SubSequence {
  /// Returns the number of `$` characters preceeding the character at index `end`.
  fileprivate func escapes(before end: Index) -> Int {
    guard let start = self[..<end].lazy.reversed().firstIndex(where: { $0 != "$" }) else { return 0 }
    return distance(from: start.base, to: end)
  }
}

internal class NinjaWriter {
  private var content: String
  private var width: Int

  public init(_ width: Int = 80) {
    self.content = ""
    self.width = width
  }

  private func variable(_ key: String, _ value: String?, indent: Int = 0) {
    guard let value else { return }
    append("\(String(repeating: " ", count: indent))\(key) = \(value)")
  }

  private func append(_ text: String, indent: Int = 0) {
    var indentation: String = String(repeating: "  ", count: indent)

#if false
    var text = text[...]
    while indentation.count + text.count > self.width {
      // Attempt to wrap the text if possible.
      let width = self.width - indentation.count - " $".count
      var index: String.Index? = text.index(text.startIndex, offsetBy: width)

      // Find the rightmost unescaped space satisfying our width constraint.
      while index == nil ? false : text.escapes(before: index!) % 2 != 0 {
        index = text[..<index!].lastIndex(of: " ")
      }

      // No such space, just use the first unescaped space we find.
      if index == nil {
        index = text.index(text.startIndex, offsetBy: width)
        while index == nil ? false : text.escapes(before: index!) % 2 != 0 {
          index = text[index!...].firstIndex(of: " ")
        }
      }

      guard let index else { break }

      content += "\(indentation)\(text[..<index]) $\n"
      text = text[text.index(after: index)...]

      // Subsequent lines are continuations, indent them.
      indentation = String(repeating: "  ", count: indent + 2)
    }
#endif
    content += "\(indentation)\(text)\n"
  }

  public func pool(_ name: String, depth: Int) {
    append("pool \(name)")
    variable("depth", "\(depth)", indent: 1)
  }

  public func rule(_ name: String, command: String, description: String? = nil,
                   depfile: String? = nil, generator: Bool = false,
                   pool: String? = nil, restat: Bool = false,
                   rspfile: (path: String?, content: String?) = (nil, nil),
                   deps: [String] = []) {
    append("rule \(name.escapedRuleName())")
    variable("command", command, indent: 1)
    if let description {
      variable("description", description, indent: 1)
    }
    if let depfile {
      variable("depfile", depfile, indent: 1)
    }
    if generator {
      variable("generator", "1", indent: 1)
    }
    if let pool {
      variable("pool", pool, indent: 1)
    }
    if restat {
      variable("restat", "1", indent: 1)
    }
    if let rspfile = rspfile.path {
      variable("rspfile", rspfile, indent: 1)
    }
    if let content = rspfile.content {
      variable("rspfile_content", content, indent: 1)
    }
    if !deps.isEmpty {
      variable("deps", deps.joined(separator: " "), indent: 1)
    }
  }

  public func build(_ outs: [String], rule: String, inputs: [String] = [],
                    implicitInputs: [String] = [], orderOnly: [String] = [],
                    variables: [String:String] = [:],
                    implicitOutputs: [String] = [], pool: String? = nil,
                    dyndep: String? = nil) {
    var ins: [String] = []
    var outputs: [String] = []

    ins.append(contentsOf: inputs.map { $0.escapedPath() })
    if !implicitInputs.isEmpty {
      ins.append("|")
      ins.append(contentsOf: implicitInputs.map { $0.escapedPath() })
    }
    if !orderOnly.isEmpty {
      ins.append("||")
      ins.append(contentsOf: orderOnly.map { $0.escapedPath() })
    }

    outputs.append(contentsOf: outs.map { $0.escapedPath() })
    if !implicitOutputs.isEmpty {
      outputs.append("|")
      outputs.append(contentsOf: implicitOutputs.map { $0.escapedPath() })
    }

    append("build \(outputs.joined(separator: " ")): \(rule.escapedRuleName()) \(ins.joined(separator: " "))")
    if let pool {
      variable("pool", pool, indent: 1)  
    }
    if let dyndep {
      variable("dyndep", dyndep, indent: 1)
    }

    for (key, value) in variables {
      variable(key, value, indent: 1)
    }
  }

  public func include(_ path: String) {
    append("include \(path.escapedPath())")
  }

  public func newline() {
    append("")
  }

  public func phony(_ output: String, outputs: [String]) {
    append("build \(output): phony \(outputs.map { $0.escapedPath() }.joined(separator: " "))")
  }

  public func subninja(_ path: String) {
    append("subninja \(path.escapedPath())")
  }

  public func `default`(_ paths: [String]) {
    append("default \(paths.map { $0.escapedPath() }.joined(separator: " "))")
  }

  public func write(to path: URL) throws {
    let data: Data = Data(content.utf8)
    try data.write(to: path, options: [.atomic])
  }
}

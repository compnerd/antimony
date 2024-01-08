// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import BUILDParser
import struct Foundation.URL

private enum ModuleType {
  case `static`
  case dynamic
  case executable
}

private func build(_ type: ModuleType, call: FunctionCallExpression,
                   arguments: [any Value], in scope: inout Scope)
    throws -> any Value {
  guard scope.importing == false else {
    throw ExecutionError("Only definition of defaults, variables, and rules are permitted in imports.",
                          at: call.callee.range)
  }
  guard scope.configuring == false else {
    throw ExecutionError("Targets may not be defined in the build configuration.",
                          at: call.callee.range)
  }

  // TODO(compnerd) prevent nesting blocks

  var child: Scope = Scope(parent: &scope, directory: scope.directory)
  guard let block = call.scope else {
    throw ExecutionError("This function call requires a block.",
                          at: call.callee.range)
  }

  // TODO(compnerd): copy target defaults into the child scope

  guard arguments.count == 1 else {
    throw ExecutionError("'\(type)' takes 1 argument, \(arguments.count) provided",
                         at: call.callee.range)
  }
  guard arguments.first?.string != nil else {
    throw ExecutionError("'\(type)' requires argument 1 to be of type 'string'",
                         at: call.arguments[1].range)
  }

  // Set the target name variable to the current target, and mark it used
  // because we don't want to issue an error if the script ignores it
  child[.target_name] = arguments.first

  _ = try block.evaluate(in: &child)

  // TODO(compnerd) bind toolchain label

  let module: any Target = switch type {
  case .static: try StaticLibraryTarget.reify(in: child)
  case .dynamic: try DynamicLibraryTarget.reify(in: child)
  case .executable: try ExecutableTarget.reify(in: child)
  }
  scope.collector.append(module)

  return NilValue()
}

// MARK:- assert

internal func Assert(_ call: FunctionCallExpression, _ arguments: [any Value]?,
                     _ scope: inout Scope) throws -> any Value {
  guard let params = arguments else {
    fatalError("'assert' does not delay parse arguments")
  }

  // Verify formal parameter airity.
  if params.isEmpty || params.count > 2 {
    throw ExecutionError("'assert' takes 1 argument, \(params.count) provided",
                         at: call.callee.range)
  }

  // Typecheck parameters.
  guard let value = params.first?.boolean else {
    throw ExecutionError("'assert' requires argument 1 to be of type 'boolean'",
                         at: call.arguments[0].range)
  }
  guard params.count == 1 || params.last is StringValue else {
    throw ExecutionError("'assert' requires argument 2 to be of type 'string'",
                          at: call.arguments[1].range)
  }

  // Evaluate assertion.
  if value { return NilValue() }

  // TODO(compnerd): locate the origin of the variable if a non-literal
  // argument is used.
  let message = if params.count == 2, let message = params.last?.string {
    "assertion failure: \(message)"
  } else {
    "assertion failure"
  }
  throw ExecutionError(message, at: call.range)
}

// MARK:- config

internal func Config(_ call: FunctionCallExpression, _ arguments: [any Value]?,
                     in scope: inout Scope) throws -> any Value {
  guard let arguments = arguments else {
    fatalError("'shared_library' does not delay parse arguments")
  }

  guard scope.importing == false else {
    throw ExecutionError("Only definition of defaults, variables, and rules are permitted in imports.",
                          at: call.callee.range)
  }

  guard arguments.count == 1 else {
    throw ExecutionError("'config' takes 1 argument, \(arguments.count) provided",
                         at: call.callee.range)
  }
  guard let name = arguments.first?.string else {
    throw ExecutionError("'config' requires argument 1 to be of type 'string'",
                         at: call.arguments[1].range)
  }

  var config: Scope = Scope(parent: &scope, directory: scope.directory)

  guard let block = call.scope else {
    throw ExecutionError("This function call requires a block.",
                          at: call.callee.range)
  }
  _ = try block.evaluate(in: &config)

  fatalError("'config' is incomplete")
}

// MARK:- shared_library

internal func DynamicLibrary(_ call: FunctionCallExpression,
                             _ arguments: [any Value]?, in scope: inout Scope)
    throws -> any Value {
  guard let arguments = arguments else {
    fatalError("'shared_library' does not delay parse arguments")
  }
  return try build(.dynamic, call: call, arguments: arguments, in: &scope)
}

// MARK:- executable

internal func Executable(_ call: FunctionCallExpression,
                         _ arguments: [any Value]?, in scope: inout Scope)
    throws -> any Value {
  guard let arguments = arguments else {
    fatalError("'executable' does not delay parse arguments")
  }
  return try build(.executable, call: call, arguments: arguments, in: &scope)
}

// MARK:- group

internal func Group(_ call: FunctionCallExpression, _ arguments: [any Value]?,
                    _ scope: inout Scope) throws -> any Value {
  guard let arguments = arguments else {
    fatalError("'executable' does not delay parse arguments")
  }

  guard scope.importing == false else {
    throw ExecutionError("Only definition of defaults, variables, and rules are permitted in imports.",
                          at: call.callee.range)
  }
  guard scope.configuring == false else {
    throw ExecutionError("Targets may not be defined in the build configuration.",
                          at: call.callee.range)
  }

  // TODO(compnerd) prevent nesting blocks

  var child: Scope = Scope(parent: &scope, directory: scope.directory)
  guard let block = call.scope else {
    throw ExecutionError("This function call requires a block.",
                         at: call.callee.range)
  }

  // TODO(compnerd): copy target defaults into the child scope

  guard arguments.count == 1 else {
    throw ExecutionError("'group' takes 1 argument, \(arguments.count) provided",
                         at: call.callee.range)
  }
  guard arguments.first?.string != nil else {
    throw ExecutionError("'group' requires argument 1 to be of type 'string'",
                         at: call.arguments[1].range)
  }

  child[.target_name] = arguments.first

  _ = try block.evaluate(in: &child)

  // TODO(compnerd) bind toolchain label

  try scope.collector.append(GroupTarget.reify(in: child))

  return NilValue()
}

// MARK:- static_library

internal func StaticLibrary(_ call: FunctionCallExpression,
                            _ arguments: [any Value]?, _ scope: inout Scope)
    throws -> any Value {
  guard let arguments = arguments else {
    fatalError("'static_library' does not delay parse arguments")
  }
  return try build(.static, call: call, arguments: arguments, in: &scope)
}

// MARK:- Builtin Function Information

struct BuiltinFunctionInfo {
  let delayed: Bool
  let invoke: (_ call: FunctionCallExpression, _ arguments: [any Value]?,
               _ scope: inout Scope)  throws -> any Value
}

internal enum Builtin {
  internal static subscript (_ name: String) -> BuiltinFunctionInfo? {
    return switch name {
    case "assert":
      BuiltinFunctionInfo(delayed: false, invoke: Assert)
    case "config":
      BuiltinFunctionInfo(delayed: false, invoke: Config)
    case "executable":
      BuiltinFunctionInfo(delayed: false, invoke: Executable)
    case "group":
      BuiltinFunctionInfo(delayed: false, invoke: Group)
    case "shared_library":
      BuiltinFunctionInfo(delayed: false, invoke: DynamicLibrary)
    case "static_library":
      BuiltinFunctionInfo(delayed: false, invoke: StaticLibrary)
    default: nil
    }
  }
}

// Copyright © 2024 Saleem Abdulrasool <compnerd@compnerd.org>
// SPDX-License-Identifier: BSD-3-Clause

internal import SwiftDriver
internal import TSCBasic

struct NULLExecutor: DriverExecutor {
  let resolver: ArgsResolver

  func execute(job: Job, forceResponseFiles: Bool,
               recordedInputModificationDates: [TypedVirtualPath:TimePoint])
      throws -> ProcessResult {
    ProcessResult(arguments: [], environmentBlock: [:],
                  exitStatus: .terminated(code: 0), output: .success([]),
                  stderrOutput: .success([]))
  }

  func execute(workload: DriverExecutorWorkload, delegate: JobExecutionDelegate,
               numParallelJobs: Int, forceResponseFiles: Bool,
               recordedInputModificationDates: [TypedVirtualPath:TimePoint])
      throws {
    fatalError()
  }

  func checkNonZeroExit(args: String..., environment: [String:String])
      throws -> String {
    try Process.checkNonZeroExit(arguments: args, environmentBlock: .init(environment))
  }

  func description(of job: Job, forceResponseFiles: Bool) throws -> String {
    String(describing: job)
  }
}

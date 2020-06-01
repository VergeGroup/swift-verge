
import Foundation
import Bulk

public let Log = Logger(context: "", sinks: [
  BulkSink<LogData>(
    buffer: MemoryBuffer.init(size: 10).asAny(),
    targets: [

//      TargetUmbrella.init(
//        transform: LogBasicFormatter().format,
//        targets: [
//          LogConsoleTarget.init().asAny()
//        ]
//      ).asAny(),

      OSLogTarget(subsystem: "VergeSpotify", category: "Log").asAny()
    ]
  )
    .asAny()
])

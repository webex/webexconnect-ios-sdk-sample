import Foundation
import WebexConnectCore

enum LoggerType: String {
    case console
    case file
}

struct LogManager {
    private static let webexConnect = WebexConnectProvider.instance

    private init() {

    }

    static func setFileLogger() {
        if let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logDirectoryURL = documentsDirectoryURL.appendingPathComponent("ConnectDemoAppLogs")
            do {
                try FileManager.default.createDirectory(at: logDirectoryURL, withIntermediateDirectories: true, attributes: nil)

                let fileLogger = FileLogger.create(filter: .debug, outputDir: logDirectoryURL, retentionDays: 1)
                webexConnect.setLogger(fileLogger)
                print("FileLogger path", logDirectoryURL.absoluteString)
            } catch {
                fatalError("Failed to create log directory: \(error)")
            }
        } else {
            fatalError("Could not find documents directory.")
        }
    }

    static func setConsoleLogger() {
        webexConnect.setLogger(ConsoleLogger(logType: .debug))
    }
}

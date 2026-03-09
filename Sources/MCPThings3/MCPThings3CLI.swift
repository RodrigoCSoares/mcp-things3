import ArgumentParser
import Foundation
import Logging
import MCP

@main
struct MCPThings3CLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mcp-things3",
        abstract: "MCP server for Things 3 task management",
        version: "1.0.0"
    )

    @Option(name: .long, help: "Transport mode: stdio")
    var transport: String = "stdio"

    @Option(name: .long, help: "Log level: trace, debug, info, warning, error, critical")
    var logLevel: String = "info"

    func run() async throws {
        // Capture values before any closures
        let resolvedLogLevel = Self.parseLogLevel(logLevel)
        let transportMode = transport.lowercased()

        // Configure logging to stderr so stdout stays clean for MCP JSON-RPC
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = resolvedLogLevel
            return handler
        }

        let logger = Logger(label: "mcp-things3")

        do {
            let server = try Things3MCPServer(logger: logger)

            switch transportMode {
            case "stdio":
                logger.info("Starting Things 3 MCP server with stdio transport")
                let stdinTransport = StdioTransport()
                try await server.start(transport: stdinTransport)
            default:
                logger.error("Unsupported transport: \(transportMode). Use 'stdio'.")
                throw ExitCode.failure
            }
        } catch let error as Things3Error {
            logger.error("Things 3 error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }

    private static func parseLogLevel(_ level: String) -> Logger.Level {
        switch level.lowercased() {
        case "trace": return .trace
        case "debug": return .debug
        case "info": return .info
        case "warning", "warn": return .warning
        case "error": return .error
        case "critical": return .critical
        default: return .info
        }
    }
}

import Foundation
import Logging
import MCP

// MARK: - Things3 MCP Server

final class Things3MCPServer: @unchecked Sendable {
    let server: Server
    let database: Things3Database
    let appleScript: Things3AppleScript
    let encoder: JSONEncoder
    let decoder: JSONDecoder
    private let logger: Logger

    init(logger: Logger) throws {
        self.logger = logger
        self.database = try Things3Database()
        self.appleScript = Things3AppleScript()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        self.decoder = decoder

        self.server = Server(
            name: "things3",
            version: "1.0.0",
            capabilities: .init(
                logging: .init(),
                tools: .init(listChanged: false)
            )
        )
    }

    // MARK: - Start

    func start(transport: any Transport) async throws {
        await registerHandlers()
        logger.info("Starting Things 3 MCP server...")
        try await server.start(transport: transport)
        logger.info("Things 3 MCP server started successfully")
        await server.waitUntilCompleted()
    }

    // MARK: - Handler Registration

    private func registerHandlers() async {
        // List Tools
        await server.withMethodHandler(ListTools.self) { [self] _ in
            ListTools.Result(tools: toolDefinitions)
        }

        // Call Tool
        await server.withMethodHandler(CallTool.self) { [self] params in
            await dispatchTool(params)
        }
    }

    // MARK: - Tool Dispatch

    private func dispatchTool(_ params: CallTool.Parameters) async -> CallTool.Result {
        do {
            let argsData: Data
            if let args = params.arguments {
                argsData = try encoder.encode(args)
            } else {
                argsData = "{}".data(using: .utf8)!
            }

            switch params.name {
            // Read - Todos
            case "get_todos":
                return try encodeResult(handleGetTodos(data: argsData))
            case "get_todo":
                return try encodeResult(handleGetTodo(data: argsData))
            case "search_todos":
                return try encodeResult(handleSearchTodos(data: argsData))

            // Read - Projects
            case "get_projects":
                return try encodeResult(handleGetProjects(data: argsData))
            case "get_project":
                return try encodeResult(handleGetProject(data: argsData))
            case "get_project_todos":
                return try encodeResult(handleGetProjectTodos(data: argsData))

            // Read - Areas
            case "get_areas":
                return try encodeResult(handleGetAreas())
            case "get_area":
                return try encodeResult(handleGetArea(data: argsData))

            // Read - Tags
            case "get_tags":
                return try encodeResult(handleGetTags())

            // Read - Headings
            case "get_headings":
                return try encodeResult(handleGetHeadings(data: argsData))

            // Create
            case "create_todo":
                return try encodeResult(handleCreateTodo(data: argsData))
            case "create_project":
                return try encodeResult(handleCreateProject(data: argsData))
            case "create_area":
                return try encodeResult(handleCreateArea(data: argsData))
            case "create_tag":
                return try encodeResult(handleCreateTag(data: argsData))

            // Update
            case "update_todo":
                return try encodeResult(handleUpdateTodo(data: argsData))
            case "update_project":
                return try encodeResult(handleUpdateProject(data: argsData))
            case "move_todo":
                return try encodeResult(handleMoveTodo(data: argsData))
            case "complete_todo":
                return try encodeResult(handleCompleteTodo(data: argsData))
            case "reopen_todo":
                return try encodeResult(handleReopenTodo(data: argsData))

            // Delete
            case "delete_todo":
                return try encodeResult(handleDeleteTodo(data: argsData))
            case "delete_project":
                return try encodeResult(handleDeleteProject(data: argsData))
            case "delete_area":
                return try encodeResult(handleDeleteArea(data: argsData))
            case "delete_tag":
                return try encodeResult(handleDeleteTag(data: argsData))
            case "empty_trash":
                return try encodeResult(handleEmptyTrash())

            default:
                return CallTool.Result(
                    content: [.text("Unknown tool: \(params.name)")],
                    isError: true
                )
            }
        } catch {
            logger.error("Tool error [\(params.name)]: \(error.localizedDescription)")
            return CallTool.Result(
                content: [.text("Error: \(error.localizedDescription)")],
                isError: true
            )
        }
    }

    // MARK: - Result Encoding

    func encodeResult<T: Encodable>(_ value: T) throws -> CallTool.Result {
        let data = try encoder.encode(value)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        return CallTool.Result(content: [.text(json)], isError: false)
    }

    func textResult(_ text: String) -> CallTool.Result {
        CallTool.Result(content: [.text(text)], isError: false)
    }
}

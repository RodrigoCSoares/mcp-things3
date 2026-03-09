import Foundation
import MCP

// MARK: - Tool Handlers

extension Things3MCPServer {

    // MARK: - Read Handlers

    func handleGetTodos(data: Data) throws -> [Things3Todo] {
        let input = try decoder.decode(ListFilterInput.self, from: data)
        return try database.getTodos(filter: input)
    }

    func handleGetTodo(data: Data) throws -> Things3Todo {
        let input = try decoder.decode(UUIDInput.self, from: data)
        return try database.getTodo(uuid: input.uuid)
    }

    func handleSearchTodos(data: Data) throws -> [Things3Todo] {
        let input = try decoder.decode(SearchInput.self, from: data)
        return try database.searchTodos(query: input.query, status: input.status)
    }

    func handleGetProjects(data: Data) throws -> [Things3Project] {
        struct Input: Decodable { let status: String? }
        let input = try decoder.decode(Input.self, from: data)
        return try database.getProjects(status: input.status)
    }

    func handleGetProject(data: Data) throws -> Things3Project {
        let input = try decoder.decode(UUIDInput.self, from: data)
        return try database.getProject(uuid: input.uuid)
    }

    func handleGetProjectTodos(data: Data) throws -> [Things3Todo] {
        let input = try decoder.decode(GetProjectTodosInput.self, from: data)
        let status = (input.includeCompleted ?? false) ? "all" : "open"
        let filter = ListFilterInput(
            list: nil,
            projectUUID: input.projectUUID,
            areaUUID: nil,
            tagName: nil,
            status: status
        )
        return try database.getTodos(filter: filter)
    }

    func handleGetAreas() throws -> [Things3Area] {
        return try database.getAreas()
    }

    func handleGetArea(data: Data) throws -> Things3Area {
        let input = try decoder.decode(UUIDInput.self, from: data)
        return try database.getArea(uuid: input.uuid)
    }

    func handleGetTags() throws -> [Things3Tag] {
        return try database.getTags()
    }

    func handleGetHeadings(data: Data) throws -> [Things3Heading] {
        struct Input: Decodable { let projectUUID: String }
        let input = try decoder.decode(Input.self, from: data)
        return try database.getHeadings(projectUUID: input.projectUUID)
    }

    // MARK: - Create Handlers

    func handleCreateTodo(data: Data) throws -> [String: String] {
        let input = try decoder.decode(CreateTodoInput.self, from: data)
        let uuid = try appleScript.createTodo(input: input)
        return ["uuid": uuid, "status": "created"]
    }

    func handleCreateProject(data: Data) throws -> [String: String] {
        let input = try decoder.decode(CreateProjectInput.self, from: data)
        let uuid = try appleScript.createProject(input: input)
        return ["uuid": uuid, "status": "created"]
    }

    func handleCreateArea(data: Data) throws -> [String: String] {
        let input = try decoder.decode(CreateAreaInput.self, from: data)
        let uuid = try appleScript.createArea(input: input)
        return ["uuid": uuid, "status": "created"]
    }

    func handleCreateTag(data: Data) throws -> [String: String] {
        let input = try decoder.decode(CreateTagInput.self, from: data)
        let uuid = try appleScript.createTag(input: input)
        return ["uuid": uuid, "status": "created"]
    }

    // MARK: - Update Handlers

    func handleUpdateTodo(data: Data) throws -> [String: String] {
        let input = try decoder.decode(UpdateTodoInput.self, from: data)
        let uuid = try appleScript.updateTodo(input: input)
        return ["uuid": uuid, "status": "updated"]
    }

    func handleUpdateProject(data: Data) throws -> [String: String] {
        let input = try decoder.decode(UpdateProjectInput.self, from: data)
        let uuid = try appleScript.updateProject(input: input)
        return ["uuid": uuid, "status": "updated"]
    }

    func handleMoveTodo(data: Data) throws -> [String: String] {
        let input = try decoder.decode(MoveTodoInput.self, from: data)
        try appleScript.moveTodo(input: input)
        return ["uuid": input.uuid, "status": "moved"]
    }

    func handleCompleteTodo(data: Data) throws -> [String: String] {
        let input = try decoder.decode(UUIDInput.self, from: data)
        try appleScript.completeTodo(uuid: input.uuid)
        return ["uuid": input.uuid, "status": "completed"]
    }

    func handleReopenTodo(data: Data) throws -> [String: String] {
        let input = try decoder.decode(UUIDInput.self, from: data)
        try appleScript.reopenTodo(uuid: input.uuid)
        return ["uuid": input.uuid, "status": "reopened"]
    }

    // MARK: - Delete Handlers

    func handleDeleteTodo(data: Data) throws -> [String: String] {
        let input = try decoder.decode(DeleteInput.self, from: data)
        try appleScript.deleteTodo(uuid: input.uuid)
        return ["uuid": input.uuid, "status": "deleted"]
    }

    func handleDeleteProject(data: Data) throws -> [String: String] {
        let input = try decoder.decode(DeleteInput.self, from: data)
        try appleScript.deleteProject(uuid: input.uuid)
        return ["uuid": input.uuid, "status": "deleted"]
    }

    func handleDeleteArea(data: Data) throws -> [String: String] {
        let input = try decoder.decode(DeleteInput.self, from: data)
        try appleScript.deleteArea(uuid: input.uuid)
        return ["uuid": input.uuid, "status": "deleted"]
    }

    func handleDeleteTag(data: Data) throws -> [String: String] {
        let input = try decoder.decode(DeleteInput.self, from: data)
        try appleScript.deleteTag(uuid: input.uuid)
        return ["uuid": input.uuid, "status": "deleted"]
    }

    func handleEmptyTrash() throws -> [String: String] {
        try appleScript.emptyTrash()
        return ["status": "trash_emptied"]
    }
}

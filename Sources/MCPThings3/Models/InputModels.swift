import Foundation

// MARK: - Input DTOs for Tool Handlers

struct UUIDInput: Decodable {
    let uuid: String
}

struct ListFilterInput: Decodable {
    let list: String?
    let projectUUID: String?
    let areaUUID: String?
    let tagName: String?
    let status: String?
}

struct SearchInput: Decodable {
    let query: String
    let status: String?
}

struct CreateTodoInput: Decodable {
    let title: String
    let notes: String?
    let dueDate: String?
    let tags: [String]?
    let checklistItems: [String]?
    let projectUUID: String?
    let headingTitle: String?
    let list: String?
    let when: String?
}

struct UpdateTodoInput: Decodable {
    let uuid: String
    let title: String?
    let notes: String?
    let dueDate: String?
    let tags: [String]?
    let completed: Bool?
    let canceled: Bool?
    let projectUUID: String?
    let list: String?
}

struct CreateProjectInput: Decodable {
    let title: String
    let notes: String?
    let dueDate: String?
    let tags: [String]?
    let areaUUID: String?
    let when: String?
    let todos: [String]?
    let headings: [String]?
}

struct UpdateProjectInput: Decodable {
    let uuid: String
    let title: String?
    let notes: String?
    let dueDate: String?
    let tags: [String]?
    let completed: Bool?
    let canceled: Bool?
}

struct CreateAreaInput: Decodable {
    let title: String
}

struct CreateTagInput: Decodable {
    let title: String
    let shortcut: String?
    let parentTagTitle: String?
}

struct DeleteInput: Decodable {
    let uuid: String
}

struct MoveTodoInput: Decodable {
    let uuid: String
    let projectUUID: String?
    let list: String?
}

struct GetProjectTodosInput: Decodable {
    let projectUUID: String
    let includeCompleted: Bool?
}

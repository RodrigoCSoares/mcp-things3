import Foundation

// MARK: - Things3 ToDo Status

enum Things3Status: Int, Codable, Sendable {
    case open = 0
    case canceled = 2
    case completed = 3

    var description: String {
        switch self {
        case .open: return "open"
        case .canceled: return "canceled"
        case .completed: return "completed"
        }
    }
}

// MARK: - Things3 ToDo

struct Things3Todo: Codable, Sendable {
    let uuid: String
    let title: String
    let notes: String?
    let status: String
    let creationDate: String?
    let modificationDate: String?
    let completionDate: String?
    let cancellationDate: String?
    let dueDate: String?
    let startDate: String?
    let tags: [String]
    let checklistItems: [Things3ChecklistItem]
    let projectUUID: String?
    let projectTitle: String?
    let areaUUID: String?
    let areaTitle: String?
    let headingTitle: String?
    let isEvening: Bool
    let list: String?
}

// MARK: - Things3 Project

struct Things3Project: Codable, Sendable {
    let uuid: String
    let title: String
    let notes: String?
    let status: String
    let creationDate: String?
    let modificationDate: String?
    let completionDate: String?
    let dueDate: String?
    let startDate: String?
    let tags: [String]
    let areaUUID: String?
    let areaTitle: String?
    let todoCount: Int
    let completedTodoCount: Int
}

// MARK: - Things3 Area

struct Things3Area: Codable, Sendable {
    let uuid: String
    let title: String
    let tags: [String]
}

// MARK: - Things3 Tag

struct Things3Tag: Codable, Sendable {
    let uuid: String
    let title: String
    let shortcut: String?
    let parentUUID: String?
    let parentTitle: String?
}

// MARK: - Things3 Checklist Item

struct Things3ChecklistItem: Codable, Sendable {
    let uuid: String
    let title: String
    let isCompleted: Bool
}

// MARK: - Things3 Heading

struct Things3Heading: Codable, Sendable {
    let uuid: String
    let title: String
    let projectUUID: String
    let projectTitle: String?
}

import Foundation

// MARK: - Things3 Error

enum Things3Error: Error, LocalizedError {
    case databaseNotFound
    case databaseAccessFailed(String)
    case queryFailed(String)
    case appleScriptFailed(String)
    case invalidInput(String)
    case notFound(String)
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "Things 3 database not found. Is Things 3 installed?"
        case .databaseAccessFailed(let detail):
            return "Failed to access Things 3 database: \(detail)"
        case .queryFailed(let detail):
            return "Database query failed: \(detail)"
        case .appleScriptFailed(let detail):
            return "AppleScript execution failed: \(detail)"
        case .invalidInput(let detail):
            return "Invalid input: \(detail)"
        case .notFound(let detail):
            return "Not found: \(detail)"
        case .operationFailed(let detail):
            return "Operation failed: \(detail)"
        }
    }
}

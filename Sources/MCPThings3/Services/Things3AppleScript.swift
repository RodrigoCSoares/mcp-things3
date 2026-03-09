import Foundation

/// Executes AppleScript commands against Things 3 for create, update, and delete operations.
/// Read operations go through the SQLite database for speed; writes go through AppleScript
/// because writing to the database directly would corrupt Things Cloud sync.
final class Things3AppleScript: Sendable {

    // MARK: - Create ToDo

    func createTodo(input: CreateTodoInput) throws -> String {
        var properties: [String] = []
        properties.append("name:\"\(escapeAS(input.title))\"")

        if let notes = input.notes {
            properties.append("notes:\"\(escapeAS(notes))\"")
        }

        if let dueDate = input.dueDate {
            properties.append("due date:date \"\(escapeAS(dueDate))\"")
        }

        var script = "tell application \"Things3\"\n"
        script += "  set newToDo to make new to do with properties {\(properties.joined(separator: ", "))}\n"

        // Tags
        if let tags = input.tags, !tags.isEmpty {
            let tagNames = tags.map { "\"\(escapeAS($0))\"" }.joined(separator: ", ")
            script += "  set tag names of newToDo to \(tagNames)\n"
        }

        // Move to project
        if let projectUUID = input.projectUUID {
            script += "  set theProject to first project whose id is \"\(escapeAS(projectUUID))\"\n"
            script += "  move newToDo to theProject\n"
        }

        // Move to list
        if let list = input.list {
            switch list.lowercased() {
            case "today":
                script += "  move newToDo to list \"Today\"\n"
            case "anytime":
                script += "  move newToDo to list \"Anytime\"\n"
            case "someday":
                script += "  move newToDo to list \"Someday\"\n"
            case "inbox":
                script += "  move newToDo to list \"Inbox\"\n"
            default:
                break
            }
        } else if let when = input.when {
            switch when.lowercased() {
            case "today":
                script += "  move newToDo to list \"Today\"\n"
            case "evening":
                script += "  move newToDo to list \"Today\"\n"
            case "anytime":
                script += "  move newToDo to list \"Anytime\"\n"
            case "someday":
                script += "  move newToDo to list \"Someday\"\n"
            default:
                // Assume it's a date string
                script += "  schedule newToDo for date \"\(escapeAS(when))\"\n"
            }
        }

        script += "  set todoId to id of newToDo\n"
        script += "  return todoId\n"
        script += "end tell"

        let result = try executeAppleScript(script)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Update ToDo

    func updateTodo(input: UpdateTodoInput) throws -> String {
        var script = "tell application \"Things3\"\n"
        script += "  set theToDo to first to do whose id is \"\(escapeAS(input.uuid))\"\n"

        if let title = input.title {
            script += "  set name of theToDo to \"\(escapeAS(title))\"\n"
        }

        if let notes = input.notes {
            script += "  set notes of theToDo to \"\(escapeAS(notes))\"\n"
        }

        if let dueDate = input.dueDate {
            if dueDate.isEmpty {
                script += "  set due date of theToDo to missing value\n"
            } else {
                script += "  set due date of theToDo to date \"\(escapeAS(dueDate))\"\n"
            }
        }

        if let tags = input.tags {
            let tagNames = tags.map { "\"\(escapeAS($0))\"" }.joined(separator: ", ")
            script += "  set tag names of theToDo to \(tagNames)\n"
        }

        if let completed = input.completed, completed {
            script += "  set status of theToDo to completed\n"
        }

        if let canceled = input.canceled, canceled {
            script += "  set status of theToDo to canceled\n"
        }

        if let list = input.list {
            switch list.lowercased() {
            case "today":
                script += "  move theToDo to list \"Today\"\n"
            case "anytime":
                script += "  move theToDo to list \"Anytime\"\n"
            case "someday":
                script += "  move theToDo to list \"Someday\"\n"
            case "inbox":
                script += "  move theToDo to list \"Inbox\"\n"
            default:
                break
            }
        }

        if let projectUUID = input.projectUUID {
            script += "  set theProject to first project whose id is \"\(escapeAS(projectUUID))\"\n"
            script += "  move theToDo to theProject\n"
        }

        script += "  return id of theToDo\n"
        script += "end tell"

        let result = try executeAppleScript(script)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Delete ToDo

    func deleteTodo(uuid: String) throws {
        let script = """
        tell application "Things3"
          set theToDo to first to do whose id is "\(escapeAS(uuid))"
          delete theToDo
        end tell
        """
        _ = try executeAppleScript(script)
    }

    // MARK: - Create Project

    func createProject(input: CreateProjectInput) throws -> String {
        var properties: [String] = []
        properties.append("name:\"\(escapeAS(input.title))\"")

        if let notes = input.notes {
            properties.append("notes:\"\(escapeAS(notes))\"")
        }

        if let dueDate = input.dueDate {
            properties.append("due date:date \"\(escapeAS(dueDate))\"")
        }

        var script = "tell application \"Things3\"\n"
        script += "  set newProject to make new project with properties {\(properties.joined(separator: ", "))}\n"

        if let tags = input.tags, !tags.isEmpty {
            let tagNames = tags.map { "\"\(escapeAS($0))\"" }.joined(separator: ", ")
            script += "  set tag names of newProject to \(tagNames)\n"
        }

        if let areaUUID = input.areaUUID {
            script += "  set theArea to first area whose id is \"\(escapeAS(areaUUID))\"\n"
            script += "  set area of newProject to theArea\n"
        }

        if let when = input.when {
            switch when.lowercased() {
            case "today":
                script += "  move newProject to list \"Today\"\n"
            case "anytime":
                script += "  move newProject to list \"Anytime\"\n"
            case "someday":
                script += "  move newProject to list \"Someday\"\n"
            default:
                script += "  schedule newProject for date \"\(escapeAS(when))\"\n"
            }
        }

        // Add child todos
        if let todos = input.todos {
            for todoTitle in todos {
                script += "  tell newProject\n"
                script += "    make new to do with properties {name:\"\(escapeAS(todoTitle))\"}\n"
                script += "  end tell\n"
            }
        }

        script += "  set projectId to id of newProject\n"
        script += "  return projectId\n"
        script += "end tell"

        let result = try executeAppleScript(script)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Update Project

    func updateProject(input: UpdateProjectInput) throws -> String {
        var script = "tell application \"Things3\"\n"
        script += "  set theProject to first project whose id is \"\(escapeAS(input.uuid))\"\n"

        if let title = input.title {
            script += "  set name of theProject to \"\(escapeAS(title))\"\n"
        }

        if let notes = input.notes {
            script += "  set notes of theProject to \"\(escapeAS(notes))\"\n"
        }

        if let dueDate = input.dueDate {
            if dueDate.isEmpty {
                script += "  set due date of theProject to missing value\n"
            } else {
                script += "  set due date of theProject to date \"\(escapeAS(dueDate))\"\n"
            }
        }

        if let tags = input.tags {
            let tagNames = tags.map { "\"\(escapeAS($0))\"" }.joined(separator: ", ")
            script += "  set tag names of theProject to \(tagNames)\n"
        }

        if let completed = input.completed, completed {
            script += "  set status of theProject to completed\n"
        }

        if let canceled = input.canceled, canceled {
            script += "  set status of theProject to canceled\n"
        }

        script += "  return id of theProject\n"
        script += "end tell"

        let result = try executeAppleScript(script)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Delete Project

    func deleteProject(uuid: String) throws {
        let script = """
        tell application "Things3"
          set theProject to first project whose id is "\(escapeAS(uuid))"
          delete theProject
        end tell
        """
        _ = try executeAppleScript(script)
    }

    // MARK: - Create Area

    func createArea(input: CreateAreaInput) throws -> String {
        let script = """
        tell application "Things3"
          set newArea to make new area with properties {name:"\(escapeAS(input.title))"}
          return id of newArea
        end tell
        """
        let result = try executeAppleScript(script)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Delete Area

    func deleteArea(uuid: String) throws {
        let script = """
        tell application "Things3"
          set theArea to first area whose id is "\(escapeAS(uuid))"
          delete theArea
        end tell
        """
        _ = try executeAppleScript(script)
    }

    // MARK: - Create Tag

    func createTag(input: CreateTagInput) throws -> String {
        var properties = "name:\"\(escapeAS(input.title))\""

        if let shortcut = input.shortcut {
            properties += ", shortcut:\"\(escapeAS(shortcut))\""
        }

        var script = "tell application \"Things3\"\n"
        script += "  set newTag to make new tag with properties {\(properties)}\n"

        if let parentTitle = input.parentTagTitle {
            script += "  set parentTag to first tag whose name is \"\(escapeAS(parentTitle))\"\n"
            script += "  set parent tag of newTag to parentTag\n"
        }

        script += "  return id of newTag\n"
        script += "end tell"

        let result = try executeAppleScript(script)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Delete Tag

    func deleteTag(uuid: String) throws {
        let script = """
        tell application "Things3"
          set theTag to first tag whose id is "\(escapeAS(uuid))"
          delete theTag
        end tell
        """
        _ = try executeAppleScript(script)
    }

    // MARK: - Move ToDo

    func moveTodo(input: MoveTodoInput) throws {
        var script = "tell application \"Things3\"\n"
        script += "  set theToDo to first to do whose id is \"\(escapeAS(input.uuid))\"\n"

        if let projectUUID = input.projectUUID {
            script += "  set theProject to first project whose id is \"\(escapeAS(projectUUID))\"\n"
            script += "  move theToDo to theProject\n"
        } else if let list = input.list {
            switch list.lowercased() {
            case "today":
                script += "  move theToDo to list \"Today\"\n"
            case "anytime":
                script += "  move theToDo to list \"Anytime\"\n"
            case "someday":
                script += "  move theToDo to list \"Someday\"\n"
            case "inbox":
                script += "  move theToDo to list \"Inbox\"\n"
            default:
                break
            }
        }

        script += "end tell"
        _ = try executeAppleScript(script)
    }

    // MARK: - Complete / Uncomplete ToDo

    func completeTodo(uuid: String) throws {
        let script = """
        tell application "Things3"
          set theToDo to first to do whose id is "\(escapeAS(uuid))"
          set status of theToDo to completed
        end tell
        """
        _ = try executeAppleScript(script)
    }

    func reopenTodo(uuid: String) throws {
        let script = """
        tell application "Things3"
          set theToDo to first to do whose id is "\(escapeAS(uuid))"
          set status of theToDo to open
        end tell
        """
        _ = try executeAppleScript(script)
    }

    // MARK: - Empty Trash

    func emptyTrash() throws {
        let script = """
        tell application "Things3"
          empty trash
        end tell
        """
        _ = try executeAppleScript(script)
    }

    // MARK: - AppleScript Execution

    private func executeAppleScript(_ source: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw Things3Error.appleScriptFailed(errorMessage)
        }

        return String(data: outputData, encoding: .utf8) ?? ""
    }

    private func escapeAS(_ input: String) -> String {
        input
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

import Foundation
import MCP

// MARK: - Tool Definitions

extension Things3MCPServer {

    var toolDefinitions: [Tool] {
        [
            // Read - Todos
            tool(
                name: "get_todos",
                description: "List to-dos from Things 3. Filter by list (inbox, today, anytime, upcoming, someday), project, area, tag, or status (open, completed, canceled, all).",
                properties: [
                    "list": enumProp(values: ["inbox", "today", "anytime", "upcoming", "someday"], description: "Filter by Things list"),
                    "projectUUID": stringProp("Filter by project UUID"),
                    "areaUUID": stringProp("Filter by area UUID"),
                    "tagName": stringProp("Filter by tag name"),
                    "status": enumProp(values: ["open", "completed", "canceled", "all"], description: "Filter by status (default: open)"),
                ],
                required: []
            ),

            tool(
                name: "get_todo",
                description: "Get a single to-do by its UUID, including checklist items, tags, and project/area info.",
                properties: [
                    "uuid": stringProp("The UUID of the to-do"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "search_todos",
                description: "Search to-dos by title or notes content.",
                properties: [
                    "query": stringProp("Search text to match against title and notes"),
                    "status": enumProp(values: ["open", "completed", "canceled", "all"], description: "Filter by status (default: open)"),
                ],
                required: ["query"]
            ),

            // Read - Projects
            tool(
                name: "get_projects",
                description: "List all projects from Things 3. Optionally filter by status.",
                properties: [
                    "status": enumProp(values: ["open", "completed", "canceled", "all"], description: "Filter by status (default: open)"),
                ],
                required: []
            ),

            tool(
                name: "get_project",
                description: "Get a single project by its UUID, including todo/completed counts.",
                properties: [
                    "uuid": stringProp("The UUID of the project"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "get_project_todos",
                description: "Get all to-dos belonging to a specific project.",
                properties: [
                    "projectUUID": stringProp("The UUID of the project"),
                    "includeCompleted": boolProp("Include completed to-dos (default: false)"),
                ],
                required: ["projectUUID"]
            ),

            // Read - Areas
            tool(
                name: "get_areas",
                description: "List all areas from Things 3.",
                properties: [:],
                required: []
            ),

            tool(
                name: "get_area",
                description: "Get a single area by its UUID.",
                properties: [
                    "uuid": stringProp("The UUID of the area"),
                ],
                required: ["uuid"]
            ),

            // Read - Tags
            tool(
                name: "get_tags",
                description: "List all tags from Things 3, including parent tag relationships.",
                properties: [:],
                required: []
            ),

            // Read - Headings
            tool(
                name: "get_headings",
                description: "List headings within a project.",
                properties: [
                    "projectUUID": stringProp("The UUID of the project"),
                ],
                required: ["projectUUID"]
            ),

            // Create
            tool(
                name: "create_todo",
                description: "Create a new to-do in Things 3.",
                properties: [
                    "title": stringProp("Title of the to-do"),
                    "notes": stringProp("Notes/description"),
                    "dueDate": stringProp("Due date (e.g., '2025-12-31')"),
                    "tags": arrayProp(itemDescription: "Tag name", description: "List of tag names to assign"),
                    "checklistItems": arrayProp(itemDescription: "Checklist item text", description: "List of checklist item titles"),
                    "projectUUID": stringProp("UUID of project to add to"),
                    "headingTitle": stringProp("Title of heading within project"),
                    "list": enumProp(values: ["inbox", "today", "anytime", "someday"], description: "Target list"),
                    "when": stringProp("When to schedule: 'today', 'evening', 'anytime', 'someday', or a date string"),
                ],
                required: ["title"]
            ),

            tool(
                name: "create_project",
                description: "Create a new project in Things 3.",
                properties: [
                    "title": stringProp("Title of the project"),
                    "notes": stringProp("Notes/description"),
                    "dueDate": stringProp("Due date"),
                    "tags": arrayProp(itemDescription: "Tag name", description: "List of tag names"),
                    "areaUUID": stringProp("UUID of area to assign to"),
                    "when": stringProp("When to schedule: 'today', 'anytime', 'someday', or a date string"),
                    "todos": arrayProp(itemDescription: "Todo title", description: "List of to-do titles to create within the project"),
                    "headings": arrayProp(itemDescription: "Heading title", description: "List of heading titles"),
                ],
                required: ["title"]
            ),

            tool(
                name: "create_area",
                description: "Create a new area in Things 3.",
                properties: [
                    "title": stringProp("Title of the area"),
                ],
                required: ["title"]
            ),

            tool(
                name: "create_tag",
                description: "Create a new tag in Things 3.",
                properties: [
                    "title": stringProp("Title of the tag"),
                    "shortcut": stringProp("Keyboard shortcut for the tag"),
                    "parentTagTitle": stringProp("Title of parent tag (for nested tags)"),
                ],
                required: ["title"]
            ),

            // Update
            tool(
                name: "update_todo",
                description: "Update an existing to-do in Things 3. Only specify fields you want to change.",
                properties: [
                    "uuid": stringProp("UUID of the to-do to update"),
                    "title": stringProp("New title"),
                    "notes": stringProp("New notes"),
                    "dueDate": stringProp("New due date (empty string to clear)"),
                    "tags": arrayProp(itemDescription: "Tag name", description: "Replace tags with these"),
                    "completed": boolProp("Mark as completed"),
                    "canceled": boolProp("Mark as canceled"),
                    "projectUUID": stringProp("Move to this project"),
                    "list": enumProp(values: ["inbox", "today", "anytime", "someday"], description: "Move to this list"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "update_project",
                description: "Update an existing project in Things 3. Only specify fields you want to change.",
                properties: [
                    "uuid": stringProp("UUID of the project to update"),
                    "title": stringProp("New title"),
                    "notes": stringProp("New notes"),
                    "dueDate": stringProp("New due date (empty string to clear)"),
                    "tags": arrayProp(itemDescription: "Tag name", description: "Replace tags with these"),
                    "completed": boolProp("Mark as completed"),
                    "canceled": boolProp("Mark as canceled"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "move_todo",
                description: "Move a to-do to a different project or list.",
                properties: [
                    "uuid": stringProp("UUID of the to-do to move"),
                    "projectUUID": stringProp("UUID of target project"),
                    "list": enumProp(values: ["inbox", "today", "anytime", "someday"], description: "Target list"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "complete_todo",
                description: "Mark a to-do as completed.",
                properties: [
                    "uuid": stringProp("UUID of the to-do"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "reopen_todo",
                description: "Reopen a completed or canceled to-do.",
                properties: [
                    "uuid": stringProp("UUID of the to-do"),
                ],
                required: ["uuid"]
            ),

            // Delete
            tool(
                name: "delete_todo",
                description: "Move a to-do to the trash in Things 3.",
                properties: [
                    "uuid": stringProp("UUID of the to-do to delete"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "delete_project",
                description: "Move a project to the trash in Things 3.",
                properties: [
                    "uuid": stringProp("UUID of the project to delete"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "delete_area",
                description: "Delete an area in Things 3.",
                properties: [
                    "uuid": stringProp("UUID of the area to delete"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "delete_tag",
                description: "Delete a tag in Things 3.",
                properties: [
                    "uuid": stringProp("UUID of the tag to delete"),
                ],
                required: ["uuid"]
            ),

            tool(
                name: "empty_trash",
                description: "Permanently delete all items in the Things 3 trash.",
                properties: [:],
                required: []
            ),
        ]
    }

    // MARK: - Schema Helpers

    private func tool(
        name: String,
        description: String,
        properties: [String: Value],
        required: [String]
    ) -> Tool {
        Tool(
            name: name,
            description: description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object(properties),
                "required": .array(required.map { .string($0) }),
            ])
        )
    }

    private func stringProp(_ description: String) -> Value {
        .object([
            "type": .string("string"),
            "description": .string(description),
        ])
    }

    private func boolProp(_ description: String) -> Value {
        .object([
            "type": .string("boolean"),
            "description": .string(description),
        ])
    }

    private func enumProp(values: [String], description: String) -> Value {
        .object([
            "type": .string("string"),
            "enum": .array(values.map { .string($0) }),
            "description": .string(description),
        ])
    }

    private func arrayProp(itemDescription: String, description: String) -> Value {
        .object([
            "type": .string("array"),
            "items": .object([
                "type": .string("string"),
                "description": .string(itemDescription),
            ]),
            "description": .string(description),
        ])
    }
}

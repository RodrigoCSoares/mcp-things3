# MCP Things 3

A [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) server for [Things 3](https://culturedcode.com/things/) on macOS. Gives AI assistants full read/write access to your tasks, projects, areas, and tags.

## Architecture

**Hybrid data strategy** — fast reads, safe writes:

- **Reads** go through the Things 3 SQLite database directly (fast, headless, rich data)
- **Writes** go through AppleScript via `osascript` (official API, won't corrupt Things Cloud sync)

Built with Swift 6.0, the [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) (v0.11.0), and stdio transport.

## Requirements

- macOS 14+
- Things 3 installed
- Swift 6.0+ toolchain

## Build

```bash
swift build -c release
```

The binary is at `.build/release/MCPThings3`.

## Configure

Add to your MCP client config (e.g. Claude Desktop, OpenCode):

```json
{
  "mcpServers": {
    "things3": {
      "command": "/path/to/MCPThings3"
    }
  }
}
```

## Tools (24)

### Read

| Tool | Description |
|------|-------------|
| `get_todos` | List todos — filter by list, project, area, tag, status |
| `get_todo` | Get a single todo by UUID with checklist items |
| `search_todos` | Full-text search across todo titles and notes |
| `get_projects` | List projects with todo counts |
| `get_project` | Get a single project by UUID |
| `get_areas` | List all areas with their tags |
| `get_area` | Get a single area by UUID |
| `get_tags` | List all tags |
| `get_headings` | List headings within a project |

### Write

| Tool | Description |
|------|-------------|
| `create_todo` | Create a todo with title, notes, tags, due date, list, project |
| `update_todo` | Update todo title, notes, tags, due date, status |
| `delete_todo` | Move a todo to trash |
| `complete_todo` | Mark a todo as completed |
| `reopen_todo` | Re-open a completed/canceled todo |
| `move_todo` | Move a todo to a different list or project |
| `create_project` | Create a project with optional child todos |
| `update_project` | Update project properties |
| `delete_project` | Move a project to trash |
| `create_area` | Create a new area |
| `delete_area` | Delete an area |
| `create_tag` | Create a tag with optional parent and keyboard shortcut |
| `delete_tag` | Delete a tag |
| `empty_trash` | Empty the Things 3 trash |
| `get_auth_token` | Get the URL scheme authentication token |

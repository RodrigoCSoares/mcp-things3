import Foundation

#if canImport(CSQLite3)
import CSQLite3
#else
typealias OpaquePointer = Swift.OpaquePointer
@_silgen_name("sqlite3_open_v2")
func sqlite3_open_v2(_ filename: UnsafePointer<CChar>?, _ ppDb: UnsafeMutablePointer<OpaquePointer?>?, _ flags: Int32, _ zVfs: UnsafePointer<CChar>?) -> Int32
@_silgen_name("sqlite3_close")
func sqlite3_close(_ db: OpaquePointer?) -> Int32
@_silgen_name("sqlite3_prepare_v2")
func sqlite3_prepare_v2(_ db: OpaquePointer?, _ zSql: UnsafePointer<CChar>?, _ nByte: Int32, _ ppStmt: UnsafeMutablePointer<OpaquePointer?>?, _ pzTail: UnsafeMutablePointer<UnsafePointer<CChar>?>?) -> Int32
@_silgen_name("sqlite3_step")
func sqlite3_step(_ stmt: OpaquePointer?) -> Int32
@_silgen_name("sqlite3_finalize")
func sqlite3_finalize(_ stmt: OpaquePointer?) -> Int32
@_silgen_name("sqlite3_column_count")
func sqlite3_column_count(_ stmt: OpaquePointer?) -> Int32
@_silgen_name("sqlite3_column_name")
func sqlite3_column_name(_ stmt: OpaquePointer?, _ N: Int32) -> UnsafePointer<CChar>?
@_silgen_name("sqlite3_column_type")
func sqlite3_column_type(_ stmt: OpaquePointer?, _ iCol: Int32) -> Int32
@_silgen_name("sqlite3_column_text")
func sqlite3_column_text(_ stmt: OpaquePointer?, _ iCol: Int32) -> UnsafePointer<UInt8>?
@_silgen_name("sqlite3_column_int64")
func sqlite3_column_int64(_ stmt: OpaquePointer?, _ iCol: Int32) -> Int64
@_silgen_name("sqlite3_column_double")
func sqlite3_column_double(_ stmt: OpaquePointer?, _ iCol: Int32) -> Double
@_silgen_name("sqlite3_errmsg")
func sqlite3_errmsg(_ db: OpaquePointer?) -> UnsafePointer<CChar>?
#endif

// SQLite constants
private let SQLITE_OK: Int32 = 0
private let SQLITE_ROW: Int32 = 100
private let SQLITE_DONE: Int32 = 101
private let SQLITE_OPEN_READONLY: Int32 = 0x00000001
private let SQLITE_INTEGER: Int32 = 1
private let SQLITE_FLOAT: Int32 = 2
private let SQLITE_TEXT: Int32 = 3
private let SQLITE_NULL: Int32 = 5

// MARK: - Things3 Core Reference Date

/// Things 3 stores dates as seconds since 2001-01-01 (Core Data / NSDate reference date).
private let coreDataReferenceDate: Date = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let components = DateComponents(year: 2001, month: 1, day: 1)
    return calendar.date(from: components)!
}()

private func coreDataTimestampToISO8601(_ timestamp: Double) -> String {
    let date = Date(timeInterval: timestamp, since: coreDataReferenceDate)
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.string(from: date)
}

/// Things 3 stores "when" dates as an integer: days since 2001-01-01.
private func thingsDateIntToISO8601(_ daysSinceRef: Int64) -> String {
    let seconds = Double(daysSinceRef) * 86400.0
    let date = Date(timeInterval: seconds, since: coreDataReferenceDate)
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.string(from: date)
}

// MARK: - Things3 Database Reader

/// Reads data from the Things 3 SQLite database. This is read-only;
/// writing to the database would corrupt Things Cloud sync.
final class Things3Database: Sendable {

    private let databasePath: String

    init() throws {
        guard let path = Things3Database.findDatabasePath() else {
            throw Things3Error.databaseNotFound
        }
        self.databasePath = path
    }

    // MARK: - Database Location

    static func findDatabasePath() -> String? {
        let groupContainer = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac")

        guard FileManager.default.fileExists(atPath: groupContainer.path) else {
            return nil
        }

        // Find the ThingsData-* directory
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: groupContainer,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        for url in contents {
            if url.lastPathComponent.hasPrefix("ThingsData-") {
                let dbPath = url
                    .appendingPathComponent("Things Database.thingsdatabase")
                    .appendingPathComponent("main.sqlite")
                if FileManager.default.fileExists(atPath: dbPath.path) {
                    return dbPath.path
                }
            }
        }
        return nil
    }

    // MARK: - Low-Level Query

    private func query(_ sql: String) throws -> [[String: Any]] {
        var db: OpaquePointer?
        let rc = sqlite3_open_v2(databasePath, &db, SQLITE_OPEN_READONLY, nil)
        guard rc == SQLITE_OK else {
            let msg = db.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "unknown"
            _ = sqlite3_close(db)
            throw Things3Error.databaseAccessFailed(msg)
        }
        defer { _ = sqlite3_close(db) }

        var stmt: OpaquePointer?
        let prepareRC = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        guard prepareRC == SQLITE_OK else {
            let msg = db.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "unknown"
            throw Things3Error.queryFailed(msg)
        }
        defer { _ = sqlite3_finalize(stmt) }

        var results: [[String: Any]] = []
        let columnCount = sqlite3_column_count(stmt)

        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any] = [:]
            for i in 0..<columnCount {
                guard let cName = sqlite3_column_name(stmt, i) else { continue }
                let name = String(cString: cName)
                let colType = sqlite3_column_type(stmt, i)

                switch colType {
                case SQLITE_INTEGER:
                    row[name] = sqlite3_column_int64(stmt, i)
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(stmt, i)
                case SQLITE_TEXT:
                    if let text = sqlite3_column_text(stmt, i) {
                        row[name] = String(cString: text)
                    }
                case SQLITE_NULL:
                    break
                default:
                    break
                }
            }
            results.append(row)
        }

        return results
    }

    // MARK: - ToDos

    func getTodos(filter: ListFilterInput? = nil) throws -> [Things3Todo] {
        var conditions: [String] = ["TASK.type = 0"]  // 0 = to-do (not project/heading)
        var statusFilter = "open"

        if let f = filter {
            statusFilter = f.status ?? "open"

            if let list = f.list {
                switch list.lowercased() {
                case "inbox":
                    conditions.append("TASK.start = 0")
                case "today":
                    conditions.append("TASK.start = 1")
                    conditions.append("TASK.startDate IS NOT NULL")
                case "anytime":
                    conditions.append("TASK.start = 1")
                case "upcoming":
                    conditions.append("TASK.start = 1")
                    conditions.append("TASK.startDate IS NOT NULL")
                    conditions.append("TASK.startDate > \(currentThingsDateInt())")
                case "someday":
                    conditions.append("TASK.start = 2")
                default:
                    break
                }
            }

            if let projectUUID = f.projectUUID {
                conditions.append("TASK.project = '\(sanitize(projectUUID))'")
            }

            if let areaUUID = f.areaUUID {
                conditions.append("(TASK.area = '\(sanitize(areaUUID))' OR PROJECT.area = '\(sanitize(areaUUID))')")
            }

            if let tagName = f.tagName {
                conditions.append("""
                    TASK.uuid IN (
                        SELECT tasks FROM TMTaskTag
                        INNER JOIN TMTag ON TMTaskTag.tags = TMTag.uuid
                        WHERE TMTag.title = '\(sanitize(tagName))'
                    )
                """)
            }
        }

        switch statusFilter {
        case "completed":
            conditions.append("TASK.status = 3")
        case "canceled":
            conditions.append("TASK.status = 2")
        case "all":
            break
        default: // "open"
            conditions.append("TASK.status = 0")
            conditions.append("TASK.trashed = 0")
            // Exclude todos whose parent project is completed, canceled, or trashed
            conditions.append("(TASK.project IS NULL OR (PROJECT.status = 0 AND PROJECT.trashed = 0))")
        }

        let whereClause = conditions.joined(separator: " AND ")

        let sql = """
            SELECT
                TASK.uuid,
                TASK.title,
                TASK.notes,
                TASK.status,
                TASK.creationDate,
                TASK.userModificationDate,
                TASK.stopDate,
                TASK.deadline,
                TASK.startDate,
                TASK.start,
                TASK.project,
                TASK.area,
                TASK.heading,
                PROJECT.title AS projectTitle,
                AREA.title AS areaTitle,
                HEADING.title AS headingTitle
            FROM TMTask AS TASK
            LEFT JOIN TMTask AS PROJECT ON TASK.project = PROJECT.uuid
            LEFT JOIN TMArea AS AREA ON TASK.area = AREA.uuid OR PROJECT.area = AREA.uuid
            LEFT JOIN TMTask AS HEADING ON TASK.heading = HEADING.uuid
            WHERE \(whereClause)
            ORDER BY TASK.todayIndex ASC, TASK.creationDate DESC
            LIMIT 500
        """

        let rows = try query(sql)
        return try rows.map { row in try buildTodo(from: row) }
    }

    func getTodo(uuid: String) throws -> Things3Todo {
        let sql = """
            SELECT
                TASK.uuid,
                TASK.title,
                TASK.notes,
                TASK.status,
                TASK.creationDate,
                TASK.userModificationDate,
                TASK.stopDate,
                TASK.deadline,
                TASK.startDate,
                TASK.start,
                TASK.project,
                TASK.area,
                TASK.heading,
                PROJECT.title AS projectTitle,
                AREA.title AS areaTitle,
                HEADING.title AS headingTitle
            FROM TMTask AS TASK
            LEFT JOIN TMTask AS PROJECT ON TASK.project = PROJECT.uuid
            LEFT JOIN TMArea AS AREA ON TASK.area = AREA.uuid OR PROJECT.area = AREA.uuid
            LEFT JOIN TMTask AS HEADING ON TASK.heading = HEADING.uuid
            WHERE TASK.uuid = '\(sanitize(uuid))'
        """

        let rows = try query(sql)
        guard let row = rows.first else {
            throw Things3Error.notFound("Todo with UUID \(uuid)")
        }
        return try buildTodo(from: row)
    }

    func searchTodos(query searchQuery: String, status: String? = nil) throws -> [Things3Todo] {
        var conditions: [String] = [
            "TASK.type = 0",
            "(TASK.title LIKE '%\(sanitize(searchQuery))%' OR TASK.notes LIKE '%\(sanitize(searchQuery))%')",
        ]

        switch status {
        case "completed":
            conditions.append("TASK.status = 3")
        case "canceled":
            conditions.append("TASK.status = 2")
        case "all":
            break
        default:
            conditions.append("TASK.status = 0")
            conditions.append("TASK.trashed = 0")
            conditions.append("(TASK.project IS NULL OR (PROJECT.status = 0 AND PROJECT.trashed = 0))")
        }

        let whereClause = conditions.joined(separator: " AND ")

        let sql = """
            SELECT
                TASK.uuid,
                TASK.title,
                TASK.notes,
                TASK.status,
                TASK.creationDate,
                TASK.userModificationDate,
                TASK.stopDate,
                TASK.deadline,
                TASK.startDate,
                TASK.start,
                TASK.project,
                TASK.area,
                TASK.heading,
                PROJECT.title AS projectTitle,
                AREA.title AS areaTitle,
                HEADING.title AS headingTitle
            FROM TMTask AS TASK
            LEFT JOIN TMTask AS PROJECT ON TASK.project = PROJECT.uuid
            LEFT JOIN TMArea AS AREA ON TASK.area = AREA.uuid OR PROJECT.area = AREA.uuid
            LEFT JOIN TMTask AS HEADING ON TASK.heading = HEADING.uuid
            WHERE \(whereClause)
            ORDER BY TASK.creationDate DESC
            LIMIT 200
        """

        let rows = try query(sql)
        return try rows.map { row in try buildTodo(from: row) }
    }

    // MARK: - Projects

    func getProjects(status: String? = nil) throws -> [Things3Project] {
        var conditions: [String] = ["TASK.type = 1"]  // 1 = project

        switch status {
        case "completed":
            conditions.append("TASK.status = 3")
        case "canceled":
            conditions.append("TASK.status = 2")
        case "all":
            break
        default:
            conditions.append("TASK.status = 0")
            conditions.append("TASK.trashed = 0")
        }

        let whereClause = conditions.joined(separator: " AND ")

        let sql = """
            SELECT
                TASK.uuid,
                TASK.title,
                TASK.notes,
                TASK.status,
                TASK.creationDate,
                TASK.userModificationDate,
                TASK.stopDate,
                TASK.deadline,
                TASK.startDate,
                TASK.area,
                AREA.title AS areaTitle,
                (SELECT COUNT(*) FROM TMTask WHERE project = TASK.uuid AND type = 0 AND status = 0 AND trashed = 0) AS todoCount,
                (SELECT COUNT(*) FROM TMTask WHERE project = TASK.uuid AND type = 0 AND status = 3) AS completedTodoCount
            FROM TMTask AS TASK
            LEFT JOIN TMArea AS AREA ON TASK.area = AREA.uuid
            WHERE \(whereClause)
            ORDER BY TASK.creationDate DESC
        """

        let rows = try query(sql)
        return rows.map { row in buildProject(from: row) }
    }

    func getProject(uuid: String) throws -> Things3Project {
        let sql = """
            SELECT
                TASK.uuid,
                TASK.title,
                TASK.notes,
                TASK.status,
                TASK.creationDate,
                TASK.userModificationDate,
                TASK.stopDate,
                TASK.deadline,
                TASK.startDate,
                TASK.area,
                AREA.title AS areaTitle,
                (SELECT COUNT(*) FROM TMTask WHERE project = TASK.uuid AND type = 0 AND status = 0 AND trashed = 0) AS todoCount,
                (SELECT COUNT(*) FROM TMTask WHERE project = TASK.uuid AND type = 0 AND status = 3) AS completedTodoCount
            FROM TMTask AS TASK
            LEFT JOIN TMArea AS AREA ON TASK.area = AREA.uuid
            WHERE TASK.uuid = '\(sanitize(uuid))' AND TASK.type = 1
        """

        let rows = try query(sql)
        guard let row = rows.first else {
            throw Things3Error.notFound("Project with UUID \(uuid)")
        }
        return buildProject(from: row)
    }

    // MARK: - Areas

    func getAreas() throws -> [Things3Area] {
        let sql = """
            SELECT
                AREA.uuid,
                AREA.title
            FROM TMArea AS AREA
            ORDER BY AREA.title ASC
        """

        let rows = try query(sql)
        return try rows.map { row in
            let uuid = row["uuid"] as? String ?? ""
            let tags = try getTagsForArea(uuid: uuid)
            return Things3Area(
                uuid: uuid,
                title: row["title"] as? String ?? "",
                tags: tags
            )
        }
    }

    func getArea(uuid: String) throws -> Things3Area {
        let sql = """
            SELECT uuid, title FROM TMArea WHERE uuid = '\(sanitize(uuid))'
        """
        let rows = try query(sql)
        guard let row = rows.first else {
            throw Things3Error.notFound("Area with UUID \(uuid)")
        }
        let tags = try getTagsForArea(uuid: uuid)
        return Things3Area(
            uuid: row["uuid"] as? String ?? "",
            title: row["title"] as? String ?? "",
            tags: tags
        )
    }

    // MARK: - Tags

    func getTags() throws -> [Things3Tag] {
        let sql = """
            SELECT
                TAG.uuid,
                TAG.title,
                TAG.shortcut,
                TAG.parent,
                PARENT.title AS parentTitle
            FROM TMTag AS TAG
            LEFT JOIN TMTag AS PARENT ON TAG.parent = PARENT.uuid
            ORDER BY TAG.title ASC
        """

        let rows = try query(sql)
        return rows.map { row in
            Things3Tag(
                uuid: row["uuid"] as? String ?? "",
                title: row["title"] as? String ?? "",
                shortcut: row["shortcut"] as? String,
                parentUUID: row["parent"] as? String,
                parentTitle: row["parentTitle"] as? String
            )
        }
    }

    // MARK: - Headings

    func getHeadings(projectUUID: String) throws -> [Things3Heading] {
        let sql = """
            SELECT
                TASK.uuid,
                TASK.title,
                TASK.project,
                PROJECT.title AS projectTitle
            FROM TMTask AS TASK
            LEFT JOIN TMTask AS PROJECT ON TASK.project = PROJECT.uuid
            WHERE TASK.type = 2 AND TASK.project = '\(sanitize(projectUUID))'
            ORDER BY TASK.todayIndex ASC
        """

        let rows = try query(sql)
        return rows.map { row in
            Things3Heading(
                uuid: row["uuid"] as? String ?? "",
                title: row["title"] as? String ?? "",
                projectUUID: row["project"] as? String ?? projectUUID,
                projectTitle: row["projectTitle"] as? String
            )
        }
    }

    // MARK: - URL Scheme Auth Token

    func getAuthToken() throws -> String? {
        let tokenSQL = "SELECT uriSchemeAuthenticationToken FROM TMSettings LIMIT 1"
        let tokenRows = try query(tokenSQL)
        return tokenRows.first?["uriSchemeAuthenticationToken"] as? String
    }

    // MARK: - Helpers

    private func getTagsForTask(uuid: String) throws -> [String] {
        let sql = """
            SELECT TMTag.title
            FROM TMTaskTag
            INNER JOIN TMTag ON TMTaskTag.tags = TMTag.uuid
            WHERE TMTaskTag.tasks = '\(sanitize(uuid))'
            ORDER BY TMTag.title ASC
        """
        let rows = try query(sql)
        return rows.compactMap { $0["title"] as? String }
    }

    private func getTagsForArea(uuid: String) throws -> [String] {
        let sql = """
            SELECT TMTag.title
            FROM TMAreaTag
            INNER JOIN TMTag ON TMAreaTag.tags = TMTag.uuid
            WHERE TMAreaTag.areas = '\(sanitize(uuid))'
            ORDER BY TMTag.title ASC
        """
        let rows = try query(sql)
        return rows.compactMap { $0["title"] as? String }
    }

    private func getChecklistItems(todoUUID: String) throws -> [Things3ChecklistItem] {
        let sql = """
            SELECT uuid, title, status
            FROM TMChecklistItem
            WHERE task = '\(sanitize(todoUUID))'
            ORDER BY `index` ASC
        """
        let rows = try query(sql)
        return rows.map { row in
            Things3ChecklistItem(
                uuid: row["uuid"] as? String ?? "",
                title: row["title"] as? String ?? "",
                isCompleted: (row["status"] as? Int64 ?? 0) == 3
            )
        }
    }

    private func buildTodo(from row: [String: Any]) throws -> Things3Todo {
        let uuid = row["uuid"] as? String ?? ""
        let statusInt = row["status"] as? Int64 ?? 0
        let status: String
        switch statusInt {
        case 2: status = "canceled"
        case 3: status = "completed"
        default: status = "open"
        }

        let tags = try getTagsForTask(uuid: uuid)
        let checklistItems = try getChecklistItems(todoUUID: uuid)

        let startValue = row["start"] as? Int64 ?? 0
        let list: String?
        switch startValue {
        case 0: list = "inbox"
        case 1: list = "anytime"
        case 2: list = "someday"
        default: list = nil
        }

        return Things3Todo(
            uuid: uuid,
            title: row["title"] as? String ?? "",
            notes: (row["notes"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            status: status,
            creationDate: (row["creationDate"] as? Double).map { coreDataTimestampToISO8601($0) },
            modificationDate: (row["userModificationDate"] as? Double).map { coreDataTimestampToISO8601($0) },
            completionDate: (row["stopDate"] as? Double).map {
                statusInt == 3 ? coreDataTimestampToISO8601($0) : nil
            } ?? nil,
            cancellationDate: (row["stopDate"] as? Double).map {
                statusInt == 2 ? coreDataTimestampToISO8601($0) : nil
            } ?? nil,
            dueDate: (row["deadline"] as? Int64).map { thingsDateIntToISO8601($0) },
            startDate: (row["startDate"] as? Int64).map { thingsDateIntToISO8601($0) },
            tags: tags,
            checklistItems: checklistItems,
            projectUUID: row["project"] as? String,
            projectTitle: row["projectTitle"] as? String,
            areaUUID: row["area"] as? String,
            areaTitle: row["areaTitle"] as? String,
            headingTitle: row["headingTitle"] as? String,
            isEvening: false,
            list: list
        )
    }

    private func buildProject(from row: [String: Any]) -> Things3Project {
        let uuid = row["uuid"] as? String ?? ""
        let statusInt = row["status"] as? Int64 ?? 0
        let status: String
        switch statusInt {
        case 2: status = "canceled"
        case 3: status = "completed"
        default: status = "open"
        }

        let tags = (try? getTagsForTask(uuid: uuid)) ?? []

        return Things3Project(
            uuid: uuid,
            title: row["title"] as? String ?? "",
            notes: (row["notes"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            status: status,
            creationDate: (row["creationDate"] as? Double).map { coreDataTimestampToISO8601($0) },
            modificationDate: (row["userModificationDate"] as? Double).map { coreDataTimestampToISO8601($0) },
            completionDate: (row["stopDate"] as? Double).map {
                statusInt == 3 ? coreDataTimestampToISO8601($0) : nil
            } ?? nil,
            dueDate: (row["deadline"] as? Int64).map { thingsDateIntToISO8601($0) },
            startDate: (row["startDate"] as? Int64).map { thingsDateIntToISO8601($0) },
            tags: tags,
            areaUUID: row["area"] as? String,
            areaTitle: row["areaTitle"] as? String,
            todoCount: Int(row["todoCount"] as? Int64 ?? 0),
            completedTodoCount: Int(row["completedTodoCount"] as? Int64 ?? 0)
        )
    }

    private func currentThingsDateInt() -> Int64 {
        let now = Date()
        let interval = now.timeIntervalSince(coreDataReferenceDate)
        return Int64(interval / 86400.0)
    }

    private func sanitize(_ input: String) -> String {
        input.replacingOccurrences(of: "'", with: "''")
    }
}

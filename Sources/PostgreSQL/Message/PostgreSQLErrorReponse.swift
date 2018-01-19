import Bits
import Debugging

/// First message sent from the frontend during startup.
struct PostgreSQLDiagnosticResponse: Decodable, Error {
    /// The diagnostic messages.
    var fields: [PostgreSQLDiagnosticType: String]

    /// See Decodable.init
    init(from decoder: Decoder) throws {
        fields = [:]
        let single = try decoder.singleValueContainer()
        parse: while true {
            let type = try single.decode(PostgreSQLDiagnosticType.self)
            switch type {
            case .end: break parse
            default:
                assert(fields[type] == nil)
                fields[type] = try single.decode(String.self)
            }
        }
    }
}

extension PostgreSQLDiagnosticResponse: Debuggable {
    /// See `Debuggable.readableName`
    static var readableName: String {
        return "PostgreSQL Diagnostic"
    }

    /// See `Debuggable.reason`
    var reason: String {
        return (fields[.localizedSeverity] ?? "ERROR") + ": " + (fields[.message] ?? "Unknown")
    }

    /// See `Debuggable.identifier`
    var identifier: String {
        return fields[.routine] ?? fields[.sqlState] ?? "unknown"
    }
}

extension PostgreSQLDiagnosticResponse: Helpable {
    /// See `Helpable.possibleCauses`
    var possibleCauses: [String] {
        var strings: [String] = []
        if let message = fields[.message] {
            strings.append(message)
        }
        return strings
    }

    /// See `Helpable.suggestedFixes`
    var suggestedFixes: [String] {
        var strings: [String] = []
        if let hint = fields[.hint] {
            strings.append(hint)
        }
        return strings
    }
}

enum PostgreSQLDiagnosticType: Byte, Decodable, Hashable {
    /// Severity: the field contents are ERROR, FATAL, or PANIC (in an error message),
    /// or WARNING, NOTICE, DEBUG, INFO, or LOG (in a notice message), or a
    //// localized translation of one of these. Always present.
    case localizedSeverity = 0x53 /// S
    /// Severity: the field contents are ERROR, FATAL, or PANIC (in an error message),
    /// or WARNING, NOTICE, DEBUG, INFO, or LOG (in a notice message).
    /// This is identical to the S field except that the contents are never localized.
    /// This is present only in messages generated by PostgreSQL versions 9.6 and later.
    case severity = 0x56 /// V
    /// Code: the SQLSTATE code for the error (see Appendix A). Not localizable. Always present.
    case sqlState = 0x43 /// C
    /// Message: the primary human-readable error message. This should be accurate but terse (typically one line).
    /// Always present.
    case message = 0x4D /// M
    /// Detail: an optional secondary error message carrying more detail about the problem.
    /// Might run to multiple lines.
    case detail = 0x44 /// D
    /// Hint: an optional suggestion what to do about the problem.
    /// This is intended to differ from Detail in that it offers advice (potentially inappropriate)
    /// rather than hard facts. Might run to multiple lines.
    case hint = 0x48 /// H
    /// Position: the field value is a decimal ASCII integer, indicating an error cursor
    /// position as an index into the original query string. The first character has index 1,
    /// and positions are measured in characters not bytes.
    case position = 0x50 /// P
    /// Internal position: this is defined the same as the P field, but it is used when the
    /// cursor position refers to an internally generated command rather than the one submitted by the client.
    /// The q field will always appear when this field appears.
    case internalPosition = 0x70 /// p
    /// Internal query: the text of a failed internally-generated command.
    /// This could be, for example, a SQL query issued by a PL/pgSQL function.
    case internalQuery = 0x71 /// q
    /// Where: an indication of the context in which the error occurred.
    /// Presently this includes a call stack traceback of active procedural language functions and
    /// internally-generated queries. The trace is one entry per line, most recent first.
    case locationContext = 0x57 /// W
    /// Schema name: if the error was associated with a specific database object, the name of
    /// the schema containing that object, if any.
    case schemaName = 0x73 /// s
    /// Table name: if the error was associated with a specific table, the name of the table.
    /// (Refer to the schema name field for the name of the table's schema.)
    case tableName = 0x74 /// t
    /// Column name: if the error was associated with a specific table column, the name of the column.
    /// (Refer to the schema and table name fields to identify the table.)
    case columnName = 0x63 /// c
    /// Data type name: if the error was associated with a specific data type, the name of the data type.
    /// (Refer to the schema name field for the name of the data type's schema.)
    case dataTypeName = 0x64 /// d
    /// Constraint name: if the error was associated with a specific constraint, the name of the constraint.
    /// Refer to fields listed above for the associated table or domain. (For this purpose, indexes are
    /// treated as constraints, even if they weren't created with constraint syntax.)
    case constraintName = 0x6E /// n
    /// File: the file name of the source-code location where the error was reported.
    case file = 0x46 /// F
    /// Line: the line number of the source-code location where the error was reported.
    case line = 0x4C /// L
    /// Routine: the name of the source-code routine reporting the error.
    case routine = 0x52 /// R
    /// No more types.
    case end = 0x00
}

import Foundation

/// What kind of issues For You recommends. Saved with `@AppStorage` through `rawValue`.
struct SuggestionFilter: Equatable, RawRepresentable {
    enum IssueLabel: String, CaseIterable, Identifiable {
        case goodFirstIssue = "good first issue"
        case helpWanted = "help wanted"
        case documentation
        case any = ""
        var id: Self { self }

        var name: String {
            switch self {
            case .goodFirstIssue: "Good first issue"
            case .helpWanted: "Help wanted"
            case .documentation: "Documentation"
            case .any: "Any label"
            }
        }

        var sectionTitle: String {
            switch self {
            case .goodFirstIssue: "Good First Issues"
            case .helpWanted: "Help Wanted"
            case .documentation: "Documentation Issues"
            case .any: "Open Issues"
            }
        }
    }

    static let dayChoices = [7, 30, 90, 365]
    static let commentChoices = [5, 10, 25]

    var label = IssueLabel.goodFirstIssue
    var days = 90
    var maxComments: Int? = 10 // nil = any number
    var unassignedOnly = true

    init() {}

    init(label: IssueLabel = .goodFirstIssue, days: Int = 90, maxComments: Int? = 10, unassignedOnly: Bool = true) {
        self.label = label
        self.days = days
        self.maxComments = maxComments
        self.unassignedOnly = unassignedOnly
    }

    /// "label|days|maxComments|unassigned", e.g. "good first issue|90|10|1". Hand-rolled: a
    /// RawRepresentable type that is also Codable recurses forever when encoded.
    init?(rawValue: String) {
        let parts = rawValue.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 4, let label = IssueLabel(rawValue: parts[0]), let days = Int(parts[1]) else { return nil }
        self.init(label: label, days: days, maxComments: Int(parts[2]), unassignedOnly: parts[3] == "1")
    }

    var rawValue: String {
        "\(label.rawValue)|\(days)|\(maxComments.map(String.init) ?? "")|\(unassignedOnly ? "1" : "0")"
    }

    var isDefault: Bool { self == SuggestionFilter() }

    /// Button text: "Filter", or what differs from the defaults, e.g. "Help wanted · Past week".
    var summary: String {
        var parts: [String] = []
        if label != .goodFirstIssue { parts.append(label.name) }
        if days != 90 { parts.append(Self.dayName(days)) }
        if maxComments != 10 { parts.append(maxComments.map { "<\($0) comments" } ?? "Any comments") }
        if !unassignedOnly { parts.append("Assigned too") }
        return parts.isEmpty ? "Filter" : parts.joined(separator: " · ")
    }

    static func dayName(_ days: Int) -> String {
        switch days {
        case 7: "Past week"
        case 30: "Past month"
        case 90: "Past 3 months"
        case 365: "Past year"
        default: "Past \(days) days"
        }
    }
}

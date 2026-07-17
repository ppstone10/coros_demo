import Foundation

struct LegalParagraph: Hashable {
    let text: String
    var highlights: [String] = []
    var isHeading: Bool = false
}

/// Parses headings and inline emphasis from the small Markdown subset used by Demo legal resources.
func parseLegalDocument(_ body: String) -> [LegalParagraph] {
    body.components(separatedBy: "\n\n").compactMap { raw in
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        let isHeading = value.hasPrefix("## ")
        let marked = isHeading ? String(value.dropFirst(3)) : value
        let components = marked.components(separatedBy: "**")
        let highlights = components.enumerated().compactMap { index, part in
            index.isMultiple(of: 2) || part.isEmpty ? nil : part
        }
        return LegalParagraph(
            text: components.joined(),
            highlights: highlights,
            isHeading: isHeading
        )
    }
}

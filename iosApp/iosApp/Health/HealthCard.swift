import Foundation
import Shared

struct HealthCard: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let isRisk: Bool
    let visual: HealthCardVisualData?

    init(id: String, title: String, summary: String, icon: String, isRisk: Bool, visual: HealthCardVisualData? = nil) {
        self.id = id; self.title = title; self.summary = summary; self.icon = icon; self.isRisk = isRisk; self.visual = visual
    }

    static func == (lhs: HealthCard, rhs: HealthCard) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

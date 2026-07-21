import Foundation

struct HealthCard: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let icon: String
    let isRisk: Bool
}

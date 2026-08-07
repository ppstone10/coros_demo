import Foundation

struct NormalEditOption: Decodable, Identifiable {
    let value: String
    let labelKey: String
    var id: String { value }
}

struct NormalEditField: Decodable, Identifiable {
    let id: String
    let labelKey: String
    let value: String
    let type: String
    let minimum: Double?
    let maximum: Double?
    let options: [NormalEditOption]
    let labelArguments: [String]
    let groupId: String?
    let rowIndex: Int?
}

struct NormalEditRepeatGroup: Decodable, Identifiable {
    let id: String
    let addLabelKey: String
    let itemLabelKey: String
    let minimumItems: Int
    let maximumItems: Int
}

struct NormalEditForm: Decodable {
    let section: String
    let titleKey: String
    let sourceKind: String
    let sourceMessageKey: String
    let fields: [NormalEditField]
    let repeatGroups: [NormalEditRepeatGroup]
}

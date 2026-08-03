import SwiftUI
import Shared

private struct NormalEditOption: Decodable, Identifiable {
    let value: String
    let labelKey: String
    var id: String { value }
}

private struct NormalEditField: Decodable, Identifiable {
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

private struct NormalEditRepeatGroup: Decodable, Identifiable {
    let id: String
    let addLabelKey: String
    let itemLabelKey: String
    let minimumItems: Int
    let maximumItems: Int
}

private struct NormalEditForm: Decodable {
    let section: String
    let titleKey: String
    let sourceKind: String
    let sourceMessageKey: String
    let fields: [NormalEditField]
    let repeatGroups: [NormalEditRepeatGroup]
}

struct NormalDataEditorOverview: View {
    @ObservedObject var viewModel: HealthDashboardViewModel
    let router: AuthRouter
    @State private var noticeTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.Health.page.ignoresSafeArea()
            VStack(spacing: 0) {
                editorHeader(
                    title: appLocalized("health_edit_normal_data"),
                    back: { router.pop() },
                    actionTitle: appLocalized("health_edit_use_defaults"),
                    action: { viewModel.restoreAllNormalDefaults() }
                )
                Text(appLocalized("health_edit_select_hint"))
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.Health.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.vertical, 12)
                if let sourceMessageKey, !sourceMessageKey.isEmpty {
                    sourceNotice(sourceMessageKey)
                }
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.editableSections, id: \.self) { section in
                            Button {
                                router.push(.normalDataSection(section: section))
                            } label: {
                                HStack {
                                    Text(sectionTitle(section))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(AppColors.Health.muted)
                                }
                                .padding(16)
                                .background(AppColors.Health.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.bottom, 24)
                }
            }
            if let notice = viewModel.editNotice {
                Text(appLocalized(notice.messageKey))
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color(.sRGB, white: 0.22, opacity: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(24)
                    .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.editNotice?.id) { id in
            noticeTask?.cancel()
            guard let id else { return }
            noticeTask = Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run { viewModel.clearEditNotice(id: id) }
            }
        }
        .onDisappear { noticeTask?.cancel() }
    }

    private func sectionTitle(_ section: String) -> String {
        guard
            let json = viewModel.normalEditFormJson(section),
            let data = json.data(using: .utf8),
            let form = try? JSONDecoder().decode(NormalEditForm.self, from: data)
        else { return section }
        return appLocalized(form.titleKey)
    }

    private var sourceMessageKey: String? {
        guard
            let section = viewModel.editableSections.first,
            let json = viewModel.normalEditFormJson(section),
            let data = json.data(using: .utf8),
            let form = try? JSONDecoder().decode(NormalEditForm.self, from: data)
        else { return nil }
        return form.sourceMessageKey
    }
}

struct NormalDataSectionEditor: View {
    let section: String
    @ObservedObject var viewModel: HealthDashboardViewModel
    let router: AuthRouter
    @State private var form: NormalEditForm?
    @State private var values: [String: String] = [:]
    @State private var error: String?
    @State private var selectedChoiceFieldID: String?

    var body: some View {
        ZStack {
            AppColors.Health.page.ignoresSafeArea()
            VStack(spacing: 0) {
                editorHeader(
                    title: form.map { appLocalized($0.titleKey) } ?? section,
                    back: { router.pop() },
                    actionTitle: appLocalized("common_save"),
                    action: save
                )
                if let form {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if !form.sourceMessageKey.isEmpty {
                                sourceNotice(form.sourceMessageKey)
                            }
                            Button {
                                loadDefaults()
                            } label: {
                                Text(appLocalized("health_edit_restore_card"))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(AppColors.Health.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)

                            if let error {
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColors.Health.warning)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            ForEach(form.fields.filter { $0.groupId == nil }) { field in
                                editField(field)
                            }
                            ForEach(form.repeatGroups) { group in
                                repeatGroupEditor(group, form: form)
                            }
                        }
                        .padding(.horizontal, AppSpacing.screen)
                        .padding(.vertical, 12)
                    }
                }
            }
            if
                let fieldID = selectedChoiceFieldID,
                let field = form?.fields.first(where: { $0.id == fieldID })
            {
                choiceSelectionOverlay(field)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: load)
    }

    @ViewBuilder
    private func editField(_ field: NormalEditField) -> some View {
        if field.type == "Choice" {
            Button {
                selectedChoiceFieldID = field.id
            } label: {
                HStack(spacing: 8) {
                    Text(localizedFieldLabel(field))
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.Health.muted)
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    Text(selectedOptionLabel(field))
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.Health.action)
                        .lineLimit(1)
                    Image(AppImages.Health.choiceChevron)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(AppColors.Health.action)
                        .frame(width: 14, height: 14)
                        .rotationEffect(.degrees(90))
                        .accessibilityHidden(true)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(AppColors.Health.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(localizedFieldLabel(field))
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.Health.muted)
                TextField("", text: valueBinding(field))
                    .keyboardType(field.type == "Integer" || field.type == "Decimal" ? .decimalPad : .default)
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.Health.muted.opacity(0.7), lineWidth: 1)
                    )
            }
            .padding(14)
            .background(AppColors.Health.card)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func repeatGroupEditor(_ group: NormalEditRepeatGroup, form: NormalEditForm) -> some View {
        let grouped = Dictionary(grouping: form.fields.filter { $0.groupId == group.id }) {
            $0.rowIndex ?? -1
        }
        let indices = grouped.keys.sorted()
        ForEach(indices, id: \.self) { rowIndex in
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(localized(group.itemLabelKey, arguments: ["\(rowIndex + 1)"]))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    if indices.count > group.minimumItems {
                        Button(appLocalized("health_edit_remove_item")) {
                            mutate(group, operation: "Remove", rowIndex: rowIndex)
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.Health.action)
                    }
                }
                ForEach(grouped[rowIndex] ?? []) { field in
                    editField(field)
                }
            }
            .padding(12)
            .background(AppColors.Health.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        Button {
            mutate(group, operation: "Add")
        } label: {
            Text("+ \(appLocalized(group.addLabelKey))")
                .foregroundStyle(
                    indices.count < group.maximumItems
                        ? AppColors.Health.addAction
                        : AppColors.Health.muted
                )
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(AppColors.Health.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(indices.count >= group.maximumItems)
    }

    private func choiceSelectionOverlay(_ field: NormalEditField) -> some View {
        ZStack {
            AppColors.Core.overlayMedium
                .ignoresSafeArea()
                .onTapGesture { selectedChoiceFieldID = nil }
            VStack(spacing: 0) {
                Text(localizedFieldLabel(field))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(field.options) { option in
                            Button {
                                values[field.id] = option.value
                                selectedChoiceFieldID = nil
                            } label: {
                                HStack {
                                    Text(appLocalized(option.labelKey))
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if values[field.id, default: field.value] == option.value {
                                        Image(AppImages.Health.choiceCheck)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(AppColors.Health.action)
                                            .frame(width: 18, height: 18)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 52)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 420)
                Button {
                    selectedChoiceFieldID = nil
                } label: {
                    Text(appLocalized("common_cancel"))
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.Health.action)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.plain)
            }
            .background(AppColors.Health.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 28)
        }
        .zIndex(10)
    }

    private func selectedOptionLabel(_ field: NormalEditField) -> String {
        let selected = values[field.id, default: field.value]
        guard let option = field.options.first(where: { $0.value == selected }) else { return "" }
        return appLocalized(option.labelKey)
    }

    private func localizedFieldLabel(_ field: NormalEditField) -> String {
        localized(field.labelKey, arguments: field.labelArguments)
    }

    private func localized(_ key: String, arguments: [String]) -> String {
        guard !arguments.isEmpty else { return appLocalized(key) }
        return String(format: appLocalized(key), arguments: arguments.map { $0 as CVarArg })
    }

    private func valueBinding(_ field: NormalEditField) -> Binding<String> {
        Binding(
            get: { values[field.id] ?? field.value },
            set: { values[field.id] = $0 }
        )
    }

    private func load() {
        guard
            let json = viewModel.normalEditFormJson(section),
            let data = json.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(NormalEditForm.self, from: data)
        else { return }
        form = decoded
        values = Dictionary(uniqueKeysWithValues: decoded.fields.map { ($0.id, $0.value) })
    }

    private func loadDefaults() {
        guard
            let json = viewModel.defaultNormalEditFormJson(section),
            let data = json.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(NormalEditForm.self, from: data)
        else { return }
        useForm(decoded)
    }

    private func useForm(_ next: NormalEditForm) {
        form = next
        values = Dictionary(uniqueKeysWithValues: next.fields.map { ($0.id, $0.value) })
        error = nil
    }

    private func encodedValues() -> String? {
        var components = URLComponents()
        components.queryItems = values.sorted(by: { $0.key < $1.key }).map {
            URLQueryItem(name: $0.key, value: $0.value)
        }
        return components.percentEncodedQuery
    }

    private func mutate(
        _ group: NormalEditRepeatGroup,
        operation: String,
        rowIndex: Int = -1
    ) {
        guard
            let spec = encodedValues(),
            let json = viewModel.mutateNormalEditFormJson(
                section,
                valuesSpec: spec,
                groupID: group.id,
                operation: operation,
                rowIndex: rowIndex
            ),
            let data = json.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(NormalEditForm.self, from: data)
        else { return }
        useForm(decoded)
    }

    private func save() {
        guard let spec = encodedValues() else {
            error = appLocalized("health_edit_invalid")
            return
        }
        let result = viewModel.saveNormalEditForm(section, valuesSpec: spec)
        guard result.success else {
            error = result.issue.map(validationMessage) ?? appLocalized("health_edit_invalid")
            return
        }
        router.pop()
    }

    private func validationMessage(_ issue: NormalEditValidationIssue) -> String {
        let label = localized(issue.labelKey, arguments: issue.labelArguments)
        let reasonKey: String
        switch issue.reason {
        case "Required": reasonKey = "health_edit_error_required"
        case "InvalidNumber": reasonKey = "health_edit_error_number"
        case "OutOfRange": reasonKey = "health_edit_error_range"
        case "InvalidChoice": reasonKey = "health_edit_error_choice"
        case "InvalidCount": reasonKey = "health_edit_error_count"
        default: reasonKey = "health_edit_error_inconsistent"
        }
        return localized(reasonKey, arguments: [label] + issue.reasonArguments)
    }
}

@ViewBuilder
private func sourceNotice(_ messageKey: String) -> some View {
    Text(appLocalized(messageKey))
        .font(.system(size: 13))
        .foregroundStyle(AppColors.Health.warning)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.Health.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, AppSpacing.screen)
}

@ViewBuilder
private func editorHeader(
    title: String,
    back: @escaping () -> Void,
    actionTitle: String,
    action: @escaping () -> Void
) -> some View {
    HStack {
        Button(action: back) {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 96, height: 44, alignment: .leading)
        }
        Text(title)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
        Button(actionTitle, action: action)
            .font(.system(size: 14))
            .foregroundStyle(AppColors.Health.action)
            .lineLimit(1)
            .frame(width: 96, height: 44, alignment: .trailing)
    }
    .padding(.horizontal, 8)
    .frame(height: 62)
}

#Preview("Normal data overview") {
    NormalDataEditorOverview(
        viewModel: HealthDashboardViewModel(
            previewState: HealthPreviewFixtures.shared.normalState()
        ),
        router: AuthRouter(
            push: { _ in },
            pop: {},
            replaceTop: { _ in },
            resetTo: { _ in },
            resetKeepingEntranceAndPush: { _ in }
        )
    )
    .preferredColorScheme(.dark)
}

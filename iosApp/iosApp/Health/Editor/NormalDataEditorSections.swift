import SwiftUI
import Shared

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

@ViewBuilder
func sourceNotice(_ messageKey: String) -> some View {
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
func editorHeader(
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

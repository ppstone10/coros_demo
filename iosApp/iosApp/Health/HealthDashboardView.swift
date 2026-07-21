import SwiftUI
import Shared
import Lottie

struct ScrollTopKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct HealthDashboardView: View {
    @Binding var isFullscreen: Bool
    @EnvironmentObject private var languageStore: AppLanguageStore
    @StateObject private var viewModel = HealthDashboardViewModel()
    @State private var editing = false
    @State private var detail: HealthCard?
    @State private var dragOffset: CGFloat = 0
    @State private var showScenarioPicker = false
    @State private var isAtScrollTop = true

    var body: some View {
        Group {
            if editing {
                HealthCardEditor(initial: viewModel.cards, onClose: closeEditor, onSave: saveCards)
            } else if let detail {
                HealthDetailView(card: detail) { self.detail = nil; isFullscreen = false }
            } else {
                dashboard
            }
        }
        .onChange(of: languageStore.current) { _, _ in detail = nil; isFullscreen = false; viewModel.load() }
        .background(AppColors.Core.black)
        .sheet(isPresented: $showScenarioPicker) { ScenarioPickerView(viewModel: viewModel) }
    }

    private var dashboard: some View {
        VStack(spacing: 0) {
            HeroTopRow(dateLabel: viewModel.dateLabel, isSyncing: viewModel.isLoading,
                       onLongPressWatch: { showScenarioPicker = true })
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        GeometryReader { geo in
                            AppColors.Core.clear.preference(key: ScrollTopKey.self,
                                value: geo.frame(in: .named("scrollSpace")).minY)
                        }.frame(height: 0)

                        HeroArcView(steps: viewModel.steps, calories: viewModel.calories,
                                    minutes: viewModel.activeMinutes).offset(y: max(0, dragOffset))

                        ForEach(viewModel.cards) { card in
                            Button {
                                detail = card; isFullscreen = true
                            } label: {
                                cardRow(card)
                            }.buttonStyle(.plain)
                                .padding(.horizontal, AppSpacing.screen)
                                .padding(.vertical, AppSpacing.xSmall)
                                .offset(y: max(0, dragOffset))
                        }

                        Button {
                            editing = true; isFullscreen = true
                        } label: {
                            Text(appLocalized("health_edit_cards"))
                                .font(.system(size: AppTypography.label))
                                .foregroundStyle(AppColors.Health.editText)
                                .padding(.horizontal, AppSpacing.actionHorizontal).padding(.vertical, AppSpacing.medium)
                                .background(AppColors.Health.card).clipShape(Capsule())
                        }.buttonStyle(.plain).padding(AppSpacing.large).offset(y: max(0, dragOffset))
                    }
                }
                .coordinateSpace(name: "scrollSpace").scrollIndicators(.hidden)
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { v in
                            let t = v.translation.height
                            if isAtScrollTop && t > 0 && !viewModel.isLoading { dragOffset = min(t * 0.4, 250) }
                        }
                        .onEnded { v in
                            if v.translation.height > 80 && !viewModel.isLoading {
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { dragOffset = 55 }
                                Task { await viewModel.refresh() }
                            } else {
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { dragOffset = 0 }
                            }
                        }
                )
                .onChange(of: viewModel.isLoading) { _, loading in
                    if !loading { withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) { dragOffset = 0 } }
                }

                if dragOffset > 10 || viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: AppColors.Health.steps)).scaleEffect(0.8)
                        Text(appLocalized("health_data_syncing")).font(.system(size: AppTypography.supporting)).foregroundColor(AppColors.Health.muted)
                    }.padding(.top, 6)
                }
            }
            .onPreferenceChange(ScrollTopKey.self) { isAtScrollTop = $0 >= 0 }
        }
        .ignoresSafeArea(edges: .top)
    }

    private func cardRow(_ card: HealthCard) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Image(card.icon).resizable().scaledToFit().frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(card.title).font(.system(size: AppTypography.cardTitle, weight: .medium)).foregroundStyle(.white)
                Text(card.summary).font(.system(size: AppTypography.supporting)).foregroundStyle(card.isRisk ? AppColors.Health.risk : AppColors.Health.muted).lineLimit(2)
            }
            Spacer(minLength: 8)
            Text("›").font(.system(size: 25, weight: .light)).foregroundStyle(AppColors.Health.chevron)
        }
        .padding(.horizontal, AppSpacing.cardContent)
        .frame(maxWidth: .infinity, minHeight: 76)
        .background(AppColors.Health.card).clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func closeEditor() { editing = false; isFullscreen = false }
    private func saveCards(_ value: [HealthCard]) {
        viewModel.saveCardConfiguration(value.map { $0.id })
        viewModel.load(); closeEditor()
    }
}

#Preview {
    HealthDashboardView(isFullscreen: .constant(false))
        .environmentObject(AppLanguageStore.shared)
}

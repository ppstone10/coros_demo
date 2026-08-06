import SwiftUI
import Shared

enum AuthRoute: Hashable {
    case entrance
    case login
    case phoneRegister
    case emailRegister
    case verifyCode(account: String, targetKind: VerifyTargetKind)
    case passwordSetup(targetKind: VerifyTargetKind)
    case forgotPassword
    case resetPassword(account: String)
    case privacyPolicy
    case serviceTerms
    case profileCompletion
    case signedIn
    case healthDetail(cardID: String)
    case healthEditor
    case normalDataEditor
    case normalDataSection(section: String)
    case profileEdit
}

struct AuthRouter {
    let push: (AuthRoute) -> Void
    let pop: () -> Void
    let replaceTop: (AuthRoute) -> Void
    let resetTo: (AuthRoute) -> Void
    let resetKeepingEntranceAndPush: (AuthRoute) -> Void

    static func create(path: Binding<NavigationPath>) -> AuthRouter {
        AuthRouter(
            push: { path.wrappedValue.append($0) },
            pop: { path.wrappedValue.removeLast() },
            replaceTop: {
                path.wrappedValue.removeLast()
                path.wrappedValue.append($0)
            },
            resetTo: {
                path.wrappedValue = NavigationPath()
                path.wrappedValue.append($0)
            },
            resetKeepingEntranceAndPush: { route in
                path.wrappedValue = NavigationPath()
                path.wrappedValue.append(AuthRoute.entrance)
                path.wrappedValue.append(route)
            }
        )
    }
}

struct AuthCoordinator: View {
    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var healthViewModel = HealthDashboardViewModel()
    @State private var path = NavigationPath()
    @Environment(\.scenePhase) private var scenePhase

    private var router: AuthRouter {
        AuthRouter.create(path: $path)
    }

    private var startRoute: AuthRoute {
        let state = viewModel.state
        if state.isLoggedIn && state.currentSession?.isProfileComplete == true {
            return .signedIn
        }
        if state.isLoggedIn && state.currentSession != nil { return .profileCompletion }
        return .entrance
    }

    var body: some View {
        ZStack {
            AppColors.Core.black.ignoresSafeArea()

            NavigationStack(path: $path) {
                rootView
                    .navigationDestination(for: AuthRoute.self) { route in
                        switch route {
                        case .entrance:
                            EntranceView(viewModel: viewModel, router: router)
                                .navigationBarBackButtonHidden(true)
                        case .login:
                            LoginPageView(viewModel: viewModel, router: router)
                                .navigationBarBackButtonHidden(true)
                        case .phoneRegister:
                            PhoneRegisterView(viewModel: viewModel, router: router)
                                .navigationBarBackButtonHidden(true)
                        case .emailRegister:
                            EmailRegisterView(viewModel: viewModel, router: router)
                                .navigationBarBackButtonHidden(true)
                        case let .verifyCode(account, targetKind):
                            VerifyCodeView(account: account, targetKind: targetKind, viewModel: viewModel, router: router)
                                .navigationBarBackButtonHidden(true)
                        case let .passwordSetup(targetKind):
                            PasswordSetupView(targetKind: targetKind, viewModel: viewModel, router: router)
                                .navigationBarBackButtonHidden(true)
                        case .forgotPassword:
                            ForgotPasswordView(viewModel: viewModel, router: router)
                                .navigationBarBackButtonHidden(true)
                        case let .resetPassword(account):
                            ResetPasswordView(account: account, viewModel: viewModel, router: router)
                                .navigationBarBackButtonHidden(true)
                        case .privacyPolicy:
                            PrivacyPolicyView(router: router)
                                .navigationBarBackButtonHidden(true)
                        case .serviceTerms:
                            ServiceTermsView(router: router)
                                .navigationBarBackButtonHidden(true)
                        case .profileCompletion:
                            ProfileCompletionView(viewModel: viewModel, router: router)
                                .navigationBarBackButtonHidden(true)
                        case .signedIn:
                            SignedInView(
                                viewModel: viewModel,
                                healthViewModel: healthViewModel,
                                router: router
                            )
                                .navigationBarBackButtonHidden(true)
                        case .healthDetail, .healthEditor, .normalDataEditor, .normalDataSection:
                            healthDestination(route, healthViewModel: healthViewModel, router: router)
                        case .profileEdit:
                            PersonalProfileEditView(viewModel: viewModel) {
                                router.pop()
                            }
                            .navigationBarBackButtonHidden(true)
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
        .overlay(SnackbarView(
            message: viewModel.toastMessage ?? "",
            isPresented: Binding(
                get: { viewModel.toastMessage != nil },
                set: { if !$0 { viewModel.toastMessage = nil } }
            )
        ))
        .alert(
            appLocalized("auth_error_session_expired_elsewhere"),
            isPresented: Binding(
                get: { viewModel.kickedDialogShown },
                set: { _ in }
            )
        ) {
            Button(appLocalized("common_confirm")) {
                viewModel.confirmKickedDialogTapped()
            }
        }
        .task {
            // MSRV-019：前台周期性会话校验，被顶即弹窗（弹窗显示期间暂停）。
            // 注意：不要在闭包里捕获 scenePhase（.task 创建时快照，启动瞬间可能非 active 导致永不检查）。
            while !Task.isCancelled {
                if viewModel.state.isLoggedIn && !viewModel.kickedDialogShown {
                    viewModel.checkSessionOnForeground()
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
        .onChange(of: viewModel.effectTrigger) { _ in
            guard let effect = viewModel.consumeEffect() else { return }
            handleNavigation(effect, viewModel: viewModel, healthViewModel: healthViewModel, router: router)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                viewModel.pauseSession()
            } else if phase == .active {
                viewModel.resumeSession()
                // MSRV-019：回前台立即检查一次，被顶即弹窗
                viewModel.checkSessionOnForeground()
            }
        }
        .onAppear {
            viewModel.handleInitialEffectIfNeeded()
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch startRoute {
        case .signedIn:
            SignedInView(
                viewModel: viewModel,
                healthViewModel: healthViewModel,
                router: router
            )
        case .profileCompletion:
            ProfileCompletionView(viewModel: viewModel, router: router)
        default:
            EntranceView(viewModel: viewModel, router: router)
        }
    }
}

@MainActor
private func handleNavigation(_ effect: LoginEffect, viewModel: LoginViewModel, healthViewModel: HealthDashboardViewModel, router: AuthRouter) {
    switch effect {
    case let effect as LoginEffectAuthSucceeded:
        healthViewModel.staleForNewAccount(shouldRefreshOnDashboard: true)
        let destination: AuthRoute = effect.isNextRouteSignedIn ? .signedIn : .profileCompletion
        router.resetTo(destination)
        viewModel.toastMessage = appLocalized(effect.mode == .register_ ? "auth_register_success" : "auth_login_success")
        // MSRV-015：登录/切换账号后用服务器头像覆盖内部目录当前头像
        ProfileImageStore.refreshFromServer(avatarUri: effect.session.profile?.avatarUri)
    case _ as LoginEffectNavigateHome:
        router.resetTo(.signedIn)
        viewModel.toastMessage = appLocalized("auth_login_success")
    case _ as LoginEffectProfileSaved:
        router.resetTo(.signedIn)
        viewModel.toastMessage = appLocalized("profile_saved")
    case _ as LoginEffectLoggedOut:
        healthViewModel.staleForNewAccount(shouldRefreshOnDashboard: false)
        router.resetTo(.entrance)
        viewModel.toastMessage = appLocalized("account_logout_success")
    case _ as LoginEffectAccountDeleted:
        router.resetTo(.entrance)
        viewModel.toastMessage = appLocalized("account_delete_success")
    case _ as LoginEffectSessionExpired:
        router.resetKeepingEntranceAndPush(.login)
        viewModel.toastMessage = appLocalized("auth_session_expired")
    case _ as LoginEffectSessionKicked:
        // MSRV-019：被顶弹窗已提示，确认后静默回登录页
        router.resetKeepingEntranceAndPush(.login)
    case let effect as LoginEffectShowMessage:
        viewModel.toastMessage = effect.message
    default:
        break
    }
}

#Preview("Authentication coordinator") {
    AuthCoordinator()
        .environmentObject(AppLanguageStore.shared)
        .preferredColorScheme(.dark)
}

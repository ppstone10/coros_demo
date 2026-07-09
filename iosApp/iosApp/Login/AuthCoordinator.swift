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
    @State private var path = NavigationPath()

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
            Color.black.ignoresSafeArea()

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
                            SignedInView(viewModel: viewModel, router: router)
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
        .onChange(of: viewModel.effectTrigger) { _ in
            guard let effect = viewModel.consumeEffect() else { return }
            handleNavigation(effect, viewModel: viewModel, router: router)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch startRoute {
        case .signedIn:
            SignedInView(viewModel: viewModel, router: router)
        case .profileCompletion:
            ProfileCompletionView(viewModel: viewModel, router: router)
        default:
            EntranceView(viewModel: viewModel, router: router)
        }
    }
}

@MainActor
private func handleNavigation(_ effect: LoginEffect, viewModel: LoginViewModel, router: AuthRouter) {
    switch effect {
    case let effect as LoginEffectAuthSucceeded:
        if effect.mode == AuthMode.register_ {
            viewModel.clearSessionSilently()
            router.resetKeepingEntranceAndPush(.login)
            viewModel.toastMessage = "注册成功"
        } else {
            let destination: AuthRoute = effect.session.isProfileComplete ? .signedIn : .profileCompletion
            router.resetTo(destination)
            viewModel.toastMessage = "登录成功"
        }
    case _ as LoginEffectNavigateHome:
        router.resetTo(.signedIn)
        viewModel.toastMessage = "登录成功"
    case _ as LoginEffectProfileSaved:
        router.resetTo(.signedIn)
        viewModel.toastMessage = "资料已保存"
    case _ as LoginEffectLoggedOut:
        router.resetTo(.entrance)
        viewModel.toastMessage = "已退出登录"
    case _ as LoginEffectAccountDeleted:
        router.resetTo(.entrance)
        viewModel.toastMessage = "账户已注销"
    case _ as LoginEffectSessionExpired:
        router.resetKeepingEntranceAndPush(.login)
        viewModel.toastMessage = "会话已失效，请重新登录"
    case let effect as LoginEffectShowMessage:
        viewModel.toastMessage = effect.message
    default:
        break
    }
}

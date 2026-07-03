import SwiftUI
import Shared

enum AuthRoute: Hashable {
    case entrance
    case login
    case phoneRegister
    case emailRegister
    case verifyCode(account: String, targetKind: VerifyTargetKind)
    case passwordSetup
    case privacyPolicy
    case serviceTerms
    case signedIn
}

struct AuthCoordinator: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var path = NavigationPath()

    private var startRoute: AuthRoute {
        let state = viewModel.state
        if state.isLoggedIn && state.currentSession != nil {
            return .signedIn
        }
        return .entrance
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NavigationStack(path: $path) {
                EntranceView(viewModel: viewModel, path: $path)
                    .navigationDestination(for: AuthRoute.self) { route in
                        switch route {
                        case .entrance:
                            EntranceView(viewModel: viewModel, path: $path)
                                .navigationBarBackButtonHidden(true)
                        case .login:
                            LoginPageView(viewModel: viewModel, path: $path)
                                .navigationBarBackButtonHidden(true)
                        case .phoneRegister:
                            PhoneRegisterView(viewModel: viewModel, path: $path)
                                .navigationBarBackButtonHidden(true)
                        case .emailRegister:
                            EmailRegisterView(viewModel: viewModel, path: $path)
                                .navigationBarBackButtonHidden(true)
                        case let .verifyCode(account, targetKind):
                            VerifyCodeView(account: account, targetKind: targetKind, viewModel: viewModel, path: $path)
                                .navigationBarBackButtonHidden(true)
                        case .passwordSetup:
                            PasswordSetupView(viewModel: viewModel, path: $path)
                                .navigationBarBackButtonHidden(true)
                        case .privacyPolicy:
                            PrivacyPolicyView(path: $path)
                                .navigationBarBackButtonHidden(true)
                        case .serviceTerms:
                            ServiceTermsView(path: $path)
                                .navigationBarBackButtonHidden(true)
                        case .signedIn:
                            SignedInView(viewModel: viewModel, path: $path)
                                .navigationBarBackButtonHidden(true)
                        }
                    }
            }
        }
        .alert(
            "提示",
            isPresented: Binding(
                get: { viewModel.toastMessage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.toastMessage = nil }
                }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.toastMessage ?? "") }
        )
        .onAppear {
            if startRoute != .entrance {
                path.append(startRoute)
            } else {
                path.append(AuthRoute.entrance)
            }
        }
        .onChange(of: viewModel.effectTrigger) { _ in
            guard let effect = viewModel.consumeEffect() else { return }
            handleNavigation(effect, viewModel: viewModel, path: $path)
        }
    }
}

@MainActor
private func handleNavigation(_ effect: LoginEffect, viewModel: LoginViewModel, path: Binding<NavigationPath>) {
    switch effect {
    case let effect as LoginEffectAuthSucceeded:
        if effect.mode == AuthMode.register_ {
            viewModel.clearSessionSilently()
            path.wrappedValue = NavigationPath()
            path.wrappedValue.append(AuthRoute.login)
            viewModel.toastMessage = "注册成功"
        } else {
            path.wrappedValue = NavigationPath()
            path.wrappedValue.append(AuthRoute.signedIn)
            viewModel.toastMessage = "登录成功"
        }
    case _ as LoginEffectNavigateHome:
        path.wrappedValue = NavigationPath()
        path.wrappedValue.append(AuthRoute.signedIn)
        viewModel.toastMessage = "登录成功"
    case _ as LoginEffectLoggedOut:
        path.wrappedValue = NavigationPath()
        path.wrappedValue.append(AuthRoute.entrance)
        viewModel.toastMessage = "已退出登录"
    case _ as LoginEffectSessionExpired:
        path.wrappedValue.append(AuthRoute.login)
        viewModel.toastMessage = "会话已失效，请重新登录"
    case let effect as LoginEffectShowMessage:
        viewModel.toastMessage = effect.message
    default:
        break
    }
}

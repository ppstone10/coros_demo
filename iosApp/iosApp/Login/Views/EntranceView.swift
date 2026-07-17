import SwiftUI

struct EntranceView: View {
    @ObservedObject var viewModel: LoginViewModel
    @EnvironmentObject private var languageStore: AppLanguageStore
    let router: AuthRouter

    var body: some View {
        let _ = languageStore.current

        ZStack {
            AppColors.Auth.entranceBackground.ignoresSafeArea()
            LoopingVideoBackground(videoName: "home").ignoresSafeArea()

            EntranceTopBar()
                .padding(.top, 8)
                .frame(maxHeight: .infinity, alignment: .top)

            VStack(spacing: 20) {
                CorosFilledButton(text: appLocalized("auth_register"), color: corosRed, action: {
                    viewModel.requestRegisterMode()
                    router.push(.phoneRegister)
                })
                CorosFilledButton(text: appLocalized("auth_login"), color: AppColors.Auth.buttonOverlay, action: {
                    viewModel.requestLoginMode()
                    router.push(.login)
                })
            }
            .padding(.horizontal, 20).padding(.bottom, 36)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

private struct EntranceTopBar: View {
    var body: some View {
        ZStack {
            CorosLogo()
            HStack {
                Spacer()
                LanguageSelectionButton()
                    .padding(.trailing, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
    }
}

import SwiftUI

struct EntranceView: View {
    @ObservedObject var viewModel: LoginViewModel
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255).ignoresSafeArea()
            LoopingVideoBackground(videoName: "home").ignoresSafeArea()

            CorosLogo().padding(.top, 62).frame(maxHeight: .infinity, alignment: .top)

            VStack(spacing: 20) {
                CorosFilledButton(text: "注册", color: corosRed, action: {
                    viewModel.requestRegisterMode()
                    path.append(AuthRoute.phoneRegister)
                })
                CorosFilledButton(text: "登录", color: Color.white.opacity(0.26), action: {
                    viewModel.requestLoginMode()
                    path.append(AuthRoute.login)
                })
            }
            .padding(.horizontal, 20).padding(.bottom, 60)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

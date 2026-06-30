import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            Text("登录")
                .font(.largeTitle.bold())

            Text("请输入账号完成登录")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("用户名", text: usernameBinding)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("密码", text: passwordBinding)
                .textFieldStyle(.roundedBorder)

            if let errorMessage = viewModel.state.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button(action: viewModel.submit) {
                HStack {
                    Spacer()
                    Text(viewModel.state.isLoading ? "登录中" : "登录")
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.state.canSubmit)

            Spacer()
        }
        .padding(24)
        .alert(
            "提示",
            isPresented: Binding(
                get: { viewModel.toastMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.toastMessage = nil
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(viewModel.toastMessage ?? "")
            }
        )
    }

    private var usernameBinding: Binding<String> {
        Binding(
            get: { viewModel.state.username },
            set: viewModel.updateUsername
        )
    }

    private var passwordBinding: Binding<String> {
        Binding(
            get: { viewModel.state.password },
            set: viewModel.updatePassword
        )
    }
}

#Preview {
    LoginView()
}

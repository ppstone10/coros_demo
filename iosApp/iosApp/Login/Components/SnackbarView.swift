import SwiftUI

struct SnackbarView: View {
    let message: String
    @Binding var isPresented: Bool
    @State private var dismissTask: DispatchWorkItem?

    var body: some View {
        VStack {
            Spacer()
            if isPresented {
                HStack {
                    Text(localizedAuthMessage(message) ?? message)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    Spacer()
                }
                .padding(16)
                .background(AppColors.Core.snackbar)
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    let task = DispatchWorkItem {
                        isPresented = false
                    }
                    dismissTask = task
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: task)
                }
                .onDisappear {
                    dismissTask?.cancel()
                    dismissTask = nil
                }
            }
        }
        .animation(.spring(response: 0.35), value: isPresented)
    }
}

#Preview {
    SnackbarView(message: "这是一个示例提示消息", isPresented: .constant(true))
        .preferredColorScheme(.dark)
}

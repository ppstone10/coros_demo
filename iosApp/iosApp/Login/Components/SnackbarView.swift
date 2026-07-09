import SwiftUI

struct SnackbarView: View {
    let message: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Spacer()
            if isPresented {
                HStack {
                    Text(message)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                    Spacer()
                }
                .padding(16)
                .background(Color.black.opacity(0.85))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { isPresented = false }
                    }
                }
            }
        }
        .animation(.spring(response: 0.35), value: isPresented)
    }
}

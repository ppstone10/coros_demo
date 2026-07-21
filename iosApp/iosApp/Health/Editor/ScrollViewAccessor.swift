import SwiftUI

struct ScrollViewAccessor: UIViewRepresentable {
    let onResolve: (UIScrollView) -> Void
    func makeUIView(context: Context) -> UIView { let v = UIView(); resolve(from: v); return v }
    func updateUIView(_ uiView: UIView, context: Context) { resolve(from: uiView) }
    private func resolve(from view: UIView) {
        DispatchQueue.main.async {
            var a = view.superview
            while let c = a { if let sv = findScrollView(in: c, excluding: view) { onResolve(sv); return }; a = c.superview }
        }
    }
    private func findScrollView(in view: UIView, excluding marker: UIView) -> UIScrollView? {
        if view !== marker, let sv = view as? UIScrollView { return sv }
        for sub in view.subviews where sub !== marker { if let sv = findScrollView(in: sub, excluding: marker) { return sv } }
        return nil
    }
}

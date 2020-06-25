import SwiftUI

struct ProcessingOverlay<Content: View>: View {

  private let content: Content
  private let isProcessing: Bool

  init(isProcessing: Bool, @ViewBuilder content: () -> Content) {
    self.isProcessing = isProcessing
    self.content = content()
  }

  var body: some View {
    ZStack {
      content
      ZStack {
        Color(white: 0, opacity: 0.001)
        FloatingProcessingView()
      }
      .opacity(isProcessing ? 1 : 0)
      .animation(.easeInOut)
    }
  }

}

struct FloatingProcessingView: View {

  var body: some View {
    ActivityIndicator(
      isAnimating: true,
      style: UIActivityIndicatorView.Style.large
    )
      .padding(32)
      .background(
        Color.init(white: 0.7, opacity: 0.7)
          .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
    )
  }

}

struct ActivityIndicator: UIViewRepresentable {

  let isAnimating: Bool
  let style: UIActivityIndicatorView.Style

  func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
    return UIActivityIndicatorView(style: style)
  }

  func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
    isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
  }
}


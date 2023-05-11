//
//  ContentView.swift
//  StoreReaderDemo
//
//  Created by Muukii on 2023/05/11.
//

import SwiftUI
import SwiftUIHosting
import Verge

struct ContentView: View {
  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundColor(.accentColor)
      Text("Hello, world!")
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

enum Preview_StoreReader: PreviewProvider {

  static var previews: some View {

    Group {

      ViewHosting().previewDisplayName("ViewHosting")

    }

  }

  struct ViewHosting: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
      _View()
    }

    func updateUIView(_ uiView: UIView, context: Context) {

    }
  }

  struct BindingView: View {

    @Binding var value: String

    init(value: Binding<String>) {
      self._value = value
    }

    var body: some View {
      VStack {
        Text(value)
        Button("Up") {
          value += "A"
        }
      }
    }
  }

  final class _View: UIView {

    init() {
      super.init(frame: .null)

      @UIState var value: String = "BBB"

      let view = SwiftUIHostingView {
        StoreReader($value) { valueProxy in
          BindingView(
            value: valueProxy.binding(\.self)
          )
        }
      }

      addSubview(view)
      view.frame = bounds
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

  }
}

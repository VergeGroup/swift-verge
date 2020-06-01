
import Foundation
import SwiftUI
import FetchImage

public protocol NetworkImage {

  var url: URL { get }
}

public struct AnyNetworkImage: NetworkImage {

  public var url: URL

  public init(_ base: NetworkImage) {
    self.url = base.url
  }

  public init(_ url: URL) {
    self.url = url
  }

  public static var empty: Self {
    AnyNetworkImage(URL(string: "about:blank")!)
  }
}

public struct NetworkImageView: View {

  @ObservedObject var image: FetchImage

  public init(_ image: NetworkImage) {
    self.image = .init(url: image.url)
  }

  public var body: some View {
    ZStack {
      Rectangle().fill(Color.gray)
      image.view?
        .resizable()
        .aspectRatio(contentMode: .fill)
    }

      // (Optional) Animate image appearance
      .animation(.default)

      // (Optional) Cancel and restart requests during scrolling
      .onAppear(perform: image.fetch)
      .onDisappear(perform: image.cancel)
  }
}

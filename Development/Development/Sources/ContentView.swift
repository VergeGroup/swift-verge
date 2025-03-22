import SwiftUI

public struct ContentView: View {
  public init() {}

  public var body: some View {
    NavigationStack {

      List {

        NavigationLink {
          BookReading()
        } label: {
          Text("@Reading")
        }

        NavigationLink {
          PassedContainer()
        } label: {
          Text("@Reading - passed")
        }
        
        NavigationLink {
          StoreReaderSolution()
        } label: {
          Text("StoreReader")
        }
      }

    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

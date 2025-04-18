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
        
        NavigationLink {
          BookLongList()
        } label: {
          Text("Long List")
        }
        
        NavigationLink {
          BookBindingUsingReading()
        } label: {
          Text("Binding @Reading")
        }
        
        NavigationLink {
          BookBindingUsingStoreReader()
        } label: {
          Text("Binding StoreReader")
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

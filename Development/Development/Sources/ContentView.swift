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

        
      }
      
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

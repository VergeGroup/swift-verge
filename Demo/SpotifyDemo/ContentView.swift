
import SwiftUI

import SpotifyService

struct ContentView: View {
    
  @State private var isConnecting = false
  
  var body: some View {
    VStack {
      Text("Hello, World!")
      Button(action: {
        self.isConnecting = true
      }) {
        Text("Connect with Spotify")
      }
    }
    .sheet(isPresented: $isConnecting) {
      SafariView(url: Auth.authorization())
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}


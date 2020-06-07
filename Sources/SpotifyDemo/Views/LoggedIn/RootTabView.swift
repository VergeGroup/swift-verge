import SwiftUI
import SpotifyService

struct RootTabView: View {

  let stack: LoggedInStack

  var body: some View {

    TabView {
      HomeView(stack: stack)
        .tag(1)
        .tabItem {
          Text("Home")
      }
      SearchView()
        .tag(2)
        .tabItem {
          Text("Search")
      }
      YourLibraryView(stack: stack)
        .tag(3)
        .tabItem {
          Text("Your Library")
      }
    }
  }

}

import SwiftUI

struct RootTabView: View {

  var body: some View {

    TabView {
      HomeView()
        .tag(1)
        .tabItem {
          Text("Home")
      }
      SearchView()
        .tag(2)
        .tabItem {
          Text("Search")
      }
      YourLibraryView()
        .tag(3)
        .tabItem {
          Text("Your Library")
      }
    }
  }

}

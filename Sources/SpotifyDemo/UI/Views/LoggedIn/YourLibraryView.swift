import SwiftUI
import VergeStore
import SpotifyService

struct YourLibraryView: View {

  let stack: LoggedInStack

  var body: some View {
    MePlaylistView(stack: stack)
      .onAppear {
        self.stack.service.fetchMePlaylist()
    }
  }
}

struct MePlaylistView: View {

  let stack: LoggedInStack

  var body: some View {

    UseState(

      stack.derivedState,

      MemoizeMap.map { state in
        state.db.entities.playlist.find(in: state.db.indexes.playlistIndex)
      }
      .dropsInput { $0.noChanges(\.db.indexes.playlistIndex) }

    ) { playlists in

      List {
        ForEach(playlists.root, id: \.entityID) { (f) in
          Text(f.name)
            .onAppear {
              print(f.name)
          }
        }
      }

    }
  }
}

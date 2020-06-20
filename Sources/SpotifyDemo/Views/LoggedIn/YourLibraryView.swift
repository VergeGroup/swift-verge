import SwiftUI
import VergeStore
import SpotifyService
import SpotifyUIKit

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
        ForEach(playlists.root, id: \.entityID) { (item) in
          HStack {

            NetworkImageView(item.images.first ?? AnyNetworkImage.empty)
              .frame(width: 60, height: 60)
              .aspectRatio(1, contentMode: .fill)
              .mask(Circle())

            Text(item.name)
              .onAppear {
                print(item.name)
            }
          }
        }
      }

    }
  }
}

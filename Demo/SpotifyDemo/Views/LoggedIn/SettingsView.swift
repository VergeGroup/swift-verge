
import Foundation
import SwiftUI
import SpotifyUIKit
import SpotifyService
import VergeStore

struct SettingsView: View {

  let stack: LoggedInStack

  var body: some View {
    UseState(stack.derivedState, .map(\.computed.me)) { me in
      ScrollView {
        SettingsViewComponent.profileCell(name: me.displayName, image: me.images.first)
        Button(action: {
          _ = self.stack.logout()
        }) {
          Text("Logout")
        }
      }
    }
  }
}


import Foundation
import SwiftUI
import SpotifyUIKit
import SpotifyService
import Verge

struct SettingsView: View {

  let stack: LoggedInStack

  var body: some View {
    StateReader(stack.derivedState.chain(.map(\.computed.me))).content { me in
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

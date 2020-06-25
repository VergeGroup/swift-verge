
import Foundation

import SwiftUI

public enum SettingsViewComponent {

  public static func profileCell(name: String, image: NetworkImage?) -> some View {

    HStack {
      NetworkImageView(image ?? AnyNetworkImage.empty)
        .frame(width: 60, height: 60)
        .aspectRatio(1, contentMode: .fill)
        .mask(Circle())
      VStack(alignment: .leading) {
        Text(name)
          .font(.system(size: 20, weight: .bold, design: .default))
        Text("View Profile")
          .font(.system(size: 14, weight: .regular, design: .default))
      }
    }
  }

  public enum Preview_ProfileCell: PreviewProvider {

    public static var previews: some View {
      Group {
        profileCell(
          name: "Hiroshi Kimura",
          image: AnyNetworkImage(URL(string: "https://avatars3.githubusercontent.com/u/1888355?s=460&u=867fc6ac562c54e5cffda269766804f2572bddc2&v=4")!)
        )
      }
    }
  }
}

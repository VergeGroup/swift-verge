
import Foundation

public enum Auth {
  
  public struct AuthCode {
    let raw: String
  }
  
  public static let callBackURI = "verge-spotify://callback"
  
  public static func authorization() -> URL {
    
    var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
    components.queryItems = [
      .init(name: "client_id", value: Secret.clientID),
      .init(name: "response_type", value: "code"),
      .init(name: "redirect_uri", value: callBackURI),
      .init(name: "scope", value: ["user-top-read", "playlist-read-private"].joined(separator: " "))
    ]

    return components.url!
  }
  
  public static func parseCallback(url: URL) -> AuthCode? {
    
    let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
    let code = components?.queryItems?.first { $0.name == "code" }?.value
    return code.map(AuthCode.init(raw: ))
  }
}

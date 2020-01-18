//
//  Requests.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

enum Auth {
  
  struct AuthCode {
    let raw: String
  }
  
  static let callBackURI = "verge-spotify://callback"
  
  static func authorization() -> URL {
    
    var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
    components.queryItems = [
      .init(name: "client_id", value: Secret.clientID),
      .init(name: "response_type", value: "code"),
      .init(name: "redirect_uri", value: callBackURI)
    ]

    return components.url!
  }
  
  static func parseCallback(url: URL) -> AuthCode? {
    
    let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
    let code = components?.queryItems?.first { $0.name == "code" }?.value
    return code.map(AuthCode.init(raw: ))
  }
}

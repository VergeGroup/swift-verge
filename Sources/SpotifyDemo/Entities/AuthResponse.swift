//
//  AuthResponse.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/19.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import JAYSON

struct AuthResponse: Decodable {
  
  let accessToken: String
  let tokenType: String
  let expiresIn: Int
  let refreshToken: String
  let scope: String

  init(from json: JSON) throws {
    self.accessToken = try json.next("access_token").getString()
    self.tokenType = try json.next("token_type").getString()
    self.expiresIn = try json.next("expires_in").getInt()
    self.refreshToken = try json.next("refresh_token").getString()
    self.scope = try json.next("scope").getString()
  }
}

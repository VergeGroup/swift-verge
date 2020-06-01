
import Foundation
import JAYSON

public struct AuthResponse: Decodable, Equatable {
  
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

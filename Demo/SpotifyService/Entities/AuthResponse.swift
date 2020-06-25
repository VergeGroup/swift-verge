
import Foundation
import JAYSON

public struct AuthResponse: Decodable, Equatable {

  var accessToken: String
  var tokenType: String
  var expiresIn: Int
  let refreshToken: String
  var scope: String

  init(from json: JSON) throws {
    self.accessToken = try json.next("access_token").getString()
    self.tokenType = try json.next("token_type").getString()
    self.expiresIn = try json.next("expires_in").getInt()
    self.refreshToken = try json.next("refresh_token").getString()
    self.scope = try json.next("scope").getString()
  }

  mutating func update(refreshTokenResponse json: JSON) throws {
    self.accessToken = try json.next("access_token").getString()
    self.tokenType = try json.next("token_type").getString()
    self.expiresIn = try json.next("expires_in").getInt()
    self.scope = try json.next("scope").getString()
  }

  init(accessToken: String, tokenType: String, expiresIn: Int, refreshToken: String, scope: String) {
    self.accessToken = accessToken
    self.tokenType = tokenType
    self.expiresIn = expiresIn
    self.refreshToken = refreshToken
    self.scope = scope
  }
  
}

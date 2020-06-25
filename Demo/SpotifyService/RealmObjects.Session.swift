
import Foundation
import RealmSwift

extension RealmObjects {

  @objc(RealmObjects_Session)
  public final class Session: RealmSwift.Object, SingleRecordType {

    public override class func primaryKey() -> String? {
      return "uniqueID"
    }

    @objc dynamic public var uniqueID: String = Session.uniqueIDValue

    @objc dynamic
    var authAccessToken: String?

    @objc dynamic
    var authTokenType: String?

    let authExpiresIn: RealmOptional<Int> = .init()

    @objc dynamic
    var authRefreshToken: String?

    @objc dynamic
    var authScope: String?

    func update(with auth: AuthResponse) {
      authAccessToken = auth.accessToken
      authExpiresIn.value = auth.expiresIn
      authScope = auth.scope
      authRefreshToken = auth.refreshToken
      authTokenType = auth.tokenType
    }

    func composeAuthResponse() throws -> AuthResponse {
      return .init(
        accessToken: try authAccessToken.unwrap(),
        tokenType: try authTokenType.unwrap(),
        expiresIn: try authExpiresIn.value.unwrap(),
        refreshToken: try authRefreshToken.unwrap(),
        scope: try authScope.unwrap()
      )
    }

  }

}


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

  }

}

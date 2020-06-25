
import Foundation
import Moya
import Combine
import CombineExt

extension MoyaProvider {

  func requestPublisher(_ target: Target) -> AnyPublisher<Response, MoyaError> {
    return .init { (s) in
      let cancellable = self.request(target) { (result) in
        switch result {
        case .success(let response):
          do {
            let response = try response.filterSuccessfulStatusAndRedirectCodes()
            s.send(response)
          } catch let error as MoyaError {
            s.send(completion: .failure(error))
          } catch {
            assertionFailure()
          }
        case .failure(let error):
          s.send(completion: .failure(error))
        }
      }
      return AnyCancellable {
        cancellable.cancel()
      }
    }
  }

}

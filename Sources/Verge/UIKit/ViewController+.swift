
import UIKit

fileprivate var _lifecycle: Void?

public protocol ViewControllerHarmonized: StoreType {}

extension UIViewController {
  
  final class _Associated {
    
    
    
    deinit {
      
    }
  }
  
  @MainActor
  fileprivate var associated: _Associated {
    get {
      if let created = objc_getAssociatedObject(self, &_lifecycle) as? _Associated {
        return created
      }
      
      let newInstance = _Associated()
      
      objc_setAssociatedObject(self, &_lifecycle, newInstance, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      
      return newInstance
    }
  }
  
  static func replaceMethods() {
    
    method_exchangeImplementations(
      class_getInstanceMethod(self, #selector(UIViewController.viewDidLoad))!,
      class_getInstanceMethod(self, #selector(UIViewController.org_verge_viewDidLoad))!
    )
  
  }
  
  @objc dynamic fileprivate func org_verge_viewDidLoad() {
    self.org_verge_viewDidLoad()
  }
}

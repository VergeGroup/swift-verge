import UIKit

open class DemoUIView: UIView {
  
  public init() {
    super.init(frame: .zero)
  }
  
  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

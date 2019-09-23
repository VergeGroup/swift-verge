//
//  IndicatorView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI

struct IndicatorView : UIViewRepresentable {
  
  @Binding var isAnimating: Bool
  
  func makeUIView(context: UIViewRepresentableContext<IndicatorView>) -> UIActivityIndicatorView {
    let view = UIActivityIndicatorView()
    return view
  }
  
  func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<IndicatorView>) {
    if isAnimating {
      uiView.startAnimating()
    } else {
      uiView.stopAnimating()
    }
  }
}

#if DEBUG
struct IndicatorView_Previews : PreviewProvider {
  static var previews: some View {
    IndicatorView(isAnimating: .constant(true))
  }
}
#endif

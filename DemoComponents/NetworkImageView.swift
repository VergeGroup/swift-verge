//
//  NetworkImageView.swift
//  SwiftUIPairs
//
//  Created by Hiroshi Kimura on 2019/06/05.
//  Copyright © 2019 eure. All rights reserved.
//

import SwiftUI
import Combine
import Nuke

struct NetworkImageView : SwiftUI.View {
  
  @State var image: UIImage? = nil
  @State var hasError: Bool = false
  
  private let url: URL
  
  init(url: URL) {
    self.url = url
  }
  
  var body: AnyView {
    
    if self.hasError {
      return AnyView(Color.init(white: 0.9))
    } else {
      if image == nil {
       return AnyView(ZStack {
          Color.init(white: 0.9)
          IndicatorView(isAnimating: .constant(true))
            .onAppear {
              ImagePipeline.shared.loadImage(with: self.url, progress: nil) { (result) in
                switch result {
                case .success(let image):
                  self.image = image.image
                case .failure(_):
                  self.hasError = true
                }
              }
          }
        })
      } else {
        return AnyView(Image(uiImage: image!)
          .resizable(capInsets: .init(), resizingMode: .stretch)
          .aspectRatio(contentMode: .fill)
        )
      }
    }
    
  }
}

//
//  NetworkImageView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/19.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class ImageDownloader {
  
  enum Error : Swift.Error {
    case failed
  }
  
  private let url: URL
  
  init(url: URL) {
    self.url = url
    print("Init \(self)")
  }
  
  deinit {
    print("Deinit \(self)")
  }
  
  func download(completion: @escaping (Result<UIImage, Error>) -> Void) {
    
    print("StartDownload")
    
    let delay: TimeInterval
    #if DEBUG
    delay = 1
    #else
    delay = 0
    #endif
    
    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
      
      // TODO: Currently, using most easy way.
      
      do {
        let data = try Data(contentsOf: self.url)
        guard let image = UIImage(data: data, scale: UIScreen.main.scale) else {
          DispatchQueue.main.async {
            completion(.failure(.failed))
          }
          return
        }
        DispatchQueue.main.async {
          completion(.success(image))
        }
      } catch {
        DispatchQueue.main.async {
          completion(.failure(.failed))
        }
      }
      
    }
    
  }
  
}

struct NetworkImageView : View {
  
  let downloader: ImageDownloader
  @State var image: UIImage? = nil
  @State var hasError: Bool = false
  
  init(url: URL) {
    // It's not best practice.
    self.downloader = ImageDownloader(url: url)
  }
  
  var body: some View {
    
    ZStack {
      if self.hasError {
        Color.init(white: 0.9)
      } else {
        if image == nil {
          Color.init(white: 0.9)
          IndicatorView(isAnimating: .constant(true))
            .onAppear {
              self.downloader.download { (r) in
                switch r {
                case .success(let image):
                  self.image = image
                case .failure(_):
                  self.hasError = true
                }
              }
          }
        } else {
          Image(uiImage: image!)
            .resizable()
            .aspectRatio(contentMode: .fill)
        }
      }
    }
    
  }
}

#if DEBUG
struct NetworkImageView_Previews : PreviewProvider {
  static var previews: some View {
    NetworkImageView(url: URL(string: "https://images.unsplash.com/photo-1558981408-db0ecd8a1ee4?ixlib=rb-1.2.1&auto=format&fit=crop&w=2734&q=80")!)
      .frame(width: 100, height: 100, alignment: .center)
  }
}
#endif

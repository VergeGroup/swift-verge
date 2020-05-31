//
//  SafariView.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
  
  typealias UIViewControllerType = SFSafariViewController
  
  let url: URL
  
  init(url: URL) {
    self.url = url
  }
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
    SFSafariViewController(url: url)
  }
  
  func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    
  }
  
}


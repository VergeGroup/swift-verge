//
//  Service.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import Combine
import CoreStore

/// To simulate using SDK
final class Service {
  
  let coreStore = CoreStore.defaultStack
    
  init() {
    
  }
  
  func fetchPhoto() -> Future<Void, Never> {
    
    return .init { promise in
      self.coreStore.perform(asynchronous: { (t: AsynchronousDataTransaction) -> Void in
        
        DynamicFeedPost.imageURLs.forEach { url in
          let post = t.create(Into<DynamicFeedPost>())
          post.rawID .= UUID().uuidString
          post.updatedAt .= Date()
          post.imageURLString .= url.absoluteString
        }
        
      }) { (r) in
        promise(.success(()))
      }
    }
            
  }
 
  
  func addComment(body: String, target post: DynamicFeedPost) -> Future<Void, Never> {
    return .init { promise in
                  
      self.coreStore.perform(asynchronous: { (t: AsynchronousDataTransaction) -> Void in
        let comment = t.create(Into<DynamicFeedPostComment>())
        let post = t.edit(post)!
        comment.rawID .= UUID().uuidString
        comment.updatedAt .= Date()
        comment.post .= post
        comment.body .= body
      }) { (r) in
        promise(.success(()))
      }

    }
  }
}

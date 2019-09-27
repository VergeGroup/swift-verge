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
  
  @Published var me: Me = .init()
    
  init() {
    
  }
  
  func fetchPhoto() -> Future<[SnapshotFeedPost.ID], Error> {
    
    return .init { promise in
      self.coreStore.perform(asynchronous: { (t: AsynchronousDataTransaction) -> [SnapshotFeedPost.ID] in
        
        let posts = DynamicFeedPost.imageURLs.map { url -> DynamicFeedPost in
          let post = t.create(Into<DynamicFeedPost>())
          post.rawID .= UUID().uuidString
          post.updatedAt .= Date()
          post.imageURLString .= url.absoluteString
          return post
        }
        
        return posts.map { $0.snapshotID }
        
      }) { (r) in
        switch r {
        case .success(let ids):
          promise(.success(ids))
        case .failure(let error):
          promise(.failure(error))
        }
      }
    }
            
  }
 
  
  func addComment(body: String, target post: SnapshotFeedPost) -> Future<Void, Never> {
    return .init { promise in
      
      self.coreStore.perform(asynchronous: { (t: AsynchronousDataTransaction) -> Void in
        
          for _ in 0..<10000 {
            
            let post = t.edit(Into<DynamicFeedPost>(), post.managedObjectID)!
            
            let comment = t.create(Into<DynamicFeedPostComment>())
            comment.rawID .= UUID().uuidString
            comment.updatedAt .= Date()
            comment.post .= post
            comment.body .= body
          }
          
      }) { (r) in
        promise(.success(()))
      }

    }
  }
}

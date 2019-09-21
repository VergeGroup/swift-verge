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

final class Service {
  
  let coreStore = CoreStore.defaultStack
    
  init() {
    
  }
  
  func createIssue(title: String, body: String) -> Future<Void, Never> {
    return .init { promise in
            
      self.coreStore.perform(asynchronous: { (t: AsynchronousDataTransaction) -> Void in
        let issue = t.create(Into<Issue>())
        issue.rawID .= UUID().uuidString
        issue.updatedAt .= Date()
        issue.title .= title
        issue.body .= body
      }) { (r) in
        promise(.success(()))
      }            
    }
    
  }
  
  func addComment(body: String, target issue: Issue) -> Future<Void, Never> {
    return .init { promise in
                  
      self.coreStore.perform(asynchronous: { (t: AsynchronousDataTransaction) -> Void in
        let comment = t.create(Into<Comment>())
        let issue = t.edit(issue)!
        comment.rawID .= UUID().uuidString
        comment.updatedAt .= Date()
        comment.issue .= issue
        comment.body .= body
      }) { (r) in
        promise(.success(()))
      }

    }
  }
}

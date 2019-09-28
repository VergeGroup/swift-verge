//
//  SessionReducer.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/19.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import Combine

import VergeNeue

final class SessionStateReducer: ReducerType {
  typealias State = SessionState
  private var subscriptions = Set<AnyCancellable>()
  
  private let queue = DispatchQueue.global(qos: .default)
  
  let service: MockService
  
  init(service: MockService) {
    self.service = service
  }
  
  func makeInitialState() -> SessionState {
    .init(env: service.env)
  }
  
  func increment() -> Mutation {
    return .init {
      $0.count += 1
    }
  }
  
  func fetchPhotos() -> Action<Void> {
    return .init { context in
      
      self.service.fetchPhotosPage1()
        .sink(receiveCompletion: { (completion) in
          
        }) { (photos) in
          
          context.commit { _ in
            .init { state in
              // normalize
              photos.forEach {
                state.photosStorage[$0.id] = $0
              }
              state.photosIdForHome = photos.map { $0.id }
            }
          }
      }
      .store(in: &self.subscriptions)
      
    }
  }
  
  func addNotification(body: String) -> Action<Void> {
    .init { context in
      
      self.queue.async {
        let n = Notification(body: body)
        
        context.commit { _ in
          .init { state in
            state.notificationStorage[n.id] = n
            state.notificationIds.append(n.id)
          }
        }
      }
      
    }
  }
  
  func addManyNotification() -> Action<Void> {
    .init { context in
      
      self.queue.async {
        
        context.commit { _ in
          .init { state in
            
            for _ in 0..<1000 {
              let n = Notification(body: Date().description)
              state.notificationStorage[n.id] = n
              state.notificationIds.append(n.id)
            }
          }
        }
      }
      
    }
  }
  
  func submitComment(body: String, photoID: Photo.ID) -> Action<Void> {
    return .init { context in
      
      let comment = Comment(photoID: photoID, body: body)
      context.commit { _ in
        .init {
          $0.commentsStorage[comment.id] = comment
        }
      }
      
    }
  }
}

//
//  Views.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import FlatStore
import CoreStore

import VergeNeue

extension Issue: Swift.Identifiable {
  public var id: String {
    rawID.value
  }
}

extension Comment: Swift.Identifiable {
  public var id: String {
    rawID.value
  }
}

struct IssueListState {
  
  var displayItems: [Issue] = []
  
}

final class IssueListReducer: ReducerType {
  typealias TargetState = IssueListState
  
  private let service: Service
  private var subscriptions = Set<AnyCancellable>()
  
  init(service: Service) {
    self.service = service
  }
  
  func addNewIssue() -> Action<Void> {
    .init { context in
      self.service
        .createIssue(title: "\(Date().description)", body: "AAA")
        .sink {
          context.commit { $0.reloadItems() }
      }
      .store(in: &self.subscriptions)
    }
  }
  
  /// In real-world, it's bad practice. We should use observing data-store.
  /// For example, if using CoreData, use NSFetchedResultsController
  private func reloadItems() -> Mutation {
    return .init {
      let objects = try! self.service.coreStore.fetchAll(From<Issue>())
      $0.displayItems = objects
    }
  }
  
}

let __store = Store(
  state: IssueListState(),
  reducer: IssueListReducer(service: AppContainer.service)
)

var detailStores: [Issue : Store<IssueDetailReducer>] = [:]

func makeDetailStore(for issue: Issue) -> Store<IssueDetailReducer> {
  guard detailStores[issue] == nil else {
    return detailStores[issue]!
  }
  let store = Store<IssueDetailReducer>.init(state: .init(), reducer: .init(service: AppContainer.service, issue: issue))
  detailStores[issue] = store
  return store
}

struct IssueListView: View {
  
  @ObservedObject var store = __store
  
  var body: some View {
    NavigationView {
      List {
        ForEach(store.state.displayItems) { ref in
          NavigationLink(destination: IssueDetailView(issue: ref, store: makeDetailStore(for: ref))) {
            issueCell(issue: ref)
          }
          .onDisappear {
            
          }
        }
      }
      .navigationBarTitle("Issues")
      .navigationBarItems(trailing: HStack {
        Button(action: {
          self.store.dispatch { $0.addNewIssue() }
        }) {
          Text("Add")
        }
      })
    }
    
  }
}

fileprivate func issueCell(issue: Issue) -> some View {
  VStack {
    Text(issue.title.value ?? "Null")
  }
}

// MARK: - IssueDetail

struct IssueDetailState {
  
  var issueTitle: String = ""
  var displayItems: [Comment] = []
}

final class IssueDetailReducer: ReducerType {
  
  typealias TargetState = IssueDetailState
  
  private var subscriptions = Set<AnyCancellable>()

  let service: Service
  
  let issue: Issue
  
  init(service: Service, issue: Issue) {
    self.service = service
    self.issue = issue
  }
  
  func addNewComment() -> Action<Void> {
    .init { context in
      
      self.service.addComment(body: "\(Date().description)", target: self.issue)
        .sink { _ in
          context.commit { $0.reloadComments() }
      }
      .store(in: &self.subscriptions)
      
    }
  }
  
  private func reloadComments() -> Mutation {
    return .init { s in
      
      let comments = try! self.service.coreStore.fetchAll(From<Comment>().where(\.issue == self.issue))
      s.displayItems = comments
                
    }
  }
}

struct IssueDetailView: View {
  
  let issue: Issue
  
  @ObservedObject var store: Store<IssueDetailReducer>
  
  var body: some View {
    VStack {
      Text("")
      List {
        ForEach(store.state.displayItems) { item in
          Text("\(item.body.value!)")
        }
      }
    }
    .navigationBarTitle("Comments")
    .navigationBarItems(trailing: HStack {
      Button(action: {
        self.store.dispatch { $0.addNewComment() }
      }) {
        Text("Add")
      }
    })
  }
}

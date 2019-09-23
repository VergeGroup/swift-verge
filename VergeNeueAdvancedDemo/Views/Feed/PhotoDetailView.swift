//
//  PhotoDetailView.swift
//  Verge
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI
import VergeNeue
import CoreStore

struct PhotoDetailView: View {
  
  @ObservedObject var store: Store<PhotoDetailReducer>
  
  var body: some View {
    VStack {
      List {
        ForEach(comments) { item in
          Text("\(item.body.value!)")
        }
      }
    }
    .navigationBarTitle("Comments")
    .navigationBarItems(trailing: HStack {
      Button(action: {
        self.store.dispatch { $0.addNewComment(target: self.post) }
      }) {
        Text("Add")
      }
    })
  }
}

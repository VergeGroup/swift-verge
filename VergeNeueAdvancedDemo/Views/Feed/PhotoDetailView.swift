//
//  PhotoDetailView.swift
//  Verge
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI
import VergeStore
import CoreStore

struct PhotoDetailView: View {
  
  @ObservedObject var store: PhotoDetailStore
  
  var body: some View {
    
    VStack {
      List {
        ForEach(store.state.comments) { item in
          Text("\(item.body.value!)")
        }
      }
    }
    .navigationBarTitle("Comments")
    .navigationBarItems(trailing: HStack {
      Button(action: {
        self.store.addAnyComment()        
      }) {
        Text("Add")
      }
    })
  }
}

//
//  PhotoDetailView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/19.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import SwiftUI

struct PhotoDetailView: View {
  
  @EnvironmentObject var sessionStore: SessionStateReducer.StoreType
  
  var photoID: Photo.ID
  
  @State var draftCommentBody: String = ""
  
  private var photo: Photo {
    sessionStore.state.photosStorage[photoID]!
  }
      
  var body: some View {
    VStack {
      Text("\(photo.id)")
      TextField("Enter comment here", text: $draftCommentBody)
        .padding(16)
      Button(action: {
        
        guard self.draftCommentBody.isEmpty == false else { return }
        
        self.sessionStore.dispatch { $0.submitComment(body: self.draftCommentBody, photoID: self.photoID) }
        self.draftCommentBody = ""
        
      }) {
        Text("Submit")
      }
    }
  }
}


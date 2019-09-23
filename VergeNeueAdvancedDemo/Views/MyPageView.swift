//
//  MyPageView.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import SwiftUI

import VergeNeue

struct MyPageView: View {
  
  @ObservedObject var store: Store<LoggedInReducer>
  
  var body: some View {
    NavigationView {
      List {
        aboutMe(me: store.state.me)
      }
      .navigationBarTitle("MyPage")
    }
  }
  
  private func aboutMe(me: LoggedInState.Me) -> some View {
    HStack {
      
      HStack {
        
        Color(white: 0.96)
          .frame(width: 64, height: 64, alignment: .center)
          .clipShape(Capsule.init(style: .circular))
        
      }
      

      HStack() {
        
        VStack {
          Text(me.postCount.description)
            .font(.body)
            .fontWeight(.bold)
          Text("Posts")
            .font(.caption)
        }
        
//        Spacer()
        
        VStack {
          Text(me.followerCount.description)
            .font(.body)
            .fontWeight(.bold)
          Text("Followers")
            .font(.caption)
        }
        
//        Spacer()
        
        VStack {
          Text(me.followingCount.description)
            .font(.body)
            .fontWeight(.bold)
          Text("Following")
            .font(.caption)
        }
      }
      
    }
  }
}


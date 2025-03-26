//
//  BookLongList.swift
//  Development
//
//  Created by Muukii on 2025/03/26.
//

import SwiftUI
import Verge

@Tracking
struct BookState {
  var items: [BookItem] = []
  
  init(items: [BookItem]) {
    self.items = items
  }
}

struct BookItem: Identifiable {
  var id: some Hashable {
    cellStore
  }
  let cellStore: Store<BookCellState, Never>
}

@Tracking
struct BookCellState {
  let id: Int
  var title: String
  var isSelected: Bool = false
}

struct BookCellContent: View {
  
  let store: Store<BookCellState, Never>

  var body: some View {
    StoreReader(store) { $state in
      RoundedRectangle(cornerRadius: 8)
        .fill(state.isSelected ? Color.red : Color.blue.opacity(0.2))
        .aspectRatio(1, contentMode: .fit)
        .overlay(
          Text("\(state.id + 1)")
            .font(.system(size: 16))
        )       
    }
  }
}

struct BookCell: View {
  
  let store: Store<BookCellState, Never>

  var body: some View {
    Button {
      store.commit { state in
        state.isSelected.toggle()
      }
    } label: {      
      BookCellContent(store: store)
    }
  }
}

struct BookLongList: View {
  private let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible()),
  ]

  @Reading<Store<BookState, Never>>({
    .init(initialState: .init(items: (0..<500).map { index in
      BookItem(
        cellStore: Store<BookCellState, Never>(
          initialState: BookCellState(
            id: index,
            title: UUID().uuidString
          )
        )
      )
    }))
  }) var state: BookState

  init() {
    
  }

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 16) {
        ForEach(state.items) { item in
          BookCell(store: item.cellStore)
        }
      }
      .padding()
    }
  }
}

#Preview {
  BookLongList()
}

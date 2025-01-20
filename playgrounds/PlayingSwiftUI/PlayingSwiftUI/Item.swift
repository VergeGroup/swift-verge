//
//  Item.swift
//  PlayingSwiftUI
//
//  Created by Muukii on 2025/01/20.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

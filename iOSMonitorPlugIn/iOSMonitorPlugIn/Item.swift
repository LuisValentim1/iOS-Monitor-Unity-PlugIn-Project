//
//  Item.swift
//  iOSMonitorPlugIn
//
//  Created by Luís Miguel on 18/03/2024.
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

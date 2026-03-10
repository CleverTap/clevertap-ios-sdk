//
//  CardModel.swift
//  SwiftTvOS
//
//  Created by Reshab Singh  on 10/03/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation

struct CardItem {
    let title: String
    let action: Selector
}

struct Section {
    let title: String
    let items: [CardItem]
}

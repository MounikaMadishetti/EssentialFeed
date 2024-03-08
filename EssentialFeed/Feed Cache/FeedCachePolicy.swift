//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Mounika Madishetti on 22/09/23.
//

import Foundation

final class FeedCachePolicy {

    private static let calender = Calendar(identifier: .gregorian)
    private static var maaxCacheInDays: Int {
        return 7
    }

    private init() {}

    static func validate(_ timestamp: Date, against  date: Date) -> Bool {
        guard let maxCacheAge = calender.date(byAdding: .day, value: 7, to: timestamp) else { return false }
        return date < maxCacheAge
    }
}

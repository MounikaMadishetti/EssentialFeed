//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Mounika Madishetti on 22/09/23.
//

import EssentialFeed

func uniqueImage() -> FeedImage {
    FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let items = [uniqueImage(), uniqueImage()]
    let localItems = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    return (models: items, local: localItems)
}

extension Date {
    private func adding(days: Int) -> Date {
         Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }

    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
}
extension Date {
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}



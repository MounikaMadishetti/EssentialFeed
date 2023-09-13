//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Mounika Madishetti on 05/08/23.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}
protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}

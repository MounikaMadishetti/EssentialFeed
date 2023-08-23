//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Mounika Madishetti on 05/08/23.
//

import Foundation
// FeedLoader module


public struct FeedItem: Codable, Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: URL

    public init(id: UUID, description: String?, location: String?, imageURL: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}



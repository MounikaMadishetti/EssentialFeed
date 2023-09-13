//
//  LocalFeedItem.swift
//  EssentialFeed
//
//  Created by Mounika Madishetti on 09/09/23.
//

public struct LocalFeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: URL

    public init(id: UUID, description: String?, location: String?, url: URL) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}

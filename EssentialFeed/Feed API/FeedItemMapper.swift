//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Mounika Madishetti on 13/08/23.
//

import Foundation

final class FeedItemMapper {

    struct Root: Decodable {
        let items: [Item]
        var feed: [FeedItem] {
            items.map { $0.item }
        }
    }
    struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var item: FeedItem {
            FeedItem(id: self.id, description: self.description, location: self.location, imageURL: self.image)
        }
    }

    static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard let root = try? JSONDecoder().decode(Root.self, from: data), response.statusCode == 200 else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }

        return .success(root.feed)
    }
}

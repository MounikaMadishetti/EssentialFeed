//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Mounika Madishetti on 13/08/23.
//

import Foundation

final class FeedItemMapper {

    struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard let root = try? JSONDecoder().decode(Root.self, from: data), response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        return root.items
    }
}

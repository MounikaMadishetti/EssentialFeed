//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Mounika Madishetti on 09/09/23.
//

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}

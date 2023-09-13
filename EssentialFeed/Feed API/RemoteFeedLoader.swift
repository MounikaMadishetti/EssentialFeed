//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Mounika Madishetti on 09/08/23.
//

import Foundation

public class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadFeedResult

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping(Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .success(data, response):
                completion(RemoteFeedLoader.map(data, response))
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            }
        }
    }

    private static func map(_ data: Data, _ response: HTTPURLResponse) -> Result {
        do {
            let items = try FeedItemMapper.map(data, from: response)
            return .success(items.toModel())
        } catch let error {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteFeedItem {
    func toModel() -> [FeedImage] {
        self.map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
    }
}

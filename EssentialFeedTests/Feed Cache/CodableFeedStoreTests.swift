//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Mounika Madishetti on 07/10/23.
//

import XCTest
import EssentialFeed

class CodableFeedStore {

    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date

        var localFeed: [LocalFeedImage] {
            return feed.map { $0.local }
        }
    }

    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL

        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }

        var local: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }

    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }

    func insert(_ feed: [LocalFeedImage], timeStamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feed: feed.map(CodableFeedImage.init), timestamp: timeStamp))
        try! encoded.write(to: storeURL)
        completion(nil)
    }

}

final class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        setupEmptyStoreState()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        let expectation = expectation(description: "wait for cache retreival")
        expect(sut, toRetrieve: .empty)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let expectation = expectation(description: "wait for cache retreival")
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("expected empty result got \(firstResult) and \(secondResult) instead")
                }
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_retrieveAfterInsteringToEmptyCache_deliversInstertedValues() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timeStamp = Date()
        let expectation = expectation(description: "wait for cache retreival")

        sut.insert(feed, timeStamp: timeStamp) { insertionError in
            XCTAssertNil(insertionError, "Expected Feed to be inserted successfully")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timeStamp))
       
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timeStamp = Date()
        let expectation = expectation(description: "wait for cache retreival")

        sut.insert(feed, timeStamp: timeStamp) { insertionError in
            XCTAssertNil(insertionError, "Expected Feed to be inserted successfully")

            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                    case let (.found(firstFound), .found(secondFoud)):
                        XCTAssertEqual(firstFound.feed, feed)
                        XCTAssertEqual(secondFoud.feed, feed)
                        
                        XCTAssertEqual(firstFound.timestamp, timeStamp)
                        XCTAssertEqual(secondFoud.timestamp, timeStamp)
                    default:
                        XCTFail("expected retrieving from non empty cache twice to deliver same \(feed) and timestamp \(timeStamp), but got \(firstResult) and \(secondResult) instead")
                    }
                    expectation.fulfill()
                }
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetriveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let expectation = expectation(description: "wait for cache retrieval")
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case let (.empty, .empty):
                break
            case let (.found(expected), .found(retrieved)):
                XCTAssertEqual(expected.feed, retrieved.feed)
                XCTAssertEqual(expected.timestamp, retrieved.timestamp)
                
            default:
                XCTFail("Expected to receive \(expectedResult), received \(retrievedResult) instead!")
            }
            expectation.fulfill()
        }
        wait(for: [expectation])
    }

    private func testSpecificStoreURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}

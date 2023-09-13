//
//  LoadFeedFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Mounika Madishetti on 05/08/23.
//

import XCTest
@testable import EssentialFeed

final class LoadFeedFromRemoteUseCaseTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        XCTAssertTrue(client.requestedUrls.isEmpty)
    }

    func test_load_requestDataFromURL() {
        // arrange: Given a client and a sut
        let (sut, client) = makeSUT()
        // act: When we invoke sut.load()
        sut.load { _ in }
        // assert: Then assert that a url tqst was inititated in the client
        XCTAssertEqual(client.requestedUrls, [URL(string: "hello")!])
    }

    func test_load_requestDataFromURLTwice() {
        // arrange: Given a client and a sut
        let url = URL(string: "hello")!
        let (sut, client) = makeSUT(url: url)
        // act: When we invoke sut.load 2 times
        sut.load { _ in }
        sut.load { _ in }
        // assert: Then assert that the 2 urls sent are same as client's requestUrls
        XCTAssertEqual(client.requestedUrls, [url, url])
    }

    func test_load_deliversErrorOnClientError() {
        // arrange
        let (sut, client) = makeSUT()

        // act
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError =  NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }

    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        [199, 201, 300, 400, 500].enumerated().forEach { (index, code) in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let data = makeItemsJSON([])
                client.complete(with: code, data: data, at: index)
            })
        }
    }

    func test_load_deliversErrorOn200HTTPResponseWithInvalidJson() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJson = Data(bytes: "invalid json".utf8)
            client.complete(with: 200, data: invalidJson)
        })
    }

    func test_load_deliversNoItemsOn200HTTPResponseEmptyJSONList() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJson = makeItemsJSON([])
            client.complete(with: 200, data: emptyListJson)
        })
    }

    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()

        let item1 = makeItem(id: UUID(), imageURL: URL(string: "url.com")!)

        let item2 = makeItem(id: UUID(), description: "this is the desc", location: "this is the location", imageURL: URL(string: "urlimage.com")!)

        let itemsJSON = [
            "items": [item1.1, item2.1]
        ]

        expect(sut, toCompleteWith: .success([item1.0, item2.0]), when: {
            client.complete(with: 200, data: makeItemsJSON([item1.1, item2.1]))
        })
    }

    func test_load_doesNotdeliverItemsOn200HTTPResponseAfterSutBecomesNil() {
        let client = SpyHTTPClient()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: URL(string: "url.com")!, client: client)
        var capturedResult = [RemoteFeedLoader.Result]()
        sut?.load { capturedResult.append($0) }
        sut = nil

        client.complete(with: 200, data: makeItemsJSON([]))
        XCTAssertTrue(capturedResult.isEmpty)
    }

    // MARK: - private method
    private func makeSUT(url: URL = URL(string: "hello")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, client: SpyHTTPClient) {
        let client = SpyHTTPClient()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackMemoryLeaks(sut)
        trackMemoryLeaks(client)
        return (sut, client)
    }

    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for load completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("expected result \(expectedResult), got received result \(receivedResult) instead")
            }
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)

    }

    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(id: id, description: description, location: location, url: imageURL)
        let itemJSON = [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image": item.url.absoluteString
        ].reduce(into: [String: Any]()) { (accumulated, ele) in
            if let value = ele.value {
                accumulated[ele.key] = value
            }

        }
        return (item, itemJSON)
    }

    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJson = ["items": items]
        let data = try! JSONSerialization.data(withJSONObject: itemsJson)
        return data
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
    }
}

class SpyHTTPClient: HTTPClient {

    private var msgs = [(url: URL, completion: (HTTPClientResult) -> Void)]()

    var requestedUrls: [URL] {
        return msgs.map { $0.url }
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        msgs.append((url, completion))
    }

    func complete(with error: Error, index: Int = 0) {
        msgs[index].completion(.failure(error))
    }

    func complete(with statusCode: Int, data: Data, at index: Int = 0) {
        let response = HTTPURLResponse(url: requestedUrls[index], statusCode: statusCode, httpVersion: nil, headerFields: nil)

        msgs[index].completion(.success(data, response!))
    }
}

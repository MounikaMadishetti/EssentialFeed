//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Mounika Madishetti on 22/08/23.
//

import XCTest
import EssentialFeed
protocol HTTPSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    private let session: HTTPSession

    init(session: HTTPSession) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: URLRequest(url: url)) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}
final class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_resumesDataTaskWithURL() {
        let url = URL(string: "url")!
        let session = HTTPSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, task: task)
        sut.get(from: url) { result in

        }
        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func test_getFromURL_failedOnRequestError() {
        let url = URL(string: "url")!
        let session = HTTPSessionSpy()
        let error = NSError(domain: "domain", code: 0)
        session.stub(url: url, error: error)
        let sut = URLSessionHTTPClient(session: session)

        let expectation = expectation(description: "wait for completion")
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError, error)
            default:
                XCTFail("expected failure with error \(error), got \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    private class HTTPSessionSpy: HTTPSession {
        var stubs = [URL: Stub]()

        struct Stub {
            let task: HTTPSessionTask
            let error: Error?
        }

        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            guard let stub = stubs[request.url!] else {
                fatalError("could not find stub for given url")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }

        func stub(url: URL, task: HTTPSessionTask  = FakeURLSessionDataTask(), error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
    }

    private class FakeURLSessionDataTask: HTTPSessionTask {
        func resume() {

        }
    }
    private class URLSessionDataTaskSpy: HTTPSessionTask {
        var resumeCallCount: Int = 0
        func resume() {
            resumeCallCount += 1
        }
    }

}

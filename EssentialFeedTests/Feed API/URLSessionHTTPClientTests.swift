//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Mounika Madishetti on 22/08/23.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClientTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }

    func test_getFromURL_performsGETRequestWithURL() {
        let url = anyURL()
        let expectation = expectation(description: "waitsg for completion")

        URLProtocolStub.observeRequests(observer: { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        })

        makeSUT().get(from: anyURL()) { _ in }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_getFromURL_failedOnRequestError() {
        let error = NSError(domain: "domain", code: 0)
        let receivedError  = resultErrorFor(data: nil, response: nil, error: error)
        XCTAssertEqual((receivedError as NSError?)?.code, error.code)
    }

    func test_getFromURL_failedOnAllInvalidRepresentationCases() {
        let anyData = anyData()
        let anyError = anyError()
        let nonHTTPURLResponse = nonHTTPURLResponse()
        let anyHttpURLResponse = anyHttpURLResponse()

        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHttpURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: anyHttpURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response: nonHTTPURLResponse, error: nil))
    }

    func test_getFromURL_SuceedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHttpURLResponse()
        let anyURL = anyURL()
        URLProtocolStub.stub(data: data, response: response)

        let expectation = expectation(description: "wait for completion")
        makeSUT().get(from: anyURL) { result in
            switch result {
            case let .success(receivedData, receivedResponse):
                XCTAssertEqual(receivedData, data)
                XCTAssertEqual(receivedResponse.url, response.url)
                XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
            default:
                XCTFail("expected success receive \(result) instead")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    func test_getFromURL_suceedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let response = anyHttpURLResponse()
        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)
        XCTAssertEqual(receivedValues?.0, Data())
        XCTAssertEqual(receivedValues?.1.url, response.url)
        XCTAssertEqual(receivedValues?.1.statusCode, response.statusCode)
    }

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func anyURL() -> URL {
        return URL(string: "https://www.any-url.com")!
    }

    private func anyData() -> Data {
        return Data(bytes: "anydata".utf8)
    }

    private func anyError() -> NSError {
        return NSError(domain: "domain", code: 1)
    }

    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: "", expectedContentLength: 0, textEncodingName: "")
    }

    private func anyHttpURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: "", headerFields: nil)!
    }

    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (Data, HTTPURLResponse)? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            XCTFail("expected success, got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }

    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let expectation = expectation(description: "wait for completion")
        var receivedResult: HTTPClientResult!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedResult
    }
    
    private class URLProtocolStub: URLProtocol {
        static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request

        }

        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {
            if let requestObserver = URLSessionHTTPClientTests.URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
               return requestObserver(request)
            }
        }

        static func stub(data: Data?, response: URLResponse?, error: Error? = nil) {
            stub = Stub(data: data, response: response, error: error)
        }

        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            self.requestObserver = observer
        }
    }
}

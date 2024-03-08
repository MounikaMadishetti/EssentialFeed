//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Mounika Madishetti on 22/09/23.
//
import Foundation

func anyURL() -> URL {
    return URL(string: "https://www.any-url.com")!
}

func anyNSError() -> NSError {
    return NSError(domain: "domain", code: 1)
}


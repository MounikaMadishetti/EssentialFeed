//
//  XCTestCaseMemoryTracking.swift
//  EssentialFeedTests
//
//  Created by Mounika Madishetti on 23/08/23.
//

import XCTest

extension XCTestCase {
    func trackMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "sut is deallocated", file: file, line: line)
        }
    }
}

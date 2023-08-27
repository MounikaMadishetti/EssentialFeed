//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Mounika Madishetti on 13/08/23.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}
//sample
public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

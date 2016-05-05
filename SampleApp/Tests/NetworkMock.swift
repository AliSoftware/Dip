//
//  NetworkMock.swift
//  Dip
//
//  Created by Olivier Halligon on 11/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation
import Dip

var wsDependencies = DependencyContainer()

// MARK: - Mock object used for tests

struct NetworkMock : NetworkLayer {
    let fakeData: NSData?
    
    init(json: AnyObject) {
        do {
            fakeData = try NSJSONSerialization.data(withJSONObject: json, options: [])
        } catch {
            fakeData = nil
        }
    }
    
    func request(path: String, completion: NetworkResponse -> Void) {
        let fakeURL = NSURL(string: "stub://")!.appendingPathComponent(path)
        if let data = fakeData {
            let response = NSHTTPURLResponse(url: fakeURL, statusCode: 200, httpVersion: "1.1", headerFields:nil)!
            completion(.Success(data, response))
        } else {
            let response = NSHTTPURLResponse(url: fakeURL, statusCode: 204, httpVersion: "1.1", headerFields:nil)!
            completion(.Success(NSData(), response))
        }
    }
}

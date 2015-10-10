//
//  URLSessionNetworkLayer.swift
//  Dip
//
//  Created by Olivier Halligon on 10/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

struct URLSessionNetworkLayer : NetworkLayer {
    let baseURL: NSURL
    let session: NSURLSession
    let responseQueue: dispatch_queue_t
    
    init?(baseURL: String, session: NSURLSession = .sharedSession(), responseQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        guard let url = NSURL(string: baseURL) else { return nil }
        self.init(baseURL: url, session: session)
    }
    
    init(baseURL: NSURL, session: NSURLSession = .sharedSession(), responseQueue: dispatch_queue_t = dispatch_get_main_queue()) {
        self.baseURL = baseURL
        self.session = session
        self.responseQueue = responseQueue
    }
    
    func request(path: String, completion: NetworkResponse -> Void) {
        let url = self.baseURL.URLByAppendingPathComponent(path)
        let task = session.dataTaskWithURL(url) { data, response, error in
            if let data = data, let response = response as? NSHTTPURLResponse {
                dispatch_async(self.responseQueue) {
                    completion(NetworkResponse.Success(data, response))
                }
            }
            else {
                let err = error ?? NSError(domain: NSURLErrorDomain, code: NSURLError.Unknown.rawValue, userInfo: nil)
                dispatch_async(self.responseQueue) {
                    completion(NetworkResponse.Error(err))
                }
            }
        }
        task.resume()
    }
}

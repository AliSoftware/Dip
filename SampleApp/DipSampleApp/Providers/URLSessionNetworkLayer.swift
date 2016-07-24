//
//  URLSessionNetworkLayer.swift
//  Dip
//
//  Created by Olivier Halligon on 10/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

///NetworkLayer implementation on top of NSURLSession
struct URLSessionNetworkLayer : NetworkLayer {
    let baseURL: URL
    let session: URLSession
    let responseQueue: DispatchQueue
    
    init?(baseURL: String, session: URLSession = .shared(), responseQueue: DispatchQueue = DispatchQueue.main) {
        guard let url = NSURL(string: baseURL) else { return nil }
        self.init(baseURL: url, session: session)
    }
    
    init(baseURL: URL, session: URLSession = .shared(), responseQueue: DispatchQueue = DispatchQueue.main) {
        self.baseURL = baseURL
        self.session = session
        self.responseQueue = responseQueue
    }
    
    func request(path: String, completion: (NetworkResponse) -> Void) {
        guard let url = try? self.baseURL.appendingPathComponent(path) else { return }
        let task = session.dataTask(with: url) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse {
                self.responseQueue.async() {
                    completion(NetworkResponse.Success(data, response))
                }
            }
            else {
                let err = error ?? NSError(domain: NSURLErrorDomain, code: NSURLError.unknown.rawValue, userInfo: nil)
                self.responseQueue.async() {
                    completion(NetworkResponse.Error(err))
                }
            }
        }
        task.resume()
    }
}

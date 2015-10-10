//
//  NetworkLayer.swift
//  Dip
//
//  Created by Olivier Halligon on 10/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

enum NetworkResponse {
    case Success(NSData, NSHTTPURLResponse)
    case Error(NSError)
    
    func unwrap() throws -> (NSData, NSHTTPURLResponse) {
        switch self {
        case Success(let data, let response):
            return (data, response)
        case Error(let error):
            throw error
        }
    }
    
    func json() throws -> AnyObject {
        let (data, _) = try self.unwrap()
        return try NSJSONSerialization.JSONObjectWithData(data, options: [])
    }
}

protocol NetworkLayer {
    func request(path: String, completion: NetworkResponse -> Void)
}

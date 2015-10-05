//
//  NetworkLayer.swift
//  Dip
//
//  Created by Olivier Halligon on 05/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

protocol NetworkLayer {
    func fetchURL(url: NSURL, completion: NSData? -> Void)
    func fetchURLAndMap<T>(url: NSURL, completion: T? -> Void, transform: NSData throws -> T)
}

extension NetworkLayer {
    func fetchURLAndMap<T>(url: NSURL, completion: T? -> Void, transform: NSData throws -> T) {
        fetchURL(url) { (data: NSData?) -> Void in
            guard let data = data else {
                completion(nil)
                return
            }
            let result: T?
            do {
                result = try transform(data)
            } catch {
                result = nil
            }
            completion(result)
        }
    }
}

//
//  SWAPIWebService.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation
import Dip

/// WebService for The StarWars API — see http://swapi.co/documentation
class SWAPIWebService : WebServiceAPI {
    let personFactory = dip.resolve() as PersonFactoryAPI

    func fetch(completion: [Person]? -> Void) {
        let url = NSURL(string: "http://swapi.co/api/people/")!
        fetchURLAndMap(url, completion: completion) { data in
            return try self.personFactory.peopleFromData(data)
        }
    }
    
    func fetch(id: Int, completion: Person? -> Void) {
        let url = NSURL(string: "http://swapi.co/api/people/\(id)")!
        fetchURLAndMap(url, completion: completion) { data in
            return try self.personFactory.personFromData(data)
        }
    }

    private func fetchURLAndMap<T>(url: NSURL, completion: T? -> Void, transform: NSData throws -> T) {
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data: NSData?, resp: NSURLResponse?, error: NSError?) -> Void in
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
            dispatch_async(dispatch_get_main_queue()) {
                completion(result)
            }
        }
        task.resume()
    }

    
}

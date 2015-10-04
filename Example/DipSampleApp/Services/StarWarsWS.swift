//
//  StarWarsWebService.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation
import Dip

class StarWarsWebService : WebServiceAPI {
    let personFactory = Dependency.resolve() as PersonFactoryAPI

    func fetchPeopleList(completion: [Person]? -> Void) {
        let url = NSURL(string: "http://swapi.co/api/people/")!
        fetchURL(url) { data in
            guard let data = data else { completion(nil); return }
            let persons: [Person]?
            do {
                persons = try self.personFactory.personListFromData(data)
            } catch {
                persons = nil
            }
            dispatch_async(dispatch_get_main_queue()) {
                completion(persons)
            }
        }
    }
    
    func fetchPerson(id: Int, completion: Person? -> Void) {
        let url = NSURL(string: "http://swapi.co/api/people/\(id)")!
        fetchURL(url) { data in
            guard let data = data else { completion(nil); return }
            let person: Person?
            do {
                person = try self.personFactory.personFromData(data)
            } catch {
                person = nil
            }
            dispatch_async(dispatch_get_main_queue()) {
                completion(person)
            }
        }
    }

    private func fetchURL(url: NSURL, completion: NSData? -> Void) {
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) { (data: NSData?, resp: NSURLResponse?, error: NSError?) -> Void in
            completion(data)
        }
        task.resume()
    }

    
}

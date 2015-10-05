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
    let networkLayer = dip.resolve() as NetworkLayer
    let personFactory = dip.resolve() as PersonFactoryAPI

    func fetch(completion: [Person]? -> Void) {
        let url = NSURL(string: "http://swapi.co/api/people/")!
        networkLayer.fetchURLAndMap(url, completion: completion) { data in
            return try self.personFactory.peopleFromData(data)
        }
    }
    
    func fetch(id: Int, completion: Person? -> Void) {
        let url = NSURL(string: "http://swapi.co/api/people/\(id)")!
        networkLayer.fetchURLAndMap(url, completion: completion) { data in
            return try self.personFactory.personFromData(data)
        }
    }

}

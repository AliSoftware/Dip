//
//  SWAPIPersonProvider.swift
//  Dip
//
//  Created by Olivier Halligon on 10/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

///Provides Person entitis fetching them with web service
struct SWAPIPersonProvider : PersonProviderAPI {
    let ws: NetworkLayer
    
    //Here we inject dependency using _constructor injection_ pattern.
    //The alternative way is a _property injection_
    //but it should be used only for optional dependencies
    //where there is a good local default implementation
    init(webService: NetworkLayer) {
        self.ws = webService
    }
    
    func fetchIDs(completion: @escaping ([Int]) -> Void) {
        ws.request(path: "people") { response in
            do {
                let dict = try response.json() as NSDictionary
                guard let results = dict["results"] as? [NSDictionary] else { throw SWAPIError.InvalidJSON }
                
                // Extract URLs (flatten to ignore invalid ones)
                let urlStrings = results.flatMap({ $0["url"] as? String })
                let ids = urlStrings.flatMap(idFromURLString)
                
                completion(ids)
            }
            catch {
                completion([])
            }
        }
    }
    
    func fetch(id: Int, completion: @escaping (Person?) -> Void) {
        ws.request(path: "people/\(id)") { response in
            do {
                let json = try response.json() as NSDictionary
                guard
                    let name = json["name"] as? String,
                    let heightStr = json["height"] as? String, let height = Int(heightStr),
                    let massStr = json["mass"] as? String, let mass = Int(massStr),
                    let hairColor = json["hair_color"] as? String,
                    let eyeColor = json["eye_color"] as? String,
                    let gender = json["gender"] as? String,
                    let starshipURLStrings = json["starships"] as? [String]
                    else {
                        throw SWAPIError.InvalidJSON
                }
                
                let person = Person(
                    name: name,
                    height: height,
                    mass: mass,
                    hairColor: hairColor,
                    eyeColor: eyeColor,
                    gender: Gender(rawValue: gender),
                    starshipIDs: starshipURLStrings.flatMap(idFromURLString)
                )
                completion(person)
            }
            catch {
                completion(nil)
            }
        }
    }
}

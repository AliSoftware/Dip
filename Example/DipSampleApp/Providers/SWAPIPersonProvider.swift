//
//  SWAPIPersonProvider.swift
//  Dip
//
//  Created by Olivier Halligon on 10/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

struct SWAPIPersonProvider : PersonProviderAPI {
    let ws = wsDependencies.resolve(.PersonWS) as NetworkLayer
    
    func fetchIDs(completion: [Int] -> Void) {
        ws.request("people") { response in
            do {
                let dict = try response.json()
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
    
    func fetch(id: Int, completion: Person? -> Void) {
        ws.request("people/\(id)") { response in
            do {
                let json = try response.json()
                guard let dict = json as? NSDictionary,
                    let name = dict["name"] as? String,
                    let heightStr = dict["height"] as? String, height = Int(heightStr),
                    let massStr = dict["mass"] as? String, mass = Int(massStr),
                    let hairColor = dict["hair_color"] as? String,
                    let eyeColor = dict["eye_color"] as? String,
                    let gender = dict["gender"] as? String,
                    let starshipURLStrings = dict["starships"] as? [String]
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

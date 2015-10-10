//
//  HardCodedStarshipProvider.swift
//  Dip
//
//  Created by Olivier Halligon on 11/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

class HardCodedStarshipProvider : StarshipProviderAPI {
    
    let starships = [
        Starship(name: "First Ship", model: "AwesomeShip", manufacturer: "HardCoded Inc.", crew: 3, passengers: 20, pilotIDs: [1,2]),
        Starship(name: "Second Ship", model: "AwesomeShip Express", manufacturer: "HardCoded Inc.", crew: 4, passengers: 10, pilotIDs: [1]),
        Starship(name: "Third Ship", model: "AwesomeShip Cargo", manufacturer: "HardCoded Inc.", crew: 12, passengers: 150, pilotIDs: [2]),
    ]
    
    func fetchIDs(completion: [Int] -> Void) {
        completion(Array(0..<starships.count))
    }
    
    func fetch(id: Int, completion: Starship? -> Void) {
        guard id < starships.count else {
            completion(nil)
            return
        }
        completion(starships[id])
    }    
}

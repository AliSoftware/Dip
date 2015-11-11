//
//  DummyStarshipProvider.swift
//  Dip
//
//  Created by Olivier Halligon on 08/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

struct DummyStarshipProvider : StarshipProviderAPI {
    var pilotName: String
    
    func fetchIDs(completion: [Int] -> Void) {
        let nbShips = pilotName.characters.count
        completion(Array(0..<nbShips))
    }
    
    func fetch(id: Int, completion: Starship? -> Void) {
        completion(dummyStarship(id))
    }
    
    private func dummyStarship(idx: Int) -> Starship {
        return Starship(
            name: "\(pilotName)'s awesome starship #\(idx)",
            model: "\(pilotName)Ship",
            manufacturer: "Dummy Industries",
            crew: 1 + (idx%3),
            passengers: 10 + (idx*7 % 40),
            pilotIDs: [idx]
        )
    }
}

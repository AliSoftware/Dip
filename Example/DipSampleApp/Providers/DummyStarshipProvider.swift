//
//  DummyStarshipProvider.swift
//  Dip
//
//  Created by Olivier Halligon on 08/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

struct DummyStarshipProvider : StarshipProviderAPI {
    var pilot: String
    
    func fetch(completion: [Starship] -> Void) {
        let nbShips = pilot.characters.count
        let starships = (1...nbShips).map { idx in
            return dummyStarship(idx)
        }
        completion(starships)
    }
    
    func fetch(id: Int, completion: Starship? -> Void) {
        completion(dummyStarship(id))
    }
    
    private func dummyStarship(idx: Int) -> Starship {
        return Starship(
            name: "\(pilot)'s awesome starship #\(idx)",
            model: "\(pilot)Ship",
            manufacturer: "\(pilot) Industries",
            crew: 1 + (idx%3),
            passengers: 10 + (idx*7 % 40),
            pilotIDs: [idx]
        )
    }
}

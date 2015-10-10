//
//  DummyPilotProvider.swift
//  Dip
//
//  Created by Olivier Halligon on 12/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

struct DummyPilotProvider : PersonProviderAPI {
    
    func fetchIDs(completion: [Int] -> Void) {
        completion(Array(0..<5))
    }
    
    func fetch(id: Int, completion: Person? -> Void) {
        completion(dummyPerson(id))
    }
    
    private func dummyPerson(idx: Int) -> Person {
        let colors = ["blue", "brown", "yellow", "orange", "red", "dark"]
        let genders: [Gender?] = [Gender.Male, Gender.Female, nil]
        return Person(
            name: "John Dummy Doe #\(idx)",
            height: 150 + (idx*27%40),
            mass: 50 + (idx*7%30),
            hairColor: colors[idx*3%colors.count],
            eyeColor: colors[idx*2%colors.count],
            gender: genders[idx%3],
            starshipIDs: [idx % 3, 2*idx % 4]
        )
    }
}

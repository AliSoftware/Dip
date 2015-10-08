//
//  PlistPersonProvider.swift
//  Dip
//
//  Created by Olivier Halligon on 12/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

class PlistPersonProvider : PersonProviderAPI {
    let people: [Person]
    
    init(plist basename: String) {
        guard let path = NSBundle.mainBundle().pathForResource(basename, ofType: "plist"),
            let list = NSArray(contentsOfFile: path),
            peopleDict = list as? [[String:AnyObject]]
            else { fatalError("PLIST for \(basename) not found") }
        
        self.people = peopleDict.map(PlistPersonProvider.personFromStringDict)
    }
    
    func fetch(completion: [Person] -> Void) {
        completion(people)
    }
    
    func fetch(id: Int, completion: Person? -> Void) {
        guard id < people.count else {
            completion(nil)
            return
        }
        completion(people[id])
    }
    
    private static func personFromStringDict(stringDict: [String:AnyObject]) -> Person {
        guard
            let name = stringDict["name"] as? String,
            height = stringDict["height"] as? Int,
            mass = stringDict["mass"] as? Int,
            hairColor = stringDict["hairColor"] as? String,
            eyeColor = stringDict["eyeColor"] as? String,
            genderStr = stringDict["gender"] as? String,
            starshipsIDs = stringDict["starships"] as? [Int]
            else { fatalError("Invalid Plist")
        }
        
        return Person(
            name: name,
            height: height,
            mass: mass,
            hairColor: hairColor,
            eyeColor: eyeColor,
            gender: Gender(rawValue: genderStr),
            starshipIDs: starshipsIDs
        )
    }
}

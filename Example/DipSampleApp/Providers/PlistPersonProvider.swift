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
        guard
            let path = NSBundle.mainBundle().pathForResource(basename, ofType: "plist"),
            let list = NSArray(contentsOfFile: path),
            peopleDict = list as? [[String:AnyObject]]
            else {
                fatalError("PLIST for \(basename) not found")
        }
        
        self.people = peopleDict.map(PlistPersonProvider.personFromDict)
    }
    
    func fetchIDs(completion: [Int] -> Void) {
        completion(Array(0..<people.count))
    }
    
    func fetch(id: Int, completion: Person? -> Void) {
        guard id < people.count else {
            completion(nil)
            return
        }
        completion(people[id])
    }
    
    private static func personFromDict(dict: [String:AnyObject]) -> Person {
        guard
            let name = dict["name"] as? String,
            height = dict["height"] as? Int,
            mass = dict["mass"] as? Int,
            hairColor = dict["hairColor"] as? String,
            eyeColor = dict["eyeColor"] as? String,
            genderStr = dict["gender"] as? String,
            starshipsIDs = dict["starships"] as? [Int]
            else {
                fatalError("Invalid Plist")
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

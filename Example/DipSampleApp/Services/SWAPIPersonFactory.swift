//
//  SWAPIPersonFactory.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation
import Dip

class SWAPIPersonFactory : PersonFactoryAPI {
    typealias JSONDict = [String:AnyObject]
    enum Error : ErrorType {
        case MissingResultsEntry
        case InvalidPersonSchema
    }
    
    let serializer = Dependency.resolve() as SerializerAPI

    func peopleFromData(personData: NSData) throws -> [Person] {
        let json = try serializer.dictionaryFromData(personData)
        if let results = json["results"] as? [JSONDict] {
            return try results.map { try personFromJSON($0) }
        } else {
            throw Error.MissingResultsEntry
        }
    }
    
    func personFromData(personData: NSData) throws -> Person {
        let json = try serializer.dictionaryFromData(personData)
        return try personFromJSON(json)
    }

    private func personFromJSON(json: JSONDict) throws -> Person {
        guard let name = json["name"] as? String,
        let heightStr = json["height"] as? String, height = Int(heightStr),
        let massStr = json["mass"] as? String, mass = Int(massStr),
        let eyesColor = json["eye_color"] as? String,
        let hairColor = json["hair_color"] as? String
        else {
            throw Error.InvalidPersonSchema
        }
        return Person(name: name, height: height, mass: mass, eyesColor: eyesColor, hairColor: hairColor)
    }
}

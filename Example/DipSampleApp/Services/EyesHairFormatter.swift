//
//  EyesHairFormatter.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

class EyesHairFormatter : PersonFormatterAPI {
    func textForPerson(person: Person) -> String {
        return person.name
    }
    func subtextForPerson(person: Person) -> String {
        return "\(person.eyesColor) eyes, \(person.hairColor) hair"
    }
}

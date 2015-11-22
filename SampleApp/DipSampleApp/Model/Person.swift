//
//  Person.swift
//  Dip
//
//  Created by Olivier Halligon on 08/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

enum Gender: String {
    case Male = "male"
    case Female = "female"
}

struct Person {
    var name: String
    var height: Int
    var mass: Int
    var hairColor: String
    var eyeColor: String
    var gender: Gender?
    var starshipIDs: [Int]
}

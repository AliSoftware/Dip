//
//  PersonFormatterAPI.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

protocol PersonFormatterAPI {
    func textForPerson(person: Person) -> String
    func subtextForPerson(person: Person) -> String
}

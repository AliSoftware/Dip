//
//  SerializerAPI.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

protocol SerializerAPI {
    func dictionaryFromData(data: NSData) throws -> [String:AnyObject]
}

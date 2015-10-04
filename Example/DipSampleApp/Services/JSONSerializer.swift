//
//  JSONSerializer.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

class JSONSerializer : SerializerAPI {
    enum Error : ErrorType {
        case UnexpectedFormat
    }
    
    func dictionaryFromData(data: NSData) throws -> [String:AnyObject] {
        let result = try NSJSONSerialization.JSONObjectWithData(data, options: [])
        if let json = result as? [String:AnyObject] {
            return json
        } else {
            throw Error.UnexpectedFormat
        }
    }
}

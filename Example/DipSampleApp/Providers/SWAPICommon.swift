//
//  SWAPICommon.swift
//  Dip
//
//  Created by Olivier Halligon on 11/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation
import Dip

enum SWAPIError: ErrorType {
    case InvalidJSON
}

enum WebService: String {
    case PersonWS
    case StarshipWS
    var tag: Tag { return Tag.String(self.rawValue) }
}

func idFromURLString(urlString: String) -> Int? {
    let url = NSURL(string: urlString)
    let idString = url.flatMap { $0.lastPathComponent }
    return idString.flatMap { Int($0) }
}

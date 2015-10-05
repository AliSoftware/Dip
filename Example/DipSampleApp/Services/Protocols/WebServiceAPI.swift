//
//  WebServiceAPI.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

protocol WebServiceAPI {
    func fetch(completion: [Person]? -> Void)
    func fetch(id: Int, completion: Person? -> Void)
}

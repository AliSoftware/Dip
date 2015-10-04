//
//  WebServiceAPI.swift
//  Dip
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

protocol WebServiceAPI {
    func fetchPeopleList(completion: [Person]? -> Void)
    func fetchPerson(id: Int, completion: Person? -> Void)
}

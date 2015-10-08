//
//  PersonProviderAPI.swift
//  Dip
//
//  Created by Olivier Halligon on 10/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

protocol PersonProviderAPI {
    func fetch(completion: [Person] -> Void)
    func fetch(id: Int, completion: Person? -> Void)
}

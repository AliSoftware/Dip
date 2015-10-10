//
//  StarshipProviderAPI.swift
//  Dip
//
//  Created by Olivier Halligon on 08/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

protocol StarshipProviderAPI {
    func fetchIDs(completion: [Int] -> Void)
    func fetch(id: Int, completion: Starship? -> Void)
}

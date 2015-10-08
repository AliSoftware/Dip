//
//  StarshipProviderAPI.swift
//  Dip
//
//  Created by Olivier Halligon on 08/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

protocol StarshipProviderAPI {
    func fetch(completion: [Starship] -> Void)
    func fetch(id: Int, completion: Starship? -> Void)
}

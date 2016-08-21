//
//  PersonProviderAPI.swift
//  Dip
//
//  Created by Olivier Halligon on 10/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import Foundation

protocol PersonProviderAPI {
    func fetchIDs(completion: @escaping ([Int]) -> Void)
    func fetch(id: Int, completion: @escaping (Person?) -> Void)
}

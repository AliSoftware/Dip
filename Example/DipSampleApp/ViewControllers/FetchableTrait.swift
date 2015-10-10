//
//  FetchableTrait.swift
//  Dip
//
//  Created by Olivier Halligon on 09/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit

protocol FetchableTrait: class {
    typealias ObjectType
    var objects: [ObjectType]? { get set }
    var batchRequestID: Int { get set }
    var tableView: UITableView! { get }
    
    var fetchOne: (Int, ObjectType? -> Void) -> Void { get }
    var fetchAll: ([ObjectType] -> Void) -> Void { get }
}

extension FetchableTrait {
    func fetchObjects(objectIDs: [Int]) {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        
        objects?.removeAll()
        for objectID in objectIDs {
            fetchOne(objectID) { (object: ObjectType?) in
                // Exit if we failed to retrive an object for this ID, or if the request
                // should be ignore because a new batch request has been started since
                guard let object = object where batch == self.batchRequestID else { return }
                if var list = self.objects {
                    list.append(object)
                } else {
                    self.objects = [object]
                }
                self.tableView?.reloadData()
            }
        }
    }
    
    func fetchAllObjects() {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        
        fetchAll() { objects in
            guard batch == self.batchRequestID else { return }
            self.objects = objects
            self.tableView?.reloadData()
        }
    }
}
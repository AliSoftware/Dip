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
    
    var fetchIDs: ([Int] -> Void) -> Void { get }
    var fetchOne: (Int, ObjectType? -> Void) -> Void { get }
    var fetchProgress: (current: Int, total: Int?) { get set }
}

extension FetchableTrait {
    func fetchObjects(objectIDs: [Int]) {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        
        objects?.removeAll()
        fetchProgress = (0,objectIDs.count)
        for objectID in objectIDs {
            fetchOne(objectID) { (object: ObjectType?) in
                // Exit if we failed to retrive an object for this ID, or if the request
                // should be ignored because a new batch request has been started since
                guard let object = object where batch == self.batchRequestID else { return }

                if self.objects == nil { self.objects = [] }
                self.objects?.append(object)
                self.fetchProgress = (self.objects?.count ?? 0, objectIDs.count)
                self.tableView?.reloadData()
            }
        }
    }
    
    func fetchAllObjects() {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        fetchProgress = (0, nil)
        fetchIDs() { objectIDs in
            guard batch == self.batchRequestID else { return }
            self.fetchObjects(objectIDs)
        }
    }
    
    func displayProgressInNavBar(navigationItem: UINavigationItem) {
        let text: String
        if let total = fetchProgress.total {
            if fetchProgress.current == fetchProgress.total {
                text = "Done."
            } else {
                text = "Loading \(fetchProgress.current) / \(total)…"
            }
        } else {
            text = "Loading IDs…"
        }
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        label.text = text
        label.textColor = .grayColor()
        label.font = .systemFontOfSize(12)
        label.sizeToFit()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: label)
    }
}
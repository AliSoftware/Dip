//
//  FetchableTrait.swift
//  Dip
//
//  Created by Olivier Halligon on 09/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit

protocol FetchableTrait: class {
    associatedtype ObjectType
    var objects: [ObjectType]? { get set }
    var batchRequestID: Int { get set }
    var tableView: UITableView! { get }
    
    func fetchIDs(completion: @escaping ([Int]) -> Void)
    func fetchOne(id: Int, completion: @escaping (ObjectType?) -> Void)
    var fetchProgress: (current: Int, total: Int?) { get set }
}

extension FetchableTrait {
    func loadObjects(objectIDs: [Int]) {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        
        objects?.removeAll()
        fetchProgress = (0,objectIDs.count)
        for objectID in objectIDs {
            fetchOne(id: objectID) { (object: ObjectType?) in
                // Exit if we failed to retrive an object for this ID, or if the request
                // should be ignored because a new batch request has been started since
                guard let object = object, batch == self.batchRequestID else { return }

                if self.objects == nil { self.objects = [] }
                self.objects?.append(object)
                self.fetchProgress.current = self.objects?.count ?? 0
                self.tableView?.reloadData()
            }
        }
    }
    
    func loadFirstPage() {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        fetchProgress = (0, nil)
        fetchIDs() { objectIDs in
            guard batch == self.batchRequestID else { return }
            self.loadObjects(objectIDs: objectIDs)
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
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 12)
        label.sizeToFit()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: label)
    }
}

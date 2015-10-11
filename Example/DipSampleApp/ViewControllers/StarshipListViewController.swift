//
//  StarshipListViewController.swift
//  Dip
//
//  Created by Olivier Halligon on 09/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit

class StarshipListViewController : UITableViewController, FetchableTrait {
    var objects: [Starship]?
    var batchRequestID = 0
    
    var provider: (Int? -> StarshipProviderAPI) = { providerDependencies.resolve($0) }
    lazy var fetchIDs: ([Int] -> Void) -> Void = self.provider(nil).fetchIDs
    lazy var fetchOne: (Int, Starship? -> Void) -> Void = { shipID, completion in
        self.provider(shipID).fetch(shipID, completion: completion)
    }
    
    var fetchProgress: (current: Int, total: Int?) = (0, nil) {
        didSet {
            displayProgressInNavBar(self.navigationItem)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard
            let id = segue.identifier, segueID = UIStoryboard.Segue.Main(rawValue: id)
            where segueID == .PilotsSegue,
            let indexPath = self.tableView.indexPathForSelectedRow,
            let destVC = segue.destinationViewController as? PersonListViewController,
            let starship = self.objects?[indexPath.row]
            else {
                fatalError()
        }
        
        destVC.fetchObjects(starship.pilotIDs)
    }
}

extension StarshipListViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let object = self.objects?[indexPath.row] else { fatalError() }
        let cell = StarshipCell.dequeueFromTableView(tableView, forIndexPath: indexPath)
        cell.fillWithObject(object)
        return cell
    }
}

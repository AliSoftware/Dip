//
//  PersonListViewController.swift
//  Dip
//
//  Created by Olivier Halligon on 09/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit

class PersonListViewController: UITableViewController {
    var objects: [Person]?
    var batchRequestID = 0
    
    let provider = dip.resolve() as PersonProviderAPI

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard
            let id = segue.identifier, segueID = UIStoryboard.Segue.Main(rawValue: id)
            where segueID == .StarshipsSegue,
            let indexPath = self.tableView.indexPathForSelectedRow,
            let destVC = segue.destinationViewController as? StarshipListViewController,
            let person = self.objects?[indexPath.row]
            else {
                fatalError()
        }
        
        destVC.fetchObjects(person.starshipIDs)
    }
}

extension PersonListViewController : FetchableTrait {
    var fetchOne: (Int, Person? -> Void) -> Void {
        return self.provider.fetch
    }
    var fetchAll: ([Person] -> Void) -> Void {
        return self.provider.fetch
    }
}

extension PersonListViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let object = self.objects?[indexPath.row] else { fatalError() }
        let cell = PersonCell.dequeueFromTableView(tableView, forIndexPath: indexPath)
        cell.fillWithObject(object)
        return cell
    }
}
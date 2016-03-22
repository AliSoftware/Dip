//
//  PersonListViewController.swift
//  Dip
//
//  Created by Olivier Halligon on 09/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit

class PersonListViewController: UITableViewController, FetchableTrait {
    var objects: [Person]?
    var batchRequestID = 0
    
    var personProvider: PersonProviderAPI!
    var starshipProvider: StarshipProviderAPI!
        
    func fetchIDs(completion: [Int] -> Void) {
        return personProvider.fetchIDs(completion)
    }
    
    func fetchOne(personID: Int, completion: Person? -> Void) {
        return personProvider.fetch(personID, completion: completion)
    }
    
    var fetchProgress: (current: Int, total: Int?) = (0, nil) {
        didSet {
            displayProgressInNavBar(self.navigationItem)
        }
    }

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
        destVC.starshipProvider = starshipProvider
        destVC.loadObjects(person.starshipIDs)
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

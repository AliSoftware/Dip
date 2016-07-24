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
    
    func fetchIDs(completion: ([Int]) -> Void) {
        return personProvider.fetchIDs(completion: completion)
    }
    
    func fetchOne(id personID: Int, completion: (Person?) -> Void) {
        return personProvider.fetch(id: personID, completion: completion)
    }
    
    var fetchProgress: (current: Int, total: Int?) = (0, nil) {
        didSet {
            displayProgressInNavBar(navigationItem: self.navigationItem)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
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
        destVC.loadObjects(objectIDs: person.starshipIDs)
    }
}

extension PersonListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let object = self.objects?[indexPath.row] else { fatalError() }
        let cell = PersonCell.dequeueFromTableView(tableView, forIndexPath: indexPath)
        cell.fillWithObject(object: object)
        return cell
    }
}

//
//  PersonListViewController.swift
//  Dip
//
//  Created by Olivier Halligon on 09/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit

class PersonListViewController: UITableViewController {
    let provider = dip.resolve() as PersonProviderAPI
    var persons = [Person]()
    var batchRequestID = 0
    
    func loadPersons(personIDs: [Int]) {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        
        persons.removeAll()
        for personID in personIDs {
            provider.fetch(personID) { (person: Person?) in
                // Exit if we failed to retrive a person for this ID, or if the request
                // should be ignore because a new batch request has been started since
                guard let person = person where batch == self.batchRequestID else { return }
                
                self.persons.append(person)
                self.tableView.reloadData()
            }
        }
    }
    
    func loadPersons() {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        
        provider.fetch { persons in
            guard batch == self.batchRequestID else { return }
            self.persons = persons
            self.tableView.reloadData()
        }
    }
}

extension PersonListViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return persons.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = PersonCell.dequeueFromTableView(tableView, forIndexPath: indexPath)
        let person = self.persons[indexPath.row]
        cell.fillWithPerson(person)
        return cell
    }
}

extension PersonListViewController {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard
            let id = segue.identifier, segueID = UIStoryboard.Segue.Main(rawValue: id)
            where segueID == .StarshipsSegue,
            let indexPath = self.tableView.indexPathForSelectedRow,
            let destVC = segue.destinationViewController as? StarshipListViewController
            else {
                fatalError()
        }
        
        let person = self.persons[indexPath.row]
        destVC.loadStarships(person.starshipIDs)
    }
}
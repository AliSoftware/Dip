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
    
    func fetchIDs(completion: @escaping ([Int]) -> Void) {
        return personProvider.fetchIDs(completion: completion)
    }
    
    func fetchOne(id personID: Int, completion: @escaping (Person?) -> Void) {
        return personProvider.fetch(id: personID, completion: completion)
    }
    
    var fetchProgress: (current: Int, total: Int?) = (0, nil) {
        didSet {
            displayProgressInNavBar(navigationItem: self.navigationItem)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            let id = segue.identifier,
            let segueID = UIStoryboard.Segue.Main(rawValue: id),
            segueID == .StarshipsSegue,
            let indexPath = self.tableView.indexPathForSelectedRow,
            let destVC = segue.destination as? StarshipListViewController,
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

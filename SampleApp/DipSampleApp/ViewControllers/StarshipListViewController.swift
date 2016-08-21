//
//  StarshipListViewController.swift
//  Dip
//
//  Created by Olivier Halligon on 09/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit
import Dip

class StarshipListViewController : UITableViewController, FetchableTrait {
    var objects: [Starship]?
    var batchRequestID = 0
    
    var starshipProvider: StarshipProviderAPI!
    var personProvider: PersonProviderAPI!
    
    func fetchIDs(completion: @escaping ([Int]) -> Void) {
        starshipProvider.fetchIDs(completion: completion)
    }
    func fetchOne(id shipID:Int, completion: @escaping (Starship?) -> Void) {
        starshipProvider.fetch(id: shipID, completion: completion)
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
            segueID == .PilotsSegue,
            let indexPath = self.tableView.indexPathForSelectedRow,
            let destVC = segue.destination as? PersonListViewController,
            let starship = self.objects?[indexPath.row]
            else {
                fatalError()
        }
        
        destVC.personProvider = personProvider
        destVC.loadObjects(objectIDs: starship.pilotIDs)
    }
}

extension StarshipListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let object = self.objects?[indexPath.row] else { fatalError() }
        let cell = StarshipCell.dequeueFromTableView(tableView, forIndexPath: indexPath)
        cell.fillWithObject(object: object)
        return cell
    }
}

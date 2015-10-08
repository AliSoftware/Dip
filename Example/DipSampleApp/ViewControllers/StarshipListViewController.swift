//
//  StarshipListViewController.swift
//  Dip
//
//  Created by Olivier Halligon on 09/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit

class StarshipListViewController : UITableViewController {
    let provider = dip.resolve() as StarshipProviderAPI
    var starships = [Starship]()
    var batchRequestID = 0
    
    func loadStarships(starshipIDs: [Int]) {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        
        starships.removeAll()
        for starshipID in starshipIDs {
            provider.fetch(starshipID) { (starship: Starship?) in
                // Exit if we failed to retrive a starship for this ID, or if the request
                // should be ignore because a new batch request has been started since
                guard let starship = starship where batch == self.batchRequestID else { return }
                
                self.starships.append(starship)
                self.tableView.reloadData()
            }
        }
    }
    
    func loadStarships() {
        self.batchRequestID += 1
        let batch = self.batchRequestID
        
        provider.fetch { starships in
            guard batch == self.batchRequestID else { return }
            self.starships = starships
            self.tableView.reloadData()
        }
    }
}

extension StarshipListViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return starships.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = StarshipCell.dequeueFromTableView(tableView, forIndexPath: indexPath)
        let starship = self.starships[indexPath.row]
        cell.fillWithStarship(starship)
        return cell
    }
}

extension StarshipListViewController {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard
            let id = segue.identifier, segueID = UIStoryboard.Segue.Main(rawValue: id)
            where segueID == .PilotsSegue,
            let indexPath = self.tableView.indexPathForSelectedRow,
            let destVC = segue.destinationViewController as? PersonListViewController
            else {
                fatalError()
        }
        
        let starship = self.starships[indexPath.row]
        destVC.loadPersons(starship.pilotIDs)
    }
}
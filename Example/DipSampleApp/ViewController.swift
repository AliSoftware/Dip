//
//  ViewController.swift
//  DipSampleApp
//
//  Created by Olivier Halligon on 04/10/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit
import Dip

let kCellIdentifier = "Cell"

class ViewController: UIViewController {
    let ws = Dependency.resolve() as WebServiceAPI
    
    var personList = [Person]()
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var displayModeSelector: UISegmentedControl!
    
    @IBAction func fetchPeople(sender: UIButton) {
        sender.enabled = false
        self.activityIndicator.startAnimating()
        ws.fetchPeopleList { persons in
            self.activityIndicator.stopAnimating()
            sender.enabled = true
            self.personList = persons ?? []
            self.tableView.reloadData()
        }
    }

    @IBAction func displayModeChanged(sender: UISegmentedControl) {
        self.tableView.reloadData()
    }
}


extension ViewController : UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.personList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier, forIndexPath: indexPath)

        let person = personList[indexPath.row]
        let formatter = Dependency.resolve(formatterTag) as PersonFormatterAPI
        cell.textLabel?.text = formatter.textForPerson(person)
        cell.detailTextLabel?.text = formatter.subtextForPerson(person)
        
        return cell
    }
    
    var formatterTag: String {
        switch displayModeSelector.selectedSegmentIndex {
        case 0: return PersonFormatterTags.MassHeight.rawValue
        default: return PersonFormatterTags.EyesHair.rawValue
        }
    }
}

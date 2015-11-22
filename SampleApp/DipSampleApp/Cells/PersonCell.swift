//
//  UserCell.swift
//  Dip
//
//  Created by Olivier Halligon on 10/09/2015.
//  Copyright © 2015 AliSoftware. All rights reserved.
//

import UIKit

final class PersonCell : UITableViewCell, FillableCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var genderImageView: UIImageView!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var massLabel: UILabel!
    @IBOutlet weak var hairLabel: UILabel!
    @IBOutlet weak var eyesLabel: UILabel!
    
    let heightFormatter: NSLengthFormatter = {
        let f = NSLengthFormatter()
        f.forPersonHeightUse = true
        return f
        }()
    let massFormatter: NSMassFormatter = {
        let f = NSMassFormatter()
        f.forPersonMassUse = true
        return f
    }()
    
    func fillWithObject(person: Person) {
        nameLabel.text = person.name
        genderImageView.image = person.gender.flatMap { UIImage(named: $0.rawValue) }
        heightLabel.text = heightFormatter.stringFromValue(Double(person.height), unit: .Centimeter)
        massLabel.text = massFormatter.stringFromValue(Double(person.mass), unit: .Kilogram)
        hairLabel.text = person.hairColor
        eyesLabel.text = person.eyeColor
    }
}

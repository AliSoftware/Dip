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
    
    let heightFormatter: LengthFormatter = {
        let f = LengthFormatter()
        f.isForPersonHeightUse = true
        return f
        }()
    let massFormatter: MassFormatter = {
        let f = MassFormatter()
        f.isForPersonMassUse = true
        return f
    }()
    
    func fillWithObject(object person: Person) {
        nameLabel.text = person.name
        genderImageView.image = person.gender.flatMap { UIImage(named: $0.rawValue) }
        heightLabel.text = heightFormatter.string(fromValue: Double(person.height), unit: .centimeter)
        massLabel.text = massFormatter.string(fromValue: Double(person.mass), unit: .kilogram)
        hairLabel.text = person.hairColor
        eyesLabel.text = person.eyeColor
    }
}

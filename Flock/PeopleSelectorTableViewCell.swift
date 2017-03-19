//
//  PeopleSelectorTableViewCell.swift
//  Flock
//
//  Created by Grant Rheingold on 3/19/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class PeopleSelectorTableViewCell: UITableViewCell {

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.resetButtonUI()
        self.profilePic.makeViewCircle()
    }

    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var selectorButton: UIButton!
    
    @IBAction func selectorButtonPressed(_ sender: Any) {
        self.setSelected(!self.isSelected, animated: true)
    }
    func resetButtonUI() {
        self.selectorButton.backgroundColor = UIColor.clear
        self.selectorButton.layer.cornerRadius = 5
        self.selectorButton.layer.borderWidth = 1
        self.selectorButton.layer.borderColor = FlockColors.FLOCK_BLUE.cgColor
    }
    func setButtonUI() {
        self.selectorButton.backgroundColor = FlockColors.FLOCK_BLUE
        self.selectorButton.layer.cornerRadius = 5
        self.selectorButton.layer.borderWidth = 1
        self.selectorButton.layer.borderColor = FlockColors.FLOCK_BLUE.cgColor
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if(self.isSelected) {
            self.setButtonUI()
        } else {
            self.resetButtonUI()
        }
        // Configure the view for the selected state
    }

}

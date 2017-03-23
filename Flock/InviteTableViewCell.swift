//
//  InviteTableViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 22/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class InviteTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
    }
    
    var indexPath : IndexPath?
    var delegate : InviteSenderTableViewDelegate?
    var firstName : String?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var backgroundButtonView: UIButton!
    @IBOutlet weak var innerButtonView: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    @IBAction func innerbuttonPressed(_ sender: Any) {
        performInvite()
    }
    
    
    @IBAction func outerButtonPressed(_ sender: Any) {
        performInvite()
    }
    
    func resetUI() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        backgroundButtonView.isHidden = false
        innerButtonView.isHidden = false
    }
    
    
    func performInvite() {

        backgroundButtonView.isHidden = true
        innerButtonView.isHidden = true
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        activityIndicator.color = FlockColors.FLOCK_BLUE
        let nameToPass : String
        if firstName != nil {
            nameToPass = firstName!
        }
        else {
            nameToPass = nameLabel.text!
        }
        
        self.delegate?.openTextMessage(toUser: nameToPass, phoneNumber: statusLabel.text!, cell : self)
    }
}

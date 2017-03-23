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
    
    var delegate : InviteSenderTableViewDelegate?
    var firstName : String?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var backgroundButtonView: UIButton!
    @IBOutlet weak var innerButtonView: UIButton!
    
    @IBAction func innerbuttonPressed(_ sender: Any) {
        performInvite()
    }
    
    
    @IBAction func outerButtonPressed(_ sender: Any) {
        performInvite()
    }
    
    func performInvite() {
        let indicator = UIActivityIndicatorView(frame: backgroundButtonView.frame)
        backgroundButtonView.isHidden = true
        innerButtonView.isHidden = true
        indicator.color = FlockColors.FLOCK_BLUE
        
        self.addSubview(indicator)
        
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

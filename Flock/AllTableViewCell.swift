//
//  AllTableViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 03/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class AllTableViewCell: UITableViewCell {
    var FBID : String?
    var chatDelegate : ChatDelegate?
    @IBOutlet weak var profilePic: UIImageView!

    @IBOutlet weak var friendName: UILabel!
    
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBAction func chatPressed(_ sender: Any) {
        if let FBID = FBID {
            chatDelegate?.callSegueFromCell(fbid: FBID)
        }
        
    }
    @IBOutlet weak var chatButton: UIButton!

}

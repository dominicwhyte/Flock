//
//  FriendRequestTableViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 03/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class FriendRequestTableViewCell: UITableViewCell {
    
    @IBOutlet weak var friendName: UILabel!
    
    @IBOutlet weak var profilePic: UIImageView!
    
    @IBAction func acceptRequest(_ sender: Any) {
    }
    
    @IBAction func rejectRequest(_ sender: Any) {
    }
    
}

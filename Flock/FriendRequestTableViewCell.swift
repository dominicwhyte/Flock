//
//  FriendRequestTableViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 03/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class FriendRequestTableViewCell: UITableViewCell {
    var fromID : String?
    var toID : String?
    
    weak var delegate: UpdateTableViewDelegate?
    
    func setIDs(fromID : String, toID : String) {
        self.fromID = fromID
        self.toID = toID
    }


    @IBOutlet weak var friendName: UILabel!
    
    @IBOutlet weak var profilePic: UIImageView!
    
    @IBAction func acceptRequest(_ sender: Any) {
        let loadingScreen = Utilities.presentLoadingScreen(vcView: delegate!.parentView!)
        FirebaseClient.confirmFriendRequest(fromID!, toID: toID!) { (success) in
            self.delegate?.updateDataAndTableView({ (successReloadData) in
                Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.delegate!.parentView!)
                if(success && successReloadData) {
                    Utilities.printDebugMessage("Successfully accepted friend request and reloaded data")
                } else {
                    Utilities.printDebugMessage("Unable to accept friend request")
                }
            })
            
        }
    }
    
    @IBAction func rejectRequest(_ sender: Any) {
        FirebaseClient.rejectFriendRequest(fromID!, toID: toID!) { (success) in
            self.delegate?.updateDataAndTableView({ (successReloadData) in
                if(success && successReloadData) {
                    Utilities.printDebugMessage("Successfully rejected friend rquest")
                } else {
                    Utilities.printDebugMessage("Unable to reject friend request")
                }
            })
        }
    }
    
}

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

    override func awakeFromNib() {
        super.awakeFromNib()
        rejectButton.setRounded()
        acceptButton.setRounded()
    }
    
    @IBOutlet weak var rejectButton: UIButton!
    
    @IBOutlet weak var acceptButton: UIButton!
    

    @IBOutlet weak var friendName: UILabel!
    
    @IBOutlet weak var profilePic: UIImageView!
    
    @IBAction func acceptButtonPressed(_ sender: Any) {
        Utilities.bounceView(viewOneIsIn: self, self.acceptButton) { (success) in
            if (!success) {
                Utilities.printDebugMessage("Error with button animation")
            }
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.delegate!.parentView!)
            FirebaseClient.confirmFriendRequest(self.fromID!, toID: self.toID!) { (success) in
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
    }
    @IBAction func rejectButtonPressed(_ sender: Any) {
        Utilities.bounceView(viewOneIsIn: self, self.rejectButton) { (success) in
            if (!success) {
                Utilities.printDebugMessage("Error with button animation")
            }
            FirebaseClient.rejectFriendRequest(self.fromID!, toID: self.toID!) { (success) in
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
    
}


extension UIView {
    
    func setRounded() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

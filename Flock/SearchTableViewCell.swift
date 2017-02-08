//
//  SearchTableViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 04/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class SearchTableViewCell: UITableViewCell {
    
    var userState : SearchPeopleTableViewController.UserStates?
    var currentUserID : String?
    var cellID : String?
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    weak var delegate: UpdateSearchTableViewDelegate?
    
    @IBAction func rejectButtonPressed(_ sender: Any) {
        switch self.userState! {
        case .alreadyFriends:
            Utilities.printDebugMessage("Reject button pressed at wrong time")
            break
        case .requestPendingFromSelf:
            Utilities.printDebugMessage("Reject button pressed at wrong time")
            break
        case .requestPendingFromUser:
            //Reject the friend request
            self.isUserInteractionEnabled = false
            setupCell(userState: .normal, currentUserID: currentUserID!, cellID: cellID!)
            FirebaseClient.rejectFriendRequest(cellID!, toID: currentUserID!, completion: { (success) in
                self.isUserInteractionEnabled = true
                Utilities.printDebugMessage("Friend request status: \(success)")
            })
        case .ourself:
            Utilities.printDebugMessage("Reject button pressed at wrong time")
            break
        case .normal:
            Utilities.printDebugMessage("Reject button pressed at wrong time")
            break
        }
    }

    @IBAction func acceptButtonPressed(_ sender: Any) {
        switch self.userState! {
        case .alreadyFriends:
            //Deflock
            self.isUserInteractionEnabled = false
            setupCell(userState: .normal, currentUserID: currentUserID!, cellID: cellID!)
            FirebaseClient.unFriendUser(cellID!, toID: currentUserID!, completion: { (success) in
                self.isUserInteractionEnabled = true
                Utilities.printDebugMessage("Deflock status: \(success)")
            })
            
        case .requestPendingFromSelf:
            //Rescind friend request sent by self
            self.isUserInteractionEnabled = false
            setupCell(userState: .normal, currentUserID: currentUserID!, cellID: cellID!)
            FirebaseClient.rejectFriendRequest(currentUserID!, toID: cellID!, completion: { (success) in
                self.isUserInteractionEnabled = true
                Utilities.printDebugMessage("Rescind friend request status: \(success)")
            })
            
        case .requestPendingFromUser:
            //Accept the friend request
            self.isUserInteractionEnabled = false
            setupCell(userState: .normal, currentUserID: currentUserID!, cellID: cellID!)
            FirebaseClient.confirmFriendRequest(cellID!, toID: currentUserID!, completion: { (success) in
                self.isUserInteractionEnabled = true
                Utilities.printDebugMessage("Friend request confirmation status: \(success)")
            })
        case .ourself:
            Utilities.printDebugMessage("Reject button pressed at wrong time")
            break
        case .normal:
            //Flock user
            self.isUserInteractionEnabled = false
            setupCell(userState: .requestPendingFromSelf, currentUserID: currentUserID!, cellID: cellID!)
            FirebaseClient.sendFriendRequest(currentUserID!, toID: cellID!, completion: { (success) in
                self.isUserInteractionEnabled = true
                Utilities.printDebugMessage("Flocked status: \(success)")
            })
        }

    }
    
    func setupCell(userState: SearchPeopleTableViewController.UserStates, currentUserID: String, cellID: String) {
        delegate?.updateStateDict(FBID: cellID, state: userState)
        
        self.userState = userState
        self.currentUserID = currentUserID
        self.cellID = cellID
        
        switch self.userState! {
        case .alreadyFriends:
            self.rejectButton.isHidden = true
            self.acceptButton.isHidden = false
            self.acceptButton.setTitle("Unflock", for: .normal)
            self.statusLabel.text = "Friends"
        case .requestPendingFromSelf:
            self.rejectButton.isHidden = true
            self.acceptButton.isHidden = false
            self.acceptButton.setTitle("Cancel", for: .normal)
            self.statusLabel.text = "Pending"
        case .requestPendingFromUser:
            self.rejectButton.isHidden = false
            self.acceptButton.isHidden = false
            self.rejectButton.setTitle("Reject", for: .normal)
            self.acceptButton.setTitle("Accept", for: .normal)
            self.statusLabel.text = "Pending"
        case .ourself:
            self.rejectButton.isHidden = true
            self.acceptButton.isHidden = true
            self.statusLabel.text = ""
        case .normal:
            self.rejectButton.isHidden = true
            self.acceptButton.isHidden = false
            self.acceptButton.setTitle("Flock", for: .normal)
            self.statusLabel.text = ""
        }
        
    }

    

}

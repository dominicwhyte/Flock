//
//  SearchTableViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 04/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class SearchTableViewCell: MGSwipeTableCell, MGSwipeTableCellDelegate {
    
    var userState : SearchPeopleTableViewController.UserStates?
    var currentUserID : String?
    var cellID : String?
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    
    weak var searchDelegate: UpdateSearchTableViewDelegate?
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        
        // delete item at indexPath
        //let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
        self.setupCell(userState: .normal, currentUserID: currentUserID!, cellID: cellID!)
        
        
        FirebaseClient.unFriendUser(cellID!, toID: currentUserID!, completion: { (success) in
            //Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
            Utilities.printDebugMessage("Deflock status: \(success)")
            cell.setEditing(false, animated: true)
            
        })

        return true
    }
    
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
            setupCell(userState: .alreadyFriends, currentUserID: currentUserID!, cellID: cellID!)
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
        searchDelegate?.updateStateDict(FBID: cellID, state: userState)
        self.delegate = self
        self.userState = userState
        self.currentUserID = currentUserID
        self.cellID = cellID
        
        switch self.userState! {
        case .alreadyFriends:
            self.rejectButton.isHidden = true
            self.acceptButton.isHidden = true
            self.statusLabel.text = "In Flock"
            //setup swipe
            self.rightButtons = [MGSwipeButton(title: "Unflock", backgroundColor: FlockColors.FLOCK_GRAY)]
            self.rightSwipeSettings.transition = MGSwipeTransition.border
            self.acceptButton.setBackgroundImage(UIImage(named: "whiteCancelIcon"), for: .normal)
            self.acceptButton.backgroundColor = FlockColors.FLOCK_GRAY
            self.acceptButton.setRounded()
        case .requestPendingFromSelf:
            self.rightButtons = []
            self.rejectButton.isHidden = true
            self.acceptButton.isHidden = false
            self.statusLabel.text = "Pending"
            self.acceptButton.backgroundColor = FlockColors.FLOCK_GRAY
            self.acceptButton.setBackgroundImage(UIImage(named: "whiteCancelIcon"), for: .normal)
            self.acceptButton.setRounded()
        case .requestPendingFromUser:
            self.rightButtons = []
            self.rejectButton.isHidden = false
            self.acceptButton.isHidden = false
            self.statusLabel.text = "Flock Request"
            
            // New version

            self.acceptButton.backgroundColor = FlockColors.FLOCK_GRAY
            self.rejectButton.setBackgroundImage(UIImage(named: "whiteCancelIcon"), for: .normal)
            self.rejectButton.setRounded()
            
            self.acceptButton.backgroundColor = FlockColors.FLOCK_BLUE
            self.acceptButton.setBackgroundImage(UIImage(named: "whiteCheckmarkIcon"), for: .normal)
            self.acceptButton.setRounded()
        case .ourself:
            self.rightButtons = []
            self.rejectButton.isHidden = true
            self.acceptButton.isHidden = true
            self.statusLabel.text = "Me"
        case .normal:
            self.rightButtons = []
            self.rejectButton.isHidden = true
            self.acceptButton.isHidden = false
            self.statusLabel.text = ""
            self.acceptButton.backgroundColor = FlockColors.FLOCK_BLUE
            self.acceptButton.setBackgroundImage(UIImage(named: "whiteAddIcon"), for: .normal)
            self.acceptButton.setRounded()
        }
    }


}

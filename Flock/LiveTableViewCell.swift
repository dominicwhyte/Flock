//
//  LiveTableViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 03/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class LiveTableViewCell: MGSwipeTableCell, MGSwipeTableCellDelegate {
    var event : Event?
    var FBID : String?
    var chatDelegate : ChatDelegate?
    struct Constants {
        static let CELL_HEIGHT = 75
    }
    @IBOutlet weak var chatButton: UIButton!
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        if let event = event {
            Utilities.animateToPlacesTabWithVenueIDandDate(venueID: event.EventID
                , date: Date())
        }
        return true
    }
    
    @IBAction func chatPressed(_ sender: Any) {
        if let FBID = FBID {
            chatDelegate?.callSegueFromCell(fbid: FBID)
        }
    }
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var friendName: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    func setupCell(event: Event) {
        self.event = event
        subtitleLabel.text = event.EventName
        var leftButtonsArray = [MGSwipeButton]()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let venueImages = appDelegate.venueImages
        
        
        if (UIImage(named: event.EventID) != nil) {
            let venueImage = UIImage(named: event.EventID)
            let button = MGSwipeButton(title: "", icon: nil, backgroundColor: UIColor.clear)
            button.setBackgroundImage(venueImage, for: .normal)
            button.frame = CGRect(x: 0, y: 0, width: Constants.CELL_HEIGHT, height: Constants.CELL_HEIGHT)
            leftButtonsArray.append(button)
        }
        //imageURL not in image cache
        else {
            if let imageURL = event.EventImageURL {
            appDelegate.getMissingImage(imageURL: imageURL, venueID: event.EventID, completion: { (status) in
                if (status) {
                    DispatchQueue.main.async {
                        if let eventImage = venueImages[imageURL] {
                            let button = MGSwipeButton(title: "", icon: nil, backgroundColor: UIColor.clear)
                            button.setBackgroundImage(eventImage, for: .normal)
                            button.frame = CGRect(x: 0, y: 0, width: Constants.CELL_HEIGHT, height: Constants.CELL_HEIGHT)
                            leftButtonsArray.append(button)
                        }
                        else {
                            Utilities.printDebugMessage("Error: could not retrieve image")
                        }
                    }
                }
            })
            }
        }
        
        
        
        
        
        //configure left buttons
        self.leftButtons = leftButtonsArray
        self.leftSwipeSettings.transition = MGSwipeTransition.border
        self.preservesSuperviewLayoutMargins = false
        self.separatorInset = UIEdgeInsets.zero
        self.layoutMargins = UIEdgeInsets.zero
        
        // Configure delegate
        self.delegate = self
        
    }
    
}

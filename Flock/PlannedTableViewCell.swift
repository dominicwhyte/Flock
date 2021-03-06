//
//  PlannedTableViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 03/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class PlannedTableViewCell: MGSwipeTableCell, MGSwipeTableCellDelegate {
    
    struct Constants {
        static let CELL_HEIGHT = 75
    }
    
    @IBAction func chatButtonPressed(_ sender: Any) {
        if let FBID = FBID {
            self.chatDelegate?.callSegueFromCell(fbid: FBID)
        }
        
    }
    @IBOutlet weak var chatButton: UIButton!
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var friendName: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    let MAX_VENUES_TO_DISPLAY = 3
    var FBID : String?
    var plans = [Plan]()
    var chatDelegate : ChatDelegate?
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        let plan = plans[index]
        Utilities.animateToPlacesTabWithVenueIDandDate(venueID: plan.venueID, date: plan.date)
        return true
    }
    
    func setupCell(plans : [Plan]) {
        self.plans = plans
        var leftButtonsArray = [MGSwipeButton]()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let venueImages = appDelegate.venueImages
        let events = appDelegate.activeEvents
        
        for index in 0...(MAX_VENUES_TO_DISPLAY - 1) {
            //if there are enough plans
            if (plans.count > index) {
                var button = MGSwipeButton(title: "", icon: UIImage(named:"cat.png"), backgroundColor: UIColor.blue)
                if let event = events[plans[index].venueID] {
                    if (UIImage(named: event.EventID) != nil) {
                        let venueImage = UIImage(named: event.EventID)
                        button = MGSwipeButton(title: "", icon: nil, backgroundColor: UIColor.clear)
                        button.setBackgroundImage(venueImage, for: .normal)
                        button.frame = CGRect(x: 0, y: 0, width: Constants.CELL_HEIGHT, height: Constants.CELL_HEIGHT)
                    }
                    else {
                        if let imageURL = event.EventImageURL {
                            appDelegate.getMissingImage(imageURL: imageURL, venueID: event.EventID, completion: { (status) in
                                if (status) {
                                    DispatchQueue.main.async {
                                        if let venueImage = venueImages[imageURL] {
                                            button = MGSwipeButton(title: "", icon: nil, backgroundColor: UIColor.clear)
                                            button.setBackgroundImage(venueImage, for: .normal)
                                            button.frame = CGRect(x: 0, y: 0, width: Constants.CELL_HEIGHT, height: Constants.CELL_HEIGHT)
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
                leftButtonsArray.append(button)
                
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
    
    func imageResize (image:UIImage, sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        image.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
    
}



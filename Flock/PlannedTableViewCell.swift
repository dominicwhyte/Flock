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
        static let CELL_HEIGHT = 74
    }
    
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var friendName: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    let MAX_VENUES_TO_DISPLAY = 3
    
    var plans = [Plan]()
    
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        Utilities.printDebugMessage("\(index)")
        return true
    }
    
    func setupCell(plans : [Plan]) {
        self.plans = plans
        var leftButtonsArray = [MGSwipeButton]()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let venueImages = appDelegate.venueImages
        let venues = appDelegate.venues
        
        for index in 0...(MAX_VENUES_TO_DISPLAY - 1) {
            //if there are enough plans
            if (plans.count > index) {
                
                //if the last button and there are still more plans
                if (index == MAX_VENUES_TO_DISPLAY - 1 && plans.count > MAX_VENUES_TO_DISPLAY) {
                    let image = UIImage(named:"cat.png")
                    let button = MGSwipeButton(title: "", icon: self.imageResize(image: image!, sizeChange: CGSize(width: Constants.CELL_HEIGHT, height: Constants.CELL_HEIGHT)), backgroundColor: UIColor.green)
                    leftButtonsArray.append(button)
                }
                //Just append the image button
                else {
                    var button = MGSwipeButton(title: "", icon: UIImage(named:"cat.png"), backgroundColor: UIColor.blue)
                    if let venue = venues[plans[index].venueID] {
                        if let venueImage = venueImages[venue.ImageURL] {
                            button = MGSwipeButton(title: "", icon: nil, backgroundColor: UIColor.clear)
                            button.setBackgroundImage(venueImage, for: .normal)
                        }
                    }
                    leftButtonsArray.append(button)
                }
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



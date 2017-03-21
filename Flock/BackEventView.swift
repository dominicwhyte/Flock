//
//  BackEventView.swift
//  Flock
//
//  Created by Dominic Whyte on 20/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class BackEventView: UIView {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var textLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
         //Utilities.applyVerticalGradient(aView: self, colorTop: UIColor.white, colorBottom: UIColor.black)
        self.backgroundColor = UIColor.black
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        let shadowPath = UIBezierPath(rect: bounds)
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 5.0)
        layer.shadowOpacity = 0.5
        layer.shadowPath = shadowPath.cgPath
    }
    
    func setupBackView(event : Event) {
        let random = Int(arc4random_uniform(UInt32(Utilities.Constants.PARTY_IMAGES.count)))
        backgroundImage.image = UIImage(named: Utilities.Constants.PARTY_IMAGES[random])
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        
        let startText = DateUtilities.convertDateToStringByFormat(date: event.EventDate, dateFormat: DateUtilities.Constants.uiDisplayFormat)
        let middleText = " @ "
        var endText = "TBD"
        if let venueName = appDelegate.venues[event.VenueID]?.VenueName {
            endText = venueName
        }
        let totalText = startText + middleText + endText
        let range = (totalText as NSString).range(of: middleText)
        let attributedString = NSMutableAttributedString(string:totalText)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: FlockColors.FLOCK_BLUE , range: range)
        textLabel.attributedText = attributedString
        
    }
    
}

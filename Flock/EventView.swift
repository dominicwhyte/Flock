//
//  EventView.swift
//
//
//  Created by Dominic Whyte on 19/03/17.
//
//

import UIKit

class EventView: UIView {
    
    
    var frontView : UIImageView?
    var backView : UIView?
    var frontViewShowing = true
    
    
    func setupEventView(event : Event) {
        frontView = UIImageView(frame: self.frame)
        frontView?.contentMode = .scaleAspectFill
        frontView?.clipsToBounds = true
        
        if let imageURL = event.EventImageURL {

            FirebaseClient.getImageFromURL(imageURL, { (image) in
                DispatchQueue.main.async {
                    self.frontView!.image = image
                }
            })
        }
        else {
            let random = Int(arc4random_uniform(UInt32(Utilities.Constants.PARTY_IMAGES.count)))
            self.frontView?.image = UIImage(named: Utilities.Constants.PARTY_IMAGES[random])
        }
        backView = UIView(frame: self.frame)
        self.addSubview(backView!)
        backView!.backgroundColor = UIColor.red
        self.addSubview(frontView!)
        
        frontViewShowing = true
        
        self.isUserInteractionEnabled = true
        let gesture:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(EventView.flipView))
        gesture.numberOfTapsRequired = 1
        self.addGestureRecognizer(gesture)
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
    
    
    func flipView() {
        if frontViewShowing {
            flip(firstView: frontView!, secondView: backView!)
        }
        else {
            flip(firstView: backView!, secondView: frontView!)
        }
        frontViewShowing = !frontViewShowing
    }
    
    fileprivate func flip(firstView : UIView, secondView : UIView) {
        let transitionOptions: UIViewAnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        
        UIView.transition(with: firstView, duration: 1.0, options: transitionOptions, animations: {
            firstView.isHidden = true
        })
        
        UIView.transition(with: secondView, duration: 1.0, options: transitionOptions, animations: {
            secondView.isHidden = false
        })
    }
    
    
    
}

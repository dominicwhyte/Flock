//
//  EventCollectionViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 19/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class EventCollectionViewCell: UICollectionViewCell {
    
    var frontView : UIView?
    var backView : UIView?
    var frontViewShowing = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        frontView = UIView(frame: self.frame)
        frontView!.backgroundColor = UIColor.blue
        backView = UIView(frame: self.frame)
        self.contentView.addSubview(backView!)
        backView!.backgroundColor = UIColor.red
        self.contentView.addSubview(frontView!)
        frontViewShowing = true
    }
    
    func flip() {
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

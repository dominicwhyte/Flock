//
//  EventView.swift
//
//
//  Created by Dominic Whyte on 19/03/17.
//
//

import UIKit

class EventView: UIView {
    
    
    var frontView : FrontEventView?
    var backView : UIView?
    var frontViewShowing = true
    
    func setupEventView(event : Event) {
        
        
        
//        backView = UIView(frame: self.frame)
//        self.addSubview(backView!)
//        backView!.backgroundColor = UIColor.red
        
        backView = UINib(nibName: "BackEventView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? BackEventView
        
        //backView!.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
       
        self.addSubview(backView!)

        
        frontView = UINib(nibName: "FrontEventView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? FrontEventView
        frontView?.setupFrontView(event: event)
        //frontView!.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        
        self.addSubview(frontView!)
        
        frontViewShowing = true
        
    }
    
    override func layoutSubviews() {
        let scaleFactor = self.frame.width / (backView?.frame.width)!
        Utilities.printDebugMessage("scale factor \(scaleFactor)")
        frontView!.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        backView!.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        super.layoutSubviews()
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
        
        UIView.transition(with: firstView, duration: 0.6, options: transitionOptions, animations: {
            firstView.isHidden = true
        })
        
        UIView.transition(with: secondView, duration: 0.6, options: transitionOptions, animations: {
            secondView.isHidden = false
        })
    }
}



//
//  FlockSuggestionCollectionViewCell.swift
//  Flock
//
//  Created by Dominic Whyte on 17/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class FlockSuggestionCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var plusIconImageView: UIImageView!
    @IBOutlet weak var blackView: UIView!
    
    var userToFriendFBID : String?
    var isPressed = false
    var isPerformed = false
    var delegate : FlockRecommenderDelegate?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        userImageView.isUserInteractionEnabled = true
        userImageView.addGestureRecognizer(tapGestureRecognizer)
        resetUINewCell()
        blackView.setRounded()
    }
    
    func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if (!isPerformed) {
            if (isPressed) {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                Utilities.printDebugMessage("take action")
                self.plusIconImageView.image = UIImage(named: "whiteCheckmarkIcon")
                self.isUserInteractionEnabled = false
                if let userToFriendFBID = userToFriendFBID {
                    self.isPerformed = true
                    delegate?.updateFBIDFlocked(fbid: userToFriendFBID)
                    FirebaseClient.sendFriendRequest(appDelegate.user!.FBID, toID: userToFriendFBID, completion: { (success) in
                        self.isUserInteractionEnabled = true
                        Utilities.printDebugMessage("Flocked status: \(success)")
                    })
                }
            }
            else {
                self.setPressedUI()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    DispatchQueue.main.async {
                        self.resetUI()
                    }
                })
                
            }

        }
    }
    
    func resetUINewCell() {
        isPressed = false
        plusIconImageView.isHidden = true
        userImageView.alpha = 1
        isPerformed = false
        plusIconImageView.image = UIImage(named: "whiteAddIcon")
    }
    
    func setPerformedUI() {
        isPressed = true
        plusIconImageView.isHidden = false
        userImageView.alpha = 0.4
        isPerformed = true
        self.plusIconImageView.image = UIImage(named: "whiteCheckmarkIcon")
    }
    
    func setPressedUI() {
        isPressed = true
        plusIconImageView.isHidden = false
        userImageView.alpha = 0.4
    }
    
    func resetUI() {
        if (!isPerformed) {
            isPressed = false
            plusIconImageView.isHidden = true
            userImageView.alpha = 1
        }
    }
}

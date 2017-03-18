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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        userImageView.isUserInteractionEnabled = true
        userImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        Utilities.printDebugMessage("pressed me")
    }
    
}

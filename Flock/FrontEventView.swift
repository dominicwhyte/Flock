//
//  FrontEventView.swift
//  Flock
//
//  Created by Dominic Whyte on 20/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class FrontEventView: UIView {
    
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        Utilities.applyVerticalGradient(aView: self, colorTop: UIColor.white, colorBottom: UIColor.black)
    }
    
    func setupFrontView(event : Event) {
        if let imageURL = event.EventImageURL, let venueID : String = event.VenueID {
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self)
            FirebaseClient.getImageFromURL(imageURL, venueID: venueID, { (image) in
                DispatchQueue.main.async {
                    Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self)
                    self.backgroundImage.image = image
                }
            })
        }
        else {
            let random = Int(arc4random_uniform(UInt32(Utilities.Constants.PARTY_IMAGES.count)))
            backgroundImage.image = UIImage(named: Utilities.Constants.PARTY_IMAGES[random])
        }
        titleLabel.text = event.EventName
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
    
    
//    required init(coder aDecoder: NSCoder) {   // 2 - storyboard initializer
//        super.init(coder: aDecoder)!
//        fromNib()   // 5.
//    }
//    
//    override init(frame : CGRect) {
//        super.init(frame: frame)  // 4.
//        fromNib()  // 6.
//    }
//    
//    init() {   // 3 - programmatic initializer
//        super.init(frame: CGRect())  // 4.
//        fromNib()  // 6.
//    }
//    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

//extension UIView {
//    
//    @discardableResult   // 1
//    func fromNib<T : UIView>() -> T? {   // 2
//        guard let view = Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)?[0] as? T else {    // 3
//            // xib not loaded, or it's top view is of the wrong type
//            return nil
//        }
//        self.addSubview(view)     // 4
//        view.translatesAutoresizingMaskIntoConstraints = false   // 5
//        //view.layoutAttachAll(to: self)   // 6
//        return view   // 7
//    }
//}

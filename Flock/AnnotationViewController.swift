//
//  AnnotationViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 22/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import Gecco

class AnnotationViewController: SpotlightViewController {
    
    @IBOutlet var annotationViews: [UIView]!
    
    var stepIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
    }
    
    func next(_ labelAnimated: Bool) {
        updateAnnotationView(labelAnimated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let screenSize = UIScreen.main.bounds.size
        switch stepIndex {
        case 0:
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width - 50, y: 42), size: CGSize(width: 200, height: 40), cornerRadius: 6))
        case 1:
            spotlightView.move(Spotlight.Oval(center: CGPoint(x: screenSize.width - 75, y: 42), diameter: 50))
            
        case 2:
            spotlightView.move(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width / 2, y: 42), size: CGSize(width: 200, height: 40), cornerRadius: 6), moveType: .disappear)
        case 3:
            spotlightView.move(Spotlight.Oval(center: CGPoint(x: screenSize.width / 2, y: 200), diameter: 220), moveType: .disappear)
        case 4:
            dismiss(animated: true, completion: nil)
        default:
            break
        }
        
        stepIndex += 1
    }
    
    func updateAnnotationView(_ animated: Bool) {
        annotationViews.enumerated().forEach { index, view in
            UIView.animate(withDuration: animated ? 0.25 : 0) {
                view.alpha = index == self.stepIndex ? 1 : 0
            }
        }
    }
}

extension AnnotationViewController: SpotlightViewControllerDelegate {
    func spotlightViewControllerWillPresent(_ viewController: SpotlightViewController, animated: Bool) {
        next(false)
    }
    
    func spotlightViewControllerTapped(_ viewController: SpotlightViewController, isInsideSpotlight: Bool) {
        next(true)
    }
    
    func spotlightViewControllerWillDismiss(_ viewController: SpotlightViewController, animated: Bool) {
        spotlightView.disappear()
    }
}

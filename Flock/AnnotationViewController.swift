//
//  AnnotationViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 22/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import Gecco
import PopupDialog

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
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: 0, y: 0), size: CGSize(width: 0, height: 0), cornerRadius: 6))
            //self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width - 50, y: 42), size: CGSize(width: 200, height: 40), cornerRadius: 6))
            
        case 1:
            
            //Utilities.animateToPlacesTabWithVenueIDandDate(venueID: "-KeKwzPquXWfqtI-jjPU", date: Date())
            //let vc = appDelegate.getCurrentViewController() as! PopupDialog
            /*
             Messing around:
             DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
             let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController
             viewController.alpha = 0.5
             viewController.stepIndex = 2
             let vc = appDelegate.getCurrentViewController() as! PopupDialog
             vc.present(viewController, animated: true, completion: nil)
             
             })
             
             */
            
            
            /*
             appDelegate.simpleTBC!.animateToTab(0, completion: { (navCon) in
             if let navCon = navCon as? UINavigationController {
             let vc = navCon.topViewController as! PlacesTableViewController
             if (vc.venues.count != 0) {
             let venueID = vc.venues[0].VenueID
             
             //vc.displayVenuePopupWithVenueIDForDay(venueID: venueID, date: Date())
             }
             else {
             Utilities.printDebugMessage("Failed to present walkthrough popup")
             }
             
             
             }
             
             })
             
             appDelegate.simpleTBC!.animateToSearch(1, completion: { (navCon) in
             if let navCon = navCon as? UINavigationController {
             let vc = navCon.topViewController as! PeopleTableViewController
             vc.performSegue(withIdentifier: "ADD_IDENTIFIER", sender: vc)
             //appDelegate.simpleTBC!.present(vc, animated: true, completion: nil)
             vc.tableView.setContentOffset(CGPoint.zero, animated: true)
             
             //let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController
             //viewController.alpha = 0.5
             
             //appDelegate.simpleTBC!.present(viewController, animated: true, completion: nil)
             }
             
             })
             */
            
            /*let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
             let nextViewController = storyBoard.instantiateViewController(withIdentifier: "Search") as! SearchPeopleTableViewController
             self.present(nextViewController, animated:true, completion:nil)
             let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController*/
            
            
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width - 50, y: 42), size: CGSize(width: screenSize.width/2, height: 40), cornerRadius: 6))
            //spotlightView.move(Spotlight.Oval(center: CGPoint(x: screenSize.width - 75, y: 42), diameter: 50))
            
            
            
            
        case 2:
            //            appDelegate.simpleTBC!.animateToTab(2, completion: { (navCon) in
            //                if let navCon = navCon as? UINavigationController {
            //                    let vc = navCon.topViewController as! ChatsTableViewController
            //
            //
            //                    //let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController
            //                    //viewController.alpha = 0.5
            //
            //                    //appDelegate.simpleTBC!.present(viewController, animated: true, completion: nil)
            //                }
            //
            //            })
            //spotlightView.move(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width / 2, y: 42), size: CGSize(width: 200, height: 40), cornerRadius: 6), moveType: .disappear)
            //self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width - 50, y: 42), size: CGSize(width: 200, height: 40), cornerRadius: 6))
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: 0, y: 0), size: CGSize(width: 0, height: 0), cornerRadius: 6))
        case 3:
            appDelegate.simpleTBC!.animateToTab(0, completion: { (navCon) in
                if let navCon = navCon as? UINavigationController {
                    let vc = navCon.topViewController as! PlacesTableViewController
                    print("\(vc.tableView.contentOffset.y)")
                    vc.tableView.setContentOffset(CGPoint(x: 0,y: -64), animated: true)
                    //vc.displayVenuePopupWithVenueIDForDay(venueID: "-KeKx9Pri9kpJmNe72uQ", date: Date())
                    //vc.showCustomDialog(venue: appDelegate.venues["-KeKx9Pri9kpJmNe72uQ"]!, startDisplayDate: Date())
                    
                    
                    //let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController
                    //viewController.alpha = 0.5
                    
                    //appDelegate.simpleTBC!.present(viewController, animated: true, completion: nil)
                }
                
            })
            //spotlightView.move(Spotlight.Oval(center: CGPoint(x: screenSize.width / 2, y: 200), diameter: 220), moveType: .disappear)
            if let user = appDelegate.user {
                var hasPendingInvitations = false
                for (_, invitation) in user.Invitations {
                    if(DateUtilities.dateIsWithinValidTimeframe(date: invitation.date)) {
                        if let isAccepted = invitation.accepted {
                            if(isAccepted) {
                                hasPendingInvitations = true
                            }
                        } else {
                            print("Hmmm, something is curious")
                            hasPendingInvitations = true
                        }
                    }
                }
                if(!hasPendingInvitations) {
                    print("No invites")
                    self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width/2, y: screenSize.height*(8/20)), size: CGSize(width: screenSize.width, height: screenSize.height*(9/20)), cornerRadius: 6))
                } else {
                    print("I have some invitations yo")
                    self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width/2, y: screenSize.height*(8/20) + 124), size: CGSize(width: screenSize.width, height: screenSize.height*(9/20)), cornerRadius: 6))
                }
            }
          
        case 4:
            if let user = appDelegate.user {
                var hasPendingInvitations = false
                for (_, invitation) in user.Invitations {
                    if(DateUtilities.dateIsWithinValidTimeframe(date: invitation.date)) {
                        if let isAccepted = invitation.accepted {
                            if(isAccepted) {
                                hasPendingInvitations = true
                            }
                        } else {
                            hasPendingInvitations = true
                        }
                    }
                }
                if(!hasPendingInvitations) {
                    print("No invites")
                    self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width/2, y: screenSize.height*(8/20)), size: CGSize(width: screenSize.width, height: screenSize.height*(9/20)), cornerRadius: 6))
                } else {
                    print("I have some invitations yo")
                    self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width/2, y: screenSize.height*(8/20) + 124), size: CGSize(width: screenSize.width, height: screenSize.height*(9/20)), cornerRadius: 6))
                }
            }
        case 5:
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width - 50, y: 42), size: CGSize(width: screenSize.width/2, height: 40), cornerRadius: 6))
        case 6:
            appDelegate.simpleTBC!.animateToTab(4, completion: { (navCon) in
                if let navCon = navCon as? UINavigationController {
                    let vc = navCon.topViewController as! EventsViewController
                    //vc.displayVenuePopupWithVenueIDForDay(venueID: "-KeKx9Pri9kpJmNe72uQ", date: Date())
                    //vc.showCustomDialog(venue: appDelegate.venues["-KeKx9Pri9kpJmNe72uQ"]!, startDisplayDate: Date())
                    
                    
                    //let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController
                    //viewController.alpha = 0.5
                    
                    //appDelegate.simpleTBC!.present(viewController, animated: true, completion: nil)
                }
                
            })
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width/2, y: screenSize.height*(1/4)), size: CGSize(width: screenSize.width, height: screenSize.height*(1/2)), cornerRadius: 6))
        case 7:
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width/2, y: screenSize.height*(3/4)), size: CGSize(width: screenSize.width, height: screenSize.height*(1/2)), cornerRadius: 6))
        case 8:
            appDelegate.simpleTBC!.animateToTab(3, completion: { (navCon) in
                if let navCon = navCon as? UINavigationController {
                    let vc = navCon.topViewController as! ProfileViewController
                    //vc.displayVenuePopupWithVenueIDForDay(venueID: "-KeKx9Pri9kpJmNe72uQ", date: Date())
                    //vc.showCustomDialog(venue: appDelegate.venues["-KeKx9Pri9kpJmNe72uQ"]!, startDisplayDate: Date())
                    
                    
                    //let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController
                    //viewController.alpha = 0.5
                    
                    //appDelegate.simpleTBC!.present(viewController, animated: true, completion: nil)
                }
                
            })
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width/2, y: screenSize.height*(0.18)), size: CGSize(width: screenSize.width, height: screenSize.height*(0.36)), cornerRadius: 6))
        case 9:
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: screenSize.width/2, y: screenSize.height*(0.70)), size: CGSize(width: screenSize.width, height: screenSize.height*(0.62)), cornerRadius: 6))
        case 10:
            appDelegate.simpleTBC!.animateToTab(2, completion: { (navCon) in
                if let navCon = navCon as? UINavigationController {
                    let vc = navCon.topViewController as! ChatsTableViewController
                    //vc.displayVenuePopupWithVenueIDForDay(venueID: "-KeKx9Pri9kpJmNe72uQ", date: Date())
                    //vc.showCustomDialog(venue: appDelegate.venues["-KeKx9Pri9kpJmNe72uQ"]!, startDisplayDate: Date())
                    
                    
                    //let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Annotation") as! AnnotationViewController
                    //viewController.alpha = 0.5
                    
                    //appDelegate.simpleTBC!.present(viewController, animated: true, completion: nil)
                }
                
            })
            self.spotlightView.appear(Spotlight.RoundedRect(center: CGPoint(x: 0, y: 0), size: CGSize(width: 0, height: 0), cornerRadius: 6))
        case 11:
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

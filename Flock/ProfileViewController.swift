//
//  ProfileViewController.swift
//  Flock
//
//  Created by Grant Rheingold on 2/21/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import Foundation
import UIKit
import PermissionScope
import SCLAlertView
import FacebookShare
import FBSDKShareKit

class ProfileViewController: UIViewController, ProfileDelegate {
   
    
    // Variables other ViewControllers might be concerned with
    var user: User?
    var didComeFromFriendsPage: Bool = false
    var plans: [Plan] = [Plan]()
    let multiPscope = PermissionScope()
 
    
    @IBOutlet weak var flockSizeLabel: UILabel!
    @IBOutlet weak var favoriteClubLabel: UILabel!
    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    var tableView: UITableView?
    var tableViewController : ProfileTableViewController?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.setupUser()
        

        // Do any additional setup after loading the view.
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.profileNeedsToUpdate) {
            Utilities.printDebugMessage("Updating profile page")
            self.setupUser()
            appDelegate.profileNeedsToUpdate = true
            self.view.setNeedsLayout()
            self.view.setNeedsDisplay()
            if let tableView = self.tableView {
                tableView.reloadData()
                tableView.separatorColor = FlockColors.FLOCK_BLUE
            }
            else {
                Utilities.printDebugMessage("Error reloading tableview from parent")
            }
            
        }
    }
    
    func setupUser() {
        let user : User?
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (self.user == nil || self.user!.FBID == appDelegate.user!.FBID) {
            user = appDelegate.user!
            if(!didComeFromFriendsPage) {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutButtonPressed))
                self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
            }
        } else {
            user = self.user!
        }
        
        self.user = user!
        //self.username = user!.Name
        
        if let tableVC = self.tableViewController {
            tableVC.plans = Array(user!.Plans.values).filter({ (plan) -> Bool in
                Utilities.printDebugMessage("VenueID: \(plan.venueID), Date: \(plan.date)")
                return DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))
                
            })

        }
        else {
            Utilities.printDebugMessage("Error 3: reloading tableVC from parent")
        }
        self.profileName.text = user?.Name
        self.flockSizeLabel.text = "Flock Size:\n\(user!.Friends.count)"
        if let favoriteClubID = appDelegate.computeFavoriteClubForUser(user: user!) {
            let clubName = appDelegate.venues[favoriteClubID]!.VenueNickName
            self.favoriteClubLabel.text = "Favorite Club:\n\(clubName)"
        } else {
            self.favoriteClubLabel.text = "Favorite Club:\n None Yet!"
        }
        
        FirebaseClient.getImageFromURL(user!.PictureURL) { (image) in
            DispatchQueue.main.async {
                self.profilePic.image = image
                self.profilePic.formatProfilePicture()
                Utilities.printDebugMessage("this aint doing shit")
            }
        }
    }
    
    func logoutButtonPressed() {
        // 1
        let optionMenu = UIAlertController(title: nil, message: "Are you sure you would like to logout?", preferredStyle: .actionSheet)
        
        // 2
        let deleteAction = UIAlertAction(title: "Logout", style: .destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            LoginClient.logout(vc: self)
        })
        
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        
        // 4
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        
        // 5
        self.present(optionMenu, animated: true, completion: nil)
    }


    // END OF TABLEVIEW FUNCTIONS
    
    
    
    func displayUnAttendedPopup(venueName : String, attendFullDate : String) {
        let displayDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.uiDisplayFormat)
        let alert = SCLAlertView()
        //_ = alert.addButton("First Button", target:self, selector:#selector(PlacesTableViewController.shareWithFlock))
        print("Second button tapped")
        _ = alert.showSuccess("Confirmed", subTitle: "You've removed your plan to go to \(venueName) on \(displayDate)")
    }
    
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tableViewController = segue.destination as? ProfileTableViewController {
            self.tableView = tableViewController.tableView
            self.tableViewController = tableViewController
            tableViewController.delegate = self
        }
        else {
            Utilities.printDebugMessage("Error: could not get table vc")
        }
    }
}

extension UIImageView {
    func formatProfilePicture() {
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        self.layer.borderWidth = 4
        self.layer.borderColor = UIColor.white.cgColor //UIColor.lightGray.cgColor
    }
}

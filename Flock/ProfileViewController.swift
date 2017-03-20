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
import Instabug

class ProfileViewController: UIViewController, ProfileDelegate {
    
    
    // Variables other ViewControllers might be concerned with
    var user: User?
    var didComeFromFriendsPage: Bool = false
    var plans: [Plan] = [Plan]()
    
    
    
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var flockSizeLabel: UILabel!
    @IBOutlet weak var favoriteClubLabel: UILabel!
    @IBOutlet weak var profileName: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    var tableView: UITableView?
    var tableViewController : ProfileTableViewController?
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        //Instabug.invoke(with: .newBug)
        /*let permissionScope = PermissionScope()
        PermissionUtilities.setupPermissionScope(permissionScope: permissionScope)
        PermissionUtilities.getPermissionsIfDenied(permissionScope: permissionScope)*/
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUser()
        setRandomSkyImage()
        // Do any additional setup after loading the view.
    }
    
    let skyImages = ["sky1", "sky2", "sky3", "sky4", "sky5"]
    
    func setRandomSkyImage() {
        let index = Int(arc4random_uniform(UInt32(skyImages.count)))
        backgroundImage.image = UIImage(named: skyImages[index])
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.profileNeedsToUpdate) {
            Utilities.printDebugMessage("Updating profile page")
            self.setupUser()
            appDelegate.profileNeedsToUpdate = false
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
            
            // Check to see if settings button should be visible
            let permissionScope = PermissionScope()
            let notificationStatus = permissionScope.statusNotifications()
            let locationStatus = permissionScope.statusLocationAlways()
            /*if(notificationStatus == .authorized && locationStatus == .authorized) {
                self.navigationItem.rightBarButtonItem = nil
            }*/
            
        } else {
            self.navigationItem.rightBarButtonItem = nil
            user = self.user!
        }
        
        self.user = user!
        //self.username = user!.Name
        
        if let tableVC = self.tableViewController {
            tableVC.plans = Array(user!.Plans.values).filter({ (plan) -> Bool in
                Utilities.printDebugMessage("VenueID: \(plan.venueID), Date: \(plan.date)")
                return DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))
                
            })
            tableVC.user = user!
            
        }
        else {
            Utilities.printDebugMessage("Error 3: reloading tableVC from parent")
        }
        self.profileName.text = user?.Name
        self.flockSizeLabel.text = "Flock Size:\n\(user!.Friends.count)"
        if let favoriteClubID = appDelegate.computeFavoriteClubForUser(user: user!) {
            let clubName = appDelegate.venues[favoriteClubID]!.VenueNickName
            self.favoriteClubLabel.text = "Top Place:\n\(clubName)"
        } else {
            self.favoriteClubLabel.text = "Top Place:\n None Yet!"
        }
        
        FirebaseClient.getImageFromURL(user!.PictureURL) { (image) in
            DispatchQueue.main.async {
                self.profilePic.image = image
                self.profilePic.formatProfilePicture()
            }
        }
    }
    
    func logoutButtonPressed() {
        // 1
        let optionMenu = UIAlertController(title: nil, message: "Are you sure you want to logout?", preferredStyle: .actionSheet)
        
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
    
    func displayUnLived(venueName : String) {
        let alert = SCLAlertView()
        //_ = alert.addButton("First Button", target:self, selector:#selector(PlacesTableViewController.shareWithFlock))
        print("Second button tapped")
        _ = alert.showSuccess("Confirmed", subTitle: "You've removed your live status for \(venueName)")
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tableViewController = segue.destination as? ProfileTableViewController {
            self.tableView = tableViewController.tableView
            self.tableViewController = tableViewController
            tableViewController.delegate = self
            tableViewController.user = self.user
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

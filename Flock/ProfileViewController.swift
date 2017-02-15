//
//  ProfileViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 08/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import Foundation
import UIKit
import LFTwitterProfile
import PermissionScope
import SCLAlertView



class ProfileViewController: TwitterProfileViewController {
    
    let multiPscope = PermissionScope()
    
    struct Constants {
        static let SECTION_TITLES = ["Plans"]
        static let CELL_HEIGHT = 75
    }
    
    var tableView: UITableView!
    
    var custom: UIView!
    var label: UILabel!
    var user: User?
    var plans: [Plan] = [Plan]()
    
    
    override func numberOfSegments() -> Int {
        return 1
    }
    
    override func segmentTitle(forSegment index: Int) -> String {
        return "Segment \(index)"
    }
    
    override func prepareForLayout() {
        // TableViews
        self.tableView = UITableView(frame: CGRect.zero, style: .plain)
        
        self.setupTables()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 25))
        //returnedView.backgroundColor = FlockColors.FLOCK_BLUE
        
        let gradient = CAGradientLayer()
        
        gradient.frame = returnedView.bounds
        
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = [FlockColors.FLOCK_BLUE.cgColor, FlockColors.FLOCK_LIGHT_BLUE.cgColor]
        
        returnedView.layer.insertSublayer(gradient, at: 0)
        
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: view.frame.size.width, height: 25))
        label.textColor = .white
        label.text = Constants.SECTION_TITLES[section]
        returnedView.addSubview(label)
        
        return returnedView
    }
    
    
    
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.SECTION_TITLES[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.SECTION_TITLES.count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.profileNeedsToUpdate) {
            Utilities.printDebugMessage("Updating profile page")
            self.setupUser()
            self.tableView.reloadData()
            appDelegate.profileNeedsToUpdate = false
        }
    }
    
    //UpdateTableViewDelegate function
    func updateDataAndTableView(_ completion: @escaping (Bool) -> Void) {
        let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllData { (success) in
            DispatchQueue.main.async {
                Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                if (success) {
                    self.setupUser()
                    self.tableView.reloadData()
                }
                else {
                    Utilities.printDebugMessage("Error updating and reloading data in table view")
                }
                completion(success)
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        PermissionUtilities.setupPermissionScope(permissionScope: multiPscope)
        
        super.viewDidLoad()
        self.setupUser()
        self.locationString = "Hong Kong"
        PermissionUtilities.getPermissionsIfNotYetSet(permissionScope: multiPscope)
    }
    
    func setupUser() {
        let user : User?
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (self.user == nil || self.user!.FBID == appDelegate.user!.FBID) {
            user = appDelegate.user!
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutButtonPressed))
            self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
        } else {
            user = self.user!
        }
        
        self.user = user!
        self.username = user!.Name
        self.plans = Array(user!.Plans.values).filter({ (plan) -> Bool in
            DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))
        })
        FirebaseClient.getImageFromURL(user!.PictureURL) { (image) in
            DispatchQueue.main.async {
                self.profileImage = image
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
    
    override func scrollView(forSegment index: Int) -> UIScrollView {
        return tableView
    }
    
    

}

// MARK: UITableViewDelegates & DataSources
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    fileprivate func setupTables() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        tableView.register(UINib(nibName: "VenueFriendTableViewCell", bundle: nil), forCellReuseIdentifier: "VENUE_FRIEND")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.plans.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let plan = plans[indexPath.row]
        Utilities.animateToPlacesTabWithVenueIDandDate(venueID: plan.venueID, date: plan.date)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let plan = self.plans[indexPath.row]
        let venue = appDelegate.venues[plan.venueID]!
        let cell = tableView.dequeueReusableCell(withIdentifier: "VENUE_FRIEND", for: indexPath) as! VenueFriendTableViewCell
        cell.nameLabel.text = venue.VenueName
        cell.subtitleLabel.text = DateUtilities.convertDateToStringByFormat(date: plan.date, dateFormat: "MMMM d")
        if let venueImage = appDelegate.venueImages[venue.ImageURL] {
            cell.profilePic.image = venueImage
        }
        else {
            appDelegate.getMissingImage(imageURL: venue.ImageURL, completion: { (status) in
                if (status) {
                    DispatchQueue.main.async {
                        if let venueImage = appDelegate.venueImages[venue.ImageURL] {
                            cell.profilePic.image = venueImage
                        }
                        else {
                            Utilities.printDebugMessage("Error: could not retrieve image")
                        }
                    }
                }
            })
        }
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(Constants.CELL_HEIGHT)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let plan = self.plans[indexPath.row]
        let venue = appDelegate.venues[plan.venueID]!
        let date = DateUtilities.getStringFromDate(date: plan.date)
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // delete item at indexPath
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            FirebaseClient.addUserToVenuePlansForDate(date: date, venueID: venue.VenueID, userID: appDelegate.user!.FBID, add: false, completion: { (success) in
                if (success) {
                    Utilities.printDebugMessage("Successfully removed plan to attend venue")
                    self.updateDataAndTableView({ (success) in
                        Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                        if (success) {
                            DispatchQueue.main.async {
                                self.displayUnAttendedPopup(venueName: venue.VenueNickName, attendFullDate: date)
                            }
                        }
                        else {
                            Utilities.printDebugMessage("Error reloading tableview in venues")
                        }
                    })
                }
                else {
                    Utilities.printDebugMessage("Error adding user to venue plans for date")
                    Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                }
            })
        }
        
        /* V2.0
         let share = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            // share item at indexPath
        }
        */
        
        //share.backgroundColor = FlockColors.FLOCK_BLUE
        delete.backgroundColor = FlockColors.FLOCK_GRAY
        
        //return [delete, share]
        return [delete]
    }
    
    func displayUnAttendedPopup(venueName : String, attendFullDate : String) {
        let displayDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.uiDisplayFormat)
        let alert = SCLAlertView()
        _ = alert.addButton("First Button", target:self, selector:#selector(PlacesTableViewController.shareWithFlock))
        print("Second button tapped")
        _ = alert.showSuccess("Confirmed", subTitle: "You've removed your plan to go to \(venueName) on \(displayDate)")
    }
}


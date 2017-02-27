//
//  ProfileTableViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 21/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class ProfileTableViewController: UITableViewController {
    
    struct Constants {
        static let SECTION_TITLES = ["Plans"]
        static let CELL_HEIGHT = 75
    }
    
    var user : User?
    var delegate : ProfileDelegate?
    var plans: [Plan] = [Plan]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.register(UINib(nibName: "VenueFriendTableViewCell", bundle: nil), forCellReuseIdentifier: "VENUE_FRIEND")
        
    }
    
    
    // TABLEVIEW FUNCTIONS
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.SECTION_TITLES[section]
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Constants.SECTION_TITLES.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.plans.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let plan = plans[indexPath.row]
        Utilities.animateToPlacesTabWithVenueIDandDate(venueID: plan.venueID, date: plan.date)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let plan = self.plans[indexPath.row]
        let venue = appDelegate.venues[plan.venueID]!
        let cell = tableView.dequeueReusableCell(withIdentifier: "VENUE_FRIEND", for: indexPath) as! VenueFriendTableViewCell
        cell.nameLabel.text = venue.VenueName
        cell.subtitleLabel.text = DateUtilities.convertDateToStringByFormat(date: plan.date, dateFormat: "MMMM d")
        if let venueImage = appDelegate.venueImages[venue.ImageURL] {
            cell.profilePic.image = venueImage
            cell.profilePic.clipsToBounds = true
            cell.profilePic.layer.borderWidth = 2
            cell.profilePic.layer.borderColor = UIColor.lightGray.cgColor
        }
        else {
            appDelegate.getMissingImage(imageURL: venue.ImageURL, completion: { (status) in
                if (status) {
                    DispatchQueue.main.async {
                        if let venueImage = appDelegate.venueImages[venue.ImageURL] {
                            cell.profilePic.image = venueImage
                            cell.profilePic.clipsToBounds = true
                            cell.profilePic.layer.borderWidth = 2
                            cell.profilePic.layer.borderColor = UIColor.lightGray.cgColor
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
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(Constants.CELL_HEIGHT)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let currentUser = self.user {
            Utilities.printDebugMessage("CanEdit, Current User: \(currentUser.FBID)  App User: \(appDelegate.user!.FBID)")
            return currentUser.FBID == appDelegate.user!.FBID
        } else {
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
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
                    if let delegate = self.delegate {
                        delegate.setupUser()
                    }
                    else {
                        Utilities.printDebugMessage("Error with delegate in profile")
                    }
                    if let tableView = self.tableView {
                        tableView.reloadData()
                    }
                    else {
                        Utilities.printDebugMessage("Error 2: with reloading table view")
                    }
                }
                else {
                    Utilities.printDebugMessage("Error updating and reloading data in table view")
                }
                completion(success)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let plan = self.plans[indexPath.row]
        let venue = appDelegate.venues[plan.venueID]!
        let date = DateUtilities.getStringFromDate(date: plan.date)
        
        if let currentUser = self.user {
            Utilities.printDebugMessage("EditActions, Current User: \(currentUser.FBID)  App User: \(appDelegate.user!.FBID)")
            if(currentUser.FBID != appDelegate.user?.FBID) {
                return nil
            }
        }
        
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
                                if let delegate = self.delegate  {
                                    delegate.displayUnAttendedPopup(venueName: venue.VenueNickName, attendFullDate: date)
                                }
                                else {
                                    Utilities.printDebugMessage("Error with delegate in profile")
                                }
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
    
}

protocol ProfileDelegate: class {
    func displayUnAttendedPopup(venueName : String, attendFullDate : String)
    func setupUser()
}

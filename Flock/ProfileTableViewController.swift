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
        static let CELL_HEIGHT = 75
        static let SECTION_TITLES = ["Live", "Planned"]
        static let LIVE_SECTION_ROW = 0
        static let PLANNED_SECTION_ROW = 1
        static let SECTIONS_COUNT = 2
    }
    
    
    var user : User?
    var delegate : ProfileDelegate?
    var plans: [Plan] = [Plan]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //eliminate lines at bottom
        
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
        return Constants.SECTIONS_COUNT
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == Constants.LIVE_SECTION_ROW) {
            if (user!.LiveClubID != nil) {
                return 1
            }
            else {
                return 0
            }
        }
        else {
            return plans.count
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.section == Constants.LIVE_SECTION_ROW) {
            Utilities.animateToPlacesTabWithVenueIDandDate(venueID: user!.LiveClubID!, date: Date())
        }
        else {
            let plan = plans[indexPath.row]
            Utilities.animateToPlacesTabWithVenueIDandDate(venueID: plan.venueID, date: plan.date)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var venue : Venue
        let plan : Plan = self.plans[indexPath.row]
        if (indexPath.section == Constants.LIVE_SECTION_ROW) {
            venue = appDelegate.venues[user!.LiveClubID!]!
        }
        else {
            venue = appDelegate.venues[plan.venueID]!
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "VENUE_FRIEND", for: indexPath) as! VenueFriendTableViewCell
        
        
        
        if (indexPath.section == Constants.LIVE_SECTION_ROW) {
            cell.subtitleLabel.text = DateUtilities.convertDateToStringByFormat(date: Date(), dateFormat: DateUtilities.Constants.uiDisplayFormat)
        } else {
            cell.subtitleLabel.text = DateUtilities.convertDateToStringByFormat(date: plan.date, dateFormat: DateUtilities.Constants.uiDisplayFormat)
        }
        
        if let venueImage = appDelegate.venueImages[venue.ImageURL] {
            cell.profilePic.image = venueImage
            cell.profilePic.clipsToBounds = true
            cell.profilePic.layer.borderWidth = 2
        }
        else {
            appDelegate.getMissingImage(imageURL: venue.ImageURL, venueID: venue.VenueID, completion: { (status) in
                if (status) {
                    DispatchQueue.main.async {
                        if let venueImage = appDelegate.venueImages[venue.ImageURL] {
                            cell.profilePic.image = venueImage
                            cell.profilePic.clipsToBounds = true
                            cell.profilePic.layer.borderWidth = 2
                        }
                        else {
                            Utilities.printDebugMessage("Error: could not retrieve image")
                        }
                    }
                }
            })
        }
        if (plan.specialEventID != nil) {
            cell.nameLabel.text = appDelegate.specialEvents[plan.specialEventID!]?.EventName
            cell.profilePic.layer.borderColor = FlockColors.FLOCK_BLUE.cgColor
            cell.nameLabel.textColor = FlockColors.FLOCK_BLUE
            
        }
        else {
            cell.nameLabel.text = venue.VenueName
            cell.profilePic.layer.borderColor = UIColor.lightGray.cgColor
            cell.nameLabel.textColor = UIColor.black
        }

        
        cell.selectionStyle = .none
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(Constants.CELL_HEIGHT)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let currentUser = self.user {
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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllDataWithoutUpdatingLocation { (success) in
            DispatchQueue.main.async {
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

        var venue : Venue
        if (indexPath.section == Constants.LIVE_SECTION_ROW) {
            venue = appDelegate.venues[user!.LiveClubID!]!
        }
        else {
            let plan = self.plans[indexPath.row]
            venue = appDelegate.venues[plan.venueID]!
            
        }

        
        if let currentUser = self.user {
            if(currentUser.FBID != appDelegate.user?.FBID) {
                return nil
            }
        }
        if (indexPath.section == Constants.LIVE_SECTION_ROW) {
            let unlive = UITableViewRowAction(style: .destructive, title: "Unlive") { (action, indexPath) in
                // delete item at indexPath
                let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
                FirebaseClient.addUserToVenueLive(date: DateUtilities.getStringFromDate(date: Date()), venueID: self.user!.LiveClubID!, userID: self.user!.FBID, add: false, completion: { (success) in
                    if (success) {
                        Utilities.printDebugMessage("Successfully unlived")
                        self.updateDataAndTableView({ (success) in
                            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                            if (success) {
                                DispatchQueue.main.async {
                                    if let delegate = self.delegate  {
                                        delegate.displayUnLived(venueName: venue.VenueNickName)
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
            unlive.backgroundColor = FlockColors.FLOCK_GRAY
            return [unlive]
        }
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            // delete item at indexPath
            let planDate = DateUtilities.getStringFromDate(date: self.plans[indexPath.row].date)
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            FirebaseClient.addUserToVenuePlansForDate(date: DateUtilities.getStringFromDate(date: self.plans[indexPath.row].date), venueID: venue.VenueID, userID: appDelegate.user!.FBID, add: false, specialEventID: self.plans[indexPath.row].specialEventID, completion: { (success) in
                if (success) {
                    Utilities.printDebugMessage("Successfully removed plan to attend venue")
                    self.updateDataAndTableView({ (success) in
                        Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                        if (success) {
                            DispatchQueue.main.async {
                                if let delegate = self.delegate  {
                                    delegate.displayUnAttendedPopup(venueName: venue.VenueNickName, attendFullDate: planDate)
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
    func displayUnLived(venueName : String)
    func setupUser()
}

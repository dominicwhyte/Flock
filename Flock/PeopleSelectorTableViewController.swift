//
//  PeopleSelectorTableViewController.swift
//  Flock
//
//  Created by Grant Rheingold on 3/19/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import SCLAlertView

class PeopleSelectorTableViewController: UITableViewController, UpdateSelectorTableViewDelegate {
    
    struct Constants {
        static let REUSE_IDENTIFIERS = ["SELECTOR"]
        static let STANDARD_CELL_SIZE = 75
    }
    @IBOutlet weak var inviteButton: UIBarButtonItem!
    
    var userName : String?
    var venueName : String?
    var fullDate : String?
    var eventName : String?
    var venueID : String?
    var userID : String?
    var specialEventID : String?
    var friends  = [User]()
    var filteredFriends = [User]()
    var friendsToInvite = [String]()
    var imageCache = [String : UIImage]()
    var plannedAttendees = [String : String]()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.friends = Array(appDelegate.friends.values)
        if let index = friends.index(of: appDelegate.user!) {
            self.friends.remove(at: index)
        }
        self.friends.sort { (user1, user2) -> Bool in
            user1.Name < user2.Name
        }
        self.inviteButton.isEnabled = false
        if let _ = self.userID {
            self.userName = appDelegate.user!.Name
        }
        if let venueID = self.venueID {
            self.venueName = appDelegate.venues[venueID]!.VenueName
        }
        if let specialEventID = self.specialEventID {
            self.eventName = appDelegate.specialEvents[specialEventID]!.EventName
        }
        
        //Search
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.barTintColor = UIColor.white
        searchController.searchBar.tintColor = FlockColors.FLOCK_GRAY
        
        searchController.searchBar.placeholder = "Search                                                                                     "
        
        tableView.tableHeaderView = searchController.searchBar
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true) {
            Utilities.printDebugMessage("Successfully dismissed friend selector")
        }
        
    }
    
    @IBAction func inviteButtonPressed(_ sender: Any) {
        for friend in self.friendsToInvite {
            print("Friend: \(friend)")
        }
        if let userName = self.userName, let venueName = self.venueName, let fullDate = self.fullDate {
            var title = ""
            let date = DateUtilities.getDateFromString(date: fullDate)
            let displayDate = DateUtilities.convertDateToStringByFormat(date: date, dateFormat: DateUtilities.Constants.uiDisplayFormat)
            if(self.eventName != nil) {
                title = "\(userName) invited you to \(self.eventName!) at \(venueName) on \(displayDate)!"
            } else {
                title = "\(userName) invited you to \(venueName) on \(displayDate)!"
            }
            
            Utilities.sendPushNotificationToPartOfFlock(title: title, toFriends: friendsToInvite)
            for friendID in friendsToInvite {
                if let userID = self.userID, let venueID = self.venueID{
                    let specialEventID : String? = self.specialEventID
                    FirebaseClient.addInvitationToUserForVenueForDate(toUserID: friendID, fromUserID: userID, date: fullDate, venueID: venueID, add: true, specialEventID: specialEventID, completion: { (success) in
                        if(success) {
                            Utilities.printDebugMessage("Successfully added invitation on Firebase")
                        }
                    })
                }
            }
        }
        self.dismiss(animated: true) {
            Utilities.printDebugMessage("Successfully dismissed friend selector")
                        let alert = SCLAlertView()
                        _ = alert.showInfo("Invites sent!", subTitle: "Flock will send you a push notification when a friend accepts his or her invite")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog("You selected cell number: \(indexPath.row)!")
        let currentCell = tableView.cellForRow(at: indexPath) as! PeopleSelectorTableViewCell
        currentCell.setSelected(currentCell.isSelected, animated: true)
        
        let friendID : String
        if searchController.isActive && searchController.searchBar.text != "" {
            friendID = self.filteredFriends[indexPath.row].FBID
        }
        else {
            friendID = self.friends[indexPath.row].FBID
        }
        
        self.addFriendIDToInvites(friendID: friendID)
        for friend in self.friendsToInvite {
            print(friend)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        NSLog("You selected cell number: \(indexPath.row)!")
        let currentCell = tableView.cellForRow(at: indexPath) as! PeopleSelectorTableViewCell
        currentCell.setSelected(currentCell.isSelected, animated: true)

        
        let friendID : String
        if searchController.isActive && searchController.searchBar.text != "" {
            friendID = self.filteredFriends[indexPath.row].FBID
        }
        else {
            friendID = self.friends[indexPath.row].FBID
        }
        
        self.removeFriendIDFromInvites(friendID: friendID)
        for friend in self.friendsToInvite {
            print(friend)
        }
    }
    
    func manuallySelectCell(row: Int, section: Int, isSelected: Bool) {
        let indexPath : IndexPath = IndexPath(row: row, section: section)
        if(!isSelected) {
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            
            let friendID : String
            if searchController.isActive && searchController.searchBar.text != "" {
                friendID = self.filteredFriends[indexPath.row].FBID
            }
            else {
                friendID = self.friends[indexPath.row].FBID
            }
            
            self.addFriendIDToInvites(friendID: friendID)
        } else {
            self.tableView.deselectRow(at: indexPath, animated: true)
            
            let friendID : String
            if searchController.isActive && searchController.searchBar.text != "" {
                friendID = self.filteredFriends[indexPath.row].FBID
            }
            else {
                friendID = self.friends[indexPath.row].FBID
            }
            
            self.removeFriendIDFromInvites(friendID: friendID)
        }
        /*
        for friend in self.friendsToInvite {
            print(friend)
        } */
    }
    
    func addFriendIDToInvites(friendID : String) {
        
        if (!friendsToInvite.contains(friendID)) {
            self.friendsToInvite.append(friendID)
            if(self.friendsToInvite.count > 0) {
                self.inviteButton.isEnabled = true
            }
        }
    }
    
    func removeFriendIDFromInvites(friendID : String) {
        if let removeIndex = self.friendsToInvite.index(of: friendID) {
            self.friendsToInvite.remove(at: removeIndex)
        }
        if(self.friendsToInvite.count == 0) {
            self.inviteButton.isEnabled = false
        }
    }
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchController.isActive && searchController.searchBar.text != "" {
            return self.filteredFriends.count
        }
        return self.friends.count
    }
    
    fileprivate func setupCell(cell : UITableViewCell) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! PeopleSelectorTableViewCell
        let friend : User
        if searchController.isActive && searchController.searchBar.text != "" {
            friend = self.filteredFriends[indexPath.row]
        }
        else {
            friend = self.friends[indexPath.row]
        }
        if (friendsToInvite.contains(friend.FBID)) {
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        
        cell.name.text = friend.Name
        self.retrieveImage(imageURL: friend.PictureURL, venueID: nil, imageView: cell.profilePic!)
        if(self.plannedAttendees[friend.FBID] != nil) {
            cell.subtitle.text = "Already planning"
            cell.isUserInteractionEnabled = false
            cell.selectorButton.isHidden = true
            
        } else {
            cell.isUserInteractionEnabled = true
            cell.selectorButton.isHidden = false
            cell.subtitle.text = "Not planning yet"
        }
        cell.friendID = friend.FBID
        cell.delegate = self
        cell.row = indexPath.row
        cell.section = indexPath.section
        //setupCell(cell: cell)
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(Constants.STANDARD_CELL_SIZE)
    }
    
    //Retrieve image with caching
    func retrieveImage(imageURL : String, venueID : String?, imageView : UIImageView) {
        if let image = imageCache[imageURL] {
            imageView.image = image
        }
        else {
            FirebaseClient.getImageFromURL(imageURL, venueID: venueID) { (image) in
                DispatchQueue.main.async {
                    self.imageCache[imageURL] = image
                    imageView.image = image
                }
            }
        }
    }
    
    func filterContentForSearchText(_ searchText: String) {
            self.filteredFriends = (friends.filter({( user : User) -> Bool in
                    return user.Name.lowercased().contains(searchText.lowercased())
            }))
        
        tableView.reloadData()
    }
}

protocol UpdateSelectorTableViewDelegate: class {
    func manuallySelectCell(row: Int, section: Int, isSelected: Bool)
}

extension PeopleSelectorTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!)
    }
}

extension PeopleSelectorTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        _ = searchController.searchBar
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

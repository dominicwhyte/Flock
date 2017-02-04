//
//  PeopleTableViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 03/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class PeopleTableViewController: UITableViewController, UpdateTableViewDelegate {
    
    internal var parentView: UIView?

    
    struct Constants {
        static let FRIEND_REQUEST_INDEX = 0
        static let LIVE_FRIENDS_INDEX = 1
        static let PLANNED_FRIENDS_INDEX = 2
        static let REMAINING_FRIENDS_INDEX = 3
        static let SECTION_TITLES = ["Friend Requests", "Live", "Planned", "All"]
        static let REUSE_IDENTIFIERS = ["FRIEND_REQUEST", "LIVE", "PLANNED", "ALL"]
    }
    
    //UpdateTableViewDelegate function
    func updateDataAndTableView(_ completion: @escaping (Bool) -> Void) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllData { (success) in
            DispatchQueue.main.async {
                if (success) {
                    Utilities.printDebugMessage("Successfully reloaded data and tableview")
                    self.friends = self.parseFriends()
                    self.filteredFriends = self.prepareArrays()
                }
                else {
                    Utilities.printDebugMessage("Error updating and reloading data in table view")
                }
                self.tableView.reloadData()
                completion(success)
            }
        }
    }
    
    var friends = [[User]]()
    var filteredFriends = [[User]]()
    let searchController = UISearchController(searchResultsController: nil)
    var imageCache = [String : UIImage]()
    
    override func viewDidLoad() {
        //set view for protocol
        self.parentView = self.view
        
        super.viewDidLoad()
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        
        self.friends = parseFriends()
        self.filteredFriends = prepareArrays()
        
        //Refresh control
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(PeopleTableViewController.refresh(refreshControl:)), for: UIControlEvents.valueChanged)
    }
    
    
    func refresh(refreshControl: UIRefreshControl) {
        self.updateDataAndTableView { (success) in
            if (!success) {
                Utilities.printDebugMessage("Error reloading table data")
            }
            self.refreshControl?.endRefreshing()
        }
    }
    
    
    
    func prepareArrays() -> [[User]] {
        var filteredFriendsArray : [[User]] = []
        for _ in Constants.SECTION_TITLES {
            filteredFriendsArray.append([])
        }
        return filteredFriendsArray
    }
    
    func filterContentForSearchText(_ searchText: String) {
        var i = 0
        
        for friendGroup in friends {
            filteredFriends[i] = friendGroup.filter({( friend : User) -> Bool in
                return friend.Name.lowercased().contains(searchText.lowercased())
            })
            i += 1
        }
        tableView.reloadData()
    }
    
    func parseFriends() -> [[User]] {
        var friendArrayArray : [[User]] = prepareArrays()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        friendArrayArray[Constants.FRIEND_REQUEST_INDEX] = Array(appDelegate.friendRequestUsers.values)
        
        // Makes array of friends in sections
        for friend in Array(appDelegate.friends.values) {
            if(friend.LiveClubID == nil && friend.Plans.count == 0) {
                friendArrayArray[Constants.REMAINING_FRIENDS_INDEX].append(friend)
            } else {
                if(friend.LiveClubID != nil) {
                    friendArrayArray[Constants.LIVE_FRIENDS_INDEX].append(friend)
                }
                if(friend.Plans.count > 0) {
                    friendArrayArray[Constants.PLANNED_FRIENDS_INDEX].append(friend)
                }
            }
        }
        
        return friendArrayArray
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            if (filteredFriends.count == 0) {
                return 0
            }
            return filteredFriends[section].count
        }
        if (friends.count == 0) {
            return 0
        }
        return friends[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.SECTION_TITLES[section]
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return friends.count
    }
    
    //Retrieve image with caching
    func retrieveImage(imageURL : String, imageView : UIImageView) {
        if let image = imageCache[imageURL] {
            imageView.image = image
        }
        else {
            FirebaseClient.getImageFromURL(imageURL) { (image) in
                DispatchQueue.main.async {
                    self.imageCache[imageURL] = image
                    imageView.image = image
                }
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friend: User
        if searchController.isActive && searchController.searchBar.text != "" {
            friend = filteredFriends[indexPath.section][indexPath.row]
        } else {
            friend = friends[indexPath.section][indexPath.row]
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        switch indexPath.section {
            
        case Constants.FRIEND_REQUEST_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! FriendRequestTableViewCell
            cell.setIDs(fromID: friend.FBID, toID: appDelegate.user!.FBID)
            cell.friendName.text = friend.Name
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)

            //Set the delegate for tableview reloaddata updates
            cell.delegate = self
            
            return cell
            
        case Constants.LIVE_FRIENDS_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! LiveTableViewCell
            cell.friendName.text = friend.Name
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
            let venue = appDelegate.venues[friend.LiveClubID!]
            cell.venueName.text = venue!.VenueName
            self.retrieveImage(imageURL: venue!.ImageURL, imageView: cell.venuePic)
            return cell
            
        case Constants.PLANNED_FRIENDS_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! PlannedTableViewCell
            cell.friendName.text = friend.Name
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
            let venue = appDelegate.venues[friend.LiveClubID!]
            cell.venueName.text = venue!.VenueName
            self.retrieveImage(imageURL: venue!.ImageURL, imageView: cell.venuePic)
            return cell
            
        case Constants.REMAINING_FRIENDS_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! AllTableViewCell
            cell.friendName.text = friend.Name
            cell.profilePic!.image = UIImage()
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
            return cell
        default:
            Utilities.printDebugMessage("Error in table view switch")
            break
        }
        //Should never run
        Utilities.printDebugMessage("Error loading people table view controller")
        let cell = UITableViewCell()
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchPeopleTableViewController = segue.destination as? SearchPeopleTableViewController {
            searchPeopleTableViewController.delegate = self
        }
    }
    
}

extension PeopleTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!)
    }
}

extension PeopleTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        _ = searchController.searchBar
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

protocol UpdateTableViewDelegate: class {
    func updateDataAndTableView(_ completion: @escaping (Bool) -> Void)
    var parentView : UIView? { get set }
}


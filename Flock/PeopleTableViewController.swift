//
//  PeopleTableViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 03/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class PeopleTableViewController: UITableViewController, UpdateTableViewDelegate, CustomSearchControllerDelegate {
    
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
    
    func configureSearchController() -> CustomSearchController {
        // Initialize and perform a minimum configuration to the search controller.
        let searchController = CustomSearchController(searchResultsController: self, searchBarFrame: CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: 50.0), searchBarFont: UIFont(name: "Futura", size: 16.0)!, searchBarTextColor: UIColor.orange, searchBarTintColor: UIColor.black)
        searchController.customDelegate = self
        searchController.customSearchBar.placeholder = "Search in this awesome bar..."
        
        
        return searchController
    }
    
    
    var friends = [[User]]()
    var filteredFriends = [[User]]()
    var searchController : UISearchController = UISearchController(searchResultsController: nil)
    var imageCache = [String : UIImage]()
    var userToPass : User?
    
    override func viewDidLoad() {
        //searchController = configureSearchController()
        //set view for protocol
        self.parentView = self.view
         self.tableView.separatorColor = FlockColors.FLOCK_BLUE
        super.viewDidLoad()
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor.white
        searchController.searchBar.tintColor = FlockColors.FLOCK_GRAY

        searchController.searchBar.placeholder = "Search                                                                                     "
        
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var userToView : User
        if searchController.isActive && searchController.searchBar.text != "" {
            userToView = filteredFriends[indexPath.section][indexPath.row]
        }
        else {
            userToView = friends[indexPath.section][indexPath.row]
        }
        self.userToPass = userToView
        performSegue(withIdentifier: "PROFILE", sender: self)
    }
    
    func didStartSearching() {
        
    }
    
    func didTapOnSearchButton() {
        
    }
    
    func didTapOnCancelButton() {
        
    }
    
    func didChangeSearchText(_ searchText: String) {
        
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
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            cell.selectionStyle = .none
            return cell
            
        case Constants.LIVE_FRIENDS_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! LiveTableViewCell
            cell.friendName.text = friend.Name
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
            let venue = appDelegate.venues[friend.LiveClubID!]
            //cell.venueName.text = venue!.VenueName
            //self.retrieveImage(imageURL: venue!.ImageURL, imageView: cell.venuePic)
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            cell.selectionStyle = .none
            return cell
            
        case Constants.PLANNED_FRIENDS_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! PlannedTableViewCell
            cell.friendName.text = friend.Name
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
            cell.subtitleLabel.text = "Live 2 days ago"
            //cell.venueName.text = venue!.VenueName
            //self.retrieveImage(imageURL: venue!.ImageURL, imageView: cell.venuePic)
            //Setup mgswipe capability
            cell.setupCell(plans: Array(friend.Plans.values))
            makeViewCircle(imageView: cell.profilePic!)
            cell.selectionStyle = .none
            return cell
            
        case Constants.REMAINING_FRIENDS_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! AllTableViewCell
            cell.friendName.text = friend.Name
            cell.profilePic!.image = UIImage()
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            cell.selectionStyle = .none
            return cell
        default:
            Utilities.printDebugMessage("Error in table view switch")
            break
        }
        //Should never run
        Utilities.printDebugMessage("Error loading people table view controller")
        let cell = UITableViewCell()
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let searchPeopleTableViewController = navController.topViewController as? SearchPeopleTableViewController {
                searchPeopleTableViewController.delegate = self
            }
        } else if let profileController = segue.destination as? ProfileViewController {
            if let userToPass = userToPass {
                profileController.user = userToPass
            } else {
                Utilities.printDebugMessage("Unable to pass user")
            }
        } else {
            Utilities.printDebugMessage("Wasn't able to find view controller")
        }
    }
    
    func makeViewCircle(imageView : UIView) {
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
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




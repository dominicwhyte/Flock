//
//  PeopleTableViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 03/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import MGSwipeTableCell
import Firebase

class PeopleTableViewController: UITableViewController, UpdateTableViewDelegate, CustomSearchControllerDelegate, ChatDelegate {
    
    internal var parentView: UIView?
    
    var facebookFriendFuggestions = [User]()
    
    struct Constants {
        static let FLOCK_SUGGESTIONS_INDEX = 0
        static let FRIEND_REQUEST_INDEX = 1
        static let LIVE_FRIENDS_INDEX = 2
        static let PLANNED_FRIENDS_INDEX = 3
        static let REMAINING_FRIENDS_INDEX = 4
        static let SECTION_TITLES = ["Flock Suggestions", "Flock Requests", "Live", "Planned", "All"]
        static let REUSE_IDENTIFIERS = ["FLOCK_SUGGESTIONS","FRIEND_REQUEST", "LIVE", "PLANNED", "ALL"]
        static let FLOCK_SUGGESTIONS_CELL_SIZE = 133
        static let STANDARD_CELL_SIZE = 75
    }
    
    func getFacebookFriendsNotInFlock(number : Int) -> [User] {
        var selectedUsers = [User]()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for (friendFBID,_) in appDelegate.facebookFriendsFBIDs {
            if (appDelegate.friends[friendFBID] == nil) {
                if (selectedUsers.count < number) {
                    if let newUser = appDelegate.users[friendFBID] {
                        selectedUsers.append(newUser)
                    }
                    else {
                        Utilities.printDebugMessage("Error: FBID not found")
                    }
                }
                else {
                    break
                }
            }
        }
        return selectedUsers
    }
    
    //UpdateTableViewDelegate function
    func updateDataAndTableView(_ completion: @escaping (Bool) -> Void) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllDataWithoutUpdatingLocation { (success) in
            DispatchQueue.main.async {
                if (success) {
                    Utilities.printDebugMessage("Successfully reloaded data and tableview")
                    self.friends = self.parseFriends()
                    self.filteredFriends = self.prepareArrays()
                    if self.searchController.isActive && self.searchController.searchBar.text != "" {
                        //reloads the table
                        self.filterContentForSearchText(self.searchController.searchBar.text!)
                    }
                    else {
                        
                        self.tableView.reloadData()
                    }
                }
                else {
                    Utilities.printDebugMessage("Error updating and reloading data in table view")
                }
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
        self.facebookFriendFuggestions = getFacebookFriendsNotInFlock(number: 5)
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
        
        //Listener for autoreloading friend requests
        NotificationCenter.default.addObserver(self, selector: #selector(PeopleTableViewController.reloadTableData(notification:)), name: Utilities.Constants.notificationName, object: nil)
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
                else if(friend.Plans.count > 0) {
                    
                    for (visitID, plan) in friend.Plans {
                        if(!DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))) {
                            friend.Plans[visitID] = nil
                        }
                    }
                    if(friend.Plans.count > 0) {
                        friendArrayArray[Constants.PLANNED_FRIENDS_INDEX].append(friend)
                    } else {
                        friendArrayArray[Constants.REMAINING_FRIENDS_INDEX].append(friend)
                    }
                }
            }
        }
        
        return friendArrayArray
    }
    
    func reloadTableData(notification: NSNotification) {
        Utilities.printDebugMessage("Getting called on, only once!")
        if(self.tableView != nil) {
            
            self.updateDataAndTableView({ (success) in
                
                if(success) {
                    
                    Utilities.printDebugMessage("Successfully updated tableview from notification")
                    
                } else {
                    
                    Utilities.printDebugMessage("Successfully updated tableview from notification")
                    
                }
                
            })
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == Constants.FLOCK_SUGGESTIONS_INDEX) {
            return 1
        }
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == Constants.FLOCK_SUGGESTIONS_INDEX) {
            if (facebookFriendFuggestions.count == 0) {
                return 0
            }
            return CGFloat(Constants.FLOCK_SUGGESTIONS_CELL_SIZE)
        }
        return CGFloat(Constants.STANDARD_CELL_SIZE)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //setup friend suggestions
        if (indexPath.section == Constants.FLOCK_SUGGESTIONS_INDEX) {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! FlockSuggestionTableViewCell
            cell.setCollectionViewDataSourceDelegate(self)
            return cell
        }
        
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
            cell.profilePic.makeViewCircle()
            setupCell(cell: cell)
            return cell
            
        case Constants.LIVE_FRIENDS_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! LiveTableViewCell
            cell.friendName.text = friend.Name
            if let venueID = friend.LiveClubID {
                if (appDelegate.venues[venueID] != nil) {
                    cell.setupCell(venue: appDelegate.venues[venueID]!)
                }
            }
            cell.profilePic.makeViewCircle()
            cell.chatButton.setRounded()
            cell.chatButton.isHidden = (appDelegate.user!.FBID == friend.FBID)
            cell.FBID = friend.FBID
            cell.chatDelegate = self
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
            
            setupCell(cell: cell)
            return cell
            
        case Constants.PLANNED_FRIENDS_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! PlannedTableViewCell
            cell.friendName.text = friend.Name
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
            let plansCount = friend.Plans.values.count
            cell.subtitleLabel.text = Utilities.setPlurality(string: "\(plansCount) plan", count: plansCount)
            
            cell.setupCell(plans: Array(friend.Plans.values))
            cell.profilePic.makeViewCircle()
            cell.FBID = friend.FBID
            cell.chatButton.setRounded()
            cell.chatButton.isHidden = (appDelegate.user!.FBID == friend.FBID)
            cell.chatDelegate = self
            setupCell(cell: cell)
            return cell
            
        case Constants.REMAINING_FRIENDS_INDEX:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! AllTableViewCell
            if let lastLive = friend.LastLive {
                
                let executions = Array(friend.Executions.values)
                var lastLiveClub = ""
                for execution in executions {
                    if(execution.date == lastLive) {
                        lastLiveClub = appDelegate.venues[execution.venueID]!.VenueNickName
                    }
                }
                let negativeDaysSinceLive = DateUtilities.daysUntilPlan(planDate: lastLive)
                cell.subtitleLabel.text = "Live at \(lastLiveClub) \(negativeDaysSinceLive * -1) \(Utilities.setPlurality(string: "day", count: negativeDaysSinceLive * -1)) ago"
            }
            else {
                cell.subtitleLabel.text = "Not yet live"
            }
            cell.friendName.text = friend.Name
            cell.profilePic!.image = UIImage()
            self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
            cell.preservesSuperviewLayoutMargins = false
            cell.profilePic.makeViewCircle()
            cell.FBID = friend.FBID
            cell.chatButton.setRounded()
            cell.chatButton.isHidden = (appDelegate.user!.FBID == friend.FBID)
            cell.chatDelegate = self
            setupCell(cell: cell)
            return cell
        default:
            Utilities.printDebugMessage("Error in table view switch")
            break
        }
        //Should never run
        Utilities.printDebugMessage("Error loading people table view controller")
        let cell = UITableViewCell()
        setupCell(cell: cell)
        return cell
    }
    
    fileprivate func setupCell(cell : UITableViewCell) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.selectionStyle = .none
    }
    
    func callSegueFromCell(fbid: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let user = appDelegate.user, let friendUser = appDelegate.users[fbid] {
            if let channelID = user.ChannelIDs[fbid] {
                 performSegue(withIdentifier: "CHAT_IDENTIFIER", sender: (channelID, friendUser))
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let searchPeopleTableViewController = navController.topViewController as? SearchPeopleTableViewController {
                searchPeopleTableViewController.delegate = self
            }
            else if let chatViewController = navController.topViewController as? ChatViewController {
                if let (channelID, friendUser) = sender as? (String, User) {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    if let friendImage = imageCache[friendUser.PictureURL], let userImage = imageCache[appDelegate.user!.PictureURL] {
                        chatViewController.userImage = userImage
                        chatViewController.friendImage = friendImage
                    }
                    chatViewController.channelRef = FIRDatabase.database().reference().child("channels").child(channelID)
                    chatViewController.friendUser = friendUser
                    chatViewController.channelID = channelID
                }
            }
        } else if let profileController = segue.destination as? ProfileViewController {
            if let userToPass = userToPass {
                profileController.user = userToPass
                profileController.didComeFromFriendsPage = true
            } else {
                Utilities.printDebugMessage("Unable to pass user")
            }
        } else {
            Utilities.printDebugMessage("Wasn't able to find view controller")
        }
    }
    
    
}

extension UIImageView {
    func makeViewCircle() {
        self.layer.cornerRadius = self.frame.size.width/2
        self.clipsToBounds = true
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.lightGray.cgColor
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

protocol ChatDelegate: class {
    func callSegueFromCell(fbid: String)
}

extension PeopleTableViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return facebookFriendFuggestions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FLOCK_SUGGESTION_COLLECTION_CELL", for: indexPath)
        let userImage = cell.viewWithTag(0) as! UIImageView
        let nameLabel = cell.viewWithTag(1) as! UILabel
        nameLabel.text = facebookFriendFuggestions[indexPath.row].Name
        Utilities.printDebugMessage("test: \(facebookFriendFuggestions[indexPath.row])")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Collection view at row \(collectionView.tag) selected index path \(indexPath)")
    }
}


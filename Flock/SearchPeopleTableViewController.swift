//
//  SearchPeopleTableViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 04/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class SearchPeopleTableViewController: UITableViewController, UpdateSearchTableViewDelegate {
    
    struct Constants {
        static let CELL_HEIGHT = 70
        static let SECTION_TITLES = ["All"]
    }
    
    var users : [User]?
    var filteredUsers = [User]()
    let searchController = UISearchController(searchResultsController: nil)
    var imageCache = [String : UIImage]()
    //Cache for caching states
    var stateCache : [String : SearchPeopleTableViewController.UserStates] = [:]
    weak var delegate: UpdateTableViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.users = orderUsers(users: Array(appDelegate.users.values), facebookFriends: appDelegate.facebookFriendsFBIDs)
        
        //Search
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.barTintColor = UIColor.white
        searchController.searchBar.tintColor = FlockColors.FLOCK_GRAY
        
        searchController.searchBar.placeholder = "Search                                                                                     "
        
        tableView.tableHeaderView = searchController.searchBar
        self.tableView.separatorColor = FlockColors.FLOCK_BLUE
    }
    
    func orderUsers(users : [User], facebookFriends : [String:String]) -> [User] {
        return users.sorted { (user1, user2) -> Bool in
            (facebookFriends[user1.FBID] != nil)
        }
    }
    
    func updateStateDict(FBID : String, state : SearchPeopleTableViewController.UserStates) {
        stateCache[FBID] = state
    }
    
    func filterContentForSearchText(_ searchText: String) {
        self.filteredUsers = (users?.filter({( user : User) -> Bool in
            return user.Name.lowercased().contains(searchText.lowercased())
        }))!
        tableView.reloadData()
    }
    
    @IBAction func popSearchPeopleTableViewController(_ sender: Any) {
        self.dismiss(animated: true) {
            self.delegate?.updateDataAndTableView({ (success) in
                Utilities.printDebugMessage("\(success)")
            })
        }

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
    
    enum UserStates {
        case alreadyFriends
        case requestPendingFromSelf
        case requestPendingFromUser
        case ourself
        case normal
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return self.filteredUsers.count
        }
        return self.users!.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (appDelegate.users.count > 0) {
            title = "\(Constants.SECTION_TITLES[section]) (\(appDelegate.users.count))"
        } else {
            title = Constants.SECTION_TITLES[section]
        }
        Utilities.printDebugMessage("\(appDelegate.users.count)")
        return title
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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (appDelegate.users.count > 0) {
            label.text = "\(Constants.SECTION_TITLES[section]) (\(appDelegate.users.count))"
            title = "\(Constants.SECTION_TITLES[section]) (\(appDelegate.users.count))"
        } else {
            label.text = Constants.SECTION_TITLES[section]
        }
        //label.text = Constants.SECTION_TITLES[section]
        returnedView.addSubview(label)
        
        return returnedView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser : User = appDelegate.user!
        let user: User
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            user = users![indexPath.row]
        }
        
        var userState : UserStates
        if (stateCache[user.FBID] != nil) {
            userState = stateCache[user.FBID]!
        }
        else if (currentUser.Friends[user.FBID] != nil) {
            userState = UserStates.alreadyFriends
        }
        else if (user.FriendRequests[currentUser.FBID] != nil) {
            userState = UserStates.requestPendingFromSelf
        }
        else if (currentUser.FriendRequests[user.FBID] != nil) {
            userState = UserStates.requestPendingFromUser
        }
        else if (user.FBID == currentUser.FBID) {
            userState = UserStates.ourself
        }
        else {
            userState = UserStates.normal
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SEARCH", for: indexPath) as! SearchTableViewCell
        self.retrieveImage(imageURL: user.PictureURL, imageView: cell.profilePic)
        self.makeViewCircle(imageView: cell.profilePic)
        cell.name.text = user.Name
        cell.setupCell(userState: userState, currentUserID: currentUser.FBID, cellID: user.FBID)
        cell.searchDelegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return CGFloat(Constants.CELL_HEIGHT)
    }
    
    func makeViewCircle(imageView : UIView) {
        imageView.layer.cornerRadius = imageView.frame.size.width/2
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
    }
    /*
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser : User = appDelegate.user!
        let user: User
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredUsers[indexPath.row]
        } else {
            user = users![indexPath.row]
        }
        
        var userState : UserStates
        if (stateCache[user.FBID] != nil) {
            userState = stateCache[user.FBID]!
        }
        else if (currentUser.Friends[user.FBID] != nil) {
            userState = UserStates.alreadyFriends
        }
        else if (user.FriendRequests[currentUser.FBID] != nil) {
            userState = UserStates.requestPendingFromSelf
        }
        else if (currentUser.FriendRequests[user.FBID] != nil) {
            userState = UserStates.requestPendingFromUser
        }
        else if (user.FBID == currentUser.FBID) {
            userState = UserStates.ourself
        }
        else {
            userState = UserStates.normal
        }

        switch userState {
        case .alreadyFriends:
            return true
        case .requestPendingFromSelf:
            return false
        case .requestPendingFromUser:
            //Reject the friend request
            return false
        case .ourself:
            return false
        case .normal:
            return false
        }
       
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            Utilities.printDebugMessage("fired double")
            
        }
        Utilities.printDebugMessage("fired")
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let delete = UITableViewRowAction(style: .default, title: "Unflock") { (action, indexPath) in
            let userToUnfriend = self.users![indexPath.row]
            // delete item at indexPath
            //let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            let cell = tableView.cellForRow(at: indexPath) as! SearchTableViewCell
          
            cell.setupCell(userState: .normal, currentUserID: appDelegate.user!.FBID, cellID: userToUnfriend.FBID)
            
            
            FirebaseClient.unFriendUser(userToUnfriend.FBID, toID: appDelegate.user!.FBID, completion: { (success) in
                //Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                Utilities.printDebugMessage("Deflock status: \(success)")
                cell.setEditing(false, animated: true)
                
            })
        }
        
        
        //share.backgroundColor = FlockColors.FLOCK_BLUE
        delete.backgroundColor = FlockColors.FLOCK_GRAY
        
        //return [delete, share]
        return [delete]
    }
    */
}


extension SearchPeopleTableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchBar.text!)
    }
}

extension SearchPeopleTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        _ = searchController.searchBar
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

protocol UpdateSearchTableViewDelegate: class {
    func updateStateDict(FBID : String, state : SearchPeopleTableViewController.UserStates)
}

//
//  SearchPeopleTableViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 04/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import SwiftAddressBook
import SCLAlertView
import MessageUI
import FBSDKCoreKit
import FBSDKShareKit

class SearchPeopleTableViewController: UITableViewController, UpdateSearchTableViewDelegate, InviteSenderTableViewDelegate, MFMessageComposeViewControllerDelegate {
    
    struct Constants {
        static let CELL_HEIGHT = 70
        static let SECTION_TITLES = ["All"]
    }
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var peopleToInvite = [SwiftAddressBookPerson]() //for use when segment is switched
    var filteredPeopleToInvite = [SwiftAddressBookPerson]()
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
    
    func inviteFacebookPressed() {
        let content = FBSDKAppInviteContent()
        content.appLinkURL = NSURL(string: "https://fb.me/1911872325698779") as URL!
        content.appInvitePreviewImageURL = NSURL(string: "https://firebasestorage.googleapis.com/v0/b/flock-43b66.appspot.com/o/message_images%2F76C9E67E-1CAB-4454-9287-C02746850D91?alt=media&token=ef9cc51c-5db6-4983-b046-fa0ae8e0d4a3") as URL!
        
        FBSDKAppInviteDialog.show(from: self, with: content, delegate: self)

    }
    
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        if (sender.selectedSegmentIndex == 1) {
            if (SwiftAddressBook.authorizationStatus() == .notDetermined) {
                
                SwiftAddressBook.requestAccessWithCompletion({ (success, error) -> Void in
                    if success {
                        //do something with swiftAddressBook
                        self.showInviteToFlockUI()
                    }
                    else {
                        sender.selectedSegmentIndex = 0
                        //self.showRestrictedAddressSettingsAlert()
                    }
                })
            }
            else if (SwiftAddressBook.authorizationStatus() == .authorized) {
                showInviteToFlockUI()
            }
            else {
                
                sender.selectedSegmentIndex = 0
                showRestrictedAddressSettingsAlert()
            }
        }
        else {
            tableView.reloadData()
        }
    }
    
    func showRestrictedAddressSettingsAlert() {
        let alert = SCLAlertView()
        let _ = alert.addButton("Settings", action: {
            UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString) as! URL)
        })
        _ = alert.showInfo("Address Book Settings", subTitle: "To invite people to Flock, we need access to your contacts! Hit settings to allow Flock access - we'll never send invites to your friends without your permission.")
    }
    
    func showInviteToFlockUI() {
        if let swiftAddressBook = swiftAddressBook {
            if let people = swiftAddressBook.allPeople {
                self.peopleToInvite = people.filter({ (person) -> Bool in
                    return (person.compositeName != nil && person.phoneNumbers != nil && person.phoneNumbers?.count != 0)
                })
            }
        }
        tableView.reloadData()
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
        if (segmentedControl.selectedSegmentIndex == 1) {
            self.filteredPeopleToInvite = (peopleToInvite.filter({( person : SwiftAddressBookPerson) -> Bool in
                if let name = person.compositeName {
                    return name.lowercased().contains(searchText.lowercased())
                }
                return false
            }))
        }
        else {
            self.filteredUsers = (users?.filter({( user : User) -> Bool in
                return user.Name.lowercased().contains(searchText.lowercased())
            }))!
        }
        
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
    
    
    
    enum UserStates {
        case alreadyFriends
        case requestPendingFromSelf
        case requestPendingFromUser
        case ourself
        case normal
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (segmentedControl.selectedSegmentIndex == 1) {
            if (section == 0) {
                return 1
            }
            if searchController.isActive && searchController.searchBar.text != "" {
                return self.filteredPeopleToInvite.count
            }
            return peopleToInvite.count
        }
        else {
            if searchController.isActive && searchController.searchBar.text != "" {
                return self.filteredUsers.count
            }
            return self.users!.count
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if (segmentedControl.selectedSegmentIndex == 1) {
            return 2
        }
        else {
            return 1
        }
    }
    

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (segmentedControl.selectedSegmentIndex == 1) {
            if (section == 1) {
                return "Facebook"
            }
            else {
                var title: String?
                if (peopleToInvite.count > 0) {
                    title = "All Contacts (\(peopleToInvite.count))"
                    self.navigationItem.title = nil
                } else {
                    title = "All Contacts"
                    self.navigationItem.title = nil
                }
                return title
            }
            
        }
        else {
            var title: String?
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if (appDelegate.users.count > 0) {
                title = "\(Constants.SECTION_TITLES[section]) (\(appDelegate.users.count))"
                self.navigationItem.title = nil
            } else {
                title = Constants.SECTION_TITLES[section]
                self.navigationItem.title = nil
            }
            Utilities.printDebugMessage("\(appDelegate.users.count)")
            return title
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
        
        if (segmentedControl.selectedSegmentIndex == 1) {
            var title: String?
            if (section == 0) {
                title = "Facebook"
            }
            if (peopleToInvite.count > 0) {
                title = "All Contacts (\(peopleToInvite.count))"
                self.navigationItem.title = nil
            } else {
                title = "All Contacts"
                self.navigationItem.title = nil
            }
            self.title = title
            label.text = title
            
            returnedView.addSubview(label)
        }
        else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if (appDelegate.users.count > 0) {
                label.text = "\(Constants.SECTION_TITLES[section]) (\(appDelegate.users.count))"
                self.title = "\(Constants.SECTION_TITLES[section]) (\(appDelegate.users.count))"
                self.navigationItem.title = nil
            } else {
                label.text = Constants.SECTION_TITLES[section]
                self.navigationItem.title = nil
            }
            //label.text = Constants.SECTION_TITLES[section]
            returnedView.addSubview(label)
        }
        
        
        return returnedView
    }
    
    func openTextMessage(toUser : String, phoneNumber : String, cell : InviteTableViewCell) {
        self.lastClickedInviteCell = cell
        Utilities.printDebugMessage(toUser + " " + phoneNumber)
        if !MFMessageComposeViewController.canSendText() {
            let alert = SCLAlertView()
            _ = alert.showInfo("Cannot send message", subTitle: "Looks like you can't send text messages! Feel free to invite friends to Flock on Facebook instead.")
        }
        else {
            /*let newFrame = buttonToReplace.frame
            buttonToReplace.isHidden = true
            
            let activityIndicator = UIActivityIndicatorView(frame: newFrame)
            self.view.addSubview(activityIndicator)
            activityIndicator.startAnimating()
            */
            
            let messageVC = MFMessageComposeViewController()
            
            messageVC.body = "Hey \(toUser), add me on Flock so we can share plans and meet up! https://fb.me/1911872325698779";
            messageVC.recipients = [phoneNumber]
            messageVC.messageComposeDelegate = self;
            
            self.present(messageVC, animated: false, completion: nil)
        }
        
    }
    
    var lastClickedInviteCell : InviteTableViewCell?
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        if (result == .sent) {
            if let cell = lastClickedInviteCell {
                if let indexPath = cell.indexPath {
                    if searchController.isActive && searchController.searchBar.text != "" {
                        self.filteredPeopleToInvite.remove(at: indexPath.row)
                    } else {
                        self.peopleToInvite.remove(at: indexPath.row)
                    }
                    
                    
                    DispatchQueue.main.async {
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
                
            }
            
        }
        else {
            if let cell = lastClickedInviteCell {
                cell.resetUI()
            }
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (segmentedControl.selectedSegmentIndex == 1) {
            if (indexPath.section == 0) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FACEBOOK_INVITE_TO_FLOCK", for: indexPath) as! InviteTableViewCell
                let button = cell.viewWithTag(1) as! UIButton
                button.addTarget(self, action: #selector(SearchPeopleTableViewController.inviteFacebookPressed), for: .touchUpInside)
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "INVITE_TO_FLOCK", for: indexPath) as! InviteTableViewCell
            cell.resetUI()
            var person : SwiftAddressBookPerson
            cell.activityIndicator.isHidden = true
            cell.indexPath = indexPath
            if searchController.isActive && searchController.searchBar.text != "" {
                person = filteredPeopleToInvite[indexPath.row]
            } else {
                person = peopleToInvite[indexPath.row]
            }
            
            if let name = person.compositeName {
                cell.nameLabel.text = name
            }
            cell.firstName = person.firstName
            cell.delegate = self
            if let phoneNumbers = person.phoneNumbers {
                if (phoneNumbers.count != 0) {
                    cell.statusLabel.text = phoneNumbers[0].value
                }
                else {
                    cell.statusLabel.text = "No number available"
                }
                
            }
            else {
                cell.statusLabel.text = "No number available"
            }
            cell.backgroundButtonView.setRounded()
            return cell
        }
        else {
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
            self.retrieveImage(imageURL: user.PictureURL, venueID: nil, imageView: cell.profilePic)
            self.makeViewCircle(imageView: cell.profilePic)
            cell.name.text = user.Name
            cell.setupCell(userState: userState, currentUserID: currentUser.FBID, cellID: user.FBID)
            cell.searchDelegate = self
            return cell
        }
        
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

protocol InviteSenderTableViewDelegate: class {
    func openTextMessage(toUser : String, phoneNumber : String, cell : InviteTableViewCell)
}

extension SearchPeopleTableViewController: FBSDKAppInviteDialogDelegate{
    /**
     Sent to the delegate when the app invite encounters an error.
     - Parameter appInviteDialog: The FBSDKAppInviteDialog that completed.
     - Parameter error: The error.
     */
    public func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: Error!) {
        Utilities.printDebugMessage("LETS GO")
    }
    
    
    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [AnyHashable : Any]!) {
        
            }
}


//
//  PeopleSelectorTableViewController.swift
//  Flock
//
//  Created by Grant Rheingold on 3/19/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit

class PeopleSelectorTableViewController: UITableViewController, UpdateSelectorTableViewDelegate {
    
    struct Constants {
        static let REUSE_IDENTIFIERS = ["SELECTOR"]
        static let STANDARD_CELL_SIZE = 75
    }
    @IBOutlet weak var inviteButton: UIBarButtonItem!
    
    var userName : String?
    var venueName : String?
    var displayDate : String?
    var friends  = [User]()
    var friendsToInvite = [String]()
    var imageCache = [String : UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.friends = Array(appDelegate.friends.values)
        self.friends.sort { (user1, user2) -> Bool in
            user1.Name < user2.Name
        }
        self.inviteButton.isEnabled = false
        
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
        if let userName = self.userName, let venueName = self.venueName, let displayDate = self.displayDate {
            Utilities.sendPushNotificationToPartOfFlock(title: "TESTING. \(userName) is planning to go to \(venueName) on \(displayDate)!", toFriends: friendsToInvite)
        }
        self.dismiss(animated: true) {
            Utilities.printDebugMessage("Successfully dismissed friend selector")
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
        let friendID = self.friends[indexPath.row].FBID
        self.addFriendIDToInvites(friendID: friendID)
        for friend in self.friendsToInvite {
            print(friend)
        }
    }
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        NSLog("You selected cell number: \(indexPath.row)!")
        let currentCell = tableView.cellForRow(at: indexPath) as! PeopleSelectorTableViewCell
        currentCell.setSelected(currentCell.isSelected, animated: true)
        let friendID = self.friends[indexPath.row].FBID
        self.removeFriendIDFromInvites(friendID: friendID)
        for friend in self.friendsToInvite {
            print(friend)
        }
    }
    
    func manuallySelectCell(row: Int, section: Int, isSelected: Bool) {
        let indexPath : IndexPath = IndexPath(row: row, section: section)
        if(!isSelected) {
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            let friendID = self.friends[indexPath.row].FBID
            self.addFriendIDToInvites(friendID: friendID)
        } else {
            self.tableView.deselectRow(at: indexPath, animated: true)
            let friendID = self.friends[indexPath.row].FBID
            self.removeFriendIDFromInvites(friendID: friendID)
        }
        for friend in self.friendsToInvite {
            print(friend)
        }
    }
    
    func addFriendIDToInvites(friendID : String) {
        self.friendsToInvite.append(friendID)
        if(self.friendsToInvite.count > 0) {
            self.inviteButton.isEnabled = true
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
        return self.friends.count
    }
    
    fileprivate func setupCell(cell : UITableViewCell) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.REUSE_IDENTIFIERS[indexPath.section], for: indexPath) as! PeopleSelectorTableViewCell
        let friend = self.friends[indexPath.row]
        cell.name.text = friend.Name
        self.retrieveImage(imageURL: friend.PictureURL, imageView: cell.profilePic!)
        cell.subtitle.text = "Something goes here?"
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
}

protocol UpdateSelectorTableViewDelegate: class {
    func manuallySelectCell(row: Int, section: Int, isSelected: Bool)
}
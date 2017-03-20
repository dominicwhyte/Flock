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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NSLog("You selected cell number: \(indexPath.row)!")
        let currentCell = tableView.cellForRow(at: indexPath) as! PeopleSelectorTableViewCell
        currentCell.setSelected(currentCell.isSelected, animated: true)
    }
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        NSLog("You selected cell number: \(indexPath.row)!")
        let currentCell = tableView.cellForRow(at: indexPath) as! PeopleSelectorTableViewCell
        currentCell.setSelected(currentCell.isSelected, animated: true)
    }

    func addFriendIDToInvites(friendID : String) {
        self.friendsToInvite.append(friendID)
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
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol UpdateSelectorTableViewDelegate: class {
    func addFriendIDToInvites(friendID : String)
}

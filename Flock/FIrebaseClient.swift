//
//  FIrebaseClient.swift
//  Flock
//
//  Created by Dominic Whyte on 02/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class FirebaseClient: NSObject
{
    static let dataRef = FIRDatabase.database().reference()
    
    //Upload an image to firebase
    class func uploadToFirebaseStorageUsingImage(_ image: UIImage, completion: @escaping (_ imageUrl: String?) -> ()) {
        let imageName = UUID().uuidString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed to upload image:", error ?? "Error")
                    completion(nil)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl)
                }
            })
        }
    }
    
    class func addVenue(_ name : String, imageURL : String, logoURL : String, completion: @escaping (Bool) -> Void)
    {
        let venueID = FirebaseClient.dataRef.child("Venues").childByAutoId().key
        let updates = ["VenueID" : venueID, "ImageURL" : imageURL, "LogoURL" : logoURL, "VenueName" : name] as [String : Any]
        dataRef.child("Venues").child(venueID).updateChildValues(updates)
        completion(true)
        
    }
    
    //Returns successful completion if friend request is sent or if friend request confirmed (via two way requests)
    class func sendFriendRequest(_ fromID : String, toID : String, completion: @escaping (Bool) -> Void) {
        
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.hasChild(toID) && snapshot.hasChild(fromID) && fromID != toID) {
                //Check that they are not already friends
                if ((snapshot.childSnapshot(forPath: toID).hasChild("Friends") && snapshot.childSnapshot(forPath: toID).childSnapshot(forPath: "Friends").hasChild(fromID)) || (snapshot.childSnapshot(forPath: fromID).hasChild("Friends") && snapshot.childSnapshot(forPath: fromID).childSnapshot(forPath: "Friends").hasChild(toID))) {
                    completion(false)
                }
                //If fromID already has a request from toID, then confirm friends
                else if (snapshot.childSnapshot(forPath: fromID).hasChild("FriendRequests") && snapshot.childSnapshot(forPath: fromID).childSnapshot(forPath: "FriendRequests").hasChild(toID)) {
                    confirmFriendRequest(toID, toID: fromID, completion: { (success) in
                        completion(success)
                    })
                }
                //Cases for actually adding friend request
                else if (snapshot.childSnapshot(forPath: toID).hasChild("FriendRequests"))
                {
                    let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                    let toUserDict = dictionary[toID] as! [String: AnyObject]
                    
                    var friendRequests = toUserDict["FriendRequests"] as! [String : AnyObject]
                    if (friendRequests[fromID] == nil) {
                        friendRequests[fromID] = fromID as AnyObject?
                    }
                    let updates = ["FriendRequests": friendRequests]
                    dataRef.child("Users").child(toID).updateChildValues(updates)
                    completion(true)
                }
                    
                else
                {
                    let updates = ["FriendRequests": [fromID : fromID]]
                    dataRef.child("Users").child(toID).updateChildValues(updates)
                    completion(true)
                }
                
            }
            else {
                completion(false)
            }
        })
    }
    
    //Returns successful completion if friend request is rejected
    class func rejectFriendRequest(_ fromID : String, toID : String, completion: @escaping (Bool) -> Void) {
        
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.hasChild(toID) && snapshot.childSnapshot(forPath: toID).hasChild("FriendRequests") && toID != fromID) {
                //Cases for actually adding friend request

                let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                let toUserDict = dictionary[toID] as! [String: AnyObject]
                    
                var friendRequests = toUserDict["FriendRequests"] as! [String : AnyObject]
                if (friendRequests[fromID] != nil) {
                    friendRequests[fromID] = nil as AnyObject?
                    let updates = ["FriendRequests": friendRequests]
                    dataRef.child("Users").child(toID).updateChildValues(updates)
                    completion(true)
                }
                else {
                    completion(false)
                }
                
            }
            else {
                completion(false)
            }
        })
    }

    
    class func confirmFriendRequest(_ fromID : String, toID : String, completion: @escaping (Bool) -> Void) {
        
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            // Confirm friend request conditions
            if (snapshot.hasChild(fromID) && snapshot.hasChild(toID) && snapshot.childSnapshot(forPath: toID).hasChild("FriendRequests") && snapshot.childSnapshot(forPath: toID).childSnapshot(forPath: "FriendRequests").hasChild(fromID) && toID != fromID) {
                let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                
                // Add the fromID to the toID friend list
                if (snapshot.childSnapshot(forPath: toID).hasChild("Friends"))
                {
                    let toUserDict = dictionary[toID] as! [String: AnyObject]
                    
                    var friends = toUserDict["Friends"] as! [String : AnyObject]
                    if (friends[fromID] == nil) {
                        friends[fromID] = fromID as AnyObject?
                    }
                    let updates = ["Friends": friends]
                    dataRef.child("Users").child(toID).updateChildValues(updates)
                }
                    
                else
                {
                    let updates = ["Friends": [fromID : fromID]]
                    dataRef.child("Users").child(toID).updateChildValues(updates)
                }
                // Add the toID to the fromID friend list
                if (snapshot.childSnapshot(forPath: fromID).hasChild("Friends"))
                {
                    let fromUserDict = dictionary[fromID] as! [String: AnyObject]
                    
                    var friends = fromUserDict["Friends"] as! [String : AnyObject]
                    if (friends[toID] == nil) {
                        friends[toID] = toID as AnyObject?
                    }
                    let updates = ["Friends": friends]
                    dataRef.child("Users").child(fromID).updateChildValues(updates)
                }
                    
                else
                {
                    let updates = ["Friends": [toID : toID]]
                    dataRef.child("Users").child(fromID).updateChildValues(updates)
                }
                // Remove the friend request, standard and should occur
                self.rejectFriendRequest(fromID, toID: toID, completion: { (success) in
                    // Remove friend request from "to" to "from", which should not be present
                    // since the two should have been auto-friended if this occurs. Hence
                    // the typical behavior should be a false completion
                    self.rejectFriendRequest(toID, toID: fromID, completion: { (failure) in
                        completion(!failure && success)
                    })
                })
                
            }
            else {
                completion(false)
            }
        })
    }
    
    class func unFriendUser(_ fromID : String, toID : String, completion: @escaping (Bool) -> Void) {
        
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            // Confirm unfriend request conditions
            if (snapshot.hasChild(fromID) && snapshot.hasChild(toID) && snapshot.childSnapshot(forPath: toID).hasChild("Friends") && snapshot.childSnapshot(forPath: toID).childSnapshot(forPath: "Friends").hasChild(fromID) && snapshot.childSnapshot(forPath: fromID).hasChild("Friends") && snapshot.childSnapshot(forPath: fromID).childSnapshot(forPath: "Friends").hasChild(toID) && fromID != toID) {
                
                //Remove fromId from toId friend list
                let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                let toUserDict = dictionary[toID] as! [String: AnyObject]
                
                var friends = toUserDict["Friends"] as! [String : AnyObject]
                if (friends[fromID] != nil) {
                    friends[fromID] = nil as AnyObject?
                }
                var updates = ["Friends": friends]
                dataRef.child("Users").child(toID).updateChildValues(updates)
                
                //Remove toId from fromId friend list
                let fromUserDict = dictionary[fromID] as! [String: AnyObject]
                
                friends = fromUserDict["Friends"] as! [String : AnyObject]
                if (friends[toID] != nil) {
                    friends[toID] = nil as AnyObject?
                }
                updates = ["Friends": friends]
                dataRef.child("Users").child(fromID).updateChildValues(updates)
                
                completion(true)
                
            }
            else {
                completion(false)
            }
        })
    }
    
    class func removeVenueWithID(_ id : String) {
        
    }
    
    //Get an image from a URL, with completion handler for caching the image
    //Should use this function more!
    static func getImageFromURL(_ imageURL : String, _ completion: @escaping (UIImage?) -> Void) {
        if (imageURL == "") {
            Utilities.printDebugMessage("Blank profile pic")
            completion(nil)
        }
        else {
            let imageURLObj = URL(string: imageURL)
            
            if (imageURLObj != nil) {
                //Create NSUrl request object
                let request = URLRequest(url: imageURLObj!)
                
                //Create NSUrlSession
                let session = URLSession.shared
                
                //Create a datatask and pass the request
                let dataTask = session.dataTask(with: request, completionHandler: { (data : Data?, response : URLResponse?, error : Error?) -> Void in
                    
                    //the following is all updating UI, so do it in the main thread
                    
                    //create image object from data and assign to image
                    if (data != nil) {
                        let image = (UIImage(data: data!)!)
                        completion(image)
                    }
                    else {
                        completion(nil)
                        Utilities.printDebugMessage("Error getting image for UITableView")
                    }
                    
                })
                dataTask.resume()
                
            }
        }
        
    }
    
    //Gets the logged in User and the Venues
    class func getAllUsers(_ completion: @escaping ([String : User]) -> Void)
    {
        
        var userDicts = [String : NSDictionary]()
        
        //Get the overall snapshot
        dataRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            
            //USER
            if (snapshot.hasChild("Users")) {
                userDicts = snapshot.childSnapshot(forPath: "Users").value as! [String : NSDictionary]
            }
            var users = [String : User]()
            
            for (_,user) in userDicts {
                let newUser = User(dict: user as! [String : AnyObject])
                users[newUser.FBID] = newUser
            }
            //Called only when the respective dictionaries have been created
            completion(users)
            
        })
    }
    
    
    //Add plan to user plans and add user to planned attendees in venue
    class func addUserToVenuePlansForDate(date: String, venueID : String, userID : String, completion: @escaping (Bool) -> Void) {
        addUserToVenuePlannedAttendees(venueID: venueID, userID: userID) { (venueSuccess) in
            if (venueSuccess) {
                addPlanToUserForDate(date: date, venueID: venueID, userID: userID, completion: { (userSuccess) in
                    completion(userSuccess)
                })
            }
            else {
                
            }
        }
    }
    
    static func addUserToVenuePlannedAttendees(venueID : String, userID : String, completion: @escaping (Bool) -> Void) {
        
        dataRef.child("Venues").observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.hasChild(venueID)) {
                if (snapshot.childSnapshot(forPath: venueID).hasChild("PlannedAttendees") ) {
                    if (snapshot.childSnapshot(forPath: venueID).childSnapshot(forPath: "PlannedAttendees").hasChild(userID)) {
                        completion(false)
                    }
                    else {
                        let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                        let venueDict = dictionary[venueID] as! [String: AnyObject]
                        
                        var plannedAttendees = venueDict["PlannedAttendees"] as! [String : AnyObject]
                        if (plannedAttendees[userID] == nil) {
                            plannedAttendees[userID] = userID as AnyObject?
                        }
                        let updates = ["PlannedAttendees": plannedAttendees]
                        dataRef.child("Venues").child(venueID).updateChildValues(updates)
                        completion(true)
                    }
                }
                 //Planned attendees dict not present
                else
                {
                    let updates = ["PlannedAttendees": [userID : userID]]
                    dataRef.child("Venues").child(venueID).updateChildValues(updates)
                    completion(true)
                }
                
            }
            else {
                completion(false)
            }
        })

    }
    
    static func addPlanToUserForDate(date: String, venueID : String, userID : String, completion: @escaping (Bool) -> Void) {
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.hasChild(userID)) {
                if (snapshot.childSnapshot(forPath: userID).hasChild("Plans")) {
                    let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                    let userDict = dictionary[userID] as! [String: AnyObject]
                    var plansDict = userDict["Plans"] as! [String : AnyObject]
                    
                    let uniqueVisitID = UUID().uuidString
                    let planDetails = ["Date" : date, "VenueID" : venueID]
                    if (plansDict[uniqueVisitID] == nil) {
                        plansDict[uniqueVisitID] = planDetails as AnyObject?
                    }
                    else {
                        Utilities.printDebugMessage("Error: unique IDs are not unique")
                    }
                    let updates = ["Plans": plansDict]
                    dataRef.child("Users").child(userID).updateChildValues(updates)
                    completion(true)
                }
                    //Planned attendees dict not present
                else
                {
                    let uniqueVisitID = UUID().uuidString
                    let planDetails = ["Date" : date, "VenueID" : venueID]
                    let plansDict = [uniqueVisitID : planDetails]
                    let updates = ["Plans": plansDict]
                    dataRef.child("Users").child(userID).updateChildValues(updates)
                    completion(true)
                }
                
            }
            else {
                completion(false)
            }
        })
    }
    
}


















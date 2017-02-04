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
    
    class func addVenue(_ name : String, imageURL : String, completion: @escaping (Bool) -> Void)
    {
        let venueID = FirebaseClient.dataRef.child("Venues").childByAutoId().key
        let updates = ["VenueID" : venueID, "ImageURL" : imageURL, "VenueName" : name] as [String : Any]
        dataRef.child("Venues").child(venueID).updateChildValues(updates)
        completion(true)
        
    }
    
    class func sendFriendRequest(_ fromID : String, toID : String, completion: @escaping (Bool) -> Void) {
        
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.hasChild(toID)) {
                if (snapshot.childSnapshot(forPath: toID).hasChild("FriendRequests"))
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
    
    class func confirmFriendRequest(_ fromID : String, toID : String, completion: @escaping (Bool) -> Void) {
        
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.hasChild(fromID)) {
                Utilities.printDebugMessage("1")
            }
            if(snapshot.hasChild(toID)) {
                Utilities.printDebugMessage("2")
            }
            if(snapshot.childSnapshot(forPath: toID).hasChild("FriendRequests")) {
                Utilities.printDebugMessage("3")
            }
            if(snapshot.childSnapshot(forPath: toID).childSnapshot(forPath: "FriendRequests").hasChild(fromID)) {
                Utilities.printDebugMessage("4")
            }
            if (snapshot.hasChild(fromID) && snapshot.hasChild(toID) && snapshot.childSnapshot(forPath: toID).hasChild("FriendRequests") && snapshot.childSnapshot(forPath: toID).childSnapshot(forPath: "FriendRequests").hasChild(fromID)) {
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
                
                //Remove Friend Request
                if (snapshot.childSnapshot(forPath: toID).hasChild("FriendRequests"))
                {
                    let toUserDict = dictionary[toID] as! [String: AnyObject]
                    
                    var friendRequests = toUserDict["FriendRequests"] as! [String : AnyObject]
                    if (friendRequests[fromID] != nil) {
                        friendRequests[fromID] = nil
                    }
                    else {
                        Utilities.printDebugMessage("Error: friend request to remove not present")
                    }
                    let updates = ["FriendRequests": friendRequests]
                    dataRef.child("Users").child(toID).updateChildValues(updates)
                }
                else {
                    Utilities.printDebugMessage("Error: could not remove friend request")
                }
                
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
    
}



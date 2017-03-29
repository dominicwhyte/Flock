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
    
    class func addVenue(_ name : String, imageURL : String, logoURL : String, nickname : String, completion: @escaping (Bool) -> Void)
    {
        let venueID = FirebaseClient.dataRef.child("Venues").childByAutoId().key
        let updates = ["VenueID" : venueID, "ImageURL" : imageURL, "LogoURL" : logoURL, "VenueName" : name, "VenueNickName" : nickname] as [String : Any]
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
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    if let user = appDelegate.user {
                        if(appDelegate.alreadySentFriendRequests[toID] == nil) {
                            Utilities.sendPushNotification(title: "\(user.Name) sent you a Flock request", toUserFBID: toID)
                        }
                        appDelegate.alreadySentFriendRequests[toID] = toID
                    }
                    else {
                        Utilities.printDebugMessage("Error getting user")
                    }
                    
                    completion(true)
                }
                    
                else
                {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    if let user = appDelegate.user {
                        if(appDelegate.alreadySentFriendRequests[toID] == nil) {
                            Utilities.sendPushNotification(title: "\(user.Name) sent you a Flock request", toUserFBID: toID)
                        }
                        appDelegate.alreadySentFriendRequests[toID] = toID
                    }
                    else {
                        Utilities.printDebugMessage("Error getting user")
                    }
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
        
        dataRef.observeSingleEvent(of: .value, with: { (snapshot) in
            // Confirm friend request conditions
            if (snapshot.childSnapshot(forPath: "Users").hasChild(fromID) && snapshot.childSnapshot(forPath: "Users").hasChild(toID) && snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: toID).hasChild("FriendRequests") && snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: toID).childSnapshot(forPath: "FriendRequests").hasChild(fromID) && toID != fromID) {
                let dictionary :[String:AnyObject] = snapshot.childSnapshot(forPath: "Users").value as! [String : AnyObject]
                
                // Add the fromID to the toID friend list
                if (snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: toID).hasChild("Friends"))
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
                if (snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: fromID).hasChild("Friends"))
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
                        
                        addChannelForTwoFriends(fromID: fromID, toID: toID, usersDictionary: dictionary, snapshot: snapshot, completion: { (channelSuccess) in
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            if let user = appDelegate.user {
                                Utilities.sendPushNotification(title: "\(user.Name) accepted your Flock request", toUserFBID: fromID)
                            }
                            completion(!failure && success && channelSuccess)
                        })
                    })
                })
                
            }
            else {
                completion(false)
            }
        })
    }
    
    class func updateUserNotificationInfo(notificationUserId : String?, notificationPushToken : String?, completion: @escaping (Bool) -> Void) {
        if let FBID = FBSDKAccessToken.current().userID {
            dataRef.observeSingleEvent(of: .value, with: { (snapshot) in
                if (snapshot.childSnapshot(forPath: "Users").hasChild(FBID)) {
                    if let notificationUserId = notificationUserId {
                        let updates = ["NotificationUserID": notificationUserId]
                        dataRef.child("Users").child(FBID).updateChildValues(updates)
                    }
                    if let notificationPushToken = notificationPushToken {
                        let updates = ["NotificationPushToken": notificationPushToken]
                        dataRef.child("Users").child(FBID).updateChildValues(updates)
                    }
                }
                completion(true)
            })
        }
        else {
            completion(false)
        }
        
    }
    
    //Creates a channel for two friends, and adds the channel to both the users' ChannelIDs Dicts
    class func addChannelForTwoFriends(fromID : String, toID : String, usersDictionary : [String: AnyObject], snapshot : FIRDataSnapshot, completion: @escaping (Bool) -> Void)
    {
        
        //Check if the users do not already have a channel together, else do nothing
        if (!(snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: toID).hasChild("ChannelIDs") && snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: fromID).hasChild("ChannelIDs") && snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: toID).childSnapshot(forPath: "ChannelIDs").hasChild(fromID) && snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: fromID).childSnapshot(forPath: "ChannelIDs").hasChild(toID)))
        {
            let channelID = createChannel(channelName: "Flock Chat")
            //toID has no channelIDs
            if (!snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: toID).hasChild("ChannelIDs")) {
                let updates = ["ChannelIDs": [fromID:channelID]]
                dataRef.child("Users").child(toID).updateChildValues(updates)
            }
            else {
                let toIDUserDict = usersDictionary[toID] as! [String: AnyObject]
                
                var channelDict = toIDUserDict["ChannelIDs"] as! [String : String]
                channelDict[fromID] = channelID
                let updates = ["ChannelIDs": channelDict]
                dataRef.child("Users").child(toID).updateChildValues(updates)
                
            }
            //fromID has no channelIDs
            if (!snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: fromID).hasChild("ChannelIDs")) {
                let updates = ["ChannelIDs": [toID:channelID]]
                dataRef.child("Users").child(fromID).updateChildValues(updates)
            }
            else {
                let fromIDUserDict = usersDictionary[fromID] as! [String: AnyObject]
                
                var channelDict = fromIDUserDict["ChannelIDs"] as! [String : String]
                channelDict[toID] = channelID
                let updates = ["ChannelIDs": channelDict]
                dataRef.child("Users").child(fromID).updateChildValues(updates)
            }
        }
        completion(true)
    }
    
    class func createChannel(channelName : String) -> String {
        let newChannelRef = dataRef.child("channels").childByAutoId() // 2
        let channelItem = [ // 3
            "name": channelName
        ]
        newChannelRef.setValue(channelItem) // 4
        Utilities.printDebugMessage("This is yo key: \(newChannelRef.key)")
        return newChannelRef.key
    }
    
    class func uploadEvent(_ chosenVenueID : String, chosenEventName : String, chosenDateString : String, optionalImageURL : String?, isSpecialEvent : Bool, completion: @escaping (Bool) -> Void) {
        
        dataRef.child("Venues").observeSingleEvent(of: .value, with: { (snapshot) in
            // Confirm unfriend request conditions
            
            if (snapshot.hasChild(chosenVenueID)) {
                let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                let venueDict = dictionary[chosenVenueID] as! [String: AnyObject]
                
                let uniqueEventID = UUID().uuidString
                
                var newDict = [EventFirebaseConstants.eventDate : chosenDateString as AnyObject, EventFirebaseConstants.eventName : chosenEventName as AnyObject, EventFirebaseConstants.specialEvent : isSpecialEvent as AnyObject, EventFirebaseConstants.venueID : chosenVenueID as AnyObject, EventFirebaseConstants.eventID : uniqueEventID as AnyObject] as [String : AnyObject]
                
                if let imageURL = optionalImageURL {
                    newDict[EventFirebaseConstants.eventImageURL] = imageURL as AnyObject
                }
                
                if (venueDict[EventFirebaseConstants.eventsSubgroup] == nil) {
                    let updates = [EventFirebaseConstants.eventsSubgroup : [uniqueEventID : newDict]]
                    dataRef.child("Venues").child(chosenVenueID).updateChildValues(updates)
                }
                else {
                    var events = venueDict[EventFirebaseConstants.eventsSubgroup] as! [String : [String : AnyObject]]
                    if (events[uniqueEventID] == nil) {
                        events[uniqueEventID] = newDict
                    }
                    else {
                        Utilities.printDebugMessage("Fatal error: unique IDs not unique")
                        completion(false)
                        return
                    }
                    let updates = [EventFirebaseConstants.eventsSubgroup : events]
                    dataRef.child("Venues").child(chosenVenueID).updateChildValues(updates)
                }
                completion(true)
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
    static func getImageFromURL(_ imageURL : String, venueID : String?, _ completion: @escaping (UIImage?) -> Void) {
        if (imageURL == "") {
            Utilities.printDebugMessage("Blank profile pic")
            completion(nil)
        }
        else if (venueID != nil && UIImage(named: venueID!) != nil){
            Utilities.printDebugMessage("Image was stored in casettes")
            let image = UIImage(named: venueID!)
            completion(image)
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
                        if let image = UIImage(data: data!) {
                            completion(image)
                        }
                        else {
                            Utilities.printDebugMessage("ERROR: could not get image from data")
                            completion(nil)
                        }
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
    
    
    
    
    //Add plan to user plans and add user to planned attendees in venue
    class func addUserToVenuePlansForDate(date: String, venueID : String, userID : String, add: Bool, specialEventID : String?, completion: @escaping (Bool) -> Void) {
        addUserToVenuePlannedAttendeesAndSpecialEventIfNecessary(venueID: venueID, userID: userID, add: add, specialEventID : specialEventID) { (venueSuccess) in
            if (venueSuccess) {
                addPlanToUserForDate(date: date, venueID: venueID, userID: userID, add : add, specialEventID : specialEventID,completion: { (userSuccess) in
                    completion(userSuccess)
                })
            }
            else {
                completion(false)
            }
        }
    }
    
    static func addUserToVenuePlannedAttendeesAndSpecialEventIfNecessary(venueID : String, userID : String,  add: Bool, specialEventID : String?, completion: @escaping (Bool) -> Void) {
        
        dataRef.observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.childSnapshot(forPath: "Venues").hasChild(venueID)) {
                //add to special event a new attendee, or remove if add is False
                if let specialEventID = specialEventID {
                    Utilities.printDebugMessage("check1")
                    if (snapshot.childSnapshot(forPath: "Venues").childSnapshot(forPath: venueID).hasChild(EventFirebaseConstants.eventsSubgroup) && snapshot.childSnapshot(forPath: "Venues").childSnapshot(forPath: venueID).childSnapshot(forPath: EventFirebaseConstants.eventsSubgroup).hasChild(specialEventID)) {
                        
                        let dictionary :[String:AnyObject] = snapshot.childSnapshot(forPath: "Venues").value as! [String : AnyObject]
                        let venueDict = dictionary[venueID] as! [String: AnyObject]
                        let eventsDict = venueDict[EventFirebaseConstants.eventsSubgroup] as! [String: AnyObject]
                        let eventToPlanWithDict = eventsDict[specialEventID] as! [String : AnyObject]
                        
                        if (add) {
                            Utilities.printDebugMessage("adding")
                            if (snapshot.childSnapshot(forPath: "Venues").childSnapshot(forPath: venueID).childSnapshot(forPath: EventFirebaseConstants.eventsSubgroup).childSnapshot(forPath: specialEventID).hasChild(EventFirebaseConstants.eventAttendeeFBIDs)) {
                                var planningAttendees = eventToPlanWithDict[EventFirebaseConstants.eventAttendeeFBIDs] as! [String:String]
                                planningAttendees[userID] = userID
                                let updates = [EventFirebaseConstants.eventAttendeeFBIDs: planningAttendees]
                                dataRef.child("Venues").child(venueID).child(EventFirebaseConstants.eventsSubgroup).child(specialEventID).updateChildValues(updates)
                                
                            }
                            else {
                                Utilities.printDebugMessage("all da way")
                                let updates = [EventFirebaseConstants.eventAttendeeFBIDs: [userID:userID]]
                                dataRef.child("Venues").child(venueID).child(EventFirebaseConstants.eventsSubgroup).child(specialEventID).updateChildValues(updates)
                            }
                        }
                        else {
                            if (snapshot.childSnapshot(forPath: "Venues").childSnapshot(forPath: venueID).childSnapshot(forPath: EventFirebaseConstants.eventsSubgroup).childSnapshot(forPath: specialEventID).hasChild(EventFirebaseConstants.eventAttendeeFBIDs)) {
                                var planningAttendees = eventToPlanWithDict[EventFirebaseConstants.eventAttendeeFBIDs] as! [String:String]
                                planningAttendees[userID] = nil
                                let updates = [EventFirebaseConstants.eventAttendeeFBIDs: planningAttendees]
                                dataRef.child("Venues").child(venueID).child(EventFirebaseConstants.eventsSubgroup).child(specialEventID).updateChildValues(updates)
                            }
                            else {
                                Utilities.printDebugMessage("Error removing user from plan to go to special event")
                            }
                        }
                        
                    }
                    else {
                        Utilities.printDebugMessage("Error: Trying to add or remove event plan from nonexisting event. Does not complete false in case a past event was deleted")
                    }
                }
                
                
                if (snapshot.childSnapshot(forPath: "Venues").childSnapshot(forPath: venueID).hasChild("PlannedAttendees") ) {
                    let dictionary :[String:AnyObject] = snapshot.childSnapshot(forPath: "Venues").value as! [String : AnyObject]
                    let venueDict = dictionary[venueID] as! [String: AnyObject]
                    
                    var plannedAttendees = venueDict["PlannedAttendees"] as! [String : AnyObject]
                    
                    // If adding to plans
                    if(add) {
                        if (plannedAttendees[userID] == nil) {
                            plannedAttendees[userID] = userID as AnyObject?
                        }
                    }
                        // If removing from plans
                    else {
                        let userDictionary :[String:AnyObject] = snapshot.childSnapshot(forPath: "Users").value as! [String : AnyObject]
                        let userDict = userDictionary[userID] as! [String: AnyObject]
                        let plansDict = userDict["Plans"] as! [String : AnyObject]
                        
                        var uniquePlansCount = 0
                        for (_, plan) in plansDict {
                            let dateString = (plan["Date"] as! String)
                            let date = DateUtilities.getDateFromString(date: dateString)
                            let isValidTimeFrame = DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: date))
                            if((plan["VenueID"] as! String) == venueID && isValidTimeFrame) {
                                uniquePlansCount += 1
                            }
                        }
                        
                        if(uniquePlansCount == 1) {
                            plannedAttendees[userID] = nil
                        }
                    }
                    let updates = ["PlannedAttendees": plannedAttendees]
                    dataRef.child("Venues").child(venueID).updateChildValues(updates)
                    completion(true)
                    
                }
                    //Planned attendees dict not present
                else
                {
                    if(add) {
                        let updates = ["PlannedAttendees": [userID : userID]]
                        dataRef.child("Venues").child(venueID).updateChildValues(updates)
                    }
                    completion(true)
                }
                
            }
            else {
                completion(false)
            }
        })
    }
    
    static func addPlanToUserForDate(date: String, venueID : String, userID : String, add: Bool, specialEventID : String?, completion: @escaping (Bool) -> Void) {
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.hasChild(userID)) {
                if (snapshot.childSnapshot(forPath: userID).hasChild("Plans")) {
                    let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                    let userDict = dictionary[userID] as! [String: AnyObject]
                    var plansDict = userDict["Plans"] as! [String : AnyObject]
                    // Adding plan to user
                    if(add) {
                        let uniqueVisitID = UUID().uuidString
                        var planDetails = ["Date" : date, "VenueID" : venueID]
                        
                        if let specialEventID = specialEventID {
                            planDetails["SpecialEventID"] = specialEventID
                        }
                        
                        if (plansDict[uniqueVisitID] == nil) {
                            plansDict[uniqueVisitID] = planDetails as AnyObject?
                        }
                        else {
                            Utilities.printDebugMessage("Error: unique IDs are not unique")
                        }
                    }
                        // Removing plan from user
                    else {
                        for (uniqueVisitID, plan) in plansDict {
                            if((plan["Date"] as! String) == date && (plan["VenueID"] as! String) == venueID) {
                                if (plansDict[uniqueVisitID] != nil) {
                                    plansDict[uniqueVisitID] = nil
                                }
                            }
                        }
                    }
                    
                    let updates = ["Plans": plansDict]
                    dataRef.child("Users").child(userID).updateChildValues(updates)
                    completion(true)
                }
                    //Planned attendees dict not present
                else
                {
                    if(add) {
                        let uniqueVisitID = UUID().uuidString
                        var planDetails = ["Date" : date, "VenueID" : venueID]
                        
                        if let specialEventID = specialEventID {
                            planDetails["SpecialEventID"] = specialEventID
                        }
                        
                        let plansDict = [uniqueVisitID : planDetails]
                        let updates = ["Plans": plansDict]
                        dataRef.child("Users").child(userID).updateChildValues(updates)
                        completion(true)
                    }
                }
                
            }
            else {
                completion(false)
            }
        })
    }
    
    // Add invitation to toUser for a venue on a date, with a special eventID if necessary
    static func addInvitationToUserForVenueForDate(toUserID: String, fromUserID: String, date: String, venueID : String, add: Bool, specialEventID : String?, completion: @escaping (Bool) -> Void) {
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.hasChild(toUserID)) {
                if (snapshot.childSnapshot(forPath: toUserID).hasChild("Invitations")) {
                    let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                    let userDict = dictionary[toUserID] as! [String: AnyObject]
                    var invitationsDict = userDict["Invitations"] as! [String : AnyObject]
                    // Adding invitation to user
                    if(add) {
                        let uniqueInvitationID = UUID().uuidString
                        var invitationDetails = ["FromUserID": fromUserID, "Date" : date, "VenueID" : venueID, "InviteID" : uniqueInvitationID]
                        
                        if let specialEventID = specialEventID {
                            invitationDetails["SpecialEventID"] = specialEventID
                        }
                        
                        if (invitationsDict[uniqueInvitationID] == nil) {
                            invitationsDict[uniqueInvitationID] = invitationDetails as AnyObject?
                        }
                        else {
                            Utilities.printDebugMessage("Error: unique IDs are not unique")
                        }
                    }
                        // Removing plan from user
                    else {
                        for (uniqueInvitationID, invitation) in invitationsDict {
                            if((invitation["Date"] as! String) == date && (invitation["VenueID"] as! String) == venueID && (invitation["fromUserID"] as! String) == fromUserID) {
                                if (invitationsDict[uniqueInvitationID] != nil) {
                                    invitationsDict[uniqueInvitationID] = nil
                                }
                            }
                        }
                    }
                    
                    let updates = ["Invitations": invitationsDict]
                    dataRef.child("Users").child(toUserID).updateChildValues(updates)
                    completion(true)
                }
                    //Planned attendees dict not present
                else
                {
                    if(add) {
                        let uniqueInvitationID = UUID().uuidString
                        var invitationDetails = ["FromUserID": fromUserID, "Date" : date, "VenueID" : venueID, "InviteID" : uniqueInvitationID]
                        
                        if let specialEventID = specialEventID {
                            invitationDetails["SpecialEventID"] = specialEventID
                        }
                        
                        let invitationsDict = [uniqueInvitationID : invitationDetails]
                        let updates = ["Invitations": invitationsDict]
                        dataRef.child("Users").child(toUserID).updateChildValues(updates)
                        completion(true)
                    }
                }
                
            }
            else {
                completion(false)
            }
        })
    }

    
    class func acceptOrRejectInviteRequest(accepted : Bool, uniqueInvitationID : String, userID : String, completion: @escaping (Bool) -> Void) {
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.hasChild(userID) && snapshot.childSnapshot(forPath: userID).hasChild("Invitations") && snapshot.childSnapshot(forPath: userID).childSnapshot(forPath: "Invitations").hasChild(uniqueInvitationID)) {
                let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                let userDict = dictionary[userID] as! [String: AnyObject]
                var invitationsDict = userDict["Invitations"] as! [String : AnyObject]
                var invitationDict = invitationsDict[uniqueInvitationID] as! [String : AnyObject]
                invitationDict["Accepted"] = accepted as AnyObject?
                let updates = [uniqueInvitationID: invitationDict]
                dataRef.child("Users").child(userID).child("Invitations").updateChildValues(updates)
                completion(true)
            }
            else {
                completion(false)
            }
        })
    }
    
    
    //Add plan to user plans and add user to planned attendees in venue
    class func addUserToVenueLive(date: String, venueID : String, userID : String, add : Bool,  completion: @escaping (Bool) -> Void) {
        addUserToVenueCurrentAttendees(venueID: venueID, userID: userID, add: add) { (venueSuccess) in
            if (venueSuccess) {
                addLiveToUserForDate(date: date, venueID: venueID, userID: userID, add: add, completion: { (userSuccess) in
                    completion(userSuccess)
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.profileNeedsToUpdate = true
                })
            }
            else {
                Utilities.printDebugMessage("Error adding user to venue")
                completion(false)
            }
        }
    }
    
    static func addUserToVenueCurrentAttendees(venueID : String, userID : String, add: Bool, completion: @escaping (Bool) -> Void) {
        
        dataRef.child("Venues").observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.hasChild(venueID)) {
                if (snapshot.childSnapshot(forPath: venueID).hasChild("CurrentAttendees") ) {
                    if (snapshot.childSnapshot(forPath: venueID).childSnapshot(forPath: "CurrentAttendees").hasChild(userID)) {
                        if(add) {
                            completion(true)
                            return
                        }
                            //remove the user from currentAttendees
                        else {
                            // Get things from Firebase
                            let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                            let venueDict = dictionary[venueID] as! [String: AnyObject]
                            var currentAttendees = venueDict["CurrentAttendees"] as! [String : AnyObject]
                            
                            // Remove user from current attendees
                            currentAttendees[userID] = nil
                            
                            // Update dat ish
                            let updates = ["CurrentAttendees": currentAttendees]
                            dataRef.child("Venues").child(venueID).updateChildValues(updates)
                            completion(true)
                            return
                        }
                    }
                    else {
                        let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                        let venueDict = dictionary[venueID] as! [String: AnyObject]
                        
                        var currentAttendees = venueDict["CurrentAttendees"] as! [String : AnyObject]
                        if(add) {
                            if (currentAttendees[userID] == nil) {
                                currentAttendees[userID] = userID as AnyObject?
                                let updates = ["CurrentAttendees": currentAttendees]
                                dataRef.child("Venues").child(venueID).updateChildValues(updates)
                            }
                        }
                        completion(true)
                        return
                    }
                }
                    //Planned attendees dict not present
                else
                {
                    if(add) {
                        let updates = ["CurrentAttendees": [userID : userID]]
                        dataRef.child("Venues").child(venueID).updateChildValues(updates)
                        completion(true)
                        return
                    }
                    else {
                        completion(true)
                        return
                    }
                }
            }
            else {
                completion(false)
            }
        })
        
    }
    
    static func addLiveToUserForDate(date: String, venueID : String, userID : String, add: Bool, completion: @escaping (Bool) -> Void) {
        dataRef.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            //Confirm send friend request conditions
            if (snapshot.hasChild(userID)) {
                
                // Add Live to User
                if(add) {
                    let updates = ["LiveClubID": venueID, "LastLive": date]
                    dataRef.child("Users").child(userID).updateChildValues(updates)
                    
                    // Add execution to users's executions
                    let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
                    let userDict = dictionary[userID] as! [String: AnyObject]
                    
                    if (snapshot.childSnapshot(forPath: userID).hasChild("Executions")) {
                        var executionsDict = userDict["Executions"] as! [String : AnyObject]
                        // Adding execution to user
                        
                        let uniqueVisitID = UUID().uuidString
                        let executionDetails = ["Date" : date, "VenueID" : venueID]
                        if (executionsDict[uniqueVisitID] == nil) {
                            executionsDict[uniqueVisitID] = executionDetails as AnyObject?
                        }
                        else {
                            Utilities.printDebugMessage("Error: unique IDs are not unique")
                        }
                        let updates = ["Executions": executionsDict]
                        dataRef.child("Users").child(userID).updateChildValues(updates)
                    }
                        //Executions dict
                    else
                    {
                        let uniqueVisitID = UUID().uuidString
                        let executionDetails = ["Date" : date, "VenueID" : venueID]
                        let executionsDict = [uniqueVisitID : executionDetails]
                        let updates = ["Executions": executionsDict]
                        dataRef.child("Users").child(userID).updateChildValues(updates)
                    }
                    
                    // See how loyal dis wonderful user is
                    var visitWasPlanned = false
                    if (userDict["Plans"] != nil) {
                        let plansDict = userDict["Plans"] as! [String : AnyObject]
                        
                        for (_, plan) in plansDict {
                            if((plan["Date"] as! String) == date && (plan["VenueID"] as! String) == venueID) {
                                visitWasPlanned = true
                                break
                            }
                        }
                    }
                    
                    if(visitWasPlanned) {
                        if(snapshot.childSnapshot(forPath: userID).hasChild("Loyalties")) {
                            var loyaltiesDict = userDict["Loyalties"] as! [String : Int]
                            if let venueLoyaltiesCount = loyaltiesDict[venueID]  {
                                loyaltiesDict[venueID] = venueLoyaltiesCount + 1
                            } else {
                                loyaltiesDict[venueID] = 1
                            }
                            let updates = ["Loyalties": loyaltiesDict]
                            dataRef.child("Users").child(userID).updateChildValues(updates)
                            
                        } else {
                            var loyaltiesDict : [String : Int] = [:]
                            loyaltiesDict[venueID] = 1
                            let updates = ["Loyalties": loyaltiesDict]
                            dataRef.child("Users").child(userID).updateChildValues(updates)
                            
                        }
                    }
                    
                    
                } else {
                    dataRef.child("Users").child(userID).child("LiveClubID").removeValue()
                }
                completion(true)
            }
            else {
                completion(false)
            }
        })
    }
    //get the text for all the messages
    class func getLastMessagesText(channelIDs : [String], completion: @escaping ([String:String]) -> Void) {
        dataRef.child("channels").observeSingleEvent(of: .value, with: { (snapshot) in
            let dictionary :[String:AnyObject] = snapshot.value as! [String : AnyObject]
            var returnMessages = [String:String]()
            for channelID in channelIDs {
                if(snapshot.hasChild(channelID)) {
                    let channelDict = dictionary[channelID] as! [String: AnyObject]
                    let messages = channelDict["Messages"] as! [String : AnyObject]
                    let messageIDs = Array(messages.keys)
                    let lastMessageID = messageIDs[messageIDs.count - 1]
                    let lastMessageObject = messages[lastMessageID] as! [String : String]
                    let lastMessageText = lastMessageObject["text"]
                    returnMessages[channelID] = lastMessageText
                }
            }
            completion(returnMessages)
        })
    }
    
    //get the user's friends, as an array of FBIDs
    class func getFriends(_ completion: @escaping ([String]) -> Void) {
        if let FBID = FBSDKAccessToken.current().userID {
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            FIRAuth.auth()?.signIn(with: credential) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                    
                else
                {
                    let parameters = ["fields": "uid", "limit": "5000"]
                    
                    // FB get current user
                    let request = FBSDKGraphRequest(graphPath: "/\(FBID)/friends", parameters: parameters, tokenString: FBSDKAccessToken.current().tokenString, version: nil, httpMethod: "GET")
                    
                    
                    // POST current user to Firebase
                    request!.start(completionHandler: { (connection, result, requestError) -> Void in
                        
                        if requestError != nil {
                            print(requestError?.localizedDescription ?? "Error with localized desc")
                            return
                        }
                        
                        let user:[String:AnyObject] = result as! [String : AnyObject]
                        
                        var friendsList : [String] = []
                        
                        if let friends = user["data"] as? NSArray {
                            for friend in friends {
                                if let fr = friend as? NSDictionary {
                                    friendsList.append(fr["id"]! as! String)
                                }
                                else {
                                    Utilities.printDebugMessage("Error parsing friend in FB graph request")
                                }
                            }
                        }
                        completion(friendsList)
                    })
                }
            }
            
        }
        else {
            completion([])
        }
    }
    
    
    
}


















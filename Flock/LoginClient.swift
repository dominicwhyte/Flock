//
//  FlockClient.swift
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

class LoginClient: NSObject
{
    static let dataRef = FIRDatabase.database().reference()
    
    class func login(_ completion: @escaping (_ success: Bool) -> ())
    {
        let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        FIRAuth.auth()?.signIn(with: credential) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(false)
                return
            }
                
            else
            {
                let parameters = ["fields": "name, id, picture.type(large)"]
                
                // FB get current user
                let request = FBSDKGraphRequest(graphPath: "me", parameters: parameters, tokenString: FBSDKAccessToken.current().tokenString, version: nil, httpMethod: "GET")
                
                // POST current user to Firebase
                request!.start(completionHandler: { (connection, result, requestError) -> Void in
                    
                    if requestError != nil {
                        print(requestError?.localizedDescription ?? "Error with localized desc")
                        completion(false)
                        return
                    }
                    
                    let FBID = FBSDKAccessToken.current().userID
                    let user:[String:AnyObject] = result as! [String : AnyObject]
                    var pictureUrl = ""
                    
                    if let picture = user["picture"] as? NSDictionary, let data = picture["data"] as? NSDictionary, let url = data["url"] as? String {
                        pictureUrl = url
                    }
                    
                    let name = user["name"] as! String
                    createUser(name: name, FBID: FBID!, pictureURL: pictureUrl, completion: { (status) in
                        completion(status)
                    })
                })
            }
        }
    }
    
    class func createUser(name : String, FBID : String, pictureURL : String, completion: @escaping (_ success: Bool) -> ()) {
        dataRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(!snapshot.hasChild("Users")) {
                Utilities.printDebugMessage("No Users")
                let updates = ["Users": []] as [String : Any]
                dataRef.updateChildValues(updates as [AnyHashable: Any])
            }
            
            //Create a new user on Firebase
            if !snapshot.childSnapshot(forPath: "Users").hasChild(FBID)
            {
                let updates = ["FBID": FBID, "Name": name, "PictureURL": pictureURL] as [String : Any]
                
                dataRef.child("Users").child(FBID).updateChildValues(updates as [AnyHashable: Any])
            }
            completion(true)
            return
        })
        { (error) in
            completion(false)
            print(error.localizedDescription)
            return
        }
        
    }
    
    class func logout()
    {
        Utilities.printDebugMessage("Logout called")
        FBSDKAccessToken.setCurrent(nil)
        try! FIRAuth.auth()!.signOut()
    }
    
    
    //Gets the logged in User and the Venues
    class func queryData(_ completion: @escaping (NSDictionary, [NSDictionary]) -> Void)
    {
        let FBID : String = FBSDKAccessToken.current().userID!
        var userDict = [:] as NSDictionary
        var venueDicts = [] as [NSDictionary]
        
        //Get the overall snapshot
        dataRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            //USER
            if (snapshot.hasChild("Users") && snapshot.childSnapshot(forPath: "Users").hasChild(FBID)) {
                userDict = snapshot.childSnapshot(forPath: "Users").childSnapshot(forPath: FBID).value as! NSDictionary
            }
            
            //VENUES
            if (snapshot.hasChild("Venues")) {
                let venueDict :[String: NSDictionary] = snapshot.childSnapshot(forPath: "Venues").value as! [String : NSDictionary]
                for venue in venueDict {
                    venueDicts.append(venue.value)
                }
            }
            //Called only when the respective dictionaries have been created
            completion(userDict, venueDicts)
            
        })
    }
    
    
    
    //Load up the user, that is: fetch all projects and all updates.
    class func retrieveData(_ completion: @escaping (User?, [String:Venue]?) -> Void)
    {
        if (FBSDKAccessToken.current().userID != nil) {
            queryData { (userDict, venueDicts) in
                
                let user = User(dict: userDict as! [String : AnyObject])
                var venues : [String:Venue] = [:]
                
                for venueDict in venueDicts
                {
                    let venue = Venue(dict: venueDict as! [String : AnyObject])
                    venues[venue.VenueID] = venue
                }
                
                
                completion(user, venues)
            }
        }
        else {
            Utilities.printDebugMessage("Error retrieving user, userFBID was NIL")
            completion(nil, nil)
        }
    }
    
    
}

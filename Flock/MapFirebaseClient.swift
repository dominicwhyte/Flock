//
//  MapFirebaseClient.swift
//  Flock
//
//  Created by Dominic Whyte on 07.08.17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth


class MapFirebaseClient: NSObject
{
    static let dataRef = FIRDatabase.database().reference()
    
    class func addEvent(_ eventName : String, eventStart : Date, eventEnd : Date, eventLocation : CLLocationCoordinate2D, eventType : EventType, eventImageURL : String?, eventDescription : String?, eventOwner : String?, completion: @escaping (Bool) -> Void)
    {
        let eventID = FirebaseClient.dataRef.child("Active_Events").childByAutoId().key
        let updates = ["EventName": eventName as AnyObject, "EventID" : eventID as AnyObject, "EventStart" : DateUtilities.getStringFromFullDate(date: eventStart) as AnyObject, "EventEnd" : DateUtilities.getStringFromFullDate(date: eventEnd) as AnyObject, "Latitude" : eventLocation.latitude.description as AnyObject, "Longitude" : eventLocation.longitude.description as AnyObject, "EventType" : eventType.rawValue as AnyObject, "EventDescription": eventDescription as AnyObject, "EventOwner": eventOwner as AnyObject] as [String : AnyObject]
        dataRef.child("Active_Events").child(eventID).updateChildValues(updates)
        completion(true)
    }
    
    class func addEventReturnID(_ eventName : String, eventStart : Date, eventEnd : Date, eventLocation : CLLocationCoordinate2D, eventType : EventType, eventImageURL : String?, eventDescription : String?, eventOwner : String?, completion: @escaping (String) -> Void)
    {
        let eventID = FirebaseClient.dataRef.child("Active_Events").childByAutoId().key
        let updates = ["EventName": eventName as AnyObject, "EventID" : eventID as AnyObject, "EventStart" : DateUtilities.getStringFromFullDate(date: eventStart) as AnyObject, "EventEnd" : DateUtilities.getStringFromFullDate(date: eventEnd) as AnyObject, "Latitude" : eventLocation.latitude.description as AnyObject, "Longitude" : eventLocation.longitude.description as AnyObject, "EventType" : eventType.rawValue as AnyObject, "EventDescription": eventDescription as AnyObject, "EventOwner": eventOwner as AnyObject] as [String : AnyObject]
        dataRef.child("Active_Events").child(eventID).updateChildValues(updates)
        completion(eventID)
    }
    
    //Creates a few test pins on the database
    static func createTestPins() {
        
        let terracePosition = CLLocationCoordinate2D(latitude: 40.347195, longitude: -74.653935)
        
        
        let hypePosition = CLLocationCoordinate2D(latitude: 40.344551, longitude: -74.654682)
        
        
        let cloisterPosition = CLLocationCoordinate2D(latitude: 40.348616, longitude: -74.650538)
        
        addEvent("Terrace Rager", eventStart: Date(), eventEnd: Date(), eventLocation: terracePosition, eventType: EventType.party, eventImageURL: nil, eventDescription: "I'm a Terrace event.", eventOwner: "Terrace Club", completion: { (success) in
            addEvent("Body Hype", eventStart: Date(), eventEnd: Date(), eventLocation: hypePosition, eventType: EventType.party, eventImageURL: nil, eventDescription: "I'm a chill Body Hype show.", eventOwner: "Body Hype Dance Co", completion: { (success) in
                addEvent("Cloister Rager", eventStart: Date(), eventEnd: Date(), eventLocation: cloisterPosition, eventType: EventType.party, eventImageURL: nil, eventDescription: "I'm a Cloister event.", eventOwner: "Cloister Club", completion: { (success) in
                    Utilities.printDebugMessage("Test pins added")
                })
            })
        })
    }
    
    class func addAction(actionType : ActionType, userID : String, event : Event) {
        dataRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.hasChild("Active_Events") && snapshot.childSnapshot(forPath: "Active_Events").hasChild(event.EventID)) {
                
            }
        })

    }

}


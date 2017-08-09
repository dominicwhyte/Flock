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
    
    class func addEvent(_ eventName : String, eventStart : Date, eventEnd : Date, eventLocation : CLLocationCoordinate2D, eventType : EventType, eventImageURL : String?, completion: @escaping (Bool) -> Void)
    {
        let eventID = FirebaseClient.dataRef.child("Active_Events").childByAutoId().key
        let updates = ["EventName": eventName, "EventID" : eventID, "EventStart" : DateUtilities.getStringFromFullDate(date: eventStart), "EventEnd" : DateUtilities.getStringFromFullDate(date: eventEnd), "Latitude" : eventLocation.latitude.description, "Longitude" : eventLocation.longitude.description, "EventType" : eventType.rawValue] as [String : AnyObject]
        dataRef.child("Active_Events").child(eventID).updateChildValues(updates)
        completion(true)
        
    }
    
    //Creates a few test pins on the database
    static func createTestPins() {
        
        let terracePosition = CLLocationCoordinate2D(latitude: 40.347195, longitude: -74.653935)
        
        
        let hypePosition = CLLocationCoordinate2D(latitude: 40.344551, longitude: -74.654682)
        
        
        let cloisterPosition = CLLocationCoordinate2D(latitude: 40.348616, longitude: -74.650538)
        
        addEvent("Terrace Rager", eventStart: Date(), eventEnd: Date(), eventLocation: terracePosition, eventType: EventType.party, eventImageURL: nil, completion: { (success) in
            addEvent("Body Hype", eventStart: Date(), eventEnd: Date(), eventLocation: hypePosition, eventType: EventType.party, eventImageURL: nil, completion: { (success) in
                addEvent("Cloister Rager", eventStart: Date(), eventEnd: Date(), eventLocation: cloisterPosition, eventType: EventType.party, eventImageURL: nil, completion: { (success) in
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


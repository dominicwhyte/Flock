
import UIKit
import CoreLocation
class Event: NSObject
{
    
    var EventName : String
    var EventDate : Date
    var EventAttendeeFBIDs : [String:String]
    var SpecialEvent : Bool
    var VenueID : String
    var EventImageURL : String? //if nil, use a random image
    
    init(dict: [String: AnyObject])
    {
        self.EventName = dict[EventFirebaseConstants.eventName] as! String
        self.SpecialEvent = dict[EventFirebaseConstants.specialEvent] as! Bool
        self.VenueID = dict[EventFirebaseConstants.venueID] as! String
        self.EventImageURL = dict[EventFirebaseConstants.eventImageURL] as? String
        
        let dateString = dict[EventFirebaseConstants.eventDate] as! String
        self.EventDate = DateUtilities.getDateFromString(date: dateString)
        
        
        if(dict[EventFirebaseConstants.eventAttendeeFBIDs] != nil) {
            self.EventAttendeeFBIDs = dict[EventFirebaseConstants.eventAttendeeFBIDs] as! [String:String]
        } else {
            self.EventAttendeeFBIDs = [:]
        }

    }
    
}

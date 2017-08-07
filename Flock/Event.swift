
import UIKit
import CoreLocation
class Event: NSObject
{
    var EventID : String
    var EventName : String
    var EventStart : Date
    var EventEnd : Date
    var EventLocation : CLLocation?
    var EventInterestedFBIDs : [String:String]
    var EventThereFBIDs : [String:String]
    var EventType : String
    var EventImageURL : String? //if nil, use a random image
    
    init(dict: [String: AnyObject])
    {
        self.EventID = dict["EventID"] as! String
        self.EventName = dict["EventName"] as! String
        self.EventType = dict["EventType"] as! String
        self.EventImageURL = dict["EventImageURL"] as? String
        
        var dateString = dict["EventStart"] as! String
        self.EventStart = DateUtilities.getDateFromString(date: dateString)
        
        dateString = dict["EventEnd"] as! String
        self.EventEnd = DateUtilities.getDateFromString(date: dateString)
        
        if(dict["EventInterestedFBIDs"] != nil) {
            self.EventInterestedFBIDs = dict["EventInterestedFBIDs"] as! [String:String]
        } else {
            self.EventInterestedFBIDs = [:]
        }
        
        if(dict["EventThereFBIDs"] != nil) {
            self.EventThereFBIDs = dict["EventThereFBIDs"] as! [String:String]
        } else {
            self.EventThereFBIDs = [:]
        }
        
        if let latitude = dict["Latitude"] as? Double, let longitude = dict["Longitude"] as? Double {
            self.EventLocation = CLLocation(latitude: latitude, longitude: longitude)
        }

    }
    
}

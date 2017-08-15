
import UIKit
import CoreLocation
import Mapbox

class Event: NSObject
{
    var EventID : String
    var EventName : String
    var EventStart : Date
    var EventEnd : Date
    var EventInterestedFBIDs : [String:String]
    var EventThereFBIDs : [String:String]
    var EventType : String
    var EventImageURL : String? //if nil, use a random image
    let Pin : MGLPointAnnotation
    
    
    init(dict: [String: AnyObject])
    {
        self.EventID = dict["EventID"] as! String
        self.EventName = dict["EventName"] as! String
        self.EventType = dict["EventType"] as! String
        self.EventImageURL = dict["EventImageURL"] as? String
        
        var dateString = dict["EventStart"] as! String
        self.EventStart = DateUtilities.getFullDateFromString(date: dateString)
        
        dateString = dict["EventEnd"] as! String
        self.EventEnd = DateUtilities.getFullDateFromString(date: dateString)
        
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
        
        
        Pin = MGLPointAnnotation()
        
        if let latitudeString = dict["Latitude"] as? String, let longitudeString = dict["Longitude"] as? String {
            if let latitude = Double(latitudeString), let longitude = Double(longitudeString) {
                Pin.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
            
        }
        Pin.title = EventName
        Pin.subtitle = EventID
    }
}

enum ActionType {
    case interested
    case live
}

enum EventType: String {
    case party
    case show
}

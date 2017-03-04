import UIKit
import CoreLocation
class Venue: NSObject
{
    var VenueID: String
    var ImageURL: String
    var LogoURL: String
    var VenueName: String
    var VenueLocation : CLLocation?
    var PlannedAttendees: [String:String]
    var CurrentAttendees: [String:String]
    var VenueNickName: String
    
    init(dict: [String: AnyObject])
    {
        self.VenueID = dict["VenueID"] as! String
        self.ImageURL = dict["ImageURL"] as! String
        self.LogoURL = dict["LogoURL"] as! String
        self.VenueName = dict["VenueName"] as! String
        
        if let latitude = dict["Latitude"] as? Double, let longitude = dict["Longitude"] as? Double {
            self.VenueLocation = CLLocation(latitude: latitude, longitude: longitude)
        }
        
        
        
        if(dict["PlannedAttendees"] != nil) {
            self.PlannedAttendees = dict["PlannedAttendees"] as! [String:String]
        } else {
            self.PlannedAttendees = [:]
        }
        if(dict["CurrentAttendees"] != nil) {
            self.CurrentAttendees = dict["CurrentAttendees"] as! [String:String]
        } else {
            self.CurrentAttendees = [:]
        }
        if(dict["VenueNickName"] != nil) {
            self.VenueNickName = dict["VenueNickName"] as! String
        } else {
            self.VenueNickName = self.VenueName
        }
    }
    
}

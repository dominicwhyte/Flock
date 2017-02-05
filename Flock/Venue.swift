import UIKit

class Venue: NSObject
{
    var VenueID: String
    var ImageURL: String
    var LogoURL: String
    var VenueName: String
    var PlannedAttendees: [String:String]
    var CurrentAttendees: [String:String]
    
    
    init(dict: [String: AnyObject])
    {
        self.VenueID = dict["VenueID"] as! String
        self.ImageURL = dict["ImageURL"] as! String
        self.LogoURL = dict["LogoURL"] as! String
        self.VenueName = dict["VenueName"] as! String
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
    }
    
}


import UIKit

class User: NSObject
{
    var FBID: String
    var Name: String
    var Friends: [String:String]
    var FriendRequests: [String:String]
    var Plans: [Plan]
    var PictureURL: String
    var LiveClubID: String?
    
    init(dict: [String: AnyObject])
    {
        self.FBID = dict["FBID"] as! String
        self.Name = dict["Name"] as! String
        self.LiveClubID = dict["CurrentClub"] as! String?
        if(dict["FriendRequests"] != nil) {
            self.FriendRequests = dict["FriendRequests"] as! [String:String]
        } else {
            self.FriendRequests = [:]
        }
        
        if(dict["Friends"] != nil) {
            self.Friends = dict["Friends"] as! [String:String]
        } else {
            self.Friends = [:]
        }
        self.PictureURL = dict["PictureURL"] as! String
        
        Plans = []
        if(dict["plannedVenues"] != nil && dict["plannedDates"] != nil)
        {
            let plannedVenues = dict["plannedVenues"] as! [String]
            let plannedDates = dict["plannedDates"] as! [String]
            
            
            for (plannedVenue, plannedDate) in zip(plannedVenues, plannedDates) {
                let plan = Plan(date: plannedDate, venueID: plannedVenue)
                self.Plans.append(plan)
            }
        } 
        
    }

}

class Plan: NSObject
{
    var date: Date
    var venueID: String
    
    init(date : String, venueID : String)
    {
        let dateString = date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let nsDate = dateFormatter.date(from: dateString)
        
        self.date = nsDate!
        self.venueID =  venueID
    }
    
}

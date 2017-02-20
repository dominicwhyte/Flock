
import UIKit

class User: NSObject
{
    var FBID: String
    var Name: String
    var Friends: [String:String]
    var FriendRequests: [String:String]
    var Plans: [String : Plan]
    var Executions: [String : Execution]
    var Loyalties: [String : Int]
    var PictureURL: String
    var LiveClubID: String?
    var LastLive: Date?
    var ChannelIDs: [String:String]
    
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
        
        var plans : [String : Plan] = [:]
        if (dict["Plans"] != nil) {
            let plansDict = dict["Plans"] as! [String: [String:String]]
            for (visitID, planDict) in plansDict {
                let date = planDict["Date"]
                let venueID = planDict["VenueID"]
                plans[visitID] = Plan(date: date!, venueID: venueID!)
            }
        }
        self.Plans = plans
        
        var executions : [String : Execution] = [:]
        if (dict["Executions"] != nil) {
            let executionsDict = dict["Executions"] as! [String: [String:String]]
            for (visitID, executionDict) in executionsDict {
                let date = executionDict["Date"]
                let venueID = executionDict["VenueID"]
                executions[visitID] = Execution(date: date!, venueID: venueID!)
            }
        }
        self.Executions = executions
        
        if(dict["Loyalties"] != nil) {
            self.Loyalties = dict["Loyalties"] as! [String:Int]
        } else {
            self.Loyalties = [:]
        }

        if (dict["LastLive"] != nil) {
            let dateString = dict["LastLive"] as! String
            self.LastLive = DateUtilities.getDateFromString(date: dateString)
        }
        if(dict["ChannelIDs"] != nil) {
            self.ChannelIDs = dict["ChannelIDs"] as! [String:String]
        } else {
            self.ChannelIDs = [:]
        }
    }

}

class Plan: NSObject
{
    var date: Date
    var venueID: String
    
    init(date : String, venueID : String)
    {
        self.date = DateUtilities.getDateFromString(date: date)
        self.venueID =  venueID
    }
}

class Execution: NSObject
{
    var date: Date
    var venueID: String
    
    init(date : String, venueID : String)
    {
        self.date = DateUtilities.getDateFromString(date: date)
        self.venueID =  venueID
    }
}

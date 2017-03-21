
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
    var NotificationInfo : NotificationInfoClass
    
    init(dict: [String: AnyObject])
    {
        self.FBID = dict["FBID"] as! String
        self.Name = dict["Name"] as! String
        self.LiveClubID = dict["LiveClubID"] as! String?
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
                let specialEventID = planDict["SpecialEventID"]
                plans[visitID] = Plan(date: date!, venueID: venueID!, specialEventID: specialEventID)
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
        
        let notificationUserID = dict["NotificationUserID"] as? String
        
        let notificationPushToken = dict["NotificationPushToken"] as? String
        
        self.NotificationInfo = NotificationInfoClass(notificationUserID : notificationUserID, notificationPushToken : notificationPushToken)
    }
    
}

class Plan: NSObject
{
    var date: Date
    var venueID: String
    var specialEventID: String? //if this is a special event
    
    init(date : String, venueID : String, specialEventID: String?)
    {
        self.date = DateUtilities.getDateFromString(date: date)
        self.venueID =  venueID
        self.specialEventID = specialEventID
    }
}

class NotificationInfoClass : NSObject
{
    var notificationUserID: String?
    var notificationPushToken: String?
    
    init(notificationUserID : String?, notificationPushToken : String?)
    {
        self.notificationUserID = notificationUserID
        self.notificationPushToken = notificationPushToken
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

//
//  AppDelegate.swift
//  Flock
//
//  Created by Dominic Whyte on 02/02/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FBSDKCoreKit
import FirebaseAuth
import SimpleTab
import CoreLocation
import UserNotifications
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate, FIRMessagingDelegate {

    struct Constants {
        static let CRITICAL_RADIUS : Double = 60.0 // meters
    }
    
    var window: UIWindow?
    var user: User?
    var users = [String : User]()
    var venues = [String:Venue]()
    var friends = [String : User]()
    var venueImages = [String : UIImage]() // indexed by IMAGEURL not VENUEID!!!!!!!!!!!!!
    var simpleTBC:SimpleTabBarController?
    var locationManager = CLLocationManager()
    var friendRequestUsers = [String : User]()
    var facebookFriendsFBIDs : [String : String] = [:]
    var profileNeedsToUpdate = true
    var isArriving = true
    var venueStatistics : Statistics?
    let gcmMessageIDKey = "gcm.message_id"
    var friendCountPlanningToAttendVenueThisWeek = [String:Int]()
    var unreadMessageCount = [String:Int]() // maps from a ChannelID to unread message count
    
    func masterLogin(completion: @escaping (_ status: Bool) -> ()) {
        updateAllData { (success) in
            // For initial efficiency, get images of all venues (eating clubs) to prevent reloading
            // at each display of the club image. Not scalable, but initially much faster
            if(success) {
                var imageURLArray = [String]()
                for (_, venue) in self.venues {
                    imageURLArray.append(venue.ImageURL)
                    imageURLArray.append(venue.LogoURL)
                }
                Utilities.printDebugMessage("TEST")
                
                //Must connect to
                self.connectToFcm()
                if let refreshedToken = FIRInstanceID.instanceID().token() {
                    Utilities.printDebugMessage("InstanceID token: \(refreshedToken)")
                }
                Utilities.printDebugMessage("TESTEND")
                
                self.setAllVenueImages(venueImageURLs: imageURLArray, completion: { (venueImageSuccess) in
                    if (!venueImageSuccess) {
                        Utilities.printDebugMessage("Failure fetching venue images")
                    }
                    completion(venueImageSuccess)
                    
                })
            }
        }
    }
    
    //Function to update data, use for refreshing
    func updateAllData(completion: @escaping (_ status: Bool) -> ()) {
        self.profileNeedsToUpdate = true
        LoginClient.retrieveData { (data) in
            if let (user, venues, users) = data {
                self.user = user
                self.venues = venues
                self.users = users
                self.getAllFriends()
                //Move to master login if slow
                self.computeAllStats()
                //Update CoreData
                if #available(iOS 10.0, *) {
                    self.updateCoreDataWithVenuesIfNecessary(venues: Array(venues.values))
                } else {
                    // Fallback on earlier versions
                }
                
                //Get unreadMessage count
                self.getUnreadMessageCount(user: self.user!)
                
                completion(true)
            }
            else {
                Utilities.printDebugMessage("Error updating all data")
                completion(false)
            }
        }
    }
    
    @available(iOS 10.0, *)
    func getPartialVenueDataFromStorage() -> [String:CoreDataVenue] {
        let managedContext = self.persistentContainer.viewContext
        var venues = [String:CoreDataVenue]()
        
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entityDescription = NSEntityDescription.entity(forEntityName: "StoredVenue", in: managedContext)
        fetchRequest.entity = entityDescription
        do {
            let storedVenuesArray = try managedContext.fetch(fetchRequest) as! [StoredVenue]
            for storedVenue in storedVenuesArray {
                let newVenue = CoreDataVenue(name: storedVenue.name!, venueID: storedVenue.venueID!, latitude: storedVenue.latitude, longitude: storedVenue.longitude)
                venues[storedVenue.venueID!] = newVenue

            }
            print(storedVenuesArray)
            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return venues
    }
    
    @available(iOS 10.0, *)
    func storePartialVenueDataInStorage(name: String, venueID: String, latitude: Double?, longitude: Double?) {
        let managedContext = self.persistentContainer.viewContext
        let entityDescription = NSEntityDescription.entity(forEntityName: "StoredVenue", in: managedContext)
        let newVenue = NSManagedObject(entity: entityDescription!, insertInto: managedContext)
        newVenue.setValue(name, forKey: "name")
        newVenue.setValue(venueID, forKey: "venueID")
        if(latitude != nil && longitude != nil) {
            newVenue.setValue(latitude, forKey: "latitude")
            newVenue.setValue(longitude, forKey: "longitude")
        }
        
        do {
            try newVenue.managedObjectContext?.save()
        } catch {
            print(error)
        }
    }
    
    @available(iOS 10.0, *)
    func updateCoreDataWithVenuesIfNecessary(venues: [Venue]) {
        let partialListOfVenues = self.getPartialVenueDataFromStorage()
        for venue in venues {
            if(partialListOfVenues[venue.VenueID] == nil) {
                var latitude : Double? = nil
                var longitude : Double? = nil
                if(venue.VenueLocation != nil) {
                    latitude = venue.VenueLocation!.coordinate.latitude
                    longitude = venue.VenueLocation!.coordinate.longitude
                }
                self.storePartialVenueDataInStorage(name: venue.VenueName, venueID: venue.VenueID, latitude: latitude, longitude: longitude)
            }
        }
    }
    
    //Call only upon app launch
    func setAllVenueImages(venueImageURLs : [String], completion: @escaping (_ status: Bool) -> ()) {
        var venueImagesTemp = [String : UIImage]()
        var imagesFetched = 0
        let imagesToFetch = venueImageURLs.count
        for imageURL in venueImageURLs {
            FirebaseClient.getImageFromURL(imageURL, { (image) in
                imagesFetched += 1
                venueImagesTemp[imageURL] = image
                if (imagesFetched >= imagesToFetch) {
                    self.venueImages = venueImagesTemp
                    
                    //Get facebook friends, to populate this. Do in here since only done on app launch
                    FirebaseClient.getFriends { (friends) in
                        for friend in friends {
                            self.facebookFriendsFBIDs[friend] = friend
                        }
                        completion(true)
                    }
                }
            })
        }
    }
    
    //call this function if an imageURL is not in the venueImages cache
    func getMissingImage(imageURL : String, completion: @escaping (_ status: Bool) -> ()) {
        FirebaseClient.getImageFromURL(imageURL) { (image) in
            if let image = image {
                self.venueImages[imageURL] = image
                completion(true)
            }
            else {
                completion(false)
            }
        }
    }
    
    func computeAllStats() {
        self.venueStatistics = self.computeVenueStats()
            //for (venueID, venue) in self.venues {
                //Utilities.printDebugMessage("\(venue.VenueName.uppercased())\nMax Plans: \(maxPlansInOneNight[venueID]), Loyalty: \(loyalty[venueID]), Popularity: \(popularity[venueID]), Lifetime Live: \(lifetimeLive[venueID])\n")
            //}
           
        
//        if let (favoriteClub, totalLiveClubs, loyalty, flockSize) = self.computeUserStats(user: self.user!) {
//            Utilities.printDebugMessage("Favorite Club: \(favoriteClub), Total Live Clubs: \(totalLiveClubs), Loyalty: \(loyalty), Flock Size: \(flockSize)\n")
//        }
        
    }
    
    func computeVenueStats() -> Statistics {
        // Stats to return
        var maxPlansInOneNight = [String:Int]() // Map from venueID to maxPlansInOneNight
        var loyalty = [String:Double]() // Maps from venueID to loyaltyFraction
        var popularity = [String:Int]() // Maps from venueID to popularityRanking
        var lifetimeLive = [String:Int]() // Maps from venueID to lifetimeLiveCount
        
        // COMPUTE ALL HERE
        var popularityTracker = [String:Int]()
        var totalPlansForVenue = [String : Int]()
        var venueLoyaltyCounts = [String:Int]()
        var venuePlanCountsForDatesForVenues = [String: [Date:Int]]()
        
        //For use in venues page
        var friendCountPlanningToAttendVenueThisWeek = [String:Int]()
        
        for (_, user) in self.users {
            // LOYALTY
            // 1: Determine the loyalty counts for each club
            for (venueID, loyalty) in user.Loyalties {
                venueLoyaltyCounts[venueID] = loyalty
            }
            // 2: Determine the total plans for each club

            for (_,plan) in user.Plans {
                if let planCountForDatesForVenue = venuePlanCountsForDatesForVenues[plan.venueID] {
                    if let count = planCountForDatesForVenue[plan.date] {
                        var newPlanCounts = planCountForDatesForVenue
                        newPlanCounts[plan.date] = count + 1
                        venuePlanCountsForDatesForVenues[plan.venueID] = newPlanCounts
                    } else {
                        var newPlanCounts = planCountForDatesForVenue
                        newPlanCounts[plan.date] = 1
                        venuePlanCountsForDatesForVenues[plan.venueID] = newPlanCounts
                    }
                } else {
                    venuePlanCountsForDatesForVenues[plan.venueID] = [plan.date : 1]
                }
                //is a friend
                if (self.user!.Friends[user.FBID] != nil || self.user!.FBID == user.FBID) {
                    if (DateUtilities.isValidTimeFrame(dayDiff: DateUtilities.daysUntilPlan(planDate: plan.date))) {
                        if (friendCountPlanningToAttendVenueThisWeek[plan.venueID] != nil) {
                            friendCountPlanningToAttendVenueThisWeek[plan.venueID] = friendCountPlanningToAttendVenueThisWeek[plan.venueID]! + 1
                        }
                        else {
                            friendCountPlanningToAttendVenueThisWeek[plan.venueID] = 1
                        }
                    }
                }
            }
            
            // 2.5: Lifetime Live
            for (_,execution) in user.Executions {
                if let _ = lifetimeLive[execution.venueID] {
                    lifetimeLive[execution.venueID]! += 1
                } else {
                    lifetimeLive[execution.venueID] = 1
                }
            }
            
            // 3: Compute (max) plans in a night for each club
            for(venueID, dateCountDictionary) in venuePlanCountsForDatesForVenues {
                var maxPlans = 0
                for (date, count) in dateCountDictionary {
                    if(count > maxPlans) {
                        maxPlans = count
                    }
                    // This is for loyalty, not maxPlans
                    if(DateUtilities.isDateBeforeToday(date: date)) {
                        if let _ = totalPlansForVenue[venueID] {
                            totalPlansForVenue[venueID]! += count
                        } else {
                            totalPlansForVenue[venueID] = count
                        }
                    }
                }
                maxPlansInOneNight[venueID] = maxPlans
            }

            
            // Compute loyalty ratio
            for (venueID, totalPlans) in totalPlansForVenue {
                if let loyaltyCount = venueLoyaltyCounts[venueID] {
                    loyalty[venueID] = Double(loyaltyCount)/Double(totalPlans)
                } else {
                    loyalty[venueID] = 0
                }
            }
            
            if let favoriteClub = self.computeFavoriteClubForUser(user: user) {
                if let _ = popularityTracker[favoriteClub] {
                    popularityTracker[favoriteClub]! += 1
                } else {
                    popularityTracker[favoriteClub] = 1
                }
            }
        }
        
        // Determine favorite club rankings
        var venueIDs = Array(popularityTracker.keys)
        venueIDs.sort { (ID1, ID2) -> Bool in
            let popularity1 = popularityTracker[ID1]
            let popularity2 = popularityTracker[ID2]
            return popularity1! > popularity2!
        }
        var rank = 1
        for venueID in venueIDs {
            popularity[venueID] = rank
            rank += 1
        }
        self.friendCountPlanningToAttendVenueThisWeek = friendCountPlanningToAttendVenueThisWeek

        return Statistics(maxPlansInOneNight: maxPlansInOneNight, loyalty: loyalty, popularity: popularity, lifetimeLive: lifetimeLive)
    }
    
    func computeUserStats(user : User) -> (String?, Int, Double?, Int)? {
        // Stats to return
        var favoriteClub : String?
        var totalLiveClubs : Int = 0
        var loyalty : Double?
        var flockSize : Int = 0
        // TOTAL LIVE CLUBS
        totalLiveClubs = user.Executions.count
        
        // FAVORITE CLUB
        favoriteClub = self.computeFavoriteClubForUser(user: user)
        
        // FLOCK SIZE
        flockSize = user.Friends.count
        
        // LOYALTY
        var totalLoyalty = 0
        for(_, loyalty) in user.Loyalties {
            totalLoyalty += loyalty
        }
        var totalPreviousPlans = 0
        for (_, plan) in user.Plans {
            if(DateUtilities.isDateBeforeToday(date: plan.date)) {
                totalPreviousPlans += 1
            }
        }
        
        if(totalPreviousPlans == 0) {
            loyalty = 1.0
        } else {
            loyalty = Double(totalLoyalty)/Double(totalPreviousPlans)
        }
        return (favoriteClub, totalLiveClubs, loyalty, flockSize)
    }
    
    func computeFavoriteClubForUser(user : User) -> String? {
        var venueAttendance = [String : Int]() // Maps from venueID to attendanceCount
        for (_, execution) in user.Executions {
            if let attendance = venueAttendance[execution.venueID] {
                venueAttendance[execution.venueID] = attendance + 1
            } else {
                venueAttendance[execution.venueID] = 1
            }
        }
        var favoriteVenue : String?
        var favoriteVenueAttendance = 0
        for (venue, attendance) in venueAttendance {
            if(attendance > favoriteVenueAttendance) {
                favoriteVenue = venue
                favoriteVenueAttendance = attendance
            }
        }
        return favoriteVenue
    }
    
    func getAllFriends() {
        if(user == nil) {
            return
        }
        
        var friendDict : [String:User] = [:]
        for (_, friendFBID) in user!.Friends{
            friendDict[friendFBID] = users[friendFBID]
        }
        var friendRequestUsersDict : [String : User] = [:]
        for (_,friendRequestFBID) in user!.FriendRequests {
            friendRequestUsersDict[friendRequestFBID] = users[friendRequestFBID]
        }
        friendDict[user!.FBID] = user!
        self.friendRequestUsers = friendRequestUsersDict
        self.friends = friendDict
    }
    
    func getUnreadMessageCount(user: User) {
        for channelID in Array(user.ChannelIDs.values) {
            let channelRef = FIRDatabase.database().reference().child("channels").child(channelID)
            
            let messageRef = channelRef.child("messages")
            // 1.
            let messageQuery = messageRef.queryLimited(toLast:5)
            let _ = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
                // 3
                let messageData = snapshot.value as! Dictionary<String, String>
                if let id = messageData["senderId"] as String!, let _ = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                    // 4
                    //self.addMessage(withId: id, name: name, text: text)
                    if (messageData["hasBeenRead"] != nil){
                        Utilities.printDebugMessage("Inside First Loops")
                        let hasBeenRead = messageData["hasBeenRead"]!
                        Utilities.printDebugMessage("HBR: \(hasBeenRead == "false"), and \(id != self.user!.FBID)")
                        if((hasBeenRead == "false") && (id != self.user!.FBID)) {
                            if let _ = self.unreadMessageCount[channelID] {
                                self.unreadMessageCount[channelID]! += 1
                            } else {
                                self.unreadMessageCount[channelID] = 1
                            }
                        }
                    }
                    Utilities.printDebugMessage("UMC: \(self.unreadMessageCount[channelID])")
                    
                } else {
                    print("Error! Could not decode message data")
                }
                
                var totalUnread = 0
                for (_, count) in self.unreadMessageCount {
                    totalUnread += count
                }
                if let stb = self.simpleTBC {
                    if totalUnread > 0 {
                        stb.addBadge(index: 3, value: totalUnread, color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
                    } else {
                        stb.removeAllBadges()
                    }
                }
                
            })
        }
    }
    
    
    
    
    
    
    
    
    
    //=================================================================================================================//
    //Start Live
    
    // CoreLocation CLVisit Code
    func startMonitoringVisits() { self.locationManager.startMonitoringVisits() }
    func stopMonitoringVisits() { self.locationManager.stopMonitoringVisits() }
    
    func setupLocationServices() {
        locationManager.delegate = self
        if (CLLocationManager.authorizationStatus() == .notDetermined) {
            locationManager.requestAlwaysAuthorization()
        }
        
        if (CLLocationManager.authorizationStatus() == .authorizedAlways){
            self.startMonitoringVisits()
        }
        
    }
    
    
    //Didvisit fired
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        
        // Determine visit location and properties
        let visitLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        let isArriving = (visit.departureDate.compare(NSDate.distantFuture).rawValue == 0)
        self.isArriving = isArriving
        
        // Get state of the application: Active, Background, or Inactive
        let state: UIApplicationState = UIApplication.shared.applicationState
        
        switch state {
            
        // Present local "pretty" popup for user
        case .active:
            if(self.user != nil) {
                manager.desiredAccuracy = kCLLocationAccuracyBest
                manager.requestLocation()
            }
        // Present local notification with GPS accuracy
        case .background:
            if(self.user != nil) {
                manager.desiredAccuracy = kCLLocationAccuracyBest
                manager.requestLocation()
            }
            
        // Present local notification without GPS accuracy
        case .inactive:
            //KEY: remove people from Live if they left
            
            showNotification(body: "IT WORKS OFFLINE")
//            var body = ""
//            let ascendingVenues = distanceToClubsAscendingWhileInactive(visitLocation: visitLocation)
//            for venue in ascendingVenues {
//                body += "\(venue.venueName) is \(venue.distAway) m away.\n"
//            }
//            showNotification(body: body)
//            
//            
//            if let (venueID,dist) = self.distanceToNearestClub(visitLocation: visitLocation) {
//                // Check if user was previously live somewhere else
//                var previousLiveID : String?
//                if(self.user!.LiveClubID != nil) {
//                    previousLiveID  = self.user!.LiveClubID
//                } else {
//                    previousLiveID = nil
//                }
//                
//                FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: venueID, previousLiveID: previousLiveID, userID: self.user!.FBID, add: isArriving, completion: { (success) in
//                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
//                    if (isArriving) {
//                        self.showNotification(body: "VENUE CHOSEN Arriving at \(appDelegate.venues[venueID]!.VenueName)")
//                    }
//                    else {
//                        self.showNotification(body: "VENUE CHOSEN Departing \(appDelegate.venues[venueID]!.VenueName)")
//                    }
//                    if(success) {
//                        Utilities.printDebugMessage("Successfully uploaded visit to database")
//                    }
//                })
//            } else {
//                if let venueID = self.user!.LiveClubID {
//                    FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: venueID, previousLiveID: nil, userID: self.user!.FBID, add: false, completion: { (success) in
//                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//                        self.showNotification(body: "DEPARTING VENUE: \(appDelegate.venues[venueID]!.VenueName)")
//                        
//                        if(success) {
//                            Utilities.printDebugMessage("Successfully uploaded visit to database")
//                        }
//                    })
//                }
//            }
        }
        
    }
    
    //Received new location from GPS
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // For testing purposes print out all locations in ascending order of distance
        let visitLocation = locations[0]
        let ascendingVenues = distanceToClubsAscending(visitLocation: visitLocation)
        var body : String = "GPS ACCURACY:\n"
        for venue in ascendingVenues {
            body += "\(venue.venueName) is \(venue.distAway) m away.\n"
        }
        showNotification(body: body) //shows notification with list of clubs that are closest
        
        //KEY: remove people from Live if they left
        
        
        //Send notification if within critical radius
        if let (venueID,dist) = self.distanceToNearestClub(visitLocation: visitLocation) {
//            var previousLiveID : String?
//            if(self.user!.LiveClubID != nil) {
//                previousLiveID = self.user!.LiveClubID
//            } else {
//                previousLiveID = nil
//            }
            if (dist < Constants.CRITICAL_RADIUS) {
                if (self.isArriving) {
                    self.showNotification(body: "Having fun at \(self.venues[venueID]!.VenueName)? Swipe left to view and check in!")
                }
                else {
                    self.showNotification(body: "VENUE CHOSEN Departing \(self.venues[venueID]!.VenueName)")
                }

            }
//            FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: venueID, previousLiveID : previousLiveID, userID: self.user!.FBID, add: self.isArriving, completion: { (success) in
//                let appDelegate = UIApplication.shared.delegate as! AppDelegate
//                if (self.isArriving) {
//                    self.showNotification(body: "VENUE CHOSEN Arriving at \(appDelegate.venues[venueID]!.VenueName)")
//                }
//                else {
//                    self.showNotification(body: "VENUE CHOSEN Departing \(appDelegate.venues[venueID]!.VenueName)")
//                }
//                if(success) {
//                    Utilities.printDebugMessage("Successfully uploaded visit to database")
//                }
//            })
        }
        
    }
    
    //Did fail
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    // Send a local notification to the user
    func showNotification(body: String) {
        let notification = UILocalNotification()
        notification.alertAction = nil
        notification.alertBody = body
        
        let category = UIMutableUserNotificationCategory()
        let acceptClub = UIMutableUserNotificationAction()
        acceptClub.identifier = "accept"
        acceptClub.isDestructive = false
        acceptClub.title = "Accept"
        acceptClub.activationMode = .background
        acceptClub.isAuthenticationRequired = false
        
        let switchClub = UIMutableUserNotificationAction()
        switchClub.identifier = "switch"
        switchClub.isDestructive = false
        switchClub.title = "Switch"
        switchClub.activationMode = .foreground
        switchClub.isAuthenticationRequired = false
        
        let cancelClub = UIMutableUserNotificationAction()
        cancelClub.identifier = "cancel"
        cancelClub.isDestructive = true
        cancelClub.title = "Cancel"
        cancelClub.activationMode = .background
        cancelClub.isAuthenticationRequired = false
        
        let categoryIdentifier = "category.identifier"
        category.identifier = categoryIdentifier
        category.setActions([acceptClub, switchClub, cancelClub], for: .default)
        
        let categories = Set(arrayLiteral: category)
        let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: categories)
        UIApplication.shared.registerUserNotificationSettings(settings)
        notification.category = categoryIdentifier
        
        UIApplication.shared.presentLocalNotificationNow(notification)
    }
    
    //When permissions changed
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (CLLocationManager.authorizationStatus() == .authorizedAlways){
            self.startMonitoringVisits()
        }
    }
    
    
    func distanceToNearestClub(visitLocation : CLLocation) -> (String, Double)? {
        var minDistance = Double.infinity
        var closestVenueID : String?
        
        for venue in Array(self.venues.values) {
            if let venueLocation = venue.VenueLocation {
                let distanceInMeters = visitLocation.distance(from: venueLocation)
                if distanceInMeters < minDistance {
                    minDistance = distanceInMeters
                    closestVenueID = venue.VenueID
                }
            }
        }
        if(closestVenueID != nil) {
            return (closestVenueID!, minDistance)
        } else {
            return nil
        }
    }
    
    //testing function
    func distanceToClubsAscending(visitLocation : CLLocation) -> [VisitLocation] {
        
        var visitLocations = [VisitLocation]()
        
        for venue in Array(self.venues.values) {
            if let venueLocation = venue.VenueLocation {
                let distanceInMeters = visitLocation.distance(from: venueLocation)
                visitLocations.append(VisitLocation(distAway: distanceInMeters, venueName: venue.VenueName))
            }
        }
        visitLocations.sort { (vl1, vl2) -> Bool in
            vl1.distAway < vl2.distAway
        }
        return visitLocations
    }
    
    //Uses core data
    func distanceToClubsAscendingWhileInactive(visitLocation: CLLocation) -> [VisitLocation] {
        var visitLocations = [VisitLocation]()
        if #available(iOS 10.0, *) {
            let storedVenues = self.getPartialVenueDataFromStorage()
            
            
            for venue in Array(storedVenues.values) {
                let venueLocation = CLLocation(latitude: Double(venue.latitude), longitude: Double(venue.longitude))
                let distanceInMeters = visitLocation.distance(from: venueLocation)
                visitLocations.append(VisitLocation(distAway: distanceInMeters, venueName: venue.name))
            }
            visitLocations.sort { (vl1, vl2) -> Bool in
                vl1.distAway < vl2.distAway
            }
        } else {
            // Fallback on earlier versions
        }
        return visitLocations
        
    }
    
//=================================================================================================================//
    

    
    
    
    
    
    
    
    
    
    
    
    
    //=================================================================================================================//
    //Start Notifications
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken as Data, type:  FIRInstanceIDAPNSTokenType.sandbox)
    }
    
    /// The callback to handle data message received via FCM for devices running iOS 10 or above.
    public func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {

    }

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        FIRApp.configure()
        self.setupLocationServices()
        self.registerForPushNotifications(application: application)
        //remove notification tags
        UIApplication.shared.applicationIconBadgeNumber = 0
        return true
    }
    
    func registerForPushNotifications(application: UIApplication) {
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }
    
    func connectToFcm() {
        // Won't connect since there is no token
        guard FIRInstanceID.instanceID().token() != nil else {
            return;
        }
        
        // Disconnect previous FCM connection if it exists.
        FIRMessaging.messaging().disconnect()
        
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
  
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        self.showNotification(body: "test")
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        self.showNotification(body: "test")
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    
    
    
    //End Notifications
    //=================================================================================================================//
    
    
    
    
    
    
    
    
    
    
    
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Flock")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if #available(iOS 10.0, *) {
            let context = persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }

    


}

class VisitLocation: NSObject
{
    var distAway: Double
    var venueName: String
    
    init(distAway : Double, venueName : String)
    {
        self.distAway = distAway
        self.venueName = venueName
    }
    
}

class Statistics: NSObject
{
    var maxPlansInOneNight = [String:Int]() // Map from venueID to maxPlansInOneNight
    var loyalty = [String:Double]() // Maps from venueID to loyaltyFraction
    var popularity = [String:Int]() // Maps from venueID to popularityRanking
    var lifetimeLive = [String:Int]() // Maps from venueID to lifetimeLiveCount
    
    
    init(maxPlansInOneNight: [String:Int], loyalty : [String:Double], popularity : [String:Int], lifetimeLive : [String:Int])
    {
        self.maxPlansInOneNight = maxPlansInOneNight
        self.loyalty = loyalty
        self.popularity = popularity
        self.lifetimeLive = lifetimeLive
    }
    
}

class CoreDataVenue: NSObject
{
    var name: String
    var venueID: String
    var latitude: Double
    var longitude: Double
    
    init(name: String, venueID: String, latitude: Double, longitude: Double) {
        self.name = name
        self.venueID = venueID
        self.latitude = latitude
        self.longitude = longitude
    }
}


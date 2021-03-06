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
    import FirebaseDatabase
    import FirebaseAuth
    import SimpleTab
    import CoreLocation
    import UserNotifications
    import SCLAlertView
    import FirebaseMessaging
    import OneSignal
    import Instabug
    import GoogleMaps
    
    @UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate, FIRMessagingDelegate {
        
        struct Constants {
            static let CRITICAL_RADIUS : Double = 50.0 // meters
        }
        
        var window: UIWindow?
        var user: User?
        var users = [String : User]()
        var activeEvents = [String:Event]()
        var venues = [String:Venue]()
        var friends = [String : User]()
        var venueImages = [String : UIImage]() // indexed by IMAGEURL not VENUEID!!!!!!!!!!!!!
        var simpleTBC:SimpleTabBarController?
        var locationManager = CLLocationManager()
        var friendRequestUsers = [String : User]()
        var facebookFriendsFBIDs : [String : String] = [:]
        var profileNeedsToUpdate = true
        var eventsNeedsToUpdate = true
        var chatNeedsToUpdate = true
        var venueStatistics : Statistics?
        let gcmMessageIDKey = "gcm.message_id"
        var friendCountPlanningToAttendVenueThisWeek = [String:Int]()
        var friendCountPlanningToAttendVenueForDates = [String:[String:Int]]()
        var unreadMessageCount = [String:Int]() // maps from a ChannelID to unread message count
        var messagesForChatsTableViewController = [String:[Conversation]]()
        var appIsWakingUpFromVisit : Bool = false
        var startGoingOutTime : Double = DateUtilities.Constants.START_NIGHT_OUT_TIME
        var endGoingOutTime : Double = DateUtilities.Constants.END_NIGHT_OUT_TIME
        var goLiveButtonPressed : Bool = false
        var alreadySentFriendRequests = [String:String]()
        var friendPlanCountDict = [String:Int]()
        
        
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
                    
                    //Get unreadMessage count
                    self.getUnreadMessageCount(user: self.user!)
                    self.getUnseenFriendRequests(user: self.user!)
                    
                    Utilities.printDebugMessage("TEST")
                    
                    
                    //Must connect to
                    self.connectToFcm()
                    if let refreshedToken = FIRInstanceID.instanceID().token() {
                        Utilities.printDebugMessage("InstanceID token: \(refreshedToken)")
                    }
                    Utilities.printDebugMessage("TESTEND")
                    
//                    self.setAllVenueImages(venueImageURLs: imageURLArray, completion: { (venueImageSuccess) in
//                        self.handlePushNotificationSetup()
//                        if (!venueImageSuccess) {
//                            Utilities.printDebugMessage("Failure fetching venue images")
//                        }
//                        completion(venueImageSuccess)
//                        
//                    })
                    self.handlePushNotificationSetup()
                    FirebaseClient.getFriends { (friends) in
                        for friend in friends {
                            self.facebookFriendsFBIDs[friend] = friend
                        }
                        completion(true)
                    }
                }
                else {
                    completion(false)
                }
            }
        }
        
        func handlePushNotificationSetup() {
            OneSignal.idsAvailable({(_ userId, _ pushToken) in
                FirebaseClient.updateUserNotificationInfo(notificationUserId: userId, notificationPushToken: pushToken, completion: { (success) in
                    if (!success) {
                        Utilities.printDebugMessage("Error uploading notifications IDs")
                    }
                })
            })
        }
        
        func openChatController(FBID : String) {
            Utilities.printDebugMessage("Attempting to open Chat Controller")
            if let user = self.user, let friendUser = self.users[FBID] {
                if let channelID = user.ChannelIDs[FBID] {
                    if let vc = self.getCurrentViewController() {
                        vc.performSegue(withIdentifier: "CHAT_IDENTIFIER", sender: (channelID, friendUser))
                    }
                }
            }
        }
        
        
        
        //Function to update data, use for refreshing
        func updateAllData(completion: @escaping (_ status: Bool) -> ()) {
            self.profileNeedsToUpdate = true
            self.eventsNeedsToUpdate = true
            LoginClient.retrieveData { (data, startTime, endTime) in
                self.startGoingOutTime = startTime
                self.endGoingOutTime = endTime
                if let (user, venues, users, activeEvents) = data {
                    //Check user location
                    self.user = user
                    self.venues = venues
                    self.users = users
                    self.activeEvents = activeEvents
                    self.getAllFriends()
                    //Move to master login if slow
                    self.computeAllStats()
                    //Update CoreData
                    //                if #available(iOS 10.0, *) {
                    //                    self.updateCoreDataWithVenuesIfNecessary(venues: Array(venues.values))
                    //                } else {
                    //                    // Fallback on earlier versions
                    //                }
                    
                    self.locationManager.requestLocation()
                    completion(true)
                }
                else {
                    Utilities.printDebugMessage("Error updating all data")
                    completion(false)
                }
            }
        }
        
        //Function to update data, use for refreshing
        func updateAllDataWithoutUpdatingLocation(completion: @escaping (_ status: Bool) -> ()) {
            self.profileNeedsToUpdate = true
            self.eventsNeedsToUpdate = true
            LoginClient.retrieveData { (data, startTime, endTime) in
                self.startGoingOutTime = startTime
                self.endGoingOutTime = endTime
                if let (user, venues, users, activeEvents) = data {
                    //Check user location
                    self.user = user
                    self.venues = venues
                    self.users = users
                    self.activeEvents = activeEvents
                    self.getAllFriends()
                    //Move to master login if slow
                    self.computeAllStats()
                    //Update CoreData
                    //                if #available(iOS 10.0, *) {
                    //                    self.updateCoreDataWithVenuesIfNecessary(venues: Array(venues.values))
                    //                } else {
                    //                    // Fallback on earlier versions
                    //                }
                    
                    //Get unreadMessage count
                    //self.getUnreadMessageCount(user: self.user!)
                    //self.getUnseenFriendRequests(user: self.user!)
                    completion(true)
                }
                else {
                    Utilities.printDebugMessage("Error updating all data")
                    completion(false)
                }
            }
        }
        
        
        
        
        //    @available(iOS 10.0, *)
        //    func getPartialVenueDataFromStorage() -> [String:CoreDataVenue] {
        //        let managedContext = self.persistentContainer.viewContext
        //        var venues = [String:CoreDataVenue]()
        //
        //
        //        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        //        let entityDescription = NSEntityDescription.entity(forEntityName: "StoredVenue", in: managedContext)
        //        fetchRequest.entity = entityDescription
        //        do {
        //            let storedVenuesArray = try managedContext.fetch(fetchRequest) as! [StoredVenue]
        //            for storedVenue in storedVenuesArray {
        //                let newVenue = CoreDataVenue(name: storedVenue.name!, venueID: storedVenue.venueID!, latitude: storedVenue.latitude, longitude: storedVenue.longitude)
        //                venues[storedVenue.venueID!] = newVenue
        //
        //            }
        //            print(storedVenuesArray)
        //
        //        } catch {
        //            let fetchError = error as NSError
        //            print(fetchError)
        //        }
        //        return venues
        //    }
        
        //    @available(iOS 10.0, *)
        //    func storePartialVenueDataInStorage(name: String, venueID: String, latitude: Double?, longitude: Double?) {
        //        let managedContext = self.persistentContainer.viewContext
        //        let entityDescription = NSEntityDescription.entity(forEntityName: "StoredVenue", in: managedContext)
        //        let newVenue = NSManagedObject(entity: entityDescription!, insertInto: managedContext)
        //        newVenue.setValue(name, forKey: "name")
        //        newVenue.setValue(venueID, forKey: "venueID")
        //        if(latitude != nil && longitude != nil) {
        //            newVenue.setValue(latitude, forKey: "latitude")
        //            newVenue.setValue(longitude, forKey: "longitude")
        //        }
        //
        //        do {
        //            try newVenue.managedObjectContext?.save()
        //        } catch {
        //            print(error)
        //        }
        //    }
        
        //    @available(iOS 10.0, *)
        //    func updateCoreDataWithVenuesIfNecessary(venues: [Venue]) {
        //        let partialListOfVenues = self.getPartialVenueDataFromStorage()
        //        for venue in venues {
        //            if(partialListOfVenues[venue.VenueID] == nil) {
        //                var latitude : Double? = nil
        //                var longitude : Double? = nil
        //                if(venue.VenueLocation != nil) {
        //                    latitude = venue.VenueLocation!.coordinate.latitude
        //                    longitude = venue.VenueLocation!.coordinate.longitude
        //                }
        //                self.storePartialVenueDataInStorage(name: venue.VenueName, venueID: venue.VenueID, latitude: latitude, longitude: longitude)
        //            }
        //        }
        //    }
        
        //Call only upon app launch
//        func setAllVenueImages(venueImageURLs : [String], completion: @escaping (_ status: Bool) -> ()) {
//            var venueImagesTemp = [String : UIImage]()
//            var imagesFetched = 0
//            let imagesToFetch = venueImageURLs.count
//            for imageURL in venueImageURLs {
//                FirebaseClient.getImageFromURL(imageURL, { (image) in
//                    imagesFetched += 1
//                    venueImagesTemp[imageURL] = image
//                    if (imagesFetched >= imagesToFetch) {
//                        self.venueImages = venueImagesTemp
//                        
//                        //Get facebook friends, to populate this. Do in here since only done on app launch
//                        FirebaseClient.getFriends { (friends) in
//                            for friend in friends {
//                                self.facebookFriendsFBIDs[friend] = friend
//                            }
//                            completion(true)
//                        }
//                    }
//                })
//            }
//            if (venueImageURLs.count == 0) {
//                //Get facebook friends, to populate this. Do in here since only done on app launch
//                FirebaseClient.getFriends { (friends) in
//                    for friend in friends {
//                        self.facebookFriendsFBIDs[friend] = friend
//                    }
//                    completion(true)
//                }
//                
//            }
//        }
        
        
        //call this function if an imageURL is not in the venueImages cache
        func getMissingImage(imageURL : String?, venueID : String?, completion: @escaping (_ status: Bool) -> ()) {
            if let imageURL = imageURL {
                FirebaseClient.getImageFromURL(imageURL, venueID: venueID) { (image) in
                    if let image = image {
                        self.venueImages[imageURL] = image
                        completion(true)
                    }
                    else {
                        completion(false)
                    }
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
            var friendCountPlanningToAttendVenueForDates = [String:[String:Int]]()
            
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
                            
                            if (friendCountPlanningToAttendVenueForDates[plan.venueID] != nil) {
                                var planDictForVenueForDates = friendCountPlanningToAttendVenueForDates[plan.venueID]!
                                
                                if(planDictForVenueForDates[DateUtilities.getStringFromDate(date: plan.date)] != nil) {
                                    planDictForVenueForDates[DateUtilities.getStringFromDate(date: plan.date)]! += 1
                                } else {
                                    planDictForVenueForDates[DateUtilities.getStringFromDate(date: plan.date)] = 1
                                }
                                friendCountPlanningToAttendVenueForDates[plan.venueID] = planDictForVenueForDates
                                
                            } else {
                                var planDictForVenueForDates = [String : Int]()
                                planDictForVenueForDates[DateUtilities.getStringFromDate(date: plan.date)] = 1
                                friendCountPlanningToAttendVenueForDates[plan.venueID] = planDictForVenueForDates
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
            self.friendCountPlanningToAttendVenueForDates = friendCountPlanningToAttendVenueForDates
            
            return Statistics(maxPlansInOneNight: maxPlansInOneNight, loyalty: loyalty, popularity: popularity, lifetimeLive: lifetimeLive, venuePlanCountsForDatesForVenues: venuePlanCountsForDatesForVenues)
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
            let dataRef = FIRDatabase.database().reference().child("channels")
            for channelID in Array(user.ChannelIDs.values) {
                let channelRef = dataRef.child(channelID)
                
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
                            let hasBeenRead = messageData["hasBeenRead"]!
                            if((hasBeenRead == "false") && (id != self.user!.FBID)) {
                                if let _ = self.unreadMessageCount[channelID] {
                                    self.unreadMessageCount[channelID]! += 1
                                } else {
                                    self.unreadMessageCount[channelID] = 1
                                }
                            }
                            
                            
                            if(self.unreadMessageCount[channelID] != nil) {
                                Utilities.printDebugMessage("Channel: \(channelID), unread: \(self.unreadMessageCount[channelID])")
                            } else {
                                Utilities.printDebugMessage("Channel: \(channelID), unread: 0")
                            }
                        }
                        
                    } else {
                        print("Error! Could not decode message data")
                    }
                    
                    var totalUnread = 0
                    for (_, count) in self.unreadMessageCount {
                        totalUnread += count
                    }
                    if let stb = self.simpleTBC {
                        if (totalUnread > 0 && totalUnread < 6) {
                            if(stb.selectedIndex == 5) {
                                //stb.addBadge(index: 3, value: totalUnread, color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
                            } else {
                                //stb.addBadge(index: 4, value: totalUnread, color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
                            }
                        } else if (totalUnread >= 6) {
                            if(stb.selectedIndex == 5) {
                                //stb.addBadge(index: 3, value: -1, color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
                            } else {
                                //stb.addBadge(index: 4, value: -1, color: FlockColors.FLOCK_BLUE, font: UIFont(name: "Helvetica", size: 11)!)
                            }
                        }
                            
                        else {
                            stb.removeAllBadges()
                        }
                    }
                    
                })
            }
        }
        
        
        func getUnseenFriendRequests(user: User) {
            let dataRef = FIRDatabase.database().reference().child("Users").child(user.FBID).child("FriendRequests")
            
            let friendQuery = dataRef.queryLimited(toLast:5)
            Utilities.printDebugMessage("Prefatal")
            
            let _ = friendQuery.observe(.childAdded, with: { (snapshot) -> Void in
                // 3
                if(snapshot.value != nil) {
                    let friendData = snapshot.value as! String
                    
                    // Define identifier
                    
                    Utilities.printDebugMessage("FATAL")
                    // Register to receive notification
                    
                    // Post notification
                    NotificationCenter.default.post(name: Utilities.Constants.notificationName, object: nil)
                }
            })
            
        }

        
        
        
        
        
        
        //=================================================================================================================//
        //Start Live
        
        
        /*
         An explanation of how this all works:
         
         When a visit is registered fired (in app or off app), we call the location manager which evenutally calls the manager didUpdateLocations
         When you update the app, we call the location manager which evenutally calls the manager didUpdateLocations
         
         That is, didUpdateLocations should be ready for anything.
         
         
         In didUpdateLocations:
         If your location is NOT registered to be within any critical radius, we remove you from your live club (if you had one)
         
         If your location is registered to be within any critical radius, we call showPopupIfActiveOrNotificationIfNot:
         1. If the app is open
         a) If we just registered you to be within the critical radius of the venue you are already live at, we do nothing
         b) If you were either not live anywhere before or you are within the critical radius of a new club, displayPrompt() is called.
         You will be prompted to go live at a club, or go live at different clubs. Going live at any club will result in goLive()
         getting called.
         2. If the app is not open
         a) showPopupIfActiveOrNotificationIfNot() will also have been called, and now shownotification() will be called. The user will be given the option to go live or switch. Upon app reopening, handleActionWithIdentifier() is called and the user will goLive() immediately if they selected to go live at that club, or they will receive the displayPrompt() as above.
         
         When goLive() is called, the user is first removed from another previous live clubs, and then added to the new club.
         
         
         */
        // CoreLocation CLVisit Code
        func startMonitoringVisits() { self.locationManager.startMonitoringVisits() }
        func stopMonitoringVisits() { self.locationManager.stopMonitoringVisits() }
        
        //the latest venues that we might be attending
        var liveVenueIDOptions = [VisitLocation]() //in order of priority
        
        func setupLocationServices() {
            locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            /*
             Ask for this later!
            if (CLLocationManager.authorizationStatus() == .notDetermined) {
                locationManager.requestAlwaysAuthorization()
                locationManager.requestWhenInUseAuthorization()
            }
            
            if (CLLocationManager.authorizationStatus() == .authorizedAlways){
                self.startMonitoringVisits()
            }
            */
            
        }
        
        
        //The prompt for going Live
        func showPopupIfActiveOrNotificationIfNot() {
            let state: UIApplicationState = UIApplication.shared.applicationState
            
            switch state {
                
            // Present local "pretty" popup for user
            case .active:
                if let chosenVenue = chosenVenueIDGoLiveAt {
                    if let currentVenue = user!.LiveClubID {
                        if (chosenVenue == currentVenue) {
                            if let venue = self.venues[chosenVenue] {
                                if(self.goLiveButtonPressed) {
                                    displayAlreadyLivePrompt(venueName: venue.VenueNickName)
                                }
                            }
                            else {
                                Utilities.printDebugMessage("Error getting venue name")
                            }
                        }
                        else {
                            //User receives option to go live
                            displayPrompt()
                        }
                    }
                    else {
                        //User receives option to go live
                        displayPrompt()
                    }
                }
                else {
                    Utilities.printDebugMessage("Fatal error: should have set chosenvenueID")
                }
            // Present local notification with GPS accuracy
            case .background:
                let eventName = liveVenueIDOptions[0].event.EventName
                self.showNotification(body: "Having fun at \(eventName)? Swipe left to view and check in!")
            // Present local notification without GPS accuracy
            case .inactive:
                let eventName = liveVenueIDOptions[0].event.EventName
                self.showNotification(body: "Having fun at \(eventName)? Swipe left to view and check in!")
                Utilities.printDebugMessage("Weird behaviour error")
            }
        }
        
        //    //TEMP FUNCTION
        //    func displayTempNotification(text : String) {
        //        DispatchQueue.main.async {
        //            self.showNotification(body: text)
        //            let alert = SCLAlertView()
        //            _ = alert.showInfo(text, subTitle: "Temp notification")
        //        }
        //    }
        
        func displayPrompt() {
            if liveVenueIDOptions.count != 0 {
                let currentEvent = liveVenueIDOptions[0].event
                let alert = SCLAlertView()
                
                //Live at first choice
                _ = alert.addButton("Go live at \(currentEvent.EventName)") {
                    Utilities.printDebugMessage("Go live pressed")
                    self.chosenVenueIDGoLiveAt = currentEvent.EventID
                    self.goLive()
                }
                
                //Go live elsewhere
                _ = alert.addButton("Live elsewhere") {
                    //Display a new popup
                    let secondaryAlert = SCLAlertView()
                    _ = secondaryAlert.addButton("\(self.liveVenueIDOptions[0].event.EventName)") {
                        self.chosenVenueIDGoLiveAt = self.liveVenueIDOptions[0].event.EventID
                        self.goLive()
                    }
                    if (self.liveVenueIDOptions.count >= 2) {
                        _ = secondaryAlert.addButton("\(self.liveVenueIDOptions[1].event.EventName)") {
                            self.chosenVenueIDGoLiveAt = self.liveVenueIDOptions[1].event.EventID
                            self.goLive()
                        }
                        
                    }
                    if (self.liveVenueIDOptions.count >= 3) {
                        _ = secondaryAlert.addButton("\(self.liveVenueIDOptions[2].event.EventName)") {
                            self.chosenVenueIDGoLiveAt = self.liveVenueIDOptions[2].event.EventID
                            self.goLive()
                        }
                    }
                    
                    _ = secondaryAlert.showNotice("Go live!", subTitle: "Choose a nearby club to go live at:")
                }
                //Show the first popup
                _ = alert.showInfo("Go live!", subTitle: "Select an option:")
            }
            else {
                Utilities.printDebugMessage("Error: no live venues to go live at")
            }
        }
        
        func displayWrongTimePrompt() {
            
            let alert = SCLAlertView()
            _ = alert.showInfo("Oops!", subTitle: "Looks like you're trying to go live, but it's not the right time. Try again when you're at a club after the event starts!")
        }
        
        func displayAlreadyLivePrompt(venueName : String) {
            let alert = SCLAlertView()
            _ = alert.showInfo("Hey there", subTitle: "Looks like you're already live at \(venueName)!")
        }
        
        func displayWrongPlacePrompt() {
            let alert = SCLAlertView()
            _ = alert.showInfo("Oops!", subTitle: "Looks like you're trying to go live, but you're not quite at a club. Try again when you're a little bit closer to where you want to be!")
        }
        
        func restoreNavItem() {
            if let navItem = self.navItem, let prevNavBarButtonItem = self.prevBarButtonItem {
                navItem.rightBarButtonItem = prevNavBarButtonItem
                //navItem.rightBarButtonItem = UIBarButtonItem(title: "Go Live", style: .plain, target: nil, action: #selector(PlacesTableViewController.goLiveButtonPressed(_:)))
            }
        }
        
        // Returns the most recently presented UIViewController (visible)
        func getCurrentViewController() -> UIViewController? {
            
            // If the root view is a navigation controller, we can just return the visible ViewController
            if let navigationController = getNavigationController() {
                
                return navigationController.visibleViewController
            }
            
            // Otherwise, we must get the root UIViewController and iterate through presented views
            if let rootController = UIApplication.shared.keyWindow?.rootViewController {
                
                var currentController: UIViewController! = rootController
                
                // Each ViewController keeps track of the view it has presented, so we
                // can move from the head to the tail, which will always be the current view
                while( currentController.presentedViewController != nil ) {
                    
                    currentController = currentController.presentedViewController
                }
                return currentController
            }
            return nil
        }
        
        // Returns the navigation controller if it exists
        func getNavigationController() -> UINavigationController? {
            
            if let navigationController = UIApplication.shared.keyWindow?.rootViewController  {
                
                return navigationController as? UINavigationController
            }
            return nil
        }
        
        var chosenVenueIDGoLiveAt : String?
        var navItem : UINavigationItem?
        var prevBarButtonItem : UIBarButtonItem?
        
        func presentNavBarActivityIndicator(navItem : UINavigationItem) {
            let uiBusy = UIActivityIndicatorView(activityIndicatorStyle: .white)
            self.navItem = navItem
            uiBusy.hidesWhenStopped = true
            uiBusy.startAnimating()
            self.prevBarButtonItem = navItem.rightBarButtonItem
            navItem.rightBarButtonItem = UIBarButtonItem(customView: uiBusy)
        }
        
        //Call this to go live, but first set chosenVenueIDGoLiveAT
        func goLive() {
            var loadingScreen : Utilities.LoadingScreenObject?
            var loadingScreenView : UIView?
            if let currentVC = getCurrentViewController() {
                loadingScreenView = currentVC.view
                loadingScreen = Utilities.presentLoadingScreen(vcView: currentVC.view)
            }
            
            //Remove user from previous live venue
            if let liveClubID = user!.LiveClubID {
                FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: liveClubID, userID: self.user!.FBID, add: false, completion: { (success) in
                    //testing func
                    //self.displayTempNotification(text: "REMOVING FROM LIVE:  \(self.venues[liveClubID]!.VenueName)")
                    
                    //go live
                    if let chosenVenueIDGoLiveAt = self.chosenVenueIDGoLiveAt {
                        self.goLiveAt(chosenVenueID: chosenVenueIDGoLiveAt, loadingScreenView: loadingScreenView, loadingScreen: loadingScreen)
                    }
                    else {
                        self.removeLoadingScreen(loadingScreen: loadingScreen, loadingScreenView: loadingScreenView)
                    }
                    
                })
            }
            else {
                Utilities.printDebugMessage("go live attempt 3")
                if let chosenVenueIDGoLiveAt = self.chosenVenueIDGoLiveAt {
                    self.goLiveAt(chosenVenueID: chosenVenueIDGoLiveAt, loadingScreenView: loadingScreenView, loadingScreen: loadingScreen)
                }
                else {
                    self.removeLoadingScreen(loadingScreen: loadingScreen, loadingScreenView: loadingScreenView)
                    Utilities.printDebugMessage("Error: chosen venueID is NIL")
                }
            }
        }
        
        func removeLoadingScreen(loadingScreen : Utilities.LoadingScreenObject?, loadingScreenView : UIView?) {
            if let loadingScreen = loadingScreen, let loadingScreenView = loadingScreenView {
                Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: loadingScreenView)
            }
        }
        
        func goLiveAt(chosenVenueID : String, loadingScreenView : UIView?, loadingScreen : Utilities.LoadingScreenObject?) {
            Utilities.printDebugMessage("goLiveAt \(chosenVenueID)")
            FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: chosenVenueID, userID: self.user!.FBID, add: true, completion: { (success) in
                Utilities.printDebugMessage("Success")
                if (!success) {
                    Utilities.printDebugMessage("Error in goLiveAt")
                }
                self.updateAllDataWithoutUpdatingLocation(completion: { (success) in
                    self.removeLoadingScreen(loadingScreen: loadingScreen, loadingScreenView: loadingScreenView)
                    if (success) {
                        Utilities.printDebugMessage("Success 2")
                        DispatchQueue.main.async {
                            let alert = SCLAlertView()
                            alert.addButton("Share with Flock", action: {
                                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                if let user = appDelegate.user, let venueName = appDelegate.venues[chosenVenueID]?.VenueNickName {
                                    Utilities.sendPushNotificationToEntireFlock(title: "\(user.Name) is live at \(venueName)!")
                                }
                            })
                            _ = alert.showSuccess(Utilities.generateRandomCongratulatoryPhrase(), subTitle: "You're live!")
                        }
                    }
                    else {
                        Utilities.printDebugMessage("Error updating app")
                    }
                })
            })
        }
        
        //Didvisit fired
        func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
            
            // Determine visit location and properties
            //let visitLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
            //        let isArriving = (visit.departureDate.compare(NSDate.distantFuture).rawValue == 0)
            //        self.isArriving = isArriving
            
            // Get state of the application: Active, Background, or Inactive
            let state: UIApplicationState = UIApplication.shared.applicationState
            
            switch state {
                
            // Present local "pretty" popup for user
            case .active:
                if(self.user != nil) {
                    manager.requestLocation()
                }
            // Present local notification with GPS accuracy
            case .background:
                if(self.user != nil) {
                    manager.requestLocation()
                }
                
            // Present local notification without GPS accuracy
            case .inactive:
                break
            }
            
        }
        
        //Received new location from GPS. KEY: this function should be able to be called at any time,
        //whether the app is on or in background. If called when it's on, it should handle displaying
        //a notification telling you that your're live, or making you unlive, or if you just arrived
        //somewhere then suggesting you go live.
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            restoreNavItem()
            // For testing purposes print out all locations in ascending order of distance
            liveVenueIDOptions = []
            let visitLocation = locations[0]
            
            
            //KEY: remove people from Live if they left
            
            //Send notification if within critical radius
            let clubsAscending = distanceToClubsAscending(visitLocation: visitLocation)
            
            var isValidTime = false
            for club in clubsAscending {
                if(DateUtilities.isDuringEvent(eventStart: club.event.EventStart, eventEnd: club.event.EventEnd)) {
                    isValidTime = true
                    break
                }
            }

            // Handle displaying prompts if user's pressed go live and aren't doing so at the right time/place
            if(self.goLiveButtonPressed && clubsAscending.count == 0) {
                self.displayWrongPlacePrompt()
            } else if (self.goLiveButtonPressed && !isValidTime) {
                self.displayWrongTimePrompt()
            }
            else {
                
                // Handle going live/not going live
                if (clubsAscending.count != 0) {
                    if isValidTime {
                        liveVenueIDOptions = clubsAscending
                        chosenVenueIDGoLiveAt = clubsAscending[0].event.EventID
                        showPopupIfActiveOrNotificationIfNot()
                    }
                }
                    //Remove the user from the club
                else {
                    if let user = self.user {
                        if let liveClubID = user.LiveClubID {
                            FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: liveClubID, userID: user.FBID, add: false, completion: { (success) in
                                //testing func
                                //self.showNotification(body: "TEMP NOTIFICATION. REMOVING FROM LIVE:  \(self.venues[liveClubID]!.VenueName)")
                            })
                        }

                    }
                }
            }
            self.goLiveButtonPressed = false
            
        }
        
        //Did fail
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print(error)
            restoreNavItem()
        }
        
        // Send a local notification to the user
        func showNotification(body: String) {
            let notification = UILocalNotification()
            notification.alertAction = nil
            notification.alertBody = body
            
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
            
            
            let category = UIMutableUserNotificationCategory()
            let categoryIdentifier = "category.identifier"
            category.identifier = categoryIdentifier
            category.setActions([acceptClub, switchClub], for: .minimal)
            category.setActions([acceptClub, switchClub, cancelClub], for: .default)
            
            let categories = Set(arrayLiteral: category)
            let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: categories)
            UIApplication.shared.registerUserNotificationSettings(settings)
            notification.category = categoryIdentifier
            
            UIApplication.shared.presentLocalNotificationNow(notification)
        }
        
        //After the user has pressed a notification button
        func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
            if(identifier != nil) {
                switch identifier! {
                case "accept":
                    goLive()
                    break
                case "switch":
                    //displayPrompt()
                    break
                default:
                    break
                }
            }
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
        
        //returns all clubs in ascending order that are in critical radius
        func distanceToClubsAscending(visitLocation : CLLocation) -> [VisitLocation] {
            
            var visitLocations = [VisitLocation]()
            
            for event in Array(self.activeEvents.values) {
                let location : CLLocation? = CLLocation(latitude: event.Pin.coordinate.latitude, longitude: event.Pin.coordinate.longitude)
                if let eventLocation = location {
                    let distanceInMeters = visitLocation.distance(from: eventLocation)
                    if (distanceInMeters < Constants.CRITICAL_RADIUS) {
                        visitLocations.append(VisitLocation(distAway: distanceInMeters, event: event))
                    }
                }
            }
            visitLocations.sort { (vl1, vl2) -> Bool in
                vl1.distAway < vl2.distAway
            }
            return visitLocations
        }
        
        //Uses core data
        //    func distanceToClubsAscendingWhileInactive(visitLocation: CLLocation) -> [VisitLocation] {
        //        var visitLocations = [VisitLocation]()
        //        if #available(iOS 10.0, *) {
        //            let storedVenues = self.getPartialVenueDataFromStorage()
        //
        //
        //            for cdvenue in Array(storedVenues.values) {
        //                let venueLocation = CLLocation(latitude: Double(cdvenue.latitude), longitude: Double(cdvenue.longitude))
        //                let distanceInMeters = visitLocation.distance(from: venueLocation)
        //                let venue = venues[cdvenue.venueID]!
        //                if (distanceInMeters < Constants.CRITICAL_RADIUS) {
        //                    visitLocations.append(VisitLocation(distAway: distanceInMeters, venue: venue))
        //                }
        //
        //            }
        //            visitLocations.sort { (vl1, vl2) -> Bool in
        //                vl1.distAway < vl2.distAway
        //            }
        //        } else {
        //            // Fallback on earlier versions
        //        }
        //        return visitLocations
        //
        //    }
        
        //=================================================================================================================//
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        //=================================================================================================================//
        //Start Notifications
        
        func application(_ application: UIApplication,
                         didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            FIRInstanceID.instanceID().setAPNSToken(deviceToken as Data, type:  FIRInstanceIDAPNSTokenType.prod)
        }
        
        /// The callback to handle data message received via FCM for devices running iOS 10 or above.
        public func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
            
        }
        
        
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
            //instabug
            Instabug.start(withToken: "292d20cd4a1c0d57de798ca15d91561d", invocationEvent: .none)
            GMSServices.provideAPIKey("AIzaSyCJcEmuHschqe1Vzx9BlD8wWD3jhKi7StY")
            //GMSPlacesClient.provideAPIKey("AIzaSyCJcEmuHschqe1Vzx9BlD8wWD3jhKi7StY")
            
            
            OneSignal.initWithLaunchOptions(launchOptions, appId: "35032170-d34b-4a41-9504-3ee4b725eafe", handleNotificationReceived: { (notification) in
                print("Received Notification - \(notification?.payload.notificationID)")
            }, handleNotificationAction: { (result) in
                //                let payload: OSNotificationPayload? = result?.notification.payload
                //
                //                var fullMessage: String? = payload?.body
                //                if payload?.additionalData != nil {
                //                    var additionalData: [AnyHashable: Any]? = payload?.additionalData
                //                    if additionalData!["actionSelected"] != nil {
                //                        fullMessage = fullMessage! + "\nPressed ButtonId:\(additionalData!["actionSelected"])"
                //                    }
                //                }
                //                print(fullMessage)
                //Utilities.printDebugMessage("yay")
            }, settings: [kOSSettingsKeyAutoPrompt : true, kOSSettingsKeyInFocusDisplayOption : OSNotificationDisplayType.notification.rawValue])
            
            
            
            FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
            FIRApp.configure()
            self.setupLocationServices()
            self.registerForPushNotifications(application: application)
            //remove notification tags
            UIApplication.shared.applicationIconBadgeNumber = 0
            //self.setupSimpleTBC()
            // Check for wakeup from inactive app
            
            if(launchOptions != nil) {
                if let _ = launchOptions![UIApplicationLaunchOptionsKey.location] {
                    self.appIsWakingUpFromVisit = true
                    if (CLLocationManager.authorizationStatus() != .notDetermined && CLLocationManager.authorizationStatus() != .denied) {
                        
                    
                    locationManager.requestLocation()
                    }
                }
            } else {
                self.appIsWakingUpFromVisit = false
            }
            
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
            
            //self.showNotification(body: "test")
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
            
            //self.showNotification(body: "test")
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
            if let _ = self.user {
                locationManager.requestLocation()
            }
        }
        
        func applicationDidBecomeActive(_ application: UIApplication) {
            // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
            FBSDKAppEvents.activateApp()
        }
        
        func applicationWillTerminate(_ application: UIApplication) {
            // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
            // Saves changes in the application's managed object context before the application terminates.
            //self.saveContext()
        }
        
        // MARK: - Core Data stack
        //
        //    @available(iOS 10.0, *)
        //    lazy var persistentContainer: NSPersistentContainer = {
        //        /*
        //         The persistent container for the application. This implementation
        //         creates and returns a container, having loaded the store for the
        //         application to it. This property is optional since there are legitimate
        //         error conditions that could cause the creation of the store to fail.
        //         */
        //        let container = NSPersistentContainer(name: "Flock")
        //        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
        //            if let error = error as NSError? {
        //                // Replace this implementation with code to handle the error appropriately.
        //                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        //
        //                /*
        //                 Typical reasons for an error here include:
        //                 * The parent directory does not exist, cannot be created, or disallows writing.
        //                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
        //                 * The device is out of space.
        //                 * The store could not be migrated to the current model version.
        //                 Check the error message to determine what the actual problem was.
        //                 */
        //                fatalError("Unresolved error \(error), \(error.userInfo)")
        //            }
        //        })
        //        return container
        //    }()
        //
        //    // MARK: - Core Data Saving support
        //
        //    func saveContext () {
        //        if #available(iOS 10.0, *) {
        //            let context = persistentContainer.viewContext
        //            if context.hasChanges {
        //                do {
        //                    try context.save()
        //                } catch {
        //                    // Replace this implementation with code to handle the error appropriately.
        //                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        //                    let nserror = error as NSError
        //                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        //                }
        //            }
        //        } else {
        //            // Fallback on earlier versions
        //        }
        //    }
        //
        
        
        
    }
    
    class VisitLocation: NSObject
    {
        var distAway: Double
        var event : Event
        
        init(distAway : Double, event : Event)
        {
            self.distAway = distAway
            self.event = event
        }
        
    }
    
    class Statistics: NSObject
    {
        var maxPlansInOneNight = [String:Int]() // Map from venueID to maxPlansInOneNight
        var loyalty = [String:Double]() // Maps from venueID to loyaltyFraction
        var popularity = [String:Int]() // Maps from venueID to popularityRanking
        var lifetimeLive = [String:Int]() // Maps from venueID to lifetimeLiveCount
        var venuePlanCountsForDatesForVenues = [String: [Date:Int]]()
        
        init(maxPlansInOneNight: [String:Int], loyalty : [String:Double], popularity : [String:Int], lifetimeLive : [String:Int], venuePlanCountsForDatesForVenues : [String: [Date:Int]])
        {
            self.maxPlansInOneNight = maxPlansInOneNight
            self.loyalty = loyalty
            self.popularity = popularity
            self.lifetimeLive = lifetimeLive
            self.venuePlanCountsForDatesForVenues = venuePlanCountsForDatesForVenues
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
    

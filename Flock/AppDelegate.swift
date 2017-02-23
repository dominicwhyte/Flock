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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {

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
                completion(true)
            }
            else {
                Utilities.printDebugMessage("Error updating all data")
                completion(false)
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
    
    
    // CoreLocation CLVisit Code
    func startMonitoringVisits() { self.locationManager.startMonitoringVisits() }
    func stopMonitoringVisits() { self.locationManager.stopMonitoringVisits() }
    
    func setupLocationServices() {
        locationManager.delegate = self
        //if (CLLocationManager.authorizationStatus() == .notDetermined) {
        //    locationManager.requestAlwaysAuthorization()
        //}
            
        if (CLLocationManager.authorizationStatus() == .authorizedAlways){
            self.startMonitoringVisits()
        }
        
    }
    
    func registerForRemoteNotification() {
        if #available(iOS 10.0, *) {
            let center  = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                if error == nil{
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    //Temporary function
    func requestNotificationPermission(application : UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func registerForPushNotifications(application: UIApplication) {
        
        // 1. Create the actions **************************************************
        
        // increment Action
        let incrementAction = UIMutableUserNotificationAction()
        incrementAction.identifier = "INCREMENT_ACTION"
        incrementAction.title = "Add +1"
        incrementAction.activationMode = UIUserNotificationActivationMode.background
        incrementAction.isAuthenticationRequired = true
        incrementAction.isDestructive = false
        
        // decrement Action
        let decrementAction = UIMutableUserNotificationAction()
        decrementAction.identifier = "DECREMENT_ACTION"
        decrementAction.title = "Sub -1"
        decrementAction.activationMode = UIUserNotificationActivationMode.background
        decrementAction.isAuthenticationRequired = true
        decrementAction.isDestructive = false
        
        // reset Action
        let resetAction = UIMutableUserNotificationAction()
        resetAction.identifier = "RESET_ACTION"
        resetAction.title = "Reset"
        resetAction.activationMode = UIUserNotificationActivationMode.foreground
        // NOT USED resetAction.authenticationRequired = true
        resetAction.isDestructive = true
        
        
        // 2. Create the category ***********************************************
        
//        // Category
//        let counterCategory = UIUser()
//        counterCategory.identifier = "COUNTER_CATEGORY"
//        
//        // A. Set actions for the default context
//        counterCategory.setActions([incrementAction, decrementAction, resetAction],
//                                   for: UIUserNotificationActionContext.default)
//        
//        // B. Set actions for the minimal context
//        counterCategory.setActions([incrementAction, decrementAction],
//                                   for: UIUserNotificationActionContext.minimal)
//        let settings = UIUserNotificationSettings(types: [.badge, .alert, .sound], categories: counterCategory)
//        
//        
        // iOS 10 support
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            application.registerForRemoteNotifications()
        }
            // iOS 9 support
        else if #available(iOS 9, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 8 support
        else if #available(iOS 8, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 7 support
        else {  
            application.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        
        let visitLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        let isArriving = (visit.departureDate.compare(NSDate.distantFuture).rawValue == 0)
        self.isArriving = isArriving
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestLocation()
        var body = ""
        let ascendingVenues = distanceToClubsAscending(visitLocation: visitLocation)
        for venue in ascendingVenues {
            body += "\(venue.venueName) is \(venue.distAway) m away.\n"
        }
        showNotification(body: body)
        
        
        if let venueID = self.whichClubIsUserIn(visitLocation: visitLocation) {
            // Check if user was previously live somewhere else
            var previousLiveID : String?
            if(self.user!.LiveClubID != nil) {
                previousLiveID  = self.user!.LiveClubID
            } else {
                previousLiveID = nil
            }
            
            FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: venueID, previousLiveID: previousLiveID, userID: self.user!.FBID, add: isArriving, completion: { (success) in
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if (isArriving) {
                    self.showNotification(body: "VENUE CHOSEN Arriving at \(appDelegate.venues[venueID]!.VenueName)")
                }
                else {
                    self.showNotification(body: "VENUE CHOSEN Departing \(appDelegate.venues[venueID]!.VenueName)")
                }
                if(success) {
                    Utilities.printDebugMessage("Successfully uploaded visit to database")
                }
            })
        } else {
            if let venueID = self.user!.LiveClubID {
                FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: venueID, previousLiveID: nil, userID: self.user!.FBID, add: false, completion: { (success) in
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    self.showNotification(body: "DEPARTING VENUE: \(appDelegate.venues[venueID]!.VenueName)")
                    
                    if(success) {
                        Utilities.printDebugMessage("Successfully uploaded visit to database")
                    }
                })
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // For testing purposes print out all locations in ascending order of distance
        let visitLocation = locations[0]
        let ascendingVenues = distanceToClubsAscending(visitLocation: visitLocation)
        var body : String = "GPS ACCURACY:\n"
        for venue in ascendingVenues {
            body += "\(venue.venueName) is \(venue.distAway) m away.\n"
        }
        showNotification(body: body)
        
        
        if let venueID = self.whichClubIsUserIn(visitLocation: visitLocation) {
            var previousLiveID : String?
            if(self.user!.LiveClubID != nil) {
                previousLiveID = self.user!.LiveClubID
            } else {
                previousLiveID = nil
            }
            FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: venueID, previousLiveID : previousLiveID, userID: self.user!.FBID, add: self.isArriving, completion: { (success) in
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                if (self.isArriving) {
                    self.showNotification(body: "VENUE CHOSEN Arriving at \(appDelegate.venues[venueID]!.VenueName)")
                }
                else {
                    self.showNotification(body: "VENUE CHOSEN Departing \(appDelegate.venues[venueID]!.VenueName)")
                }
                if(success) {
                    Utilities.printDebugMessage("Successfully uploaded visit to database")
                }
            })
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    // Notification function for local testing/debugging
    func showNotification(body: String) {
        let notification = UILocalNotification()
        notification.alertAction = nil
        notification.alertBody = body
        UIApplication.shared.presentLocalNotificationNow(notification)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (CLLocationManager.authorizationStatus() == .authorizedAlways){
            self.startMonitoringVisits()
        }
    }
    
    func distanceToNearestClub(visitLocation : CLLocation) -> (String, Double)? {
        var minDistance = Double.infinity
        var closestVenueName : String?
        
        for venue in Array(self.venues.values) {
            if let venueLocation = venue.VenueLocation {
                let distanceInMeters = visitLocation.distance(from: venueLocation)
                if distanceInMeters < minDistance {
                    minDistance = distanceInMeters
                    closestVenueName = venue.VenueName
                }
            }
        }
        if(closestVenueName != nil) {
            return (closestVenueName!, minDistance)
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
    
    // Determines if user is in club and returns venueID of appropriate club
    func whichClubIsUserIn(visitLocation : CLLocation) -> String? {
        
        for venue in Array(self.venues.values) {
            if let venueLocation = venue.VenueLocation {
                let distanceInMeters = visitLocation.distance(from: venueLocation)
                if(distanceInMeters < Constants.CRITICAL_RADIUS) {
                    return venue.VenueID
                }
            }
        }
        return nil
    }
    
//    //Called when a notification is delivered to a foreground app.
//    @available(iOS 10.0, *)
//    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        print("User Info = ",notification.request.content.userInfo)
//        completionHandler([.alert, .badge, .sound])
//    }
//    
//    //Called to let your app know which action was selected by the user for a given notification.
//    @available(iOS 10.0, *)
//    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
//        print("User Info = ",response.notification.request.content.userInfo)
//        completionHandler()
//    }
//    
//    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
//        if notificationSettings.types != .none {
//            application.registerForRemoteNotifications()
//        }
//    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification data: [AnyHashable : Any]) {
        // Print notification payload data
        print("Push notification received: \(data)")
    }
    
    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        // Print it to console
        print("APNs device token: \(deviceTokenString)")
        
        // Persist it in your backend in case it's new
    }
    
    // Called when APNs failed to register the device for push notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Print the error to console (you should alert the user that registration failed)
        print("APNs registration failed: \(error)")
    }

    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        FIRApp.configure()
        self.setupLocationServices()
        //self.requestNotificationPermission(application: application)
        //registerForRemoteNotification()
        self.registerForPushNotifications(application: application)
        return true
    }
    


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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
        //self.saveContext()
    }

    // MARK: - Core Data stack
/*
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
    }
*/
    


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


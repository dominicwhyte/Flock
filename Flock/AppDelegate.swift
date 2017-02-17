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
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    struct Constants {
        static let CRITICAL_RADIUS : Double = 40.0 // meters
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
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        
        Utilities.printDebugMessage("visit: \(visit.coordinate.latitude),\(visit.coordinate.longitude)")
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestLocation()
        let visitLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        let isArriving = (visit.departureDate.compare(NSDate.distantFuture).rawValue == 0)
        if let (venueName, distToVenue) = distanceToNearestClub(visitLocation: visitLocation) {
            showNotification(body: "Closest venue: \(venueName), \(distToVenue) m away. Is arriving: \(isArriving). ")
        }
        let ascendingVenues = distanceToClubsAscending(visitLocation: visitLocation)
        var body : String = ""
        for venue in ascendingVenues {
            body += "\(venue.venueName) is \(venue.distAway) m away.\n"
        }
        showNotification(body: body)
        
        if let venueID = self.whichClubIsUserIn(visitLocation: visitLocation) {
            FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: venueID, userID: self.user!.FBID, add: isArriving, completion: { (success) in
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
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations[0]
        let ascendingVenues = distanceToClubsAscending(visitLocation: currentLocation)
        var body : String = "GPS ACCURACY:\n"
        for venue in ascendingVenues {
            body += "\(venue.venueName) is \(venue.distAway) m away.\n"
        }
        showNotification(body: body)
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

    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        FIRApp.configure()
        self.setupLocationServices()
        self.requestNotificationPermission(application: application)

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


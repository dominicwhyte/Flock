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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    struct Constants {
        static let CRITICAL_RADIUS = 23.0 // meters
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
    
    func updateAllData(completion: @escaping (_ status: Bool) -> ()) {
        LoginClient.retrieveData { (user, venues) in
            assert(user != nil && venues != nil)
            self.user = user
            self.venues = venues!
            self.getAllUsers(completion: { (status) in
                if(!status) {
                    Utilities.printDebugMessage("Could not get all users?")
                }
                completion(true)
            })
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
                    completion(true)
                }
            })
        }
    }
    
    func getAllUsers(completion: @escaping (_ status: Bool) -> ()) {
        FirebaseClient.getAllUsers { (users) in
            self.users = users
            self.getAllFriends()
            completion(true)
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

        self.friendRequestUsers = friendRequestUsersDict
        self.friends = friendDict
    }
    
    
    // CoreLocation CLVisit Code
    func startMonitoringVisits() { self.locationManager.startMonitoringVisits() }
    func stopMonitoringVisits() { self.locationManager.stopMonitoringVisits() }
    
    func setupLocationServices() {
        locationManager.delegate = self
        if (CLLocationManager.authorizationStatus() == .notDetermined) {
            locationManager.requestAlwaysAuthorization()
        } else if (CLLocationManager.authorizationStatus() == .authorizedAlways){
            self.startMonitoringVisits()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        
        Utilities.printDebugMessage("visit: \(visit.coordinate.latitude),\(visit.coordinate.longitude)")
        showNotification(body: "Visit: \(visit)")
        let visitLocation = CLLocation(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        if let venueID = self.whichClubIsUserIn(visitLocation: visitLocation) {
            FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: venueID, userID: self.user!.FBID, completion: { (success) in
                if(success) {
                    Utilities.printDebugMessage("Successfully uploaded visit to database")
                }
            })
        }
        // Not quite sure how to do this comparison. Maybe one of the following
        //if visit.departureDate > Date() {
        if (visit.departureDate.compare(NSDate.distantFuture).rawValue == 0) {
            // A visit has begun, but not yet ended. User must still be at the place.
            FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: "-KcBNbASBTPdCIiwFv2m", userID: self.user!.FBID, completion: { (success) in
                if(success) {
                    Utilities.printDebugMessage("Arrived to venue")
                }
            })
        } else {
            FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: "-KcBNbASBTPdCIiwFv2m", userID: self.user!.FBID, completion: { (success) in
                if(success) {
                    Utilities.printDebugMessage("Leaving venue")
                }
            })
        }
        FirebaseClient.addUserToVenueLive(date: DateUtilities.getTodayFullDate(), venueID: "-KcBOlWnYeNXN1FWTnFv", userID: self.user!.FBID, completion: { (success) in
            if(success) {
                Utilities.printDebugMessage("Visit logged")
            }
        })
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


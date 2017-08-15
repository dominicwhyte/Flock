//
//  MapViewController.swift
//  Flock
//
//  Created by Grant Rheingold on 7/25/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import GoogleMaps
import Mapbox
import PopupDialog
import SCLAlertView
import SAConfettiView
import CoreLocation
import BTNavigationDropdownMenu


class MapViewController: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate, VenueDelegate, UITableViewDelegate, UITableViewDataSource /*,MGLMapViewDelegate, UIGestureRecognizerDelegate*/ {
    
    //For zoom
    var zoomLevel : ZoomLevel = ZoomLevel.max
    var tap : UITapGestureRecognizer!
    
    var mapView : MGLMapView?
    
    // For delegate
    internal var venueToPass: Venue?
    internal var eventToPass: Event?
    var imageCache = [String : UIImage]()
    var latestAttendButton : DefaultButton?
    var closestEvent : Event?
    var events = [String:Event]()
    var filteredEvents = [String:Event]()
    
    var displayDates : [String] = []
    var fullDates : [Date] = []
    
    fileprivate let reuseIdentifier = "PLACE"
    
    struct Constants {
        static let FLOCK_INVITE_REQUEST_CELL_SIZE = 129.0
    }
    
    // Detail Window
    
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var firstSubtitleLabel: UILabel!
    
    @IBOutlet weak var secondSubtitleLabel: UILabel!
    
    @IBOutlet weak var interestedButton: UIButton!
    @IBOutlet weak var thereButton: UIButton!
    
    @IBOutlet weak var listButton: UIBarButtonItem!
    
    @IBOutlet weak var createEventButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    //let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView = setupMap()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.events = appDelegate.activeEvents
        self.filteredEvents = appDelegate.activeEvents
        view.addSubview(mapView!)
        
        
        // Set the map view‘s delegate property.
        mapView!.delegate = self
        
        populateMap(mapView: mapView!)
        
        // Single Tap Recognition
        tap = UITapGestureRecognizer(target: self, action: #selector(changeZoom))
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        
        self.mapView!.addGestureRecognizer(tap)
        
        self.navigationItem.title = "None"
        self.navigationController?.navigationBar.tintColor = UIColor.white

        // Stack views appropriately
        
        self.view.bringSubview(toFront: detailView)
        self.view.bringSubview(toFront: titleLabel)
        self.view.bringSubview(toFront: firstSubtitleLabel)
        self.view.bringSubview(toFront: secondSubtitleLabel)
        self.view.bringSubview(toFront: interestedButton)
        self.view.bringSubview(toFront: thereButton)
        self.view.bringSubview(toFront: tableView)
        self.tableView.isHidden = true
        
        self.detailView.layer.cornerRadius = 20
        
        // Initialize closest event if exist
        self.setClosestEvent(mapView: mapView!)
        
        //nav bar
        let allText = "All Dates"
        
        var displayDates : [String] = []
        var fullDates : [Date] = []
        for (_,event) in self.events {
            if(displayDates.count > 0) {
                let title = "\(DateUtilities.convertDateToStringByFormat(date: event.EventStart, dateFormat: DateUtilities.Constants.dropdownDisplayFormat))"
                displayDates.append(title)
                fullDates.append(event.EventStart)
            } else {
                displayDates.append(allText)
                fullDates.append(Date())
            }
        }
        self.displayDates = displayDates
        self.fullDates = fullDates
        let menuView = BTNavigationDropdownMenu(navigationController: self.navigationController, containerView: self.navigationController!.view, title: displayDates[0], items: displayDates as [AnyObject])
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = FlockColors.FLOCK_BLUE
        menuView.menuTitleColor = UIColor.white
        menuView.cellTextLabelColor = FlockColors.FLOCK_BLUE
        self.navigationItem.titleView = menuView
        menuView.cellBackgroundColor = UIColor.white
        
        
        menuView.didSelectItemAtIndexHandler = {[weak self] (indexPath: Int) -> () in
            if(indexPath > 0) {
                self?.filterMapForDate(date: (self!.fullDates[indexPath]))
            } else {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                self?.events = appDelegate.activeEvents
            }
        }
        
    }
    
    func filterMapForDate(date: Date) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let activeEvents = appDelegate.activeEvents
        var filteredEvents = [String:Event]()
        for (eventID, event) in activeEvents {
            if(event.EventStart == date) {
                filteredEvents[eventID] = event
            }
        }
        self.events = filteredEvents
        
        // Surely there's a way to do this
        /*self.events = (activeEvents.filter({(eventID , event) -> Bool in
            return event.EventStart == date
        }))*/
        tableView?.reloadData()
    }
    
    func setupMap() -> MGLMapView {
        let mapView = MGLMapView(frame: view.bounds, styleURL: MGLStyle.lightStyleURL())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.tintColor = .darkGray
        
        // Set the map's bounds to Pisa, Italy.
        /*
         let bounds = MGLCoordinateBounds(
         sw: CLLocationCoordinate2D(latitude: 43.7115, longitude: 10.3725),
         ne: CLLocationCoordinate2D(latitude: 43.7318, longitude: 10.4222))
         mapView.setVisibleCoordinateBounds(bounds, animated: false)
         
         */

        mapView.setCenter(MapUtilities.Constants.PRINCETON_LOCATION, animated: false)
        mapView.setZoomLevel(ZoomLevel.max.rawValue, animated: true)
        mapView.isZoomEnabled = false
        mapView.isUserInteractionEnabled = true
        
        return mapView
    }
    
    func reloadMapData(mapView: MGLMapView) {
        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        self.populateMap(mapView: mapView)
    }
    
    func populateMap(mapView : MGLMapView) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for (_,event) in self.events {
            Utilities.printDebugMessage("Test" + String(event.Pin.coordinate.latitude))
            mapView.addAnnotation(event.Pin)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //mapView!.setZoomLevel(ZoomLevel.max.rawValue, animated: true)
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return nil
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        // Try to reuse the existing ‘pisa’ annotation image, if it exists.
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "pisa")
        
        if annotationImage == nil {
            // Leaning Tower of Pisa by Stefan Spieler from the Noun Project.
            var image = UIImage(named: "blue-college-15")!
            
            // The anchor point of an annotation is currently always the center. To
            // shift the anchor point to the bottom of the annotation, the image
            // asset includes transparent bottom padding equal to the original image
            // height.
            //
            // To make this padding non-interactive, we create another image object
            // with a custom alignment rect that excludes the padding.
            image = image.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: image.size.height/2, right: 0))
            
            // Initialize the ‘pisa’ annotation image with the UIImage we just loaded.
            annotationImage = MGLAnnotationImage(image: image, reuseIdentifier: "pisa")
        }
        
        return annotationImage
    }
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        self.setClosestEvent(mapView: mapView)
    }
    
    func setClosestEvent(mapView: MGLMapView) {
        if let pins = self.mapView!.visibleAnnotations(in: self.mapView!.frame) {
            // Go through pins to find closest
            
            var title : String?
            var eventID : String?
            var minDistance = Double.infinity
            
            let mapCenter = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            for pin in pins {
                let pinLocation = CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
                let pinDistance = pinLocation.distance(from: mapCenter)
                if(pinDistance < minDistance) {
                    minDistance = pinDistance
                    title = pin.title!
                    eventID = pin.subtitle!
                }
            }
            self.titleLabel.text = title
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            self.closestEvent = self.events[eventID!]
        }
    }
    
    
    func changeZoom() {
        
        switch zoomLevel {
        case .max:
            zoomLevel = ZoomLevel.min
        case .min:
            zoomLevel = ZoomLevel.max
        }
        self.mapView?.setZoomLevel(zoomLevel.rawValue, animated: true)
    }
    
    
    @IBAction func interestedButtonPressed(_ sender: Any) {
        let venueID = "-KeKwmy05LN6DpMkNmr1"
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let venues = appDelegate.venues
        let venue = venues[venueID]!
        self.venueToPass = venue
        self.eventToPass = self.closestEvent
        self.showCustomDialog(event: eventToPass!, startDisplayDate: nil)
        let eventLocation = CLLocationCoordinate2D(latitude: eventToPass!.Pin.coordinate.latitude, longitude: eventToPass!.Pin.coordinate.longitude)
        mapView!.setCenter(eventLocation, animated: false)
    }
    
    
    
    @IBAction func thereButtonPressed(_ sender: Any) {
    }
    
    func retrieveImage(imageURL : String?, venueID: String?, completion: @escaping (_ image: UIImage) -> ()) {
        if let imageURL = imageURL {
            if let image = imageCache[imageURL] {
                completion(image)
            }
            else {
                FirebaseClient.getImageFromURL(imageURL, venueID: venueID) { (image) in
                completion(image!)
                    self.imageCache[imageURL] = image
                }
            }
        }
    }
    
    //Retrieve image with caching
    func retrieveImage(imageURL : String?, venueID: String?, imageView : UIImageView) {
        if let imageURL = imageURL {
            if let image = imageCache[imageURL] {
                imageView.image = image
            }
            else {
                FirebaseClient.getImageFromURL(imageURL, venueID: venueID) { (image) in
                    DispatchQueue.main.async {
                        self.imageCache[imageURL] = image
                        imageView.image = image
                    }
                }
            }
        }
    }
    
    func showCustomDialog(event : Event, startDisplayDate : Date?) {
        
        // Create a custom view controller
        let popupSubView = PopupSubViewController(nibName: "PopupSubViewController", bundle: nil)
        
        popupSubView.delegate = self
        
        if let date = startDisplayDate {
            popupSubView.setStartDate(date: date)
        }
        
        // Create the dialog
        let popup = PopupDialog(viewController: popupSubView, buttonAlignment: .horizontal, transitionStyle: .bounceDown, gestureDismissal: true)
        
        
        // Create second button
        let todaysDate = DateUtilities.convertDateToStringByFormat(date: Date(), dateFormat: "MMMM d")
        let attendButton = DefaultButton(title: "GO TO \(event.EventName.uppercased()) ON \(todaysDate.uppercased())", dismissOnTap: true) {
            
            if (popupSubView.buttonIsInviteButton) {
                Utilities.printDebugMessage("Invite flock!")
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let userID = appDelegate.user!.FBID
                
                
                
                let eventID = self.eventToPass!.EventID
                let fullDate = popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex]
                
                let plannedFriendUsersForDate = popupSubView.allFriendsForDate[popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex]]![1] //1 for planned attendees
                var plannedAttendeesForDate = [String:String]()
                
                for user in plannedFriendUsersForDate {
                    Utilities.printDebugMessage(user.Name)
                    plannedAttendeesForDate[user.FBID] = user.FBID
                }
                let specialEventID = popupSubView.specialEventID
                self.performSegueToSelector(userID: userID, venueID: eventID, fullDate: fullDate, plannedAttendeesForDate: plannedAttendeesForDate, specialEventID: specialEventID)
                //popupSubView.performSegue(withIdentifier: "SELECTOR_IDENTIFIER", sender: (userID, venueID, fullDate, plannedAttendeesForDate, specialEventID))
            }
            else {
                Utilities.printDebugMessage("Attending \(event.EventName.uppercased())")
                let date = popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex]
                
                let plannedFriendUsersForDate = popupSubView.allFriendsForDate[popupSubView.stringsOfUpcomingDays[popupSubView.datePicker.selectedItemIndex]]![1] //1 for planned attendees
                var plannedAttendeesForDate = [String:String]()
                
                for user in plannedFriendUsersForDate {
                    Utilities.printDebugMessage(user.Name)
                    plannedAttendeesForDate[user.FBID] = user.FBID
                }
                
                //Add Venue and present popup
                self.attendEventWithConfirmation(date: date, eventID: self.eventToPass!.EventID, add: true, specialEventID: popupSubView.specialEventID, plannedFriendAttendeesForDate: plannedAttendeesForDate)
            }
            
        }
        
        
        //attendButton.isEnabled = self.shouldAttendButtonBeEnabledUponInitialPopup(appDelegate: appDelegate)
        attendButton.backgroundColor = FlockColors.FLOCK_BLUE
        
        attendButton.setTitleColor(.white, for: .normal)
        //        if(!attendButton.isEnabled) {
        //            self.disableButton(button: attendButton)
        //        }
        latestAttendButton = attendButton
        // Add buttons to dialog
        popup.addButtons([attendButton])
        
        //Hacky solution, don't show this on ipads
        if (popupSubView.view.frame.height > self.view.frame.height) {
            Utilities.printDebugMessage("Height error")
        }
        else {
            popupSubView.setAttendButtonTitle()
            present(popup, animated: true, completion: nil)
        }
        // Present dialog
        
    }
    
    func attendEventWithConfirmation(date : String, eventID : String, add : Bool, specialEventID : String?, plannedFriendAttendeesForDate : [String : String]) {
        Utilities.printDebugMessage("EventID: \(eventID)")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //        let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
        let (loadingScreen, foundView) = Utilities.presentLoadingScreenAutoGetView()
        FirebaseClient.addInterestedUserToEvent(date: date, eventID: eventID, userID: appDelegate.user!.FBID, add: true, completion: { (success) in
            if (success) {
                appDelegate.profileNeedsToUpdate = true
                
                self.updateDataAndMap({ (success) in
                    if (success) {
                        DispatchQueue.main.async {
                            let event = self.events[eventID]!
                            Utilities.printDebugMessage("Successfully added plan to attend venue")
                            Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: foundView)
                            self.displayAttendedPopup(venueName: event.EventName, venueID: eventID, attendFullDate: date, plannedAttendees: plannedFriendAttendeesForDate, specialEventID: specialEventID)
                        }
                    }
                    else {
                        Utilities.printDebugMessage("Error reloading tableview in venues")
                    }
                })
            }
            else {
                Utilities.printDebugMessage("Error adding user to venue plans for date")
                Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
            }
        })
        
    }
    
    func displayAttendedPopup(venueName : String, venueID: String, attendFullDate : String, plannedAttendees: [String:String], specialEventID: String?) {
        let fullDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.fullDateFormat)
        let displayDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.uiDisplayFormat)
        let alert = SCLAlertView()
        alert.addButton("Invite Flock", action: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let user = appDelegate.user {
                //self.selectFlockersToInvite(userID: user.FBID, venueID : venueID, fullDate : fullDate, plannedAttendees: plannedAttendees, specialEventID: specialEventID)
                Utilities.printDebugMessage("This needs to be implemented")
            }
        })
        alert.addButton("Share with Flock", action: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let user = appDelegate.user {
                Utilities.sendPushNotificationToEntireFlock(title: "\(user.Name) is planning to go to \(venueName) on \(displayDate)!")
                //let newAlert = SCLAlertView()
                //_ = alert.showSuccess("Shared", subTitle: "Your friends have been notified!")
            }
        })
        _ = alert.showSuccess(Utilities.generateRandomCongratulatoryPhrase(), subTitle: "You're going to \(venueName) on \(displayDate)")
        
        //        let confettiView = SAConfettiView(frame: self.view.bounds)
        //        self.view.addSubview(confettiView)
        //        confettiView.startConfetti()
    }
    
    //UpdateTableViewDelegate function
    func updateDataAndMap(_ completion: @escaping (Bool) -> Void) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllData { (success) in
            DispatchQueue.main.async {
                if (success) {
                    //self.setDataForInvitesRequestsCollectionView()
                    //self.flockInviteRequestCollectionView?.reloadData()
                    //Utilities.printDebugMessage("Successfully reloaded data and tableview")
                    Utilities.printDebugMessage("Successfully reloaded data")
                    
                }
                else {
                    Utilities.printDebugMessage("Error updating and reloading data")
                }
                completion(success)
            }
        }
    }
    
    func performSegueToSelector(userID : String, venueID : String, fullDate : String, plannedAttendeesForDate : [String: String], specialEventID : String?) {
        self.performSegue(withIdentifier: "SELECTOR_IDENTIFIER", sender: (userID, venueID, fullDate, plannedAttendeesForDate, specialEventID))
    }
    
    func changeButtonTitle(title: String) {
        latestAttendButton?.backgroundColor = FlockColors.FLOCK_BLUE
        latestAttendButton?.setTitle(title, for: .normal)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let peopleSelectorTableViewController = navController.topViewController as? PeopleSelectorTableViewController {
                if let (userID, venueID, fullDate, plannedAttendees, specialEventID) = sender as? (String, String, String, [String:String], String?) {
                    peopleSelectorTableViewController.userID = userID
                    peopleSelectorTableViewController.venueID = venueID
                    peopleSelectorTableViewController.fullDate = fullDate
                    peopleSelectorTableViewController.plannedAttendees = plannedAttendees
                    peopleSelectorTableViewController.specialEventID = specialEventID
                }
            }
        }
    }
    
    @IBAction func listButtonPressed(_ sender: Any) {
        self.view.bringSubview(toFront: tableView)
        self.tableView.isHidden = !self.tableView.isHidden
    }
    
    @IBAction func createEventButtonPressed(_ sender: Any) {
    }
    
    // TABLE VIEW FUNCTIONS
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.separatorStyle = .none
        tableView.backgroundView?.isHidden = true
        Utilities.printDebugMessage("Rows: \(self.events.count)")
        return self.events.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        Utilities.printDebugMessage("Cell being referenced")
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! PlacesTableViewCell
        cell.selectionStyle = .none
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        
        //Setup Cell
        
        var event : Event
        
        /*if searchController.isActive && searchController.searchBar.text != "" {
            venue = filteredVenues[indexPath.row]
        }
        else {*/
            let eventsArray = Array(self.events.values)
            event = eventsArray[indexPath.row]
        //}
        
        if (DateUtilities.dateIsToday(date: event.EventStart)) {
            cell.nextOpenLabel.text = "Next open tonight"
        }
        else {
            cell.nextOpenLabel.text = "Next open \(DateUtilities.convertDateToStringByFormat(date: event.EventStart, dateFormat: "E"))"
        }
        

        
        let currentLive = event.EventThereFBIDs.count
        cell.rightStatLabel.text = "\(String(currentLive))"
        
        cell.leftStatLabel.text = "\(event.EventInterestedFBIDs.count)"
        
        cell.placesNameLabel.text = event.EventName
        self.retrieveImage(imageURL: event.EventImageURL, venueID: event.EventID, imageView: cell.backgroundImage)
        //        cell.liveLabel.text = "\(venue.CurrentAttendees.count) live"
        //        cell.plannedLabel.text = "\(venue.PlannedAttendees.count) planned"
        
        cell.subtitleLabel.text = "Be first to plan!"
        /*if(self.currentTab != self.allText) {
            if let planDictForDates = appDelegate.friendCountPlanningToAttendVenueForDates[venue.VenueID]{
                if let plannedFriends = planDictForDates[self.currentTab] {
                    cell.subtitleLabel.text = "\(plannedFriends) planned \(Utilities.setPlurality(string: "friend", count: plannedFriends))"
                } else {
                    cell.subtitleLabel.text = "Be first to plan!"
                }
            }
        }
        else {
            if let plannedFriends = appDelegate.friendCountPlanningToAttendVenueThisWeek[venue.VenueID] {
                cell.subtitleLabel.text = "\(plannedFriends) planned \(Utilities.setPlurality(string: "friend", count: plannedFriends))"
            }
            else {
                cell.subtitleLabel.text = "Be first to plan!"
            }
        }*/

        
        return cell
        

    }
    
    let inverseGoldenRatio : CGFloat = 0.621
    let l : CGFloat = 12
    let r : CGFloat = 12
    let t : CGFloat = 12
    let b : CGFloat  = 60
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        let cellHeight = inverseGoldenRatio * (CGFloat(self.view.frame.width) - l - r) + b + t
        
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // cell selected code here
        Utilities.printDebugMessage("Row: \(indexPath.row)")
        let eventsArray = Array(self.events.values)
        let event = eventsArray[indexPath.row]
        self.eventToPass = event
        self.showCustomDialog(event: event, startDisplayDate: nil)
    }
}

protocol VenueDelegate: class {
    var venueToPass : Venue? {get set}
    func retrieveImage(imageURL : String?, venueID: String?, completion: @escaping (_ image: UIImage) -> ())
    func changeButtonTitle(title: String)
    var eventToPass : Event? {get set}
    
}

enum ZoomLevel : Double {
    case min = 18.0
    case max = 15.0
}

class Region: NSObject
{
    var bounds : Bounds
    var name : String
    
    init(bounds : Bounds, name : String)
    {
        self.bounds = bounds
        self.name = name
    }
}

class Bounds: NSObject
{
    var northEast : CLLocationCoordinate2D
    var southWest : CLLocationCoordinate2D
    
    init(northEast : CLLocationCoordinate2D, southWest : CLLocationCoordinate2D)
    {
        self.northEast = northEast
        self.southWest = southWest
    }
}

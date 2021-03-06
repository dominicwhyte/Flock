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
import M13Checkbox
import SearchTextField
import DateTimePicker
import PickerController
import Firebase
import FirebaseDatabase
import FirebaseAuth
import AIFlatSwitch


class MapViewController: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate, VenueDelegate, UITableViewDelegate, UITableViewDataSource /*,MGLMapViewDelegate, UIGestureRecognizerDelegate*/ {
    
    //For zoom
    var zoomLevel : ZoomLevel = ZoomLevel.max
    var tap : UITapGestureRecognizer!
    var detailWindowTap : UITapGestureRecognizer!
    //var createEventTap : UITapGestureRecognizer!
    
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
    
    // Picker 
    var labelIndices = UILabel()
    var labelItems = UILabel()
    
    fileprivate let reuseIdentifier = "PLACE"
    
    // Structure for handling user-created events
    var isUserCreatingEvent = false
    var userCreatedEventName : String?
    var userCreatedEventDescription : String?
    var userCreatedEventType : EventType?
    var userCreatedEventStart : Date?
    var userCreatedEventEnd : Date?
    var userCreatedEventLocation : CLLocationCoordinate2D?
    var userCreatedEventPrivacy : String?
    
    
    
    var privacyCheckbox : AIFlatSwitch?
    var privacyLabel : UILabel?
    
    struct Constants {
        static let FLOCK_INVITE_REQUEST_CELL_SIZE = 129.0
    }
    
    // Detail Window
    
    @IBOutlet weak var detailView: UIView!
    @IBOutlet weak var titleLabel: UILabel!

    
    @IBOutlet weak var interestedButton: UIButton!
    @IBOutlet weak var thereButton: UIButton!
    
    @IBOutlet weak var listButton: UIBarButtonItem!
    
    @IBOutlet weak var createEventButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var plannedLabel: UILabel!
    
    @IBOutlet weak var liveLabel: UILabel!
    
    @IBOutlet weak var nextOpenLabel: UILabel!
    
    @IBOutlet weak var createEventInfoView: UIView!
    @IBOutlet weak var createEventInfoLabel: UILabel!
    @IBOutlet weak var createEventCancelButton: UIButton!
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
        //self.mapView!.addGestureRecognizer(tap)
        
        // Long Press
        /*let createEventTap = UITapGestureRecognizer(target: self, action: "createEventTap:")
        createEventTap.numberOfTapsRequired = 1
        createEventTap.delegate = self
        
        self.mapView!.addGestureRecognizer(createEventTap)*/
        
        var uilgr = UILongPressGestureRecognizer(target: self, action: #selector(createEventLongPress(sender:)))
        uilgr.minimumPressDuration = 1.0
        
        //self.mapView!.add (uilgr)
        self.createEventInfoView.isHidden = true
        //IOS 9
        self.mapView!.addGestureRecognizer(uilgr)
        
        // Detail window centerer
        detailWindowTap = UITapGestureRecognizer(target: self, action: #selector(centerOnEvent))
        detailWindowTap.numberOfTapsRequired = 1
        detailWindowTap.delegate = self
        
        self.detailView.addGestureRecognizer(detailWindowTap)
        
        self.navigationItem.title = "None"
        self.navigationController?.navigationBar.tintColor = UIColor.white

        // Stack views appropriately
        
        self.view.bringSubview(toFront: detailView)
        self.view.bringSubview(toFront: titleLabel)
        self.view.bringSubview(toFront: plannedLabel)
        self.view.bringSubview(toFront: liveLabel)
        self.view.bringSubview(toFront: nextOpenLabel)
        self.view.bringSubview(toFront: interestedButton)
        self.view.bringSubview(toFront: thereButton)
        self.view.bringSubview(toFront: tableView)
        
        self.view.bringSubview(toFront: createEventInfoView)
        self.view.bringSubview(toFront: createEventInfoLabel)
        self.view.bringSubview(toFront: createEventCancelButton)
        self.tableView.isHidden = true
        
        // Aesthetic
        self.detailView.layer.cornerRadius = 20
        self.detailView.layer.borderWidth = 3.0
        self.detailView.layer.borderColor = FlockColors.FLOCK_LIGHT_GRAY.cgColor
        self.createEventInfoView.layer.cornerRadius = 20
        self.createEventInfoView.layer.borderWidth = 3.0
        self.createEventInfoView.layer.borderColor = FlockColors.FLOCK_LIGHT_BLUE.cgColor
        self.interestedButton.layer.cornerRadius = 8
        self.interestedButton.layer.shadowColor = UIColor.gray.cgColor
        self.interestedButton.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.interestedButton.layer.shadowOpacity = 1.0
        self.interestedButton.layer.shadowRadius = 0.0
        self.interestedButton.layer.masksToBounds = false
        self.interestedButton.adjustsImageWhenHighlighted = false
        self.thereButton.adjustsImageWhenHighlighted = false
        self.thereButton.layer.cornerRadius = 10//self.interestedButton.frame.height/2
        self.thereButton.layer.shadowColor = UIColor.gray.cgColor
        self.thereButton.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.thereButton.layer.shadowOpacity = 1.0
        self.thereButton.layer.shadowRadius = 0.0
        self.thereButton.layer.masksToBounds = false
        
        
        // Initialize closest event if exist
        self.setClosestEvent(mapView: mapView!)
        
        //nav bar
        let allText = "Upcoming"
        
        var displayDates : [String] = []
        var fullDates : [Date] = []
        
        // initialize
        displayDates.append(allText)
        fullDates.append(Date())
        
        for (_,event) in self.events {
            let title = "\(DateUtilities.convertDateToStringByFormat(date: event.EventStart, dateFormat: DateUtilities.Constants.dropdownDisplayFormat))"
            Utilities.printDebugMessage("For event \(event.EventName) we have \(title)")
            if(!fullDates.contains(event.EventStart)) {
                //displayDates.append(title)
                fullDates.append(event.EventStart)
            }
            
        }
        fullDates.sort { (date1, date2) -> Bool in
            return date1 < date2
        }
        
        for date in fullDates {
            let title = "\(DateUtilities.convertDateToStringByFormat(date: date, dateFormat: DateUtilities.Constants.dropdownDisplayFormat))"
            //if(!displayDates.contains(title)) {
                displayDates.append(title)
            //}
            
            
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
                self?.filterMapAndTableviewForDate(date: (self!.fullDates[indexPath]))
            } else {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                self?.events = appDelegate.activeEvents
            }
            self?.tableView!.reloadData()
            self?.reloadMapData(mapView: self!.mapView!)
        }
        
    }
    
    func filterMapAndTableviewForDate(date: Date) {
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
    }
    
    @IBAction func cancelCreateEventButtonPressed(_ sender: Any) {
        self.isUserCreatingEvent = false
        self.createEventInfoView.isHidden = true
    }
    func createEventLongPress(sender: UIGestureRecognizer){
        Utilities.printDebugMessage("Long press")
        
        if(self.isUserCreatingEvent) {
            let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
            let touchPoint = sender.location(in: mapView)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let user = appDelegate.user!
            let eventLocation = self.mapView!.convert(touchPoint, toCoordinateFrom: mapView)
            
            let eventName = self.userCreatedEventName!
            let eventStart = self.userCreatedEventStart!
            let eventEnd = self.userCreatedEventEnd!
            let eventType = self.userCreatedEventType!
            let eventImageURL : String? = nil
            let eventDescription = self.userCreatedEventDescription!
            let eventOwner = user.FBID
            let eventPrivacy = self.userCreatedEventPrivacy!
            
            MapFirebaseClient.addEventReturnID(eventName, eventStart: eventStart, eventEnd: eventEnd, eventLocation: eventLocation, eventType: eventType, eventImageURL: eventImageURL, eventDescription: eventDescription, eventOwner: eventOwner, eventPrivacy: eventPrivacy, completion: { (eventID) in
                
                let eventDict = ["EventID" : eventID as AnyObject, "EventName": eventName as AnyObject, "EventStart" : DateUtilities.getStringFromFullDate(date: eventStart) as AnyObject, "EventEnd" : DateUtilities.getStringFromFullDate(date: eventEnd) as AnyObject, "Latitude" : eventLocation.latitude.description as AnyObject, "Longitude" : eventLocation.longitude.description as AnyObject, "EventType" : eventType.rawValue as AnyObject, "EventDescription": eventDescription as AnyObject, "EventOwner": eventOwner as AnyObject, "EventPrivacy": eventPrivacy as AnyObject] as [String : AnyObject]
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let newEvent = Event(dict: eventDict)
                appDelegate.activeEvents[eventID] = newEvent
                self.events[eventID] = newEvent
                
                let annotation = MGLPointAnnotation()
                annotation.coordinate = eventLocation
                annotation.title = self.userCreatedEventName
                annotation.subtitle = eventID
                
                self.mapView!.addAnnotation(annotation)
                
                DispatchQueue.main.async {
                    Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                    let alert = SCLAlertView()
                    alert.addButton("Share with Flock", action: {
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        //if let user = appDelegate.user, let venueName = appDelegate.activeEvents[chosenVenueID]?.VenueNickName {
                        //    Utilities.sendPushNotificationToEntireFlock(title: "\(user.Name) is live at \(venueName)!")
                        //}
                    })
                    _ = alert.showSuccess(Utilities.generateRandomCongratulatoryPhrase(), subTitle: "You're live!")
                    self.isUserCreatingEvent = false
                    self.createEventInfoView.isHidden = true
                }
            })
        } else {
            /*let touchPoint = sender.location(in: mapView)
            let eventLocation = self.mapView!.convert(touchPoint, toCoordinateFrom: mapView)
            self.userCreatedEventLocation =*/
        }
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
        mapView.setZoomLevel(ZoomLevel.min.rawValue, animated: true)
        mapView.isZoomEnabled = true
        mapView.maximumZoomLevel = ZoomLevel.max.rawValue
        mapView.minimumZoomLevel = ZoomLevel.min.rawValue
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
        return false
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        
        if let eventID = annotation.subtitle {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let event = appDelegate.activeEvents[eventID!] {
                self.centerOnPassedEvent(event: event)
            }
            Utilities.printDebugMessage("Callout brings happiness")
        }
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotationView: MGLAnnotationView) {
        Utilities.printDebugMessage("Annotation view")
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        // Try to reuse the existing ‘pisa’ annotation image, if it exists.
        let reuseIdentifier = reuseIdentifierForAnnotation(annotation: annotation)
        
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: reuseIdentifier)
        
        if annotationImage == nil {
            // Leaning Tower of Pisa by Stefan Spieler from the Noun Project.
            var isHighlightedImage = determineHighlightedImage(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            var image : UIImage?
            if(isHighlightedImage) {
                image = UIImage(named: "white-college-15")!
            } else {
                image = UIImage(named: "blue-college-15")!
            }
            
            // The anchor point of an annotation is currently always the center. To
            // shift the anchor point to the bottom of the annotation, the image
            // asset includes transparent bottom padding equal to the original image
            // height.
            //
            // To make this padding non-interactive, we create another image object
            // with a custom alignment rect that excludes the padding.
            image = image!.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: 0, bottom: image!.size.height/2, right: 0))
            
            // Initialize the ‘pisa’ annotation image with the UIImage we just loaded.
            annotationImage = MGLAnnotationImage(image: image!, reuseIdentifier: reuseIdentifier)
        }
        
        return annotationImage
    }
    
    func reuseIdentifierForAnnotation(annotation: MGLAnnotation) -> String {
        var reuseIdentifier = "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)"
        if let title = annotation.title {
            reuseIdentifier += title!
        }
        if let subtitle = annotation.subtitle {
            reuseIdentifier += subtitle!
        }
        return reuseIdentifier
    }
    
    func determineHighlightedImage(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> Bool {
        if let closestEvent = self.closestEvent {
            let closestLat = closestEvent.Pin.coordinate.latitude
            let closestLong = closestEvent.Pin.coordinate.longitude
            if(closestLat == latitude && closestLong == longitude) {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
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
            var annotation : MGLAnnotation?
            var highlightedAnnotation : MGLAnnotation?
            
            let mapCenter = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            for pin in pins {
                let pinLocation = CLLocation(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
                let pinDistance = pinLocation.distance(from: mapCenter)
                
                // Fin pin that was previously marked by being the closest
                let reuseIdentifier = reuseIdentifierForAnnotation(annotation: pin)
                if let annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: reuseIdentifier) {
                    
                    if annotationImage.image == UIImage(named: "blue-college-15")! {
                        highlightedAnnotation = pin
                    }
                }
                
                if(pinDistance < minDistance) {
                    minDistance = pinDistance
                    title = pin.title!
                    eventID = pin.subtitle!
                    annotation = pin
                }
            }
            self.titleLabel.text = title
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            self.closestEvent = self.events[eventID!]
            self.plannedLabel.text = "\(self.closestEvent!.EventInterestedFBIDs.count)"
            self.liveLabel.text = "\(self.closestEvent!.EventThereFBIDs.count)"
            let nextOpenDateString = DateUtilities.convertDateToStringByFormat(date: self.closestEvent!.EventStart, dateFormat: DateUtilities.Constants.uiDisplayFormat)
            self.nextOpenLabel.text = nextOpenDateString
            
            if(self.closestEvent!.EventInterestedFBIDs[appDelegate.user!.FBID] != nil) {
                self.interestedButton.backgroundColor = FlockColors.FLOCK_GRAY
                self.interestedButton.setTitle("Uninterested", for: .normal)
            } else {
                self.interestedButton.backgroundColor = FlockColors.FLOCK_BLUE
                self.interestedButton.setTitle("Interested", for: .normal)
            }
            
            if(appDelegate.user!.LiveClubID != nil) {
                if(appDelegate.user!.LiveClubID! == closestEvent?.EventID) {
                    self.thereButton.backgroundColor = FlockColors.FLOCK_GRAY
                    self.thereButton.setTitle("Not There", for: .normal)
                } else {
                    self.thereButton.backgroundColor = FlockColors.FLOCK_BLUE
                    self.thereButton.setTitle("There", for: .normal)
                }
            } else {
                self.thereButton.backgroundColor = FlockColors.FLOCK_BLUE
                self.thereButton.setTitle("There", for: .normal)
            }
            
            /*if(highlightedAnnotation != nil && annotation != nil && highlightedAnnotation!.coordinate.latitude == annotation!.coordinate.latitude &&  highlightedAnnotation!.coordinate.longitude == annotation!.coordinate.longitude) {
             self.mapView!.removeAnnotation(highlightedAnnotation!)
             self.mapView!.addAnnotation(highlightedAnnotation!)
             
             self.mapView!.removeAnnotation(annotation!)
             self.mapView!.addAnnotation(annotation!)
             } else {
             if let highlightedAnnotation = highlightedAnnotation {
             let reuseIdentifier = reuseIdentifierForAnnotation(annotation: highlightedAnnotation)
             
             if let annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: reuseIdentifier) {
             Utilities.printDebugMessage("Erasing old highlighted image")
             annotationImage.image = UIImage(named: "blue-college-15")!
             }
             }
             
             // Update pin image
             if let annotation = annotation {
             let reuseIdentifier = reuseIdentifierForAnnotation(annotation: annotation)
             
             if let annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: reuseIdentifier) {
             Utilities.printDebugMessage("Setting highlighted image")
             annotationImage.image = UIImage(named: "white-college-15")!
             }
             }
             }*/
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
    
    func centerOnEvent() {
        let mapView = self.mapView!
        if let closestEvent = self.closestEvent {
            let eventLocation = CLLocationCoordinate2D(latitude: closestEvent.Pin.coordinate.latitude, longitude: closestEvent.Pin.coordinate.longitude)
            mapView.setCenter(eventLocation, animated: false)
        }
        
        // And popup subview
        
        self.eventToPass = self.closestEvent
        self.showCustomDialog(event: eventToPass!)
        
    }
    
    func centerOnPassedEvent(event: Event) {

        
        // And popup subview
        let mapView = self.mapView!
        self.eventToPass = event
        self.closestEvent = event
        let eventLocation = CLLocationCoordinate2D(latitude: event.Pin.coordinate.latitude, longitude: event.Pin.coordinate.longitude)
        mapView.setCenter(eventLocation, animated: false)
        self.showCustomDialog(event: event)
    }
    

    
    
    @IBAction func interestedButtonPressed(_ sender: Any) {
        /*
        let venueID = "-KeKwmy05LN6DpMkNmr1"
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let venues = appDelegate.venues
        let venue = venues[venueID]!
        self.venueToPass = venue
        self.eventToPass = self.closestEvent
        self.showCustomDialog(event: eventToPass!, startDisplayDate: nil)
        let eventLocation = CLLocationCoordinate2D(latitude: eventToPass!.Pin.coordinate.latitude, longitude: eventToPass!.Pin.coordinate.longitude)
        mapView!.setCenter(eventLocation, animated: false)*/
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let userFBID = appDelegate.user!.FBID
        if let event = self.closestEvent {
            let date = DateUtilities.convertDateToStringByFormat(date: event.EventStart, dateFormat: DateUtilities.Constants.fullDateFormat)
            var plannedAttendees = event.EventInterestedFBIDs
            plannedAttendees[userFBID] = userFBID

            let add = (self.interestedButton.currentTitle! == "Interested")
            self.attendEventWithConfirmation(date: date, eventID: event.EventID, add: add, specialEventID: nil, plannedFriendAttendeesForDate: plannedAttendees)
  
        }
        
        
        //self.interestedButton.isSelected = !self.interestedButton.isSelected
        
    }
    
    
    
    @IBAction func thereButtonPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.goLiveButtonPressed = true
        if (!Utilities.isInternetAvailable()) {
            let alert = SCLAlertView()
            _ = alert.showInfo("Oops!", subTitle: "Looks like you don't have internet! Connect to internet so you can go live on Flock")
        }
        else if(CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse) {
            appDelegate.locationManager.requestLocation()
            //appDelegate.presentNavBarActivityIndicator(navItem: self.navigationItem)
            
        }
        else if (CLLocationManager.authorizationStatus() == .notDetermined) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.locationManager.requestWhenInUseAuthorization()
        }
        else {
            let alert = SCLAlertView()
            let _ = alert.addButton("Settings", action: {
                UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString) as! URL)
            })
            _ = alert.showInfo("Oops!", subTitle: "Looks like you haven't setup your location services permissions. Hit the settings button in your profile to enable this for a better Flock experience!")
        }
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
    
    func showCustomDialog(event : Event) {
        
        // Create a custom view controller
        let popupSubView = PopupSubViewController(nibName: "PopupSubViewController", bundle: nil)
        
        popupSubView.delegate = self
        
        // Create the dialog
        let popup = PopupDialog(viewController: popupSubView, buttonAlignment: .horizontal, transitionStyle: .bounceDown, gestureDismissal: true)
        
        
        // Create second button
        let eventDate = DateUtilities.convertDateToStringByFormat(date: event.EventStart, dateFormat: "MMMM d")
        let attendButton = DefaultButton(title: "GO TO \(event.EventName.uppercased()) ON \(eventDate.uppercased())", dismissOnTap: true) {
            
            if (popupSubView.buttonIsInviteButton) {
                Utilities.printDebugMessage("Invite flock!")
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let userID = appDelegate.user!.FBID
                
                
                
                let eventID = self.eventToPass!.EventID
                let fullDate = popupSubView.stringsOfEvents[popupSubView.datePicker.selectedItemIndex]
                
                let plannedFriendUsersForEvent = popupSubView.allFriendsForEvent[popupSubView.stringsOfEvents[popupSubView.datePicker.selectedItemIndex]]![1] //1 for planned attendees
                var plannedAttendeesForEvent = [String:String]()
                
                for user in plannedFriendUsersForEvent {
                    Utilities.printDebugMessage(user.Name)
                    plannedAttendeesForEvent[user.FBID] = user.FBID
                }
                let specialEventID = popupSubView.specialEventID
                self.performSegueToSelector(userID: userID, venueID: eventID, fullDate: fullDate, plannedAttendeesForDate: plannedAttendeesForEvent, specialEventID: specialEventID)
                //popupSubView.performSegue(withIdentifier: "SELECTOR_IDENTIFIER", sender: (userID, venueID, fullDate, plannedAttendeesForDate, specialEventID))
            }
            else {
                Utilities.printDebugMessage("Attending \(event.EventName.uppercased())")
                let eventID = popupSubView.stringsOfEvents[popupSubView.datePicker.selectedItemIndex]
                
                let plannedFriendUsersForEvent = popupSubView.allFriendsForEvent[popupSubView.stringsOfEvents[popupSubView.datePicker.selectedItemIndex]]![1] //1 for planned attendees
                var plannedAttendeesForEvent = [String:String]()
                
                for user in plannedFriendUsersForEvent {
                    Utilities.printDebugMessage(user.Name)
                    plannedAttendeesForEvent[user.FBID] = user.FBID
                }
                
                let fullDateString = DateUtilities.getStringFromFullDate(date: event.EventStart)
                
                //Add Venue and present popup
                self.attendEventWithConfirmation(date: fullDateString, eventID: self.eventToPass!.EventID, add: true, specialEventID: popupSubView.specialEventID, plannedFriendAttendeesForDate: plannedAttendeesForEvent)
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
                            //self.displayAttendedPopup(venueName: event.EventName, venueID: eventID, attendFullDate: date, plannedAttendees: plannedFriendAttendeesForDate, specialEventID: specialEventID)
                            if(add) {
                                self.interestedButton.backgroundColor = FlockColors.FLOCK_GRAY
                                self.interestedButton.setTitle("Uninterested", for: .normal)
                                self.displayAttendedPopup(venueName: event.EventName, eventID: eventID, attendFullDate: date, plannedAttendees: plannedFriendAttendeesForDate)
                            } else {
                                self.interestedButton.backgroundColor = FlockColors.FLOCK_BLUE
                                self.interestedButton.setTitle("Interested", for: .normal)
                                self.displayUnAttendedPopup(eventName: event.EventName, attendFullDate: date)
                            }
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
    
    func displayUnAttendedPopup(eventName : String, attendFullDate : String) {
        let displayDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.uiDisplayFormat)
        let alert = SCLAlertView()
        //_ = alert.addButton("First Button", target:self, selector:#selector(PlacesTableViewController.shareWithFlock))
        print("Second button tapped")
        _ = alert.showSuccess("Confirmed", subTitle: "You've removed your plan to go to \(eventName) on \(displayDate)")
    }
    
    func displayAttendedPopup(venueName : String, eventID: String, attendFullDate : String, plannedAttendees: [String:String]) {
        let fullDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.fullDateFormat)
        let displayDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.uiDisplayFormat)
        let alert = SCLAlertView()
        alert.addButton("Invite Flock", action: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let user = appDelegate.user {
                self.selectFlockersToInvite(userID: user.FBID, eventID : eventID, fullDate : fullDate, plannedAttendees: plannedAttendees)
                
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
    
    func selectFlockersToInvite(userID : String, eventID: String, fullDate : String, plannedAttendees: [String:String]) {
        print("Selecting users")
        performSegue(withIdentifier: "SELECTOR_IDENTIFIER", sender: (userID, eventID, fullDate, plannedAttendees))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let peopleSelectorTableViewController = navController.topViewController as? PeopleSelectorTableViewController {
                if let (userID, eventID, fullDate, plannedAttendees) = sender as? (String, String, String, [String:String]) {
                    peopleSelectorTableViewController.userID = userID
                    peopleSelectorTableViewController.venueID = eventID
                    peopleSelectorTableViewController.fullDate = fullDate
                    peopleSelectorTableViewController.plannedAttendees = plannedAttendees
                }
            }
        }
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
    
    @IBAction func listButtonPressed(_ sender: Any) {
        self.view.bringSubview(toFront: tableView)
        self.tableView.isHidden = !self.tableView.isHidden
    }
    
    @IBAction func createEventButtonPressed(_ sender: Any) {
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false
        )
        let alert = SCLAlertView(appearance: appearance)
        //let txt = alert.addTextField("This is a text field title")
        //alert.addButton("Show Name") {
        //    Utilities.printDebugMessage("Text value: \(txt.text)")
        //}
        // Creat the subview
        
        self.isUserCreatingEvent = true
        

        
        let width = 210
        let subviewWidth = 216
        let subviewHeight = 150
        
        let subView = UIView(frame: CGRect(x: 0, y: 20, width: subviewWidth, height: subviewHeight))
        let x = (Int(subView.frame.width) - width) / 2
        let yOffset = 10
        let textFieldHeight = 30

        
        // Add textfield 1
        let textfield1 = SearchTextField(frame: CGRect(x: x, y: yOffset, width: width, height: textFieldHeight))
        textfield1.layer.borderColor = FlockColors.FLOCK_BLUE.cgColor
        textfield1.layer.borderWidth = 1.5
        textfield1.layer.cornerRadius = 5
        textfield1.placeholder = "Give your event a name!"
        textfield1.textAlignment = NSTextAlignment.center

        
        // Add textfield 2
        let textfield2 = SearchTextField(frame: CGRect(x: x, y: Int(textfield1.frame.maxY) + yOffset,width: width, height: textFieldHeight))
        textfield2.layer.borderColor = FlockColors.FLOCK_BLUE.cgColor
        textfield2.layer.borderWidth = 1.5
        textfield2.layer.cornerRadius = 5
        textfield2.placeholder = "(Optional) Describe your event"
        textfield2.textAlignment = NSTextAlignment.center
        
        // Add textfield 2
        let textfield3 = SearchTextField(frame: CGRect(x: x, y: Int(textfield2.frame.maxY) + yOffset,width: width, height: textFieldHeight))
        textfield3.layer.borderColor = FlockColors.FLOCK_BLUE.cgColor
        textfield3.layer.borderWidth = 1.5
        textfield3.layer.cornerRadius = 5
        textfield3.placeholder = "(Optional) Describe your event"
        textfield3.textAlignment = NSTextAlignment.center

        alert.addButton("Cancel") {
            print("Cancel button tapped")
            self.isUserCreatingEvent = false
            alert.hideView()
            /*let picker = DateTimePicker.show()
             picker.highlightColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 138.0/255.0, alpha: 1)
             picker.isDatePickerOnly = false // to hide time and show only date picker
             picker.completionHandler = { date in
             // do something after tapping done
             }*/
        }
        

        subView.addSubview(textfield1)
        subView.addSubview(textfield2)
        //subView.addSubview(textfield3)

        
        /*let picker = DateTimePicker.show()
        picker.highlightColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 138.0/255.0, alpha: 1)
        picker.completionHandler = { date in
            // do something after tapping done
        }*/
        
        let labelWidth = 80
        let labelHeight = 30
        let labelOffset = 10

        
//        let label = UILabel(frame: CGRect(x: x, y: Int(textfield2.frame.maxY) + yOffset, width: labelWidth, height: labelHeight))
//        label.text = "Private"
//        let checkbox = UISwitch(frame: CGRect(x: labelWidth + labelOffset, y: Int(textfield2.frame.maxY) + yOffset, width: 25, height: 25))
//        
//        //checkbox.lineWidth = 2.0
//        //checkbox.strokeColor = FlockColors.FLOCK_BLUE
//        //checkbox.trailStrokeColor = FlockColors.FLOCK_LIGHT_BLUE.withAlphaComponent(0.2)
//        checkbox.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        checkbox.isSelected = false
//        checkbox.onTintColor = FlockColors.FLOCK_BLUE
//        
//
//        subView.addSubview(checkbox)
//        
//        //updateSwitchValue(label: label)
//        subView.addSubview(label)
        
        let segmentedControl = UISegmentedControl(frame: CGRect(x: x, y: Int(textfield2.frame.maxY) + yOffset, width: width, height: textFieldHeight))
        //segmentedControl.setTitle("Public", forSegmentAt: 0)
        //segmentedControl.setTitle("Private", forSegmentAt: 1)
        segmentedControl.insertSegment(withTitle: "Public", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Private", at: 1, animated: false)
        segmentedControl.tintColor = FlockColors.FLOCK_BLUE
        segmentedControl.selectedSegmentIndex = 0
        subView.addSubview(segmentedControl)
        
        alert.addButton("Next") {
            print("Next button tapped")
            
            // Update values with types
            self.userCreatedEventName = textfield1.text
            self.userCreatedEventDescription = textfield2.text
            /*if( textfield3.text == "Show") {
             self.userCreatedEventType = EventType.show
             } else if (textfield3.text == "Pregame") {
             self.userCreatedEventType = EventType.party
             } else {
             self.userCreatedEventType = EventType.party
             }*/
            self.userCreatedEventType = EventType.custom
            
            if(segmentedControl.selectedSegmentIndex == 0) {
                self.userCreatedEventPrivacy = "Public"
            } else {
                self.userCreatedEventPrivacy = "Private"
            }
            self.createEventInfoView.isHidden = false
            self.view.bringSubview(toFront: self.createEventInfoView)
            self.view.bringSubview(toFront: self.createEventInfoLabel)
            self.view.bringSubview(toFront: self.createEventCancelButton)
            
            self.createEventInfoLabel.text = "Pick when your event starts"
            
            alert.hideView()
            
            let maxDays = 9
            let min = Date()
            let max = Date().addingTimeInterval(TimeInterval(60 * 60 * 24 * maxDays))
            let picker = DateTimePicker.show(minimumDate: min, maximumDate: max)
            picker.selectedDate = Date()
            picker.highlightColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 138.0/255.0, alpha: 1)

            picker.isDatePickerOnly = false
            
            picker.completionHandler = { date in
                // do something after tapping done
                self.createEventInfoLabel.text = "Pick when your event ends"
                
                self.userCreatedEventStart = date
                
                let newPicker = DateTimePicker.show(minimumDate: min, maximumDate: max)
                newPicker.selectedDate = Date()
                newPicker.highlightColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 138.0/255.0, alpha: 1)
                newPicker.isDatePickerOnly = false
                newPicker.completionHandler = { newDate in
                    // do something after tapping done
                    self.userCreatedEventEnd = newDate
                    self.createEventInfoLabel.text = "Press and hold on the map to select the location for your event!"
                }

                
            }
        }
        
        // Add the subview to the alert's UI property
        alert.customSubview = subView
        alert.showEdit("Create Your Own Event!", subTitle: "Create your very own event!")
    }

    
    func didDismissAlert () {
        Utilities.printDebugMessage("Alert dismissed")
    }
    
    @IBAction func plannedIconPressed(_ sender: Any) {
        self.showPlannedPopup()
    }

    @IBAction func plannedTableIconPressed(_ sender: Any) {
        self.showPlannedPopup()
    }
    
    @IBAction func liveIconPressed(_ sender: Any) {
        self.showLivePopup()
    }

    @IBAction func liveTableIconPressed(_ sender: Any) {
        self.showLivePopup()
    }
    
    func showPlannedPopup() {
        let alert = SCLAlertView()
        
        var event : Event
        //if searchController.isActive && searchController.searchBar.text != "" {
        //    venue = self.filteredVenues[indexPath.row]
        //} else {
        event = self.closestEvent!
        //}
        let countText = self.closestEvent!.EventInterestedFBIDs.count
        var peopleText = "people are"
        if Int(countText) == 1 {
            peopleText = "person is"
        }
        _ = alert.showInfo("Planned", subTitle: "\(countText) \(peopleText) planning to go to \(event.EventName) in the coming days")
        
    }
    
    func showLivePopup() {
        let alert = SCLAlertView()
        
        var event : Event
        //if searchController.isActive && searchController.searchBar.text != "" {
        //    venue = self.filteredVenues[indexPath.row]
        //} else {
        event = self.closestEvent!
        //}
        let countText = self.closestEvent!.EventThereFBIDs.count
        var peopleText = "people are"
        if Int(countText) == 1 {
            peopleText = "person is"
        }
        _ = alert.showInfo("Live", subTitle: "\(countText) \(peopleText) currently live at \(event.EventName)")
        
    }
    
    func setMapCenter(event: Event) {
        let mapView = self.mapView!
        
        let eventLocation = CLLocationCoordinate2D(latitude: event.Pin.coordinate.latitude, longitude: event.Pin.coordinate.longitude)
        mapView.setCenter(eventLocation, animated: false)
        
        self.titleLabel.text = event.EventName

        self.plannedLabel.text = "\(event.EventInterestedFBIDs.count)"
        self.liveLabel.text = "\(event.EventThereFBIDs.count)"
        let nextOpenDateString = DateUtilities.convertDateToStringByFormat(date: event.EventStart, dateFormat: DateUtilities.Constants.uiDisplayFormat)
        self.nextOpenLabel.text = nextOpenDateString
        
        self.closestEvent = event

        
    }
    
    // TABLE VIEW FUNCTIONS
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.separatorStyle = .none
        tableView.backgroundView?.isHidden = true
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
            cell.nextOpenLabel.text = "Open tonight"
        }
        else {
            cell.nextOpenLabel.text = "Open \(DateUtilities.convertDateToStringByFormat(date: event.EventStart, dateFormat: "E"))"
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
        self.showCustomDialog(event: event)
    }
}

protocol VenueDelegate: class {
    var venueToPass : Venue? {get set}
    func retrieveImage(imageURL : String?, venueID: String?, completion: @escaping (_ image: UIImage) -> ())
    func changeButtonTitle(title: String)
    var eventToPass : Event? {get set}
    func setMapCenter(event : Event)
    
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

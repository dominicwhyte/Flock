//
//  EventsViewController.swift
//  Flock
//
//  Created by Dominic Whyte on 19/03/17.
//  Copyright © 2017 Dominic Whyte. All rights reserved.
//

import UIKit
import Firebase

class EventsViewController: UIViewController, iCarouselDataSource, iCarouselDelegate, FlockSuggestionCollectionViewCellDelegate {
    var events: [Event] = []
    var userFBIDSofPlanningAttendees = [String]()
    
    var imageCache = [String : UIImage]()
    
    var tap = UITapGestureRecognizer()
    
    @IBOutlet var carousel: iCarousel!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var submitButton: ZFRippleButton!
    @IBOutlet weak var topCover: UIView!
    @IBOutlet weak var bottomCover: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setEventsInTimeFrame()
        
    }
    
    func setEventsInTimeFrame() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.events = []
        for (_,event) in appDelegate.specialEvents {
            if (DateUtilities.dateIsWithinValidTimeframe(date: event.EventDate)) {
                self.events.append(event)
            }
        }
    }
    
    func addTestEvents() {
        var newDict = [EventFirebaseConstants.eventName : "Capmandu" as AnyObject, EventFirebaseConstants.eventDate : "2017-03-17" as AnyObject, EventFirebaseConstants.specialEvent : true as AnyObject, EventFirebaseConstants.venueID : "-KeKwZoP21jkaCs4LFN0" as AnyObject, EventFirebaseConstants.eventAttendeeFBIDs : ["10208026242633924" : "10208026242633924", "10210419661620438" : "10210419661620438"] as AnyObject] as [String : AnyObject]
        var newEvent = Event(dict: newDict)
        events.append(newEvent)
        
        newDict = [EventFirebaseConstants.eventName : "Capmandu lit party lot's of fun" as AnyObject, EventFirebaseConstants.eventDate : "2017-03-17" as AnyObject, EventFirebaseConstants.specialEvent : true as AnyObject, EventFirebaseConstants.venueID : "-KeKwZoP21jkaCs4LFN0" as AnyObject, EventFirebaseConstants.eventAttendeeFBIDs : ["10208026242633924" : "10208026242633924"] as AnyObject] as [String : AnyObject]
        newEvent = Event(dict: newDict)
        
        events.append(newEvent)
        newDict = [EventFirebaseConstants.eventName : "Capmandu lit party lot's of fun" as AnyObject, EventFirebaseConstants.eventDate : "2017-03-17" as AnyObject, EventFirebaseConstants.specialEvent : true as AnyObject, EventFirebaseConstants.venueID : "-KeKwZoP21jkaCs4LFN0" as AnyObject, EventFirebaseConstants.eventAttendeeFBIDs : ["10208026242633924" : "10208026242633924", "10206799811314250" : "10206799811314250", "10210419661620438" : "10210419661620438"] as AnyObject] as [String : AnyObject]
        newEvent = Event(dict: newDict)
        events.append(newEvent)
        
        newDict = [EventFirebaseConstants.eventName : "Capmandu lit party lot's of fun" as AnyObject, EventFirebaseConstants.eventDate : "2017-03-17" as AnyObject, EventFirebaseConstants.specialEvent : true as AnyObject, EventFirebaseConstants.venueID : "-KeKwZoP21jkaCs4LFN0" as AnyObject, EventFirebaseConstants.eventAttendeeFBIDs : ["10208026242633924" : "10208026242633924", "10206799811314250" : "10206799811314250", "10210419661620438" : "10210419661620438"] as AnyObject, EventFirebaseConstants.eventImageURL : "https://firebasestorage.googleapis.com/v0/b/flock-43b66.appspot.com/o/message_images%2F1FD8CE52-BFC2-48A6-885E-F842C5E7B01C?alt=media&token=fc3d3624-6b3f-4577-9a29-594c47e9deb8" as AnyObject] as [String : AnyObject]
        newEvent = Event(dict: newDict)
        events.append(newEvent)
    }
    
    
    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.setContentOffset(collectionView.contentOffset, animated:false) // Stops collection view if it was scrolling.
        
        super.viewDidLoad()
        carousel.type = .linear
        carousel.isPagingEnabled = true
        
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.backgroundView = nil
        
        if (events.count != 0) {
            updateUINoCollectionReload()
        }
        
        tap.numberOfTapsRequired = 2  // add double tap
        tap.addTarget(self, action: "goToChatFromDoubleTap")
        collectionView.isUserInteractionEnabled = true
        self.collectionView.addGestureRecognizer(tap)
        
        
        self.topCover.setNeedsDisplay()
        
    }
    
    func goToChatFromDoubleTap(){
        var pointInCollectionView: CGPoint = tap.location(in: self.collectionView)
        if(self.collectionView.indexPathForItem(at: pointInCollectionView) != nil) {
            var indexPath: IndexPath = self.collectionView.indexPathForItem(at: pointInCollectionView)!
            
            var selectedCell: FlockSuggestionCollectionViewCell = self.collectionView.cellForItem(at: indexPath)! as! FlockSuggestionCollectionViewCell
            let friendFBID = selectedCell.userToFriendFBID
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if let user = appDelegate.user, let friendUser = appDelegate.users[friendFBID!] {
                if let channelID = user.ChannelIDs[friendFBID!] {
                    performSegue(withIdentifier: "CHAT_IDENTIFIER", sender: (channelID, friendUser))
                }
            }
            
            //if (friendFBID != nil) {
            //    appDelegate.openChatController(FBID: friendFBID!)
            //}
            // Rest code
            Utilities.printDebugMessage("I just got double tapped double time")
        }
        
    }
    
    func goToChat(friendFBID: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let user = appDelegate.user, let friendUser = appDelegate.users[friendFBID] {
            if let channelID = user.ChannelIDs[friendFBID] {
                performSegue(withIdentifier: "CHAT_IDENTIFIER", sender: (channelID, friendUser))
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        Utilities.applyVerticalGradient(aView: topCover, colorTop: FlockColors.FLOCK_GRAY, colorBottom: FlockColors.FLOCK_LIGHT_GRAY)
        super.viewWillLayoutSubviews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Utilities.applyVerticalGradient(aView: bottomCover, colorTop: FlockColors.FLOCK_LIGHT_BLUE, colorBottom: FlockColors.FLOCK_GOLD)
        bottomCover.backgroundColor = UIColor.white
        carousel.reloadData()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.eventsNeedsToUpdate) {
            Utilities.printDebugMessage("Updating events page")
            appDelegate.eventsNeedsToUpdate = false
            self.updateUI()
        }
    }
    
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return events.count
    }
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        
        if (index == carousel.currentItemIndex) {
            if let currentEventView = carousel.currentItemView as? EventView {
                currentEventView.flipView()
            }
            else {
                Utilities.printDebugMessage("Error getting EventView")
            }
        }
    }
    
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
        updateUI()
    }
    
    func setupLabelForNoEvents() {
        infoLabel.text = "No upcoming events!"
        submitButton.isEnabled = false
    }
    
    func setupLabelAndButton(event : Event) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let userFriends = appDelegate.user!.Friends
        let attendeesFBIDs = event.EventAttendeeFBIDs
        var friendsCount = 0
        for (fbid,_) in attendeesFBIDs {
            if (userFriends[fbid] != nil) {
                friendsCount += 1
            }
        }
        
        let peoplePlurality = Utilities.setPluralityForPeople(count: attendeesFBIDs.count)
        let startText = "\(attendeesFBIDs.count) \(peoplePlurality) going "
        let endText = "(\(friendsCount) \(Utilities.setPlurality(string: "friend", count: friendsCount)))"
        let totalText = startText + endText
        let range = (totalText as NSString).range(of: endText)
        let attributedString = NSMutableAttributedString(string:totalText)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: FlockColors.FLOCK_BLUE , range: range)
        infoLabel.attributedText = attributedString
        
        if (event.EventAttendeeFBIDs[appDelegate.user!.FBID] == nil) {
            submitButton.setTitle("Go to \(event.EventName)", for: .normal)
        }
        else {
            submitButton.setTitle("Invite your Flock", for: .normal)
        }
        
        submitButton.titleLabel?.minimumScaleFactor = 0.5
        submitButton.titleLabel?.numberOfLines = 1
        submitButton.titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        
        var eventView: EventView
        
        //reuse view if available, otherwise create a new view
        if let view = view as? EventView {
            eventView = view
            eventView.setupEventView(event: events[index])
            //get a reference to the label in the recycled view
            //label = itemView.viewWithTag(1) as! UILabel
        } else {
            //don't do anything specific to the index within
            //this `if ... else` statement because the view will be
            //recycled and used with other index values later
            let width = self.view.frame.width
            
            var offset = 170.0
            if(width < 325) {
                offset = 70.0
            } else if (width < 345) {
                offset = 90.0
            } else if (width < 365) {
                offset = 110.0
            } else if (width < 385) {
                offset = 130.0
            } else if (width < 405) {
                offset = 150.0
            }
            
            //eventView = EventView(frame: CGRect(x: 0, y: 0, width: width - 150, height: width - 150))
            eventView = EventView(frame: CGRect(x: 0, y: 0, width: width - CGFloat(offset), height: width - CGFloat(offset)))
            eventView.setupEventView(event: events[index])
            
            //            label = UILabel(frame: itemView.bounds)
            //            label.backgroundColor = .clear
            //            label.textAlignment = .center
            //            label.font = label.font.withSize(50)
            //            label.tag = 1
            //            itemView.addSubview(label)
        }
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        
        
        return eventView
    }
    
    
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {
            return value * 1.1
        }
        //enable wrap
        if (option == .wrap && events.count > 2) {
            return 1 //living the objective C life though
        }
        
        return value
    }
    
    func updateDataAndCarouselAndCollectionView(_ completion: @escaping (Bool) -> Void) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllDataWithoutUpdatingLocation { (success) in
            DispatchQueue.main.async {
                if (success) {
                    self.updateUI()
                }
                else {
                    Utilities.printDebugMessage("Error updating and reloading data in table view")
                }
                completion(success)
            }
        }
    }
    
    func updateUINoCollectionReload() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        setEventsInTimeFrame()
        
        let event = self.events[self.carousel.currentItemIndex]
        self.userFBIDSofPlanningAttendees = Array(event.EventAttendeeFBIDs.values)
        userFBIDSofPlanningAttendees = userFBIDSofPlanningAttendees.filter { (fbid) -> Bool in
            return (appDelegate.friends[fbid] != nil)
        }
        
        self.setupLabelAndButton(event: event)
    }
    
    func updateUI() {
        if (events.count != 0) {
            updateUINoCollectionReload()
        } else {
            setupLabelForNoEvents()
        }
        self.collectionView.reloadData()
    }
    
    
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        if (events.count != 0) {
            let event = events[carousel.currentItemIndex]
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if (event.EventAttendeeFBIDs[appDelegate.user!.FBID] == nil) {
                let loadingScreen = Utilities.presentLoadingScreen(vcView: self.view)
                FirebaseClient.addUserToVenuePlansForDate(date: DateUtilities.getStringFromDate(date: event.EventDate), venueID: event.VenueID, userID: appDelegate.user!.FBID, add: true, specialEventID: event.EventID, completion: { (success) in
                    if (success) {
                        Utilities.printDebugMessage("Successfully made plan to go to event")
                    }
                    else {
                        Utilities.printDebugMessage("Error making making to go to event")
                    }
                    self.updateDataAndCarouselAndCollectionView({ (secondarySuccess) in
                        if (!secondarySuccess) {
                            Utilities.printDebugMessage("Error refreshing events page")
                        }
                        Utilities.removeLoadingScreen(loadingScreenObject: loadingScreen, vcView: self.view)
                    })
                })
            }
            else {
                Utilities.printDebugMessage("Invite flock!")
                let userID = appDelegate.user!.FBID
                let venueID = appDelegate.venues[event.VenueID]!.VenueID
                let fullDate = DateUtilities.convertDateToStringByFormat(date: event.EventDate, dateFormat: DateUtilities.Constants.fullDateFormat)
                let plannedAttendees = event.EventAttendeeFBIDs
                let specialEventID = event.EventID
                performSegue(withIdentifier: "SELECTOR_IDENTIFIER", sender: (userID, venueID, fullDate, plannedAttendees, specialEventID))
            }
            carousel.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController {
            if let peopleSelectorTableViewController = navController.topViewController as? PeopleSelectorTableViewController {
                if let (userID, venueID, fullDate, plannedAttendees, specialEventID) = sender as? (String, String, String, [String:String], String) {
                    peopleSelectorTableViewController.userID = userID
                    peopleSelectorTableViewController.venueID = venueID
                    peopleSelectorTableViewController.fullDate = fullDate
                    peopleSelectorTableViewController.plannedAttendees = plannedAttendees
                    peopleSelectorTableViewController.specialEventID = specialEventID
                }
            }
            else if let chatViewController = navController.topViewController as? ChatViewController {
                if let (channelID, friendUser) = sender as? (String, User) {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    if let friendImage = imageCache[friendUser.PictureURL], let userImage = imageCache[appDelegate.user!.PictureURL] {
                        chatViewController.userImage = userImage
                        chatViewController.friendImage = friendImage
                    }
                    chatViewController.channelRef = FIRDatabase.database().reference().child("channels").child(channelID)
                    chatViewController.friendUser = friendUser
                    chatViewController.channelID = channelID
                }
            }
        }
    }
    
    
}

extension EventsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    //Retrieve image with caching
    func retrieveImage(imageURL : String, venueID: String?, imageView : UIImageView) {
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
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.userFBIDSofPlanningAttendees.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FLOCK_SUGGESTION_COLLECTION_CELL", for: indexPath) as! FlockSuggestionCollectionViewCell
        cell.cellType = FlockSuggestionCollectionViewCell.CollectionViewCellType.messager
        //        cell.delegate = self
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let suggestedUser = appDelegate.users[self.userFBIDSofPlanningAttendees[indexPath.row]]!
        let userImage = cell.viewWithTag(2) as! UIImageView
        let nameLabel = cell.viewWithTag(1) as! UILabel
        cell.userToFriendFBID = suggestedUser.FBID
        nameLabel.text = suggestedUser.Name
        userImage.makeViewCircle()
        self.retrieveImage(imageURL: suggestedUser.PictureURL, venueID: nil, imageView: userImage)
        cell.flockSuggestionCollectionViewCellDelegate = self
        if let delegate = cell.delegate {
            if delegate.FBIDWasFlocked(fbid: suggestedUser.FBID) {
                cell.setPerformedUI()
            }
            else {
                cell.resetUINewCell()
            }
        }
        else {
            
            cell.resetUINewCell()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Collection view at row \(collectionView.tag) selected index path \(indexPath)")
    }
}

protocol FlockSuggestionCollectionViewCellDelegate: class {
    func goToChat(friendFBID: String)
}


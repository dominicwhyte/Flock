//
//  RatingViewController.swift
//  PopupDialog
//
//  Created by Martin Wildfeuer on 11.07.16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import MVHorizontalPicker
import SAConfettiView
import SCLAlertView

class PopupSubViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    
    struct Constants {
        static let SECTION_TITLES = ["Live", "Interested"]
        static let LIVE_SECTION_ROW = 0
        static let PLANNED_SECTION_ROW = 1
        static let CELL_HEIGHT : CGFloat = 74.0
    }
    @IBOutlet weak var gradientBackgroundForImage: UIView!
    
    @IBOutlet weak var optionalEventNameLabel: UILabel!
    @IBOutlet weak var tableViewFrameView: UIView!
    @IBOutlet weak var datePicker: MVHorizontalPicker!
    @IBOutlet weak var venueImageView: UIImageView!
    weak var delegate: VenueDelegate?
    
    @IBOutlet weak var liveAttendeesLabel: UILabel!
    @IBOutlet weak var liveFriendsLabel: UILabel!
    @IBOutlet weak var plannedAttendeesLabel: UILabel!
    @IBOutlet weak var plannedFriendsLabel: UILabel!
    
    
    let INDEX_OF_PLANNED_ATTENDEES = 1
    let INDEX_OF_LIVE_ATTENDEES = 0
    var specialEventID : String?
    var stringsOfEvents : [String] = [] // Full dates
    var imageCache = [String: UIImage]()
    //keys are yyyy-MM-dd
    var allFriendsForEvent : [String : [[User]]] = [:]
    var allPlannedAttendeesForEventCountDict = [String : Int]()
    var allCurrentAttendeesForEventCountDict = [String : Int]()
    var allPlannedFriendsForEventCountDict = [String : Int]()
    var allCurrentFriendsForEventCountDict = [String : Int]()
    
    var buttonIsInviteButton = false
    
    var tableView: UITableView  =   UITableView()
    
    var startDate : Date?
    
    func setStartDate(date : Date) {
        self.startDate = date
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let eventID = self.delegate!.eventToPass!.EventID
        
        if let startIndex = stringsOfEvents.index(of: eventID) {
            datePicker.setSelectedItemIndex(startIndex, animated: true)
            setAttendButtonTitle()
            setLabelsForGraphic()
            self.tableView.reloadData()
        }
        
        
    }
    
    
    @IBAction func liveIconPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentEventID = self.stringsOfEvents[datePicker.selectedItemIndex]
        let eventString = appDelegate.activeEvents[currentEventID]!.EventName
        let alert = SCLAlertView()
        _ = alert.showInfo("Live Total", subTitle: "The number of people currently live at \(eventString)")
    }
    
    
    @IBAction func liveFriendsIconPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentEventID = self.stringsOfEvents[datePicker.selectedItemIndex]
        let eventString = appDelegate.activeEvents[currentEventID]!.EventName
        let alert = SCLAlertView()
        _ = alert.showInfo("Live Friends", subTitle: "The number of friends currently live at \(eventString)")
    }
    
    @IBAction func plannedPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentEventID = self.stringsOfEvents[datePicker.selectedItemIndex]
        let eventString = appDelegate.activeEvents[currentEventID]!.EventName
        let alert = SCLAlertView()
        _ = alert.showInfo("Planned Total", subTitle: "The number of people interested in \(eventString)")
    }
    
    @IBAction func plannedFriendsPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentEventID = self.stringsOfEvents[datePicker.selectedItemIndex]
        let eventString = appDelegate.activeEvents[currentEventID]!.EventName
        let alert = SCLAlertView()
        _ = alert.showInfo("Planned Friends", subTitle: "The number of friends interested in \(eventString)")
    }
    
    
    override func viewDidLoad() {
        
        
        datePicker.titles = self.determineTitleOrder()
        datePicker.itemWidth = 110
        
        datePicker.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        datePicker.borderWidth = 1
        
        datePicker.tintColor = UIColor.black
        super.viewDidLoad()
        delegate?.retrieveImage(imageURL: (delegate?.eventToPass?.EventImageURL), venueID: (delegate?.eventToPass?.EventID)!, completion: { (image) in
            DispatchQueue.main.async {
                self.venueImageView.image = image
            }
        })
        
        //tableview
        tableView.frame         =   tableViewFrameView.frame
        let frame = CGRect(x: tableViewFrameView.frame.minX, y: tableViewFrameView.frame.minY, width: tableViewFrameView.frame.width + 50.0, height: tableViewFrameView.frame.height)
        tableView.frame = frame
        tableView.delegate      =   self
        tableView.dataSource    =   self
        tableView.allowsSelection = false
        
        
        tableView.register(UINib(nibName: "VenueFriendTableViewCell", bundle: nil), forCellReuseIdentifier: "VENUE_FRIEND")
        setFriendsForEventID(event: delegate!.eventToPass!)
        setAttendButtonTitle()
        setLabelsForGraphic()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if (appDelegate.friendPlanCountDict.count == 0 ) {
            setFriendSubtitle()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapDatePicker(_:)))
        self.datePicker.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        //self.datePicker.addGestureRecognizer(tap)
        
        self.view.addSubview(tableView)
        
        gradientBackgroundForImage.frame = CGRect(x: 0.0, y: 0.0, width: tableViewFrameView.frame.width + 50.0, height: gradientBackgroundForImage.frame.height)
        Utilities.applyVerticalGradient(aView: gradientBackgroundForImage, colorTop: UIColor.white, colorBottom: UIColor.black)
    }
    /*
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentDay = stringsOfEvents[datePicker.selectedItemIndex]
        let friendsAttendingClubForDay = self.allFriendsForDate[currentDay]!
        let friend = friendsAttendingClubForDay[indexPath.section][indexPath.row]
        return friend.FBID == appDelegate.user!.FBID
        
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
        }
    }
    */
    
    func setFriendSubtitle() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        var planCountDict = [String:Int]()
        // Makes array of friends in sections
        for friend in Array(appDelegate.friends.values) {
            
            if(friend.Plans.count > 0) {
                let activeEvents = appDelegate.activeEvents
                
                var planCount = 0
                for (visitID, _) in friend.Plans {
                    if let event = activeEvents[visitID] {
                        if(DateUtilities.dateIsValidEventTimeFrame(eventStart: event.EventStart, eventEnd: event.EventEnd)) {
                            planCount += 1
                        }
                    }
                }
                
                planCountDict[friend.FBID] = planCount
                
            }
        }
        appDelegate.friendPlanCountDict = planCountDict
    }
    
    func displayUnAttendedPopup(venueName : String, attendFullDate : String) {
        let displayDate = DateUtilities.convertDateToStringByFormat(date: DateUtilities.getDateFromString(date: attendFullDate), dateFormat: DateUtilities.Constants.uiDisplayFormat)
        let alert = SCLAlertView()
        //_ = alert.addButton("First Button", target:self, selector:#selector(PlacesTableViewController.shareWithFlock))
        print("Second button tapped")
        _ = alert.showSuccess("Confirmed", subTitle: "You've removed your plan to go to \(venueName) on \(displayDate)")
    }
    
    func displayUnLived(venueName : String) {
        let alert = SCLAlertView()
        //_ = alert.addButton("First Button", target:self, selector:#selector(PlacesTableViewController.shareWithFlock))
        print("Second button tapped")
        _ = alert.showSuccess("Confirmed", subTitle: "You've removed your live status for \(venueName)")
    }

    //UpdateTableViewDelegate function
    func updateDataAndTableView(_ completion: @escaping (Bool) -> Void) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.updateAllDataWithoutUpdatingLocation { (success) in
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if (!success) {
                    Utilities.printDebugMessage("Error updating and reloading data in table view")
                }
                completion(success)
            }
        }
    }
 
    func tapDatePicker(_ sender: UITapGestureRecognizer) {
        print("\(sender.location(in: datePicker))")
        print("Item Width: \(datePicker.itemWidth))")
        print("Frame Width: \(datePicker.frame.width)")
        
        if(sender.location(in: datePicker).x > (datePicker.frame.width + datePicker.itemWidth)/2 ) {
            Utilities.printDebugMessage("HI I SHOULD GO RIGHT NOW PLEASE!!")
            if(datePicker.selectedItemIndex < datePicker.titles.count - 1) {
                datePicker.setSelectedItemIndex(datePicker.selectedItemIndex + 1, animated: true)
                let currentEventID = self.stringsOfEvents[datePicker.selectedItemIndex]
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let event = appDelegate.activeEvents[currentEventID]!
                setFriendsForEventID(event: event)
                setAttendButtonTitle()
                setLabelsForGraphic()
                if (appDelegate.friendPlanCountDict.count == 0 ) {
                    setFriendSubtitle()
                }
                self.tableView.reloadData()
                self.delegate?.setMapCenter(event: event)
            }
        } else if (sender.location(in: datePicker).x < (datePicker.frame.width - datePicker.itemWidth)/2) {
            Utilities.printDebugMessage("HI I SHOULD GO LEFT NOW PLEASE!!")
            if(datePicker.selectedItemIndex > 0) {
                datePicker.setSelectedItemIndex(datePicker.selectedItemIndex - 1, animated: true)
                let currentEventID = self.stringsOfEvents[datePicker.selectedItemIndex]
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let event = appDelegate.activeEvents[currentEventID]!
                setFriendsForEventID(event: event)
                setAttendButtonTitle()
                setLabelsForGraphic()
                if (appDelegate.friendPlanCountDict.count == 0 ) {
                    setFriendSubtitle()
                }
                self.tableView.reloadData()
                self.delegate?.setMapCenter(event: event)
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currentDay = self.stringsOfEvents[datePicker.selectedItemIndex]
        let friendsAttendingClubForDay = self.allFriendsForEvent[currentDay]!
        return friendsAttendingClubForDay[section].count
    }
    
    func tableView(_ cellForRowAttableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let currentEvent = self.stringsOfEvents[datePicker.selectedItemIndex]
        let friendsAttendingClubForEvent = self.allFriendsForEvent[currentEvent]!
        let friend = friendsAttendingClubForEvent[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "VENUE_FRIEND")! as! VenueFriendTableViewCell
        cell.isEditing = true
        cell.profilePic.makeViewCircle()
        cell.nameLabel.text = friend.Name
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let planCount = appDelegate.friendPlanCountDict[friend.FBID]!
        if(indexPath.section == Constants.LIVE_SECTION_ROW) {
            cell.subtitleLabel.text = "Currently Live"
        }
        else {
            cell.subtitleLabel.text = Utilities.setPlurality(string: "\(planCount) plan", count: planCount)
        }
        retrieveImage(imageURL: friend.PictureURL, venueID: nil, imageView: cell.profilePic)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 25))
        //returnedView.backgroundColor = FlockColors.FLOCK_BLUE
        
        let gradient = CAGradientLayer()
        
        gradient.frame = returnedView.bounds
        
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = [FlockColors.FLOCK_BLUE.cgColor, FlockColors.FLOCK_LIGHT_BLUE.cgColor]
        
        returnedView.layer.insertSublayer(gradient, at: 0)
        
        
        
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: view.frame.size.width, height: 25))
        label.textColor = .white
        label.text = Constants.SECTION_TITLES[section]
        returnedView.addSubview(label)
        
        return returnedView
    }
    
    @IBAction func pickerValueChanged(_ sender: MVHorizontalPicker) {
        let currentEventID = self.stringsOfEvents[datePicker.selectedItemIndex]
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let event = appDelegate.activeEvents[currentEventID]!
        setFriendsForEventID(event: event)
        setAttendButtonTitle()
        setLabelsForGraphic()
        if (appDelegate.friendPlanCountDict.count == 0 ) {
            setFriendSubtitle()
        }
        self.tableView.reloadData()
        self.delegate?.setMapCenter(event: event)
    }
    
    func setLabelsForGraphic() {
        let currentEventID = self.stringsOfEvents[datePicker.selectedItemIndex]
        self.liveFriendsLabel.text = Utilities.setPlurality(string: "\(self.allCurrentFriendsForEventCountDict[currentEventID]!) Live\nFriend", count: self.allCurrentFriendsForEventCountDict[currentEventID]!)
        self.liveAttendeesLabel.text = "\(self.allCurrentAttendeesForEventCountDict[currentEventID]!) Live\nTotal"
        self.plannedFriendsLabel.text = Utilities.setPlurality(string: "\(self.allPlannedFriendsForEventCountDict[currentEventID]!) Planned\nFriend", count: self.allPlannedFriendsForEventCountDict[currentEventID]!)
        self.plannedAttendeesLabel.text = "\(self.allPlannedAttendeesForEventCountDict[currentEventID]!) Planned\nTotal"
        
    }
    
    func setAttendButtonTitle() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentEventID = self.stringsOfEvents[datePicker.selectedItemIndex]
        let event = appDelegate.activeEvents[currentEventID]!
        let eventName = event.EventName
        let dateString = self.stringsOfEvents[datePicker.selectedItemIndex]
        let date = event.EventStart
        let dateStringInFormat = DateUtilities.convertDateToStringByFormat(date: date, dateFormat: "MMMM d")
        
        venueImageView.alpha = 1
        optionalEventNameLabel.text = ""
        
        specialEventID = nil
        
        
        var specialEventName : String?
        
        // UNCOMMENT FOR SPECIAL EVENT HANDLING
        
        /*for (_,event) in venue.Events {
            if (event.EventStart == date) {
                if (true) {
                    Utilities.printDebugMessage("This event is special!")
                    handleSpecialEvent(event: event)
                    specialEventName = event.EventName
                    specialEventID = event.EventID
                    break
                }
                else {
                    Utilities.printDebugMessage("This venue is open!")
                    handleRegularEvent(event: event)
                    break
                }
            }
        }*/
        
        var inviteButton = false
        buttonIsInviteButton = false
        
        Utilities.printDebugMessage("Checking invite")
        
        let plans = appDelegate.user!.Plans
        
        for (_, plan) in plans {
            Utilities.printDebugMessage("Checking plans")
            if(plan.venueID == event.EventID) {
                inviteButton = true
                break
            }
        }
        
        /*if let plannedUsersForEvent = self.allFriendsForEvent[event.EventID]?[INDEX_OF_PLANNED_ATTENDEES] {
            Utilities.printDebugMessage("Looking at users")
            for user in plannedUsersForEvent {
                Utilities.printDebugMessage("checking")
                if(user.FBID == appDelegate.user!.FBID) {
                    Utilities.printDebugMessage("disabling")
                    inviteButton = true
                    break
                }
            }
        } else {
            inviteButton = true
            Utilities.printDebugMessage("Error with date dictionary - doesn't contain dateString")
        }*/
        if (inviteButton) {
            buttonIsInviteButton = true
            self.delegate?.changeButtonTitle(title: "INVITE YOUR FLOCK")
        }
        else {
            
            if (specialEventID != nil) {
                self.delegate?.changeButtonTitle(title: "GO TO \(specialEventName!.uppercased()) @ \(eventName)")
            }
            else {
                self.delegate?.changeButtonTitle(title: "GO TO \(eventName) ON \(dateStringInFormat.uppercased())")
            }
        }
        
    }
    
    
    
    func handleRegularEvent(event : Event) {
        
        UIView.animate(withDuration: 0.5, animations: { 
            self.venueImageView.alpha = 0.7
            if(event.EventName != "") {
                self.optionalEventNameLabel.text = event.EventName
            } else {
                self.optionalEventNameLabel.text = "Open"
            }
        })


    }
    
    func handleSpecialEvent(event : Event) {
        
        UIView.animate(withDuration: 0.5, animations: { 
            self.venueImageView.alpha = 0.7
            self.optionalEventNameLabel.text = event.EventName
        }) { (success) in
            let confettiView = SAConfettiView(frame: self.view.bounds)
            confettiView.type = SAConfettiView.ConfettiType.confetti
            confettiView.intensity = 0.6
            self.venueImageView.addSubview(confettiView)
            
            confettiView.startConfetti()
            let delayInSeconds = 3.0
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
                DispatchQueue.main.async {
                    confettiView.stopConfetti()
                    confettiView.removeFromSuperview()
                    
                }
            }
        }
        
        
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let currentDay = self.stringsOfEvents[datePicker.selectedItemIndex]
        let friendsAttendingClubForDay = self.allFriendsForEvent[currentDay]!
        return friendsAttendingClubForDay.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.SECTION_TITLES[section]
    }
    
    //Set the dictionary to use for tableview display, maps from full string dates to array of arrays of users
    func setFriendsForEventID(event : Event ) {

        var allFriendsForEvent : [String : [[User]]] = initializeAllDictionaries()
        let plannedAttendees = event.EventInterestedFBIDs
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let friends = appDelegate.friends
        let users = appDelegate.users
        let eventID = event.EventID
        for (_, plannedAttendee) in plannedAttendees {
            Utilities.printDebugMessage("Going through attendee: \(plannedAttendee)")
            if let friend = friends[plannedAttendee] {
                Utilities.printDebugMessage("\(plannedAttendee) is a friend.")
                //check that there is not already a plan for this friend for this day
                
                //KEY: this check could be removed for GH purposes
                if(allFriendsForEvent[eventID] != nil) {
                    if (!allFriendsForEvent[eventID]![self.INDEX_OF_PLANNED_ATTENDEES].contains(friend)) {
                        allFriendsForEvent[eventID]![self.INDEX_OF_PLANNED_ATTENDEES].append(friend)
                    
                        self.allPlannedFriendsForEventCountDict[eventID]! += 1
                        self.allPlannedAttendeesForEventCountDict[eventID]! += 1
                    }
                }
            }
            else if let user = users[plannedAttendee] {
                            
                self.allPlannedAttendeesForEventCountDict[eventID]! += 1
            }
        }
        
        var liveUsers : [User] = []
        for (_, currentAttendee) in event.EventThereFBIDs {
            if let friend = friends[currentAttendee] {
                liveUsers.append(friend)
            }
        }
        self.allCurrentAttendeesForEventCountDict[eventID] = event.EventThereFBIDs.count
        self.allCurrentFriendsForEventCountDict[eventID] = liveUsers.count
        allFriendsForEvent[eventID]![INDEX_OF_LIVE_ATTENDEES] = liveUsers
        self.allFriendsForEvent = allFriendsForEvent
    }
    
    func initializeAllDictionaries() -> [String : [[User]]] {
        var plannedFriendsForDate : [String : [[User]]] = [:]
        for event in stringsOfEvents {
            plannedFriendsForDate[event] = [[],[]]
            allPlannedAttendeesForEventCountDict[event] = 0
            allCurrentAttendeesForEventCountDict[event] = 0
            allPlannedFriendsForEventCountDict[event] = 0
            allCurrentFriendsForEventCountDict[event] = 0
        }
        return plannedFriendsForDate
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.CELL_HEIGHT
    }
    
    
    
    //Retrieve image with caching
    func retrieveImage(imageURL : String, venueID : String?, imageView : UIImageView) {
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
    
    // Determines the order for the day of the week by getting the current day, finding the index in
    // a standard week, and iterating through array
    func determineTitleOrder() -> [String] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let activeEvents = appDelegate.activeEvents
        var titleArray : [String] = []
        var fullArray : [String] = []
        for (eventID, event) in activeEvents {
            Utilities.printDebugMessage(event.EventName)
            titleArray.append(event.EventName)
            fullArray.append(eventID)
        }
        self.stringsOfEvents = fullArray
        return titleArray
    }
    
}
